# Calibrated risk index for repeat test-takers

Combines evidence statistics into \`T = sum(z)\` and calibrates it by
parametric bootstrap: \`n_null\` complete replicate administrations are
simulated under the fitted no-misconduct model (same persons, forms,
covariates; attempt-1 ability drawn from each person's posterior; honest
growth; honest response times), and the full evidence pipeline is rerun
on each. Because the null distribution comes from the same pipeline, the
correlation between evidence sources is accounted for, and \`p_value\`
is an honest false-positive rate for an honest repeater.

## Usage

``` r
rt_risk(fit, evidence = NULL, n_null = 10, alpha = 0.01, seed = NULL)
```

## Arguments

- fit:

  An \`rt_fit\`.

- evidence:

  Which statistics to combine: any of \`"gain"\`, \`"exposed"\`,
  \`"rt"\`. The default combines \`exposed\` and \`rt\` (when response
  times are available). \`z_gain\` is always reported but not combined
  by default: in known-truth simulations it mostly repeats the
  exposed-item signal with extra noise, and adding it lowered detection
  at a fixed false-positive rate.

- n_null:

  Null replicates (each is a full administration).

- alpha:

  Flagging level.

- seed:

  Optional seed.

## Value

An \`rt_risk\` data frame: evidence columns, \`T\`, per-component
empirical p-values, \`p_value\`, \`q_value\` (Benjamini-Hochberg),
\`flag\`.

## Examples

``` r
sim <- rt_simulate(n_persons = 300, form_exposed = 20, form_new = 10, seed = 1)
fit <- rt_fit(sim)
risk <- rt_risk(fit, n_null = 2, alpha = 0.01, seed = 1)
risk
#> <rt_risk> 300 repeaters | evidence: exposed + rt | null draws: 600 
#> 15 flagged at p < 0.01 (about 3.0 expected if everyone were honest); 0 with q < 0.05
#> 
#>  person S1 S2 z_gain z_exposed z_rt    T  p_gain p_exposed    p_rt p_value
#>  C00065 18 23  0.872     3.423 3.25 6.68 0.20466   0.00166 0.00166 0.00166
#>  C00017 12 18  1.632     2.471 3.67 6.14 0.06489   0.00832 0.00166 0.00166
#>  C00110 13 18  0.899     1.879 3.07 4.95 0.19634   0.02995 0.00166 0.00166
#>  C00183 16 22  0.541     1.808 2.94 4.75 0.30948   0.03328 0.00166 0.00333
#>  C00153 14 16  1.057     0.829 3.82 4.65 0.14975   0.21797 0.00166 0.00333
#>  C00072 13 17  0.931     2.863 1.76 4.62 0.18136   0.00166 0.03494 0.00333
#>  C00259 12 15  0.654     1.716 2.53 4.25 0.26955   0.03993 0.00666 0.00832
#>  C00116  9 19  3.040     2.492 1.70 4.19 0.00166   0.00666 0.04326 0.00832
#>  C00007 10 20  1.572     1.711 2.43 4.15 0.06988   0.03993 0.00666 0.00832
#>  C00058 15 15 -0.811     0.861 3.08 3.94 0.79534   0.21464 0.00166 0.00832
#>  q_value flag
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
#>    0.166 TRUE
table(flagged = risk$flag, preknowledge = sim$truth$preknowledge)
#>        preknowledge
#> flagged FALSE TRUE
#>   FALSE   285    0
#>   TRUE      4   11
```
