# Assemble two-attempt repeater data

Assemble two-attempt repeater data

## Usage

``` r
rt_data(responses, persons, bank)
```

## Arguments

- responses:

  Long data frame, one row per person x attempt x item: \`person\`,
  \`attempt\` (1 or 2), \`item\`, \`x\` (0/1), and optionally \`rt\`
  (response time in seconds).

- persons:

  One row per repeater: \`person\` plus the covariates used by the
  growth model (e.g. \`days_between\`, \`remediation\`).

- bank:

  Calibrated item bank: \`item\`, \`b\` (Rasch difficulty), \`exposed\`
  (TRUE for items that may be compromised, e.g. long-running operational
  items; FALSE for new items), and optionally \`beta\` (lognormal time
  intensity, log-seconds).

## Value

An \`rt_data\` object.

## Details

Assumes no item is administered to the same person on both attempts
(legitimate item memory would otherwise look like preknowledge).

## Examples

``` r
bank <- data.frame(item = paste0("Q", 1:20), b = rnorm(20),
                   exposed = rep(c(TRUE, FALSE), each = 10))
persons <- data.frame(person = c("A", "B"), days_between = c(60, 200),
                      remediation = c(0, 1))
resp <- data.frame(person = rep(c("A", "B"), each = 20),
                   attempt = rep(rep(1:2, each = 10), 2),
                   item = c(paste0("Q", c(1:5, 11:15, 6:10, 16:20)),
                            paste0("Q", c(6:10, 16:20, 1:5, 11:15))),
                   x = rbinom(40, 1, 0.6))
str(rt_data(resp, persons, bank)$responses)
#> 'data.frame':    40 obs. of  6 variables:
#>  $ person : chr  "A" "A" "A" "A" ...
#>  $ attempt: int  1 1 1 1 1 1 1 1 1 1 ...
#>  $ item   : chr  "Q1" "Q2" "Q3" "Q4" ...
#>  $ x      : int  0 1 0 0 1 0 0 0 0 1 ...
#>  $ b      : num  -1.40004 0.25532 -2.43726 -0.00557 0.62155 ...
#>  $ exposed: logi  TRUE TRUE TRUE TRUE TRUE FALSE ...
```
