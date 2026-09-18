# Download and read RAIS microdata in one call

Convenience wrapper:
[`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md)
followed by
[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
on every archive found, with the results stacked. Archives missing on
the server are skipped with a message.

## Usage

``` r
rais_fetch(
  year,
  uf = NULL,
  type = "vinculos",
  edition = "final",
  columns = NULL,
  cache_dir = NULL,
  force = FALSE,
  types = TRUE,
  chunk_size = 500000L,
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

- columns:

  Optional character vector of columns to keep, using the normalized
  names listed by
  [`rais_layout()`](https://strategicprojects.github.io/raisr/reference/rais_layout.md).
  `NULL` keeps all columns. `municipio` is always read (it is needed for
  filtering) but is only returned when requested or when `columns` is
  `NULL`.

- cache_dir:

  Optional cache directory (see
  [`rais_cache_dir()`](https://strategicprojects.github.io/raisr/reference/rais_cache_dir.md)).

- force:

  Re-download archives already in the cache?

- types:

  Convert numeric columns? The Ministry's marker for ignored values (a
  token in braces, `{n class}` with a tilde on the n) becomes `NA` in
  every column; remuneration values and tenure become doubles; codes and
  counts whose values are all integers become integers; classification
  codes with leading zeros (CNAE, CBO) stay character. If `FALSE` every
  column is returned as character, exactly as in the file (trimmed).

- chunk_size:

  Number of lines parsed per chunk. Larger chunks are faster but use
  more memory; the default (500,000 lines of 60 columns) uses well under
  1 GB.

- timeout:

  Timeout in seconds for each file.

- verbose:

  Emit progress messages? Defaults to
  `getOption("raisr.verbose", TRUE)`.

## Value

A tibble with the records of every archive read (see
[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
for the columns), or an empty tibble when nothing was available. The
attribute `"download"` holds the tibble returned by
[`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md),
so that `not_found` and `error` files can be inspected.

## Examples

``` r
if (FALSE) { # \dontrun{
# Pernambuco, RAIS 2024, a few columns (downloads the 600 MB NORDESTE file)
pe <- rais_fetch(2024, uf = "PE",
                 columns = c("municipio", "cnae_20_subclasse", "vinculo_ativo_31_12",
                             "vl_remun_dezembro_nom"))
rais_stock(pe, by = "municipio")
} # }
```
