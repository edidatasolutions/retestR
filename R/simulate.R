#' Simulate repeat test-takers with known misconduct
#'
#' Honest repeaters grow by `g0 + g1 * log(days / 30) + g2 * remediation`
#' plus normal noise. A fraction `p_preknowledge` obtained a random share
#' (`known_frac`) of the exposed pool between attempts: on those items they
#' answer correctly with probability `known_p` and respond `speedup` log-units
#' faster.
#'
#' @param n_persons Number of repeaters.
#' @param n_exposed_pool,n_new_pool Bank sizes.
#' @param form_exposed,form_new Items per form from each pool; forms are
#'   disjoint across a person's two attempts.
#' @param theta_mean,theta_sd Attempt-1 ability of repeaters.
#' @param growth Coefficients `c(g0, g1, g2)`.
#' @param growth_sd SD of individual growth.
#' @param p_remediation Share of repeaters who completed remediation.
#' @param p_preknowledge Share with preknowledge at attempt 2.
#' @param known_frac,known_p,speedup Preknowledge strength.
#' @param rt_sd Residual SD of log response time.
#' @param seed Optional seed.
#' @return An `rt_sim`: `$data` (an `rt_data`) and `$truth` (per-person
#'   `theta1`, `theta2`, `growth_mean`, `preknowledge`, `remediation`).
#' @examples
#' sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
#' head(sim$truth)
#' table(sim$truth$preknowledge)
#' @export
rt_simulate <- function(n_persons = 2000, n_exposed_pool = 300, n_new_pool = 200,
                        form_exposed = 40, form_new = 20,
                        theta_mean = -0.5, theta_sd = 0.7,
                        growth = c(0.1, 0.1, 0.4), growth_sd = 0.25,
                        p_remediation = 0.4, p_preknowledge = 0.05,
                        known_frac = 0.6, known_p = 0.95, speedup = 1,
                        rt_sd = 0.5, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  bank <- data.frame(
    item = sprintf("Q%03d", seq_len(n_exposed_pool + n_new_pool)),
    b = stats::rnorm(n_exposed_pool + n_new_pool, -0.3, 1),
    exposed = rep(c(TRUE, FALSE), c(n_exposed_pool, n_new_pool)),
    beta = stats::rnorm(n_exposed_pool + n_new_pool, 4, 0.3)
  )
  ids <- sprintf("C%05d", seq_len(n_persons))
  persons <- data.frame(person = ids,
                        days_between = round(stats::runif(n_persons, 30, 365)),
                        remediation = stats::rbinom(n_persons, 1, p_remediation))
  gm <- growth[1] + growth[2] * log(persons$days_between / 30) + growth[3] * persons$remediation
  theta1 <- stats::rnorm(n_persons, theta_mean, theta_sd)
  theta2 <- theta1 + gm + stats::rnorm(n_persons, 0, growth_sd)
  tau <- stats::rnorm(n_persons, 0, 0.3)
  pre <- stats::runif(n_persons) < p_preknowledge
  exp_pool <- bank$item[bank$exposed]; new_pool <- bank$item[!bank$exposed]

  rows <- lapply(seq_len(n_persons), function(n) {
    e <- sample(exp_pool, 2 * form_exposed); w <- sample(new_pool, 2 * form_new)
    data.frame(person = ids[n], attempt = rep(1:2, each = form_exposed + form_new),
               item = c(e[1:form_exposed], w[1:form_new],
                        e[-(1:form_exposed)], w[-(1:form_new)]),
               stringsAsFactors = FALSE)
  })
  r <- do.call(rbind, rows)
  bi <- match(r$item, bank$item)
  n <- match(r$person, ids)
  th <- ifelse(r$attempt == 1, theta1[n], theta2[n])
  p <- stats::plogis(th - bank$b[bi])
  logt <- bank$beta[bi] - tau[n] + stats::rnorm(nrow(r), 0, rt_sd)

  known <- rep(FALSE, nrow(r))
  for (k in which(pre)) {
    kn <- sample(exp_pool, round(known_frac * length(exp_pool)))
    known[r$person == ids[k] & r$attempt == 2 & r$item %in% kn] <- TRUE
  }
  p[known] <- pmax(p[known], known_p)
  logt[known] <- logt[known] - speedup
  r$x <- stats::rbinom(nrow(r), 1, p)
  r$rt <- exp(logt)

  structure(list(
    data = rt_data(r, persons, bank),
    truth = data.frame(person = ids, theta1 = theta1, theta2 = theta2,
                       growth_mean = gm, preknowledge = pre,
                       remediation = persons$remediation, stringsAsFactors = FALSE)
  ), class = "rt_sim")
}
