library(retestR)
ns <- asNamespace("retestR")

# 1. Building blocks ----------------------------------------------------------
grid <- seq(-5, 5, by = 0.2)
W <- matrix(dnorm(grid, 0, 1), 1); W <- W / sum(W)
Wp <- ns$propagate(W, grid, m = 0.5, sd = 0.3)
stopifnot(abs(sum(Wp) - 1) < 1e-12,
          abs(sum(Wp * grid) - 0.5) < 0.01,                 # mean shifts by m
          abs(sum(Wp * grid^2) - 0.5^2 - (1 + 0.09)) < 0.02) # variances add

# 2. Growth model recovery -----------------------------------------------------
sim <- rt_simulate(n_persons = 1200, seed = 11)
fit <- rt_fit(sim)
stopifnot(fit$converged,
          abs(fit$mu1 - (-0.5)) < 0.1, abs(fit$s1 - 0.7) < 0.1,
          abs(fit$beta[["remediation"]] - 0.4) < 0.1,
          abs(fit$beta[["log(days_between)"]] - 0.1) < 0.06,
          abs(fit$sigma_growth - 0.25) < 0.08,
          mean(abs(fit$growth_mean - sim$truth$growth_mean)) < 0.1,
          abs(fit$sigma_rt - 0.5) < 0.03)

# 3. Evidence is standardized for honest repeaters ------------------------------
rk <- rt_risk(fit, n_null = 4, alpha = 0.01, seed = 1)
stopifnot(identical(attr(rk, "evidence"), c("z_exposed", "z_rt")),
          all(c("p_gain", "p_exposed", "p_rt") %in% names(rk)))
honest <- !sim$truth$preknowledge
for (z in c("z_gain", "z_exposed", "z_rt"))
  stopifnot(abs(mean(rk[[z]][honest])) < 0.1, abs(sd(rk[[z]][honest]) - 1) < 0.1)

# 4. Power, and fewer honest remediated flags than raw-gain flagging -------------
stopifnot(mean(rk$flag[!honest]) > 0.8, mean(rk$flag[honest]) < 0.025)
raw <- rt_raw_gain(sim)
rf <- raw$gain >= sort(raw$gain, decreasing = TRUE)[sum(rk$flag)]
rem <- honest & sim$truth$remediation == 1
stopifnot(sum(rk$flag & rem) < sum(rf & rem), mean(rk$flag[!honest]) > mean(rf[!honest]))

# 5. Calibration under the null (nobody cheats) -----------------------------------
sim0 <- rt_simulate(n_persons = 1200, p_preknowledge = 0, seed = 12)
rk0 <- rt_risk(rt_fit(sim0), n_null = 4, alpha = 0.05, seed = 2)
stopifnot(abs(mean(rk0$flag) - 0.05) < 0.02)

# 6. Evidence subsets and input checks ------------------------------------------------
rk2 <- rt_risk(fit, evidence = c("gain", "exposed"), n_null = 2, seed = 3)
stopifnot(identical(attr(rk2, "evidence"), c("z_gain", "z_exposed")))
bad <- sim$data$responses[1:10, ]; bad$attempt <- 3
stopifnot(inherits(try(rt_data(bad, sim$data$persons, sim$data$bank), silent = TRUE),
                   "try-error"))
cat("All retestR tests passed.\n")
