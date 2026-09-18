# Streaming, cache and file generations

``` r

library(raisr)
```

## How an archive is read

Each `.7z` archive holds a single text file: Latin-1, one header line,
one record per line. Extracted, a regional file is several gigabytes of
text (the establishments file of 2023 alone is 1.3 GB), and a naive
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) on it needs many
times that in memory.

[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
never extracts the archive. It opens a read connection on the compressed
entry through
[`archive::archive_read()`](https://archive.r-lib.org/reference/archive_read.html),
so `libarchive` decompresses on the fly, and hands that connection to
[`readr::read_delim_chunked()`](https://readr.tidyverse.org/reference/read_delim_chunked.html).
Every chunk (500,000 lines by default) goes through a callback that:

1.  keeps only the records whose municipality code starts with one of
    the requested states (`uf`);
2.  keeps only the requested `columns`.

Only what survives the callback is accumulated. Everything is read as
character first, and typed once at the end (wages as doubles, integer
codes as integers, the Ministry’s ignored marker as `NA`), because the
two file generations write numbers differently.

The chunk size is a memory/speed trade-off: 500,000 lines of 60 short
columns is a few hundred megabytes at peak. Lower it on a small machine;
the result is the same:

``` r

f <- system.file("extdata", "2022", "RAIS_VINC_PUB_NORDESTE_sample.7z", package = "raisr")
a <- rais_read(f, chunk_size = 5L, verbose = FALSE)
b <- rais_read(f, chunk_size = 100000L, verbose = FALSE)
identical(a, b)
#> [1] TRUE
```

## Two header generations

Up to the RAIS 2022 (and in the partial and legacy editions) the files
are `;`-separated with decimal comma, padded fields and headers such as
`Vínculo Ativo 31/12`; the ignored marker is `{ñ class}`. From the RAIS
2023 onwards the files are `,`-separated with quoted strings, decimal
point and headers such as `Ind Vínculo Ativo 31/12 - Código`, and two
columns were added (`ind_vinculo_abandonado`, `categoria_trabalhador`).

[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
detects the generation from the header line and maps both to the same
normalized names, so different years stack directly:

``` r

new <- rais_read(system.file("extdata", "2024", "RAIS_VINC_PUB_NORDESTE_sample.7z", package = "raisr"),
                 columns = c("municipio", "vinculo_ativo_31_12", "vl_remun_media_nom"), verbose = FALSE)
old <- rais_read(f, columns = c("municipio", "vinculo_ativo_31_12", "vl_remun_media_nom"), verbose = FALSE)
rais_stock(rbind(new, old))
#> # A tibble: 2 × 3
#>   rais_year records stock
#>       <int>   <int> <int>
#> 1      2022      32     0
#> 2      2024      32    24
```

[`rais_layout()`](https://strategicprojects.github.io/raisr/reference/rais_layout.md)
lists the two spellings of every column:

``` r

subset(rais_layout(), original != original_2023)[, c("column", "original", "original_2023")]
#> # A tibble: 44 × 3
#>    column              original            original_2023               
#>    <chr>               <chr>               <chr>                       
#>  1 bairros_sp          Bairros SP          Bairros SP - Código         
#>  2 bairros_fortaleza   Bairros Fortaleza   Bairros Fortaleza - Código  
#>  3 bairros_rj          Bairros RJ          Bairros RJ - Código         
#>  4 causa_afastamento_1 Causa Afastamento 1 Causa Afastamento 1 - Código
#>  5 causa_afastamento_2 Causa Afastamento 2 Causa Afastamento 2 - Código
#>  6 causa_afastamento_3 Causa Afastamento 3 Causa Afastamento 3 - Código
#>  7 motivo_desligamento Motivo Desligamento Motivo Desligamento - Código
#>  8 cbo_ocupacao_2002   CBO Ocupação 2002   CBO 2002 Ocupação - Código  
#>  9 cnae_20_classe      CNAE 2.0 Classe     CNAE 2.0 Classe - Código    
#> 10 cnae_95_classe      CNAE 95 Classe      CNAE 95 Classe - Código     
#> # ℹ 34 more rows
```

Before 2018 the files are per state and shorter: the monthly wage
columns exist from 2015 (named `vl_rem_<mes>_cc` up to 2017,
`vl_rem_<mes>_sc` after), and the oldest years use other classifications
(`cbo_ocupacao`, `grau_instrucao_2005_1985`). Columns absent from a year
come back as `NA` when years are stacked with
[`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md).

## The cache

[`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md)
stores every archive under
[`rais_cache_dir()`](https://strategicprojects.github.io/raisr/reference/rais_cache_dir.md),
mirroring the server: one sub-folder per year and edition, the server’s
file name inside.

    <cache>/2024/RAIS_VINC_PUB_NORDESTE.7z
    <cache>/2024/RAIS_ESTAB_PUB.7z
    <cache>/2023-legado/RAIS_VINC_PUB_NORDESTE.7z
    <cache>/2017/PE2017.7z

A file already in the cache is not downloaded again
(`status = "cached"`) unless `force = TRUE`. This is what lets you call
[`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md)
for the same years repeatedly, with different states or columns, and pay
for the download only once.
[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
takes the reference year from that folder name (or from the file name of
pre-2018 files); pass `year` explicitly for an archive kept elsewhere.

The cache location is resolved from the `cache_dir` argument, the
`RAISR_CACHE_DIR` environment variable, the `raisr.cache_dir` option, or
a folder under [`tempdir()`](https://rdrr.io/r/base/tempfile.html) (the
CRAN-compliant default, wiped with the R session). A persistent cache is
strongly recommended: a regional file is hundreds of megabytes and the
Ministry’s server is slow.

``` r

Sys.setenv(RAISR_CACHE_DIR = "~/dados/rais")
rais_cache_list()
rais_cache_clear(2019)      # drop one year
```

## Editions: final, partial and legacy

Some years are published first as a preliminary edition, in a folder
`<year> Parcial`, and when a year is re-published the previous files are
kept in a `Legado` sub-folder.
[`rais_available()`](https://strategicprojects.github.io/raisr/reference/rais_available.md)
reports them with `edition = "parcial"` and `"legado"`, and
[`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md),
[`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md)
and
[`rais_files()`](https://strategicprojects.github.io/raisr/reference/rais_files.md)
accept `edition` to fetch them; they are cached under `<year>-parcial`
and `<year>-legado`. The default, `"final"`, is the current official
file of the year.

``` r

rais_files(2023, uf = "PE", edition = "legado")$url
#> [1] "ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/2023/Legado/RAIS_VINC_PUB_NORDESTE.7z"
```

## Network

The server is a plain FTP server. Outbound access on port 21 **and** on
the high ports used by passive mode is required; corporate firewalls
often block one or both. When the server cannot be reached
[`rais_available()`](https://strategicprojects.github.io/raisr/reference/rais_available.md)
returns an empty tibble with a warning, and
[`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md)
reports `status = "error"` after three attempts, without raising, so
that a long loop over years can continue and be inspected afterwards
through the `"download"` attribute of
[`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md).
