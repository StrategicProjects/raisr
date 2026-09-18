# Getting started with raisr

## What the RAIS is

The RAIS (*Relação Anual de Informações Sociais*) is the annual census
of formal employment in Brazil: every employer declares, for each year,
the employment relationships it held (with admission and separation
dates, occupation, wages month by month, worker characteristics) and the
establishments themselves. The Ministry of Labour and Employment
publishes the public, non-identified microdata on the PDET FTP server,
one folder per reference year:

    ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/
        1985/ ... 2017/      one file per state (PE2017.7z, ...) + ESTB2017.7z
        2018/ ... 2025/      RAIS_VINC_PUB_<REGION>.7z (7 regional files) + RAIS_ESTAB_PUB.7z
        2023 Parcial/        preliminary edition of a year, when one was published
        2023/Legado/         the previous files, kept when a year is re-published

The regional files of the employment relationships (`vinculos`) are
large: about 130 MB compressed for the North, 600 MB for the Northeast
and more than 1 GB for Sao Paulo, each with tens of millions of records.

`raisr` does three things with these files:

1.  **lists** what is on the server and resolves which archive holds a
    state;
2.  **downloads** the archives into an idempotent local cache;
3.  **reads** them as a stream, filtering by state and selecting columns
    *before* anything is kept in memory.

The third point is what makes the package useful on an ordinary laptop:
one state of the Northeast is a fraction of its regional file, and you
never hold the rest in memory.

## Installation

``` r

# From CRAN (when available):
install.packages("raisr")

# Development version:
# remotes::install_github("StrategicProjects/raisr")
```

The package reads `.7z` archives through the `archive` package, which
needs `libarchive`. It is bundled on Windows and macOS binaries; on
Linux install `libarchive-dev` (Debian/Ubuntu) or `libarchive-devel`
(Fedora) first.

## Sample archives ship with the package

Every function that reads data can be tried offline with the small
archives in `inst/extdata`, which keep the exact format of the
Ministry’s files (Latin-1 text, original headers, separator and decimal
mark of each generation) for a handful of records from Pernambuco and
Bahia.

``` r

library(raisr)

f <- system.file("extdata", "2024", "RAIS_VINC_PUB_NORDESTE_sample.7z", package = "raisr")
x <- rais_read(f, verbose = FALSE)
x
#> # A tibble: 32 × 64
#>    bairros_sp bairros_fortaleza bairros_rj causa_afastamento_1
#>         <int>             <int>      <int>               <int>
#>  1     999997            999997     999997                 999
#>  2     999997            999997     999997                 999
#>  3     999997            999997     999997                 999
#>  4     999997            999997     999997                 999
#>  5     999997            999997     999997                 999
#>  6     999997            999997     999997                 999
#>  7     999997            999997     999997                 999
#>  8     999997            999997     999997                 999
#>  9     999997            999997     999997                 999
#> 10     999997            999997     999997                  40
#> # ℹ 22 more rows
#> # ℹ 60 more variables: causa_afastamento_2 <int>, causa_afastamento_3 <int>,
#> #   motivo_desligamento <int>, cbo_ocupacao_2002 <chr>, cnae_20_classe <chr>,
#> #   cnae_95_classe <chr>, distritos_sp <int>, vinculo_ativo_31_12 <int>,
#> #   faixa_etaria <int>, faixa_remun_media_sm <int>, faixa_hora_contrat <int>,
#> #   faixa_remun_dezem_sm <int>, faixa_tempo_emprego <int>,
#> #   escolaridade_apos_2005 <int>, qtd_hora_contr <int>, idade <int>, …
```

Column names come back normalized (accents removed, lower case, `_`
between words); codes are integers, wages are numbers, classification
codes with leading zeros (CNAE, CBO) stay character. Two columns are
added by the package: `rais_year` (taken from the folder or the file
name) and `rais_type` (`"vinculos"` or `"estabelecimentos"`).

``` r

rais_layout()[, c("column", "original", "type")]
#> # A tibble: 62 × 3
#>    column              original            type     
#>    <chr>               <chr>               <chr>    
#>  1 bairros_sp          Bairros SP          integer  
#>  2 bairros_fortaleza   Bairros Fortaleza   integer  
#>  3 bairros_rj          Bairros RJ          integer  
#>  4 causa_afastamento_1 Causa Afastamento 1 integer  
#>  5 causa_afastamento_2 Causa Afastamento 2 integer  
#>  6 causa_afastamento_3 Causa Afastamento 3 integer  
#>  7 motivo_desligamento Motivo Desligamento integer  
#>  8 cbo_ocupacao_2002   CBO Ocupação 2002   character
#>  9 cnae_20_classe      CNAE 2.0 Classe     character
#> 10 cnae_95_classe      CNAE 95 Classe      character
#> # ℹ 52 more rows
```

## Reading one state

The employment files have no state column: the state is the first two
digits of the establishment’s municipality code, and
[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
filters on that. Pass the IBGE code or the two-letter abbreviation, and
optionally the columns you need. Both filters are applied chunk by chunk
while the archive is being decompressed.

``` r

pe <- rais_read(
  f,
  uf = "PE",
  columns = c("municipio", "cnae_20_subclasse", "vinculo_ativo_31_12",
              "mes_admissao", "mes_desligamento", "vl_remun_dezembro_nom"),
  verbose = FALSE
)
pe
#> # A tibble: 24 × 8
#>    municipio cnae_20_subclasse vinculo_ativo_31_12 mes_admissao mes_desligamento
#>        <int> <chr>                           <int>        <int>            <int>
#>  1    260960 8424800                             1            0                0
#>  2    260410 8219999                             0            0                3
#>  3    260410 4759899                             0           11               11
#>  4    260410 8121400                             0            2                3
#>  5    261160 8211300                             0           11               12
#>  6    260410 8610102                             0            0                9
#>  7    260790 4329103                             1            0                0
#>  8    260960 8411600                             1            0                0
#>  9    261160 0161003                             1            8                0
#> 10    260790 8112500                             1            0                0
#> # ℹ 14 more rows
#> # ℹ 3 more variables: vl_remun_dezembro_nom <dbl>, rais_year <int>,
#> #   rais_type <chr>
```

## Stock, admissions, separations and payroll

`vinculo_ativo_31_12` is `1` for a relationship active on 31 December,
which is what the Ministry calls the employment **stock**.
`mes_admissao` and `mes_desligamento` are `0` when the movement did not
happen in the year.
[`rais_stock()`](https://strategicprojects.github.io/raisr/reference/rais_stock.md)
turns that into the usual figures, by `rais_year` plus any grouping
columns you ask for:

``` r

rais_stock(pe, by = "municipio")
#> # A tibble: 4 × 8
#>   rais_year municipio records stock admissions separations december_payroll
#>       <int>     <int>   <int> <int>      <int>       <int>            <dbl>
#> 1      2024    260410       9     3          5           6            5976.
#> 2      2024    260790       3     3          0           0            6209.
#> 3      2024    260960       5     5          2           0           17962.
#> 4      2024    261160       7     6          2           1            9336.
#> # ℹ 1 more variable: mean_december_wage <dbl>
```

## Establishments

The establishments file has one row per establishment with the stock of
relationships (`qtd_vinculos_ativos`), activity and size codes and, from
2018, the postal code. It does have a `uf` column, but the state filter
works the same way.

``` r

e <- system.file("extdata", "2023", "RAIS_ESTAB_PUB_sample.7z", package = "raisr")
rais_read(e, uf = 26, columns = c("municipio", "cnae_20_subclasse", "qtd_vinculos_ativos"),
          verbose = FALSE)
#> # A tibble: 20 × 5
#>    municipio cnae_20_subclasse qtd_vinculos_ativos rais_year rais_type       
#>        <int> <chr>                           <int>     <int> <chr>           
#>  1    261160 4923001                             0      2023 estabelecimentos
#>  2    261110 1012101                             0      2023 estabelecimentos
#>  3    260640 4712100                             0      2023 estabelecimentos
#>  4    260640 7711000                             3      2023 estabelecimentos
#>  5    260290 9491000                             0      2023 estabelecimentos
#>  6    261640 4120400                             0      2023 estabelecimentos
#>  7    261160 4330499                             0      2023 estabelecimentos
#>  8    261410 4781400                             0      2023 estabelecimentos
#>  9    260500 7319002                             0      2023 estabelecimentos
#> 10    260680 4722901                             0      2023 estabelecimentos
#> 11    261160 9491000                             0      2023 estabelecimentos
#> 12    261160 6810201                             0      2023 estabelecimentos
#> 13    260960 4773300                             0      2023 estabelecimentos
#> 14    261160 7020400                             0      2023 estabelecimentos
#> 15    261160 9430800                             0      2023 estabelecimentos
#> 16    260005 4771701                             0      2023 estabelecimentos
#> 17    261190 9430800                             0      2023 estabelecimentos
#> 18    261110 4520001                             0      2023 estabelecimentos
#> 19    260600 9499500                             0      2023 estabelecimentos
#> 20    261160 9491000                             0      2023 estabelecimentos
```

## Working with the server

Which archive holds a state is decided offline by
[`rais_files()`](https://strategicprojects.github.io/raisr/reference/rais_files.md):

``` r

rais_files(2024, uf = "PE")
#> # A tibble: 1 × 6
#>    year edition type     group    file                      url                 
#>   <int> <chr>   <chr>    <chr>    <chr>                     <chr>               
#> 1  2024 final   vinculos NORDESTE RAIS_VINC_PUB_NORDESTE.7z ftp://ftp.mtps.gov.…
rais_files(2017, uf = c("PE", "BA"), type = c("vinculos", "estabelecimentos"))
#> # A tibble: 3 × 6
#>    year edition type             group file        url                          
#>   <int> <chr>   <chr>            <chr> <chr>       <chr>                        
#> 1  2017 final   vinculos         PE    PE2017.7z   ftp://ftp.mtps.gov.br/pdet/m…
#> 2  2017 final   vinculos         BA    BA2017.7z   ftp://ftp.mtps.gov.br/pdet/m…
#> 3  2017 final   estabelecimentos NA    ESTB2017.7z ftp://ftp.mtps.gov.br/pdet/m…
```

The functions below need network access to `ftp.mtps.gov.br` (port 21
and the passive-mode data ports). They are not evaluated in this
vignette.

``` r

# Everything published for 2024, with sizes and dates
rais_available(year = 2024)

# Download the NORDESTE regional file of 2024 into the cache (about 600 MB)
rais_download(2024, uf = "PE")

# Download and read in one go: Pernambuco, three years, a few columns
pe <- rais_fetch(2022:2024, uf = "PE",
                 columns = c("municipio", "vinculo_ativo_31_12", "vl_remun_dezembro_nom"))

# Stock and December payroll by municipality and year
rais_stock(pe, by = "municipio")
```

By default the cache lives under
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) and disappears with
the R session. For repeated work set a persistent location once:

``` r

Sys.setenv(RAISR_CACHE_DIR = "~/dados/rais")
rais_cache_list()
```

See
[`vignette("streaming-and-cache")`](https://strategicprojects.github.io/raisr/articles/streaming-and-cache.md)
for the details of how files are read and cached, and for the two header
generations of the files.
