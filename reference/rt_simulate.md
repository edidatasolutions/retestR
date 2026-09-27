# Simulate repeat test-takers with known misconduct

Honest repeaters grow by \`g0 + g1 \* log(days / 30) + g2 \*
remediation\` plus normal noise. A fraction \`p_preknowledge\` obtained
a random share (\`known_frac\`) of the exposed pool between attempts: on
those items they answer correctly with probability \`known_p\` and
respond \`speedup\` log-units faster.

## Usage

``` r
rt_simulate(
  n_persons = 2000,
  n_exposed_pool = 300,
  n_new_pool = 200,
  form_exposed = 40,
  form_new = 20,
  theta_mean = -0.5,
  theta_sd = 0.7,
  growth = c(0.1, 0.1, 0.4),
  growth_sd = 0.25,
  p_remediation = 0.4,
  p_preknowledge = 0.05,
  known_frac = 0.6,
  known_p = 0.95,
  speedup = 1,
  rt_sd = 0.5,
  seed = NULL
)
```

## Arguments

- n_persons:

  Number of repeaters.

- n_exposed_pool, n_new_pool:

  Bank sizes.

- form_exposed, form_new:

  Items per form from each pool; forms are disjoint across a person's
  two attempts.

- theta_mean, theta_sd:

  Attempt-1 ability of repeaters.

- growth:

  Coefficients \`c(g0, g1, g2)\`.

- growth_sd:

  SD of individual growth.

- p_remediation:

  Share of repeaters who completed remediation.

- p_preknowledge:

  Share with preknowledge at attempt 2.

- known_frac, known_p, speedup:

  Preknowledge strength.

- rt_sd:

  Residual SD of log response time.

- seed:

  Optional seed.

## Value

An \`rt_sim\`: \`\$data\` (an \`rt_data\`) and \`\$truth\` (per-person
\`theta1\`, \`theta2\`, \`growth_mean\`, \`preknowledge\`,
\`remediation\`).

## Examples

``` r
sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
head(sim$truth)
#>   person      theta1      theta2 growth_mean preknowledge remediation
#> 1 C00001 -1.58992502 -0.86586927   0.3373354        FALSE           0
#> 2 C00002  0.84621456  1.63775475   0.7468100        FALSE           1
#> 3 C00003 -1.79978074 -1.53370503   0.3367124        FALSE           0
#> 4 C00004 -1.97428290 -1.88861236   0.2774952        FALSE           0
#> 5 C00005 -0.01164603  0.45846265   0.6142097        FALSE           1
#> 6 C00006  0.13521109  0.07242169   0.1659246        FALSE           0
table(sim$truth$preknowledge)
#> 
#> FALSE  TRUE 
#>   191     9 
```
