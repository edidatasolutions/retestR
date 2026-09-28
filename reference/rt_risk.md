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
sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
fit <- rt_fit(sim)
risk <- rt_risk(fit, n_null = 2, alpha = 0.01, seed = 1)
risk
#> <rt_risk> 200 repeaters | evidence: exposed + rt | null draws: 400 
#> 9 flagged at p < 0.01 (about 2.0 expected if everyone were honest); 0 with q < 0.05
#> 
#>  person S1 S2 z_gain z_exposed z_rt    T  p_gain p_exposed    p_rt p_value
#>  C00066 12 27 3.6680      3.22 4.62 7.84 0.00249   0.00249 0.00249 0.00249
#>  C00197  8 17 2.0726      3.53 4.17 7.71 0.01247   0.00249 0.00249 0.00249
#>  C00194 16 27 2.4577      2.91 4.44 7.35 0.00748   0.00249 0.00249 0.00249
#>  C00167 11 24 3.1789      3.89 3.30 7.19 0.00499   0.00249 0.00249 0.00249
#>  C00127 18 25 1.7868      2.08 4.66 6.74 0.02244   0.01496 0.00249 0.00249
#>  C00109 10 19 2.0821      2.64 3.08 5.72 0.01247   0.00249 0.00249 0.00249
#>  C00168  7 15 0.4378      2.77 2.68 5.45 0.31920   0.00249 0.00748 0.00249
#>  C00180 13 20 1.4794      2.26 2.33 4.59 0.08728   0.01247 0.01247 0.00249
#>  C00013 15 16 0.0949      2.16 1.24 3.40 0.48130   0.01247 0.07980 0.00998
#>  C00173 11 23 1.5838      1.75 1.21 2.97 0.06983   0.03242 0.08728 0.01496
#>  q_value  flag
#>   0.0623  TRUE
#>   0.0623  TRUE
#>   0.0623  TRUE
#>   0.0623  TRUE
#>   0.0623  TRUE
#>   0.0623  TRUE
#>   0.0623  TRUE
#>   0.0623  TRUE
#>   0.2217  TRUE
#>   0.2993 FALSE
table(flagged = risk$flag, preknowledge = sim$truth$preknowledge)
#>        preknowledge
#> flagged FALSE TRUE
#>   FALSE   190    1
#>   TRUE      1    8
```
