#' Calibrated risk index for repeat test-takers
#'
#' Combines evidence statistics into `T = sum(z)` and calibrates it by
#' parametric bootstrap: `n_null` complete replicate administrations are
#' simulated under the fitted no-misconduct model (same persons, forms,
#' covariates; attempt-1 ability drawn from each person's posterior; honest
#' growth; honest response times), and the full evidence pipeline is rerun on
#' each. Because the null distribution comes from the same pipeline, the
#' correlation between evidence sources is accounted for, and `p_value` is an
#' honest false-positive rate for an honest repeater.
#'
#' @param fit An `rt_fit`.
#' @param evidence Which statistics to combine: any of `"gain"`, `"exposed"`,
#'   `"rt"`. The default combines `exposed` and `rt` (when response times are
#'   available). `z_gain` is always reported but not combined by default: in
#'   known-truth simulations it mostly repeats the exposed-item signal with
#'   extra noise, and adding it lowered detection at a fixed false-positive rate.
#' @param n_null Null replicates (each is a full administration).
#' @param alpha Flagging level.
#' @param seed Optional seed.
#' @return An `rt_risk` data frame: evidence columns, `T`, per-component
#'   empirical p-values, `p_value`, `q_value` (Benjamini-Hochberg), `flag`.
#' @examples
#' sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
#' fit <- rt_fit(sim)
#' risk <- rt_risk(fit, n_null = 2, alpha = 0.01, seed = 1)
#' risk
#' table(flagged = risk$flag, preknowledge = sim$truth$preknowledge)
#' @export
rt_risk <- function(fit, evidence = NULL, n_null = 10, alpha = 0.01, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  r <- fit$data$responses; ids <- fit$data$persons$person
  N <- length(ids); grid <- fit$grid; h <- grid[2] - grid[1]
  obs <- evidence_core(r, ids, fit)
  ev <- obs$evidence
  if (is.null(evidence)) evidence <- c("exposed", "rt")
  zcols <- intersect(paste0("z_", sub("^z_", "", evidence)), grep("^z_", names(ev), value = TRUE))
  if (!length(zcols)) stop("None of the requested evidence is available.")
  ev$T <- rowSums(ev[zcols])

  idx <- match(r$person, ids)
  tau <- NULL
  if ("z_rt" %in% names(ev)) {
    sel <- r$attempt == 2 & !r$exposed
    tau <- person_sum(r$beta[sel] - log(r$rt[sel]), idx[sel], N) /
      person_sum(rep(1, sum(sel)), idx[sel], N)
  }
  cum <- t(apply(obs$W1, 1, cumsum))
  null <- vector("list", n_null)
  for (k in seq_len(n_null)) {
    gi <- pmin(rowSums(cum < stats::runif(N)) + 1, length(grid))
    th1 <- grid[gi] + stats::runif(N, -h / 2, h / 2)
    th2 <- th1 + fit$growth_mean[ids] + stats::rnorm(N, 0, fit$sigma_growth)
    rs <- r
    th <- ifelse(rs$attempt == 1, th1[idx], th2[idx])
    rs$x <- stats::rbinom(nrow(rs), 1, stats::plogis(th - rs$b))
    if (!is.null(tau))
      rs$rt <- exp(rs$beta - tau[idx] + stats::rnorm(nrow(rs), 0, fit$sigma_rt))
    e0 <- evidence_core(rs, ids, fit)$evidence
    e0$T <- rowSums(e0[zcols])
    null[[k]] <- e0[c(grep("^z_", names(e0), value = TRUE), "T")]
  }
  null <- do.call(rbind, null)

  emp_p <- function(obs_v, null_v) {
    s <- sort(null_v)
    (1 + length(s) - findInterval(obs_v, s, left.open = TRUE)) / (1 + length(s))
  }
  for (z in grep("^z_", names(ev), value = TRUE))
    ev[[paste0("p_", sub("^z_", "", z))]] <- emp_p(ev[[z]], null[[z]])
  ev$p_value <- emp_p(ev$T, null$T)
  ev$q_value <- stats::p.adjust(ev$p_value, "BH")
  ev$flag <- ev$p_value < alpha
  structure(ev, class = c("rt_risk", "data.frame"), alpha = alpha,
            evidence = zcols, n_null = nrow(null))
}

#' @export
print.rt_risk <- function(x, n = 10, ...) {
  cat("<rt_risk>", nrow(x), "repeaters | evidence:",
      paste(sub("^z_", "", attr(x, "evidence")), collapse = " + "),
      "| null draws:", attr(x, "n_null"), "\n")
  cat(sprintf("%d flagged at p < %g (about %.1f expected if everyone were honest); %d with q < 0.05\n\n",
              sum(x$flag), attr(x, "alpha"), attr(x, "alpha") * nrow(x), sum(x$q_value < 0.05)))
  top <- x[order(x$p_value, -x$T), ][seq_len(min(n, nrow(x))), ]
  print(format(as.data.frame(top), digits = 3), row.names = FALSE)
  invisible(x)
}

#' Raw-gain flagging (the common practice, as a baseline)
#'
#' @param data An `rt_data` or `rt_sim`.
#' @param threshold Flag gains in proportion correct at or above this value.
#' @return Data frame: `person`, `p1`, `p2`, `gain`, `flag`.
#' @examples
#' sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
#' raw <- rt_raw_gain(sim, threshold = 0.2)
#' # raw gains also flag honest candidates who remediated
#' table(flagged = raw$flag, remediation = sim$truth$remediation)
#' @export
rt_raw_gain <- function(data, threshold = 0.2) {
  if (inherits(data, "rt_sim")) data <- data$data
  r <- data$responses
  p <- tapply(r$x, list(r$person, r$attempt), mean)
  ids <- data$persons$person
  out <- data.frame(person = ids, p1 = p[ids, "1"], p2 = p[ids, "2"],
                    stringsAsFactors = FALSE)
  out$gain <- out$p2 - out$p1
  out$flag <- out$gain >= threshold
  out
}
