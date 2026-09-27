for (f in list.files("C:/Users/User/Documents/retestR/R", full.names = TRUE)) source(f)
t0 <- Sys.time()
sim <- rt_simulate(n_persons = 2000, seed = 7)
cat("sim:", format(Sys.time() - t0), "\n")
t0 <- Sys.time(); fit <- rt_fit(sim); cat("fit:", format(Sys.time() - t0), "\n"); print(fit)
cat("true intercept (log days):", 0.1 - 0.1 * log(30), " slope 0.1, remediation 0.4, sd 0.25\n")
cat("growth_mean r:", cor(fit$growth_mean, sim$truth$growth_mean),
    " MAE:", mean(abs(fit$growth_mean - sim$truth$growth_mean)), "\n")
t0 <- Sys.time(); rk <- rt_risk(fit, n_null = 10, alpha = 0.01, seed = 1); cat("risk:", format(Sys.time() - t0), "\n")
tr <- sim$truth
honest <- !tr$preknowledge
cat("honest flag rate:", mean(rk$flag[honest]), " cheater detection:", mean(rk$flag[!honest]), "\n")
for (z in c("z_gain", "z_exposed", "z_rt"))
  cat(z, "honest mean/sd:", round(mean(rk[[z]][honest]), 3), round(sd(rk[[z]][honest]), 3),
      " cheater mean:", round(mean(rk[[z]][!honest]), 2), "\n")
raw <- rt_raw_gain(sim)
thr <- sort(raw$gain, decreasing = TRUE)[sum(rk$flag)]
rf <- raw$gain >= thr
cat("matched count", sum(rk$flag), "| raw gain: detection", mean(rf[!honest]),
    " honest remediated flagged", sum(rf & honest & tr$remediation == 1),
    " vs model", sum(rk$flag & honest & tr$remediation == 1), "\n")
sim0 <- rt_simulate(n_persons = 2000, p_preknowledge = 0, seed = 8)
rk0 <- rt_risk(rt_fit(sim0), n_null = 10, alpha = 0.05, seed = 2)
cat("null flag rate @.05:", mean(rk0$flag), " @.01:", mean(rk0$p_value < 0.01), "\n")
