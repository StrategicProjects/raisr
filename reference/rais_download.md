# Download RAIS archives

Fetches from the PDET/MTE FTP server the `.7z` archives that hold the
RAIS microdata of one or more years for the requested states, into the
local cache (see
[`rais_cache_dir()`](https://strategicprojects.github.io/raisr/reference/rais_cache_dir.md)).
The archives to fetch are chosen by the routing rule described in
[`rais_files()`](https://strategicprojects.github.io/raisr/reference/rais_files.md):
one regional file per group of states from 2018 onwards, one file per
state before that, and a national establishments file in both cases.
Archives already in the cache are not downloaded again unless
`force = TRUE`.

## Usage

``` r
rais_download(
  year,
  uf = NULL,
  type = "vinculos",
  edition = "final",
  cache_dir = NULL,
  force = FALSE,
  timeout = 3600,
  verbose = NULL
)
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

- cache_dir:

  Optional cache directory (see
  [`rais_cache_dir()`](https://strategicprojects.github.io/raisr/reference/rais_cache_dir.md)).

- force:

  Re-download archives already in the cache?

- timeout:

  Timeout in seconds for each file.

- verbose:

  Emit progress messages? Defaults to
  `getOption("raisr.verbose", TRUE)`.

## Value

A tibble with one row per archive and columns `year`, `edition`, `type`,
`group`, `file`, `path` (local path, `NA` when not available), `status`
(`"downloaded"`, `"cached"`, `"not_found"` or `"error"`) and `url`.

## Details

The files are large: a regional employment file has from about 130 MB
(North) to more than 1 GB (Sao Paulo) compressed, and the Ministry's
server is slow at times. The default timeout allows one hour per file.

## See also

[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
to read a downloaded archive,
[`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md)
for download and read in one call.

## Examples

``` r
# Which archives would be fetched (offline):
rais_files(2024, uf = "PE", type = c("vinculos", "estabelecimentos"))
#> # A tibble: 2 × 6
#>    year edition type             group    file                      url         
#>   <int> <chr>   <chr>            <chr>    <chr>                     <chr>       
#> 1  2024 final   vinculos         NORDESTE RAIS_VINC_PUB_NORDESTE.7z ftp://ftp.m…
#> 2  2024 final   estabelecimentos NA       RAIS_ESTAB_PUB.7z         ftp://ftp.m…
if (FALSE) { # \dontrun{
# Pernambuco, RAIS 2024: the NORDESTE regional file (about 600 MB)
rais_download(2024, uf = "PE")
} # }
```
