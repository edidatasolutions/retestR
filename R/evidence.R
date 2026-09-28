person_sum <- function(v, idx, N) {
  out <- numeric(N)
  s <- rowsum(v, idx)
  out[as.integer(rownames(s))] <- s
  out
}

# All evidence statistics for responses `r` under fixed model parameters.
# Used on the observed data and, unchanged, on null replicates.
evidence_core <- function(r, ids, fit) {
  grid <- fit$grid; N <- length(ids)
  idx <- match(r$person, ids)
  a1 <- r$attempt == 1; a2 <- !a1
  a2new <- a2 & !r$exposed; a2exp <- a2 & r$exposed

  LL1 <- grid_loglik(idx[a1], r$b[a1], r$x[a1], N, grid)
  W1 <- normalize_rows(sweep(exp(LL1 - apply(LL1, 1, max)), 2,
                             stats::dnorm(grid, fit$mu1, fit$s1), "*"))
  Wpred <- propagate(W1, grid, fit$growth_mean[ids], fit$sigma_growth)
  LL2 <- grid_loglik(idx[a2new], r$b[a2new], r$x[a2new], N, grid)
  W2 <- normalize_rows(Wpred * exp(LL2 - apply(LL2, 1, max)))

  S1 <- person_sum(r$x[a1], idx[a1], N)
  S2 <- person_sum(r$x[a2], idx[a2], N)
  S_exp <- person_sum(r$x[a2exp], idx[a2exp], N)
  out <- data.frame(
    person = ids, S1 = S1, S2 = S2,
    # Attempt-2 total vs what attempt 1 + expected growth predict.
    z_gain = predictive_z(Wpred, grid_moments(idx[a2], r$b[a2], N, grid), S2),
    # Exposed-item score vs what everything else predicts.
    z_exposed = predictive_z(W2, grid_moments(idx[a2exp], r$b[a2exp], N, grid), S_exp),
    stringsAsFactors = FALSE
  )
  if (!is.null(r$rt) && !is.na(fit$sigma_rt)) {
    res <- r$beta - log(r$rt)          # larger = faster than the item's norm
    ne <- person_sum(rep(1, sum(a2exp)), idx[a2exp], N)
    nn <- person_sum(rep(1, sum(a2new)), idx[a2new], N)
    me <- person_sum(res[a2exp], idx[a2exp], N) / ne
    mn <- person_sum(res[a2new], idx[a2new], N) / nn
    out$z_rt <- (me - mn) / (fit$sigma_rt * sqrt(1 / ne + 1 / nn))
  }
  list(evidence = out, W1 = W1)
}

#' Evidence statistics for each repeater
#'
#' Each statistic is a posterior-predictive z-score, positive in the
#' suspicious direction:
#' \describe{
#'   \item{`z_gain`}{Attempt-2 total score against the distribution predicted
#'     from attempt 1 plus the fitted expected growth for this person's
#'     covariates. A large gain after long study and remediation is expected;
#'     the same gain after two weeks is not.}
#'   \item{`z_exposed`}{Attempt-2 score on exposed items against the
#'     prediction from attempt 1, expected growth and attempt-2 new items.
#'     Gains concentrated on exposed items are the signature of preknowledge.}
#'   \item{`z_rt`}{Mean log-speed on exposed minus new items (lognormal RT
#'     model with known time intensities); present when response times are.}
#' }
#' @param fit An `rt_fit`.
#' @return Data frame: `person`, `S1`, `S2`, `z_gain`, `z_exposed`, and `z_rt`.
#' @examples
#' sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
#' fit <- rt_fit(sim)
#' ev <- rt_evidence(fit)
#' # preknowledge shows up on exposed items and in speed, not only in the gain
#' aggregate(ev[c("z_gain", "z_exposed", "z_rt")],
#'           list(preknowledge = sim$truth$preknowledge), mean)
#' @export
rt_evidence <- function(fit) {
  evidence_core(fit$data$responses, fit$data$persons$person, fit)$evidence
}
