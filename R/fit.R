#' Fit the expected-gain model
#'
#' Marginal maximum likelihood on a theta grid, in two stages: (1) the
#' attempt-1 ability distribution of repeaters, N(mu1, s1); (2) growth
#' `theta2 = theta1 + X beta + N(0, sigma_growth)` from attempt-1 responses
#' and attempt-2 responses to **new items only**. Because exposed items never
#' enter the growth model, preknowledge cannot inflate the expected gain, and
#' conditioning on the full attempt-1 likelihood handles regression to the mean.
#'
#' @param data An `rt_data` (or `rt_sim`) object.
#' @param growth One-sided formula for mean growth, evaluated in `data$persons`.
#' @param grid Theta grid.
#' @return An `rt_fit` object.
#' @examples
#' sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
#' fit <- rt_fit(sim)
#' fit    # growth coefficients: intercept, log(days_between), remediation
#' @export
rt_fit <- function(data, growth = ~ log(days_between) + remediation,
                   grid = seq(-5, 5, by = 0.2)) {
  if (inherits(data, "rt_sim")) data <- data$data
  r <- data$responses; P <- data$persons; ids <- P$person
  N <- length(ids); G <- length(grid); h <- grid[2] - grid[1]
  idx <- match(r$person, ids)
  a1 <- r$attempt == 1; a2new <- r$attempt == 2 & !r$exposed
  LL1 <- grid_loglik(idx[a1], r$b[a1], r$x[a1], N, grid)
  LL2 <- grid_loglik(idx[a2new], r$b[a2new], r$x[a2new], N, grid)
  L1 <- exp(LL1 - apply(LL1, 1, max)); L2 <- exp(LL2 - apply(LL2, 1, max))

  # Stage 1: repeater ability distribution at attempt 1.
  nll1 <- function(p) {
    pr <- stats::dnorm(grid, p[1], exp(p[2])); pr <- pr / sum(pr)
    -sum(log(drop(L1 %*% pr) + 1e-300))
  }
  o1 <- stats::optim(c(0, 0), nll1, method = "BFGS")
  mu1 <- o1$par[1]; s1 <- exp(o1$par[2])

  # Stage 2: growth. With the prior fixed, the likelihood is
  #   sum_d C_d(n) * N(d h - m_n; 0, sigma) h,
  # where C_d(n) = sum_g A[n, g] L2[n, g + d] does not depend on the growth
  # parameters and is computed once.
  pr1 <- stats::dnorm(grid, mu1, s1); pr1 <- pr1 / sum(pr1)
  A <- sweep(L1, 2, pr1, "*")
  ds <- -(G - 1):(G - 1)
  Cc <- matrix(0, N, length(ds))
  for (k in seq_along(ds)) {
    g1 <- max(1, 1 - ds[k]):min(G, G - ds[k])
    Cc[, k] <- rowSums(A[, g1, drop = FALSE] * L2[, g1 + ds[k], drop = FALSE])
  }
  X <- stats::model.matrix(growth, P)
  # The growth kernel is normalized over grid offsets. An unnormalized
  # discretized density lets the likelihood diverge as sigma -> 0 whenever a
  # predicted growth lands on a grid point.
  nll2 <- function(p) {
    m <- drop(X %*% p[-length(p)])
    K <- stats::dnorm(outer(-m, ds * h, "+"), 0, exp(p[length(p)]))
    K <- K / pmax(rowSums(K), 1e-300)
    -sum(log(rowSums(Cc * K) + 1e-300))
  }
  start <- c(0.2, rep(0, ncol(X) - 1), log(0.3))
  o2 <- stats::optim(start, nll2, method = "BFGS", hessian = TRUE,
                     control = list(maxit = 500))
  beta <- stats::setNames(o2$par[-length(o2$par)], colnames(X))
  vc <- tryCatch(solve(o2$hessian), error = function(e) NULL)
  if (exp(o2$par[length(o2$par)]) < h / 2)
    warning("Estimated growth SD is below half the grid spacing; use a finer `grid`.")

  # Residual SD of log response time, pooled within person over responses
  # that cannot reflect preknowledge (attempt 1 and attempt-2 new items).
  sigma_rt <- NA_real_
  if (!is.null(r$rt)) {
    clean <- a1 | a2new
    res <- r$beta[clean] - log(r$rt[clean])
    grp <- paste(r$person[clean], r$attempt[clean])
    dev <- res - stats::ave(res, grp)
    sigma_rt <- sqrt(sum(dev^2) / (length(res) - length(unique(grp))))
  }

  structure(list(
    data = data, grid = grid, growth = growth,
    mu1 = mu1, s1 = s1, beta = beta,
    sigma_growth = exp(o2$par[length(o2$par)]),
    se = if (is.null(vc)) NULL else sqrt(pmax(diag(vc), 0)),
    growth_mean = stats::setNames(drop(X %*% beta), ids),
    sigma_rt = sigma_rt,
    converged = o1$convergence == 0 && o2$convergence == 0
  ), class = "rt_fit")
}

#' @export
print.rt_fit <- function(x, ...) {
  cat("<rt_fit> expected-gain model,", nrow(x$data$persons), "repeaters\n")
  cat(sprintf("attempt-1 ability: N(%.3f, %.3f^2)\n", x$mu1, x$s1))
  cat("growth coefficients:\n")
  print(round(cbind(estimate = x$beta, se = x$se[seq_along(x$beta)]), 3))
  cat(sprintf("growth SD: %.3f", x$sigma_growth))
  if (!is.na(x$sigma_rt)) cat(sprintf(" | log-RT residual SD: %.3f", x$sigma_rt))
  cat("\n")
  invisible(x)
}
