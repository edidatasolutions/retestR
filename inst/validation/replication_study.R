# Replication study for the retestR manuscript: the known-truth design of
# known_truth.R repeated over independent seeds (means with Monte Carlo SEs).
# Design: 3,000 repeaters, 40% remediated, 5% with preknowledge of 60% of the
# exposed pool. For speed, each replication computes the evidence and the
# bootstrap null once, then evaluates every evidence combination on them;
# this mirrors rt_risk() exactly.
# Usage: Rscript inst/validation/replication_study.R [n_reps] [n_workers]
args <- commandArgs(trailingOnly = TRUE)
n_reps <- if (length(args) >= 1) as.integer(args[1]) else 100
n_workers <- if (length(args) >= 2) as.integer(args[2]) else max(1, parallel::detectCores() - 2)

one_rep <- function(seed) {
  suppressPackageStartupMessages(library(retestR))
  ns <- asNamespace("retestR")
  set.seed(seed)
  sim <- rt_simulate(n_persons = 3000, seed = seed)
  fit <- rt_fit(sim)
  tr <- sim$truth; honest <- !tr$preknowledge; rem <- honest & tr$remediation == 1

  # Evidence and bootstrap null (as in rt_risk, n_null = 10).
  r <- fit$data$responses; ids <- fit$data$persons$person
  N <- length(ids); grid <- fit$grid; h <- grid[2] - grid[1]
  obs <- ns$evidence_core(r, ids, fit); ev <- obs$evidence
  idx <- match(r$person, ids)
  sel <- r$attempt == 2 & !r$exposed
  tau <- ns$person_sum(r$beta[sel] - log(r$rt[sel]), idx[sel], N) /
    ns$person_sum(rep(1, sum(sel)), idx[sel], N)
  cum <- t(apply(obs$W1, 1, cumsum))
  null <- do.call(rbind, lapply(1:10, function(k) {
    gi <- pmin(rowSums(cum < stats::runif(N)) + 1, length(grid))
    th1 <- grid[gi] + stats::runif(N, -h / 2, h / 2)
    th2 <- th1 + fit$growth_mean[ids] + stats::rnorm(N, 0, fit$sigma_growth)
    rs <- r
    rs$x <- stats::rbinom(nrow(rs), 1, stats::plogis(ifelse(rs$attempt == 1, th1[idx], th2[idx]) - rs$b))
    rs$rt <- exp(rs$beta - tau[idx] + stats::rnorm(nrow(rs), 0, fit$sigma_rt))
    ns$evidence_core(rs, ids, fit)$evidence[c("z_gain", "z_exposed", "z_rt")]
  }))
  emp_p <- function(o, nv) { s <- sort(nv); (1 + length(s) - findInterval(o, s, left.open = TRUE)) / (1 + length(s)) }

  raw <- rt_raw_gain(sim)
  out <- list(seed = seed, n_pre = sum(!honest),
              growth_mae = mean(abs(fit$growth_mean - tr$growth_mean)),
              b_remediation = fit$beta[["remediation"]], b_logdays = fit$beta[[2]],
              sigma_growth = fit$sigma_growth)
  for (z in c("z_gain", "z_exposed", "z_rt")) {
    out[[paste0(z, "_mean_honest")]] <- mean(ev[[z]][honest])
    out[[paste0(z, "_sd_honest")]] <- stats::sd(ev[[z]][honest])
  }
  combos <- list(default = c("z_exposed", "z_rt"), all = c("z_gain", "z_exposed", "z_rt"),
                 exposed = "z_exposed", gain_exposed = c("z_gain", "z_exposed"), gain = "z_gain")
  for (nm in names(combos)) {
    p <- emp_p(rowSums(ev[combos[[nm]]]), rowSums(null[combos[[nm]]]))
    flag <- p < 0.01
    k <- sum(flag)
    rf <- if (k > 0) raw$gain >= sort(raw$gain, decreasing = TRUE)[k] else rep(FALSE, N)
    out[[paste0(nm, "_flagged")]] <- k
    out[[paste0(nm, "_detection")]] <- mean(flag[!honest])
    out[[paste0(nm, "_fpr01")]] <- mean(flag[honest])
    out[[paste0(nm, "_rem_flagged")]] <- sum(flag & rem)
    out[[paste0(nm, "_raw_detection")]] <- mean(rf[!honest])
    out[[paste0(nm, "_raw_rem_flagged")]] <- sum(rf & rem)
    if (nm == "default") {
      out$default_fpr05 <- mean(p[honest] < 0.05)
      out$default_fpr001 <- mean(p[honest] < 0.001)
    }
  }
  as.data.frame(out)
}

t0 <- Sys.time()
cl <- parallel::makeCluster(n_workers)
invisible(parallel::clusterCall(cl, function(p) .libPaths(c(p, .libPaths())), .libPaths()[1]))
res <- do.call(rbind, parallel::parLapply(cl, 20000 + seq_len(n_reps), one_rep))
parallel::stopCluster(cl)
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
out_dir <- if (dir.exists("inst/validation")) "inst/validation" else "."
saveRDS(res, file.path(out_dir, "replication_results.rds"))

mse <- function(v) { v <- v[!is.na(v)]; c(mean(v), stats::sd(v) / sqrt(length(v))) }
fmt <- function(v, d = 3) { m <- mse(v); sprintf(paste0("%.", d, "f (%.", d, "f)"), m[1], m[2]) }
cat(sprintf("Replications: %d | workers: %d | %.1f minutes\nValues: mean (Monte Carlo SE)\n\n", nrow(res), n_workers, elapsed))
cat("Growth recovery: mean-growth MAE", fmt(res$growth_mae), "| remediation", fmt(res$b_remediation),
    "(true 0.40) | log(days)", fmt(res$b_logdays), "(true 0.10) | growth SD", fmt(res$sigma_growth), "(true 0.25)\n")
for (z in c("z_gain", "z_exposed", "z_rt"))
  cat(sprintf("Honest %s: mean %s, SD %s\n", z, fmt(res[[paste0(z, "_mean_honest")]]), fmt(res[[paste0(z, "_sd_honest")]])))
cat("Honest false-positive rate (default index): p<.05", fmt(res$default_fpr05, 4), "| p<.01",
    fmt(res$default_fpr01, 4), "| p<.001", fmt(res$default_fpr001, 4), "\n\n")
cat("Table 1. Flagging at alpha = .01\n")
t1 <- do.call(rbind, lapply(c("default", "all", "exposed", "gain_exposed", "gain"), function(nm) data.frame(
  evidence = c(default = "exposed + rt (default)", all = "gain + exposed + rt", exposed = "exposed only",
               gain_exposed = "gain + exposed", gain = "gain only")[[nm]],
  detection = fmt(res[[paste0(nm, "_detection")]]), honest_fpr = fmt(res[[paste0(nm, "_fpr01")]], 4),
  remediated_flagged = fmt(res[[paste0(nm, "_rem_flagged")]], 1),
  raw_detection = fmt(res[[paste0(nm, "_raw_detection")]]),
  raw_remediated = fmt(res[[paste0(nm, "_raw_rem_flagged")]], 1))))
print(t1, row.names = FALSE, right = FALSE)
