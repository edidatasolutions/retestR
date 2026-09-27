# Robustness of the growth fit across seeds and sizes.
for (f in list.files("C:/Users/User/Documents/retestR/R", full.names = TRUE)) source(f)
for (s in c(2026, 7, 11, 1, 2, 3, 4, 5)) {
  sim <- rt_simulate(n_persons = 3000, seed = s)
  fit <- rt_fit(sim)
  cat(sprintf("seed %4d: b0 %.3f b_logdays %.3f b_rem %.3f sd %.3f | growth MAE %.3f\n", s,
              fit$beta[1], fit$beta[2], fit$beta[3], fit$sigma_growth,
              mean(abs(fit$growth_mean - sim$truth$growth_mean))))
}
cat("truth:     b0 -0.240 b_logdays 0.100 b_rem 0.400 sd 0.250\n")
