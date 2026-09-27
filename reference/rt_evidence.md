# Evidence statistics for each repeater

Each statistic is a posterior-predictive z-score, positive in the
suspicious direction:

- \`z_gain\`:

  Attempt-2 total score against the distribution predicted from attempt
  1 plus the fitted expected growth for this person's covariates. A
  large gain after long study and remediation is expected; the same gain
  after two weeks is not.

- \`z_exposed\`:

  Attempt-2 score on exposed items against the prediction from attempt
  1, expected growth and attempt-2 new items. Gains concentrated on
  exposed items are the signature of preknowledge.

- \`z_rt\`:

  Mean log-speed on exposed minus new items (lognormal RT model with
  known time intensities); present when response times are.

## Usage

``` r
rt_evidence(fit)
```

## Arguments

- fit:

  An \`rt_fit\`.

## Value

Data frame: \`person\`, \`S1\`, \`S2\`, \`z_gain\`, \`z_exposed\`, and
\`z_rt\`.

## Examples

``` r
sim <- rt_simulate(n_persons = 300, form_exposed = 20, form_new = 10, seed = 1)
fit <- rt_fit(sim)
ev <- rt_evidence(fit)
# preknowledge shows up on exposed items and in speed, not only in the gain
aggregate(ev[c("z_gain", "z_exposed", "z_rt")],
          list(preknowledge = sim$truth$preknowledge), mean)
#>   preknowledge    z_gain z_exposed        z_rt
#> 1        FALSE 0.1026923 0.1484031 -0.04455579
#> 2         TRUE 1.0031042 1.8654883  2.78101215
```
