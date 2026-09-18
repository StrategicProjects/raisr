# Archives needed for a year and a set of states (offline)

Builds, without touching the network, the list of archives that hold the
RAIS microdata of one or more years for the requested states. This is
the routing rule of the server:

## Usage

``` r
rais_files(year, uf = NULL, type = "vinculos", edition = "final")
```

## Arguments

- year:

  Reference years (integer or character vector).

- uf:

  Optional states to cover, as IBGE two-digit codes (`26`) or two-letter
  abbreviations (`"PE"`). `NULL` covers every state (all regional files,
  or all 27 state files).

- type:

  Which files: `"vinculos"` (employment relationships, the default),
  `"estabelecimentos"` (establishments) or both.

- edition:

  `"final"` (the default), `"parcial"` (the preliminary edition some
  years receive before the final one) or `"legado"` (the previous files,
  kept in a `Legado` sub-folder when a year is re-published).

## Value

A tibble with one row per archive and columns `year`, `edition`, `type`,
`group`, `file` and `url`.

## Details

- from the RAIS **2018** onwards, the employment relationships
  (`vinculos`) are published in one file per group of states
  (`RAIS_VINC_PUB_NORTE.7z`, `..._NORDESTE.7z`, `..._MG_ES_RJ.7z`,
  `..._SP.7z`, `..._SUL.7z`, `..._CENTRO_OESTE.7z`), plus a small
  `RAIS_VINC_PUB_NI.7z` with records whose municipality is not
  identified; the establishments are in a single national
  `RAIS_ESTAB_PUB.7z`;

- up to the RAIS **2017**, there is one file per state (`PE2017.7z`,
  `SP2017.7z`, ...) and a national `ESTB2017.7z`.

## Examples

``` r
rais_files(2024, uf = "PE")
#> # A tibble: 1 × 6
#>    year edition type     group    file                      url                 
#>   <int> <chr>   <chr>    <chr>    <chr>                     <chr>               
#> 1  2024 final   vinculos NORDESTE RAIS_VINC_PUB_NORDESTE.7z ftp://ftp.mtps.gov.…
rais_files(2017, uf = c(26, 29), type = c("vinculos", "estabelecimentos"))
#> # A tibble: 3 × 6
#>    year edition type             group file        url                          
#>   <int> <chr>   <chr>            <chr> <chr>       <chr>                        
#> 1  2017 final   vinculos         PE    PE2017.7z   ftp://ftp.mtps.gov.br/pdet/m…
#> 2  2017 final   vinculos         BA    BA2017.7z   ftp://ftp.mtps.gov.br/pdet/m…
#> 3  2017 final   estabelecimentos NA    ESTB2017.7z ftp://ftp.mtps.gov.br/pdet/m…
rais_files(2024)$file
#> [1] "RAIS_VINC_PUB_NORTE.7z"        "RAIS_VINC_PUB_NORDESTE.7z"    
#> [3] "RAIS_VINC_PUB_MG_ES_RJ.7z"     "RAIS_VINC_PUB_SP.7z"          
#> [5] "RAIS_VINC_PUB_SUL.7z"          "RAIS_VINC_PUB_CENTRO_OESTE.7z"
#> [7] "RAIS_VINC_PUB_NI.7z"          
```
