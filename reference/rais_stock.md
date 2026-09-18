# Consolidate employment stock, admissions and separations

Aggregates employment records read with
[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
or
[`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md)
into the figures the Ministry publishes from the RAIS: the **stock** of
employment relationships active on 31 December
(`vinculo_ativo_31_12 == 1`), the admissions and separations that
happened during the year (records with a non-zero `mes_admissao` /
`mes_desligamento`) and the December payroll and mean wage of the active
stock. The aggregation is by `rais_year` plus any grouping columns you
ask for.

## Usage

``` r
rais_stock(data, by = NULL)
```

## Arguments

- data:

  A tibble returned by
  [`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
  or
  [`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md)
  for `vinculos` files. Must contain `vinculo_ativo_31_12` and
  `rais_year`; the other columns are used when present.

- by:

  Character vector of additional grouping columns (for example
  `"municipio"`, `"cnae_20_subclasse"`, `"sexo_trabalhador"`).

## Value

A tibble with the grouping columns and `records` (records aggregated),
`stock` (relationships active on 31/12), `admissions` and `separations`
(when `mes_admissao` / `mes_desligamento` are present),
`december_payroll` (sum of `vl_remun_dezembro_nom` over the active
stock) and `mean_december_wage` (that sum divided by the stock with a
positive December wage), the last two when `vl_remun_dezembro_nom` is
present.

## Examples

``` r
f <- system.file("extdata", "2024", "RAIS_VINC_PUB_NORDESTE_sample.7z", package = "raisr")
x <- rais_read(f, verbose = FALSE)
rais_stock(x, by = "municipio")
#> # A tibble: 7 × 8
#>   rais_year municipio records stock admissions separations december_payroll
#>       <int>     <int>   <int> <int>      <int>       <int>            <dbl>
#> 1      2024    260410       9     3          5           6            5976.
#> 2      2024    260790       3     3          0           0            6209.
#> 3      2024    260960       5     5          2           0           17962.
#> 4      2024    261160       7     6          2           1            9336.
#> 5      2024    290570       5     5          0           0           13263.
#> 6      2024    291080       1     1          1           0            3673.
#> 7      2024    292740       2     1          2           1            1365.
#> # ℹ 1 more variable: mean_december_wage <dbl>
```
