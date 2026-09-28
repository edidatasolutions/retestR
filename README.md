# retestR

**Model-based anomaly detection for repeat test-takers.**

Programs usually flag repeaters on raw score gain, which punishes candidates
who legitimately studied or remediated. retestR models the gain each repeater
*should* show, then flags departures from it using evidence that preknowledge
leaves behind and honest growth does not.

```r
library(retestR)

sim  <- rt_simulate(n_persons = 3000, seed = 1)   # or rt_data(responses, persons, bank)
fit  <- rt_fit(sim, growth = ~ log(days_between) + remediation)
risk <- rt_risk(fit, alpha = 0.01)                # calibrated risk index
risk                                              # highest-risk repeaters first
```

## Installation

From CRAN (once released):

```r
install.packages("retestR")
```

Development version from GitHub:

```r
install.packages("pak")
pak::pak("edidatasolutions/retestR")
```

## How it works

1. **Expected gain.** Marginal ML on a theta grid: attempt-1 ability
   N(mu, s), and growth `theta2 = theta1 + X beta + N(0, sigma)`. The growth
   model uses attempt 1 plus attempt 2's **new items only**, so preknowledge
   cannot inflate the expected gain, and conditioning on the full attempt-1
   likelihood handles regression to the mean.
2. **Evidence** (posterior-predictive z-scores, positive = suspicious):
   - `z_exposed`: score on exposed items vs what attempt 1, expected growth and
     attempt-2 new items predict. This is the item-level gain decomposition.
   - `z_rt`: speed on exposed vs new items (lognormal RT model).
   - `z_gain`: total gain vs expected (reported; not combined by default).
3. **Risk index.** `T = z_exposed + z_rt` is calibrated by parametric bootstrap.
   Complete null administrations (same persons, forms and covariates, with
   honest growth and honest response times) go through the same pipeline, so
   `p_value` is a false-positive rate for an honest repeater. `q_value` is BH.

## Validation (known truth, `inst/validation/known_truth.R`)

3,000 repeaters, 40% remediated. 5% had preknowledge of 60% of the exposed pool
at attempt 2. Flagging at alpha = .01:

| evidence | detection | honest false-positive rate | honest remediated flagged |
|---|---|---|---|
| exposed + rt (default) | 100% | 1.01% | 13 |
| exposed only (no RT data) | 66% | 0.84% | 8 |
| raw gain, same number flagged | 45% | — | 86 |

- The growth model recovers true coefficients across 8 seeds (mean growth
  error ≤ 0.02 logits).
- With nobody cheating, flag rates are 5.4% / 1.2% / 0.13% at .05 / .01 / .001.
  That is slightly liberal, because the null uses plug-in parameters.

## Status and assumptions

Done: `rt_data`, `rt_simulate`, `rt_fit`, `rt_evidence`, `rt_risk`,
`rt_raw_gain`. Planned: `rt_consistency` (proxy screening from response
style and speed profile), `rt_report` (case files), a person-fit evidence
source, and a weighted (likelihood-ratio) evidence combination in place of the
unweighted sum.

Assumes a calibrated Rasch bank with item-level exposure status and
lognormal time intensities, two attempts per repeater, and no item repeated
within a person.

## Getting help and contributing

Questions and bug reports: https://github.com/edidatasolutions/retestR/issues. See
[CONTRIBUTING.md](.github/CONTRIBUTING.md) for how to report problems, get
help, or contribute code.
