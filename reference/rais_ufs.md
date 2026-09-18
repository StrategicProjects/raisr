# The 27 Brazilian states and the regional file that carries each one

Offline reference table used by the package to translate state codes and
abbreviations and to route a state to its regional archive from the RAIS
2018 onwards.

## Usage

``` r
rais_ufs()
```

## Value

A tibble with columns `uf` (IBGE two-digit code), `sigla` (two-letter
abbreviation), `name` and `region` (the suffix of the
`RAIS_VINC_PUB_<region>.7z` file).

## Examples

``` r
rais_ufs()
#> # A tibble: 27 × 4
#>       uf sigla name      region  
#>    <int> <chr> <chr>     <chr>   
#>  1    11 RO    Rondônia  NORTE   
#>  2    12 AC    Acre      NORTE   
#>  3    13 AM    Amazonas  NORTE   
#>  4    14 RR    Roraima   NORTE   
#>  5    15 PA    Pará      NORTE   
#>  6    16 AP    Amapá     NORTE   
#>  7    17 TO    Tocantins NORTE   
#>  8    21 MA    Maranhão  NORDESTE
#>  9    22 PI    Piauí     NORDESTE
#> 10    23 CE    Ceará     NORDESTE
#> # ℹ 17 more rows
subset(rais_ufs(), region == "NORDESTE")
#> # A tibble: 9 × 4
#>      uf sigla name                region  
#>   <int> <chr> <chr>               <chr>   
#> 1    21 MA    Maranhão            NORDESTE
#> 2    22 PI    Piauí               NORDESTE
#> 3    23 CE    Ceará               NORDESTE
#> 4    24 RN    Rio Grande do Norte NORDESTE
#> 5    25 PB    Paraíba             NORDESTE
#> 6    26 PE    Pernambuco          NORDESTE
#> 7    27 AL    Alagoas             NORDESTE
#> 8    28 SE    Sergipe             NORDESTE
#> 9    29 BA    Bahia               NORDESTE
```
