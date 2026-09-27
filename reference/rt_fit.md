# Fit the expected-gain model

Marginal maximum likelihood on a theta grid, in two stages: (1) the
attempt-1 ability distribution of repeaters, N(mu1, s1); (2) growth
\`theta2 = theta1 + X beta + N(0, sigma_growth)\` from attempt-1
responses and attempt-2 responses to \*\*new items only\*\*. Because
exposed items never enter the growth model, preknowledge cannot inflate
the expected gain, and conditioning on the full attempt-1 likelihood
handles regression to the mean.

## Usage

``` r
rt_fit(
  data,
  growth = ~log(days_between) + remediation,
  grid = seq(-5, 5, by = 0.2)
)
```

## Arguments

- data:

  An \`rt_data\` (or \`rt_sim\`) object.

- growth:

  One-sided formula for mean growth, evaluated in \`data\$persons\`.

- grid:

  Theta grid.

## Value

An \`rt_fit\` object.

## Examples

``` r
sim <- rt_simulate(n_persons = 300, form_exposed = 20, form_new = 10, seed = 1)
fit <- rt_fit(sim)
fit    # growth coefficients: intercept, log(days_between), remediation
#> <rt_fit> expected-gain model, 300 repeaters
#> attempt-1 ability: N(-0.498, 0.701^2)
#> growth coefficients:
#>                   estimate    se
#> (Intercept)         -0.401 0.427
#> log(days_between)    0.101 0.083
#> remediation          0.486 0.111
#> growth SD: 0.459 | log-RT residual SD: 0.502
```
