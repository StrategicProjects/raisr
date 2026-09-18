# Cache directory used by raisr

Downloaded archives are stored in a local cache so that a file is never
downloaded twice. Inside the cache, archives keep their server names in
one sub-folder per year and edition (`2024/RAIS_VINC_PUB_NORDESTE.7z`,
`2023-parcial/RAIS_ESTAB_PUB.7z`, `2017/PE2017.7z`). The location is
resolved in this order:

## Usage

``` r
rais_cache_dir(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Optional path. When given, it is returned as is (after creating the
  folder).

## Value

The cache directory path, created if needed.

## Details

1.  the `cache_dir` argument;

2.  the `RAISR_CACHE_DIR` environment variable;

3.  the `raisr.cache_dir` R option;

4.  a session-scoped folder under
    [`tempdir()`](https://rdrr.io/r/base/tempfile.html), which R removes
    when the session ends.

Set one of the first three to keep the archives between sessions. The
regional files are large (from about 130 MB for the North region to more
than 1 GB for Sao Paulo) and change only when a year is re-published, so
a persistent cache is strongly recommended.

## Examples

``` r
rais_cache_dir()
#> [1] "/tmp/Rtmp3ANxsQ/raisr-cache"
if (FALSE) { # \dontrun{
# Persistent cache for every session:
Sys.setenv(RAISR_CACHE_DIR = "~/dados/rais")
} # }
```
