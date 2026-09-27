# Model-based flagging of repeat test-takers

Flagging repeaters on raw score gain punishes candidates who studied or
remediated. retestR asks a different question: is this gain larger than
*this* candidate’s circumstances predict, and is it concentrated where
preknowledge would put it?

## Data

Each repeater took two disjoint forms drawn from a calibrated bank in
which every item is marked either `exposed` (long-running, possibly
compromised) or new. The simulation plants preknowledge in 5% of
repeaters.

``` r

library(retestR)
sim <- rt_simulate(n_persons = 800, form_exposed = 30, form_new = 15, seed = 1)
head(sim$data$persons)
#>   person days_between remediation
#> 1 C00001          322           1
#> 2 C00002          354           0
#> 3 C00003          320           0
#> 4 C00004          177           0
#> 5 C00005           94           0
#> 6 C00006           58           1
table(sim$truth$preknowledge)
#> 
#> FALSE  TRUE 
#>   758    42
```

With real data, assemble the same structure with
`rt_data(responses, persons, bank)`.

## Expected gain

The growth model uses attempt 1 and only the *new* items of attempt 2,
so preknowledge cannot inflate the expected gain.

``` r

fit <- rt_fit(sim, growth = ~ log(days_between) + remediation)
fit
#> <rt_fit> expected-gain model, 800 repeaters
#> attempt-1 ability: N(-0.513, 0.732^2)
#> growth coefficients:
#>                   estimate    se
#> (Intercept)         -0.446 0.209
#> log(days_between)    0.144 0.041
#> remediation          0.392 0.052
#> growth SD: 0.260 | log-RT residual SD: 0.502
```

## Evidence and risk

``` r

risk <- rt_risk(fit, n_null = 4, alpha = 0.01, seed = 1)
risk
#> <rt_risk> 800 repeaters | evidence: exposed + rt | null draws: 3200 
#> 44 flagged at p < 0.01 (about 8.0 expected if everyone were honest); 38 with q < 0.05
#> 
#>  person S1 S2 z_gain z_exposed z_rt     T   p_gain p_exposed     p_rt  p_value
#>  C00737 10 25  2.760      5.71 5.77 11.49 0.001250  0.000312 0.000312 0.000312
#>  C00660  3 19  3.948      6.52 4.79 11.31 0.000312  0.000312 0.000312 0.000312
#>  C00257  5 25  3.981      6.68 4.50 11.19 0.000312  0.000312 0.000312 0.000312
#>  C00717 11 26  2.603      3.87 6.30 10.18 0.002499  0.000312 0.000312 0.000312
#>  C00055  7 18  1.645      4.61 4.35  8.96 0.049984  0.000312 0.000312 0.000312
#>  C00265 13 30  3.543      5.33 3.21  8.54 0.000312  0.000312 0.000625 0.000312
#>  C00651 14 27  3.200      4.15 4.37  8.52 0.000625  0.000312 0.000312 0.000312
#>  C00176 15 25  0.616      2.95 5.16  8.11 0.276476  0.001250 0.000312 0.000312
#>  C00012 21 34  2.129      3.13 4.89  8.02 0.014683  0.000937 0.000312 0.000312
#>  C00525 25 33  1.502      2.67 5.16  7.84 0.064980  0.002812 0.000312 0.000312
#>  q_value flag
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
#>  0.00893 TRUE
```

`p_value` is calibrated by simulating complete honest administrations
through the same pipeline, so it is the false-positive rate for an
honest repeater.

``` r

table(flagged = risk$flag, preknowledge = sim$truth$preknowledge)
#>        preknowledge
#> flagged FALSE TRUE
#>   FALSE   754    2
#>   TRUE      4   40
```

## Compared with raw-gain flagging

Flag the same number of candidates by raw gain and look at who gets
caught:

``` r

raw <- rt_raw_gain(sim)
k <- sum(risk$flag)
raw_flag <- raw$gain >= sort(raw$gain, decreasing = TRUE)[k]
honest_remediated <- !sim$truth$preknowledge & sim$truth$remediation == 1
c(model_caught = sum(risk$flag & sim$truth$preknowledge),
  raw_caught = sum(raw_flag & sim$truth$preknowledge),
  model_flags_remediated = sum(risk$flag & honest_remediated),
  raw_flags_remediated = sum(raw_flag & honest_remediated))
#>           model_caught             raw_caught model_flags_remediated 
#>                     40                     17                      2 
#>   raw_flags_remediated 
#>                     17
```
