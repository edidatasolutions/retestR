# Known-truth validation for retestR.
# 3,000 repeaters, 5% with preknowledge of 60% of the exposed pool at attempt 2.
library(retestR)

sim <- rt_simulate(n_persons = 3000, seed = 2026)
fit <- rt_fit(sim)
print(fit)
tr <- sim$truth
honest <- !tr$preknowledge
rem <- honest & tr$remediation == 1

raw <- rt_raw_gain(sim)
res <- list()
for (ev in list(c("gain", "exposed", "rt"), c("exposed", "rt"), c("gain", "exposed"),
                "exposed", "gain")) {
  rk <- rt_risk(fit, evidence = ev, n_null = 10, alpha = 0.01, seed = 1)
  rf <- raw$gain >= sort(raw$gain, decreasing = TRUE)[sum(rk$flag)]
  res[[length(res) + 1]] <- data.frame(
    evidence = paste(ev, collapse = "+"),
    flagged = sum(rk$flag),
    detection = round(mean(rk$flag[!honest]), 3),
    honest_fpr = round(mean(rk$flag[honest]), 4),
    honest_remediated_flagged = sum(rk$flag & rem),
    raw_gain_detection = round(mean(rf[!honest]), 3),
    raw_gain_honest_remediated = sum(rf & rem))
}
cat("\nModel-based risk (alpha = .01) vs raw-gain flagging of the same number of people:\n")
print(do.call(rbind, res), row.names = FALSE)

sim0 <- rt_simulate(n_persons = 3000, p_preknowledge = 0, seed = 99)
rk0 <- rt_risk(rt_fit(sim0), n_null = 10, alpha = 0.05, seed = 2)
cat(sprintf("\nNo-misconduct calibration: flag rate %.4f at .05, %.4f at .01, %.4f at .001\n",
            mean(rk0$p_value < .05), mean(rk0$p_value < .01), mean(rk0$p_value < .001)))
