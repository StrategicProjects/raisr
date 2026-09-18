# List the RAIS archives published on the PDET/MTE FTP server

Queries the public FTP server of the Ministry of Labour and Employment
and returns every RAIS archive currently published, one row per file,
with its size and the date it was last modified on the server. The
Ministry publishes the RAIS of a year around the second half of the
following year, sometimes preceded by a partial edition (`"parcial"`),
and keeps the previous files in a `Legado` folder when a year is
re-published (`"legado"`).

## Usage

``` r
rais_available(year = NULL, timeout = 30, verbose = NULL)
```

## Arguments

- year:

  Optional integer vector of years to restrict the listing (for example
  `2020:2025`). `NULL` (the default) lists every year since 1985, which
  takes one FTP request per year folder.

- timeout:

  Connection timeout in seconds for each FTP request.

- verbose:

  Emit progress messages? Defaults to
  `getOption("raisr.verbose", TRUE)`.

## Value

A tibble with one row per archive and columns `year`, `edition`
(`"final"`, `"parcial"` or `"legado"`), `type` (`"vinculos"` or
`"estabelecimentos"`), `group` (the region of a regional file, the state
of a pre-2018 file, or `NA`), `file`, `size_bytes`, `modified`
(`POSIXct`, server time) and `url`. Sorted from the most recent to the
oldest year. Returns an empty tibble, with a warning, when the server
cannot be reached.

## See also

[`rais_files()`](https://strategicprojects.github.io/raisr/reference/rais_files.md)
to build the same table offline for a given year and set of states,
[`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md)
to fetch the archives.

## Examples

``` r
# \donttest{
# Requires network access to ftp.mtps.gov.br
files <- tryCatch(rais_available(year = 2024), error = function(e) NULL)
#> ✔ 16 archives on the server (2024 to 2024).
if (!is.null(files)) files[, c("edition", "type", "group", "size_bytes")]
#> # A tibble: 16 × 4
#>    edition type             group        size_bytes
#>    <chr>   <chr>            <chr>             <dbl>
#>  1 final   estabelecimentos NA            140661991
#>  2 final   vinculos         CENTRO_OESTE  343753235
#>  3 final   vinculos         MG_ES_RJ      747149815
#>  4 final   vinculos         NI               597127
#>  5 final   vinculos         NORDESTE      595420317
#>  6 final   vinculos         NORTE         196258746
#>  7 final   vinculos         SP           1066197453
#>  8 final   vinculos         SUL           680693192
#>  9 parcial estabelecimentos NA            136902586
#> 10 parcial vinculos         CENTRO_OESTE  263259706
#> 11 parcial vinculos         MG_ES_RJ      586487485
#> 12 parcial vinculos         NI               139540
#> 13 parcial vinculos         NORDESTE      411343446
#> 14 parcial vinculos         NORTE         134685247
#> 15 parcial vinculos         SP            921989467
#> 16 parcial vinculos         SUL           577695656
# }
```
