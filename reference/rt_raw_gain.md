# Raw-gain flagging (the common practice, as a baseline)

Raw-gain flagging (the common practice, as a baseline)

## Usage

``` r
rt_raw_gain(data, threshold = 0.2)
```

## Arguments

- data:

  An \`rt_data\` or \`rt_sim\`.

- threshold:

  Flag gains in proportion correct at or above this value.

## Value

Data frame: \`person\`, \`p1\`, \`p2\`, \`gain\`, \`flag\`.

## Examples

``` r
sim <- rt_simulate(n_persons = 200, form_exposed = 20, form_new = 10, seed = 1)
raw <- rt_raw_gain(sim, threshold = 0.2)
# raw gains also flag honest candidates who remediated
table(flagged = raw$flag, remediation = sim$truth$remediation)
#>        remediation
#> flagged   0   1
#>   FALSE 103  49
#>   TRUE   24  24
```
