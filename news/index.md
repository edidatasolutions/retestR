# Changelog

## retestR 0.1.0

CRAN release: 2026-10-08

- Initial release.
- Expected-gain model for repeaters fitted by marginal ML, robust to
  preknowledge
  ([`rt_fit()`](https://edidatasolutions.github.io/retestR/reference/rt_fit.md)).
- Posterior-predictive evidence: score gain, exposed-item performance,
  response speed
  ([`rt_evidence()`](https://edidatasolutions.github.io/retestR/reference/rt_evidence.md)).
- Risk index calibrated by parametric bootstrap with explicit
  false-positive rates
  ([`rt_risk()`](https://edidatasolutions.github.io/retestR/reference/rt_risk.md)).
- Raw-gain baseline
  ([`rt_raw_gain()`](https://edidatasolutions.github.io/retestR/reference/rt_raw_gain.md))
  and known-truth simulation
  ([`rt_simulate()`](https://edidatasolutions.github.io/retestR/reference/rt_simulate.md)).
