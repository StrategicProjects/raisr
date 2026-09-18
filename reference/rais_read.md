# Read a RAIS archive as a stream

Reads the text file inside a `.7z` archive of the RAIS without
extracting it to disk and without loading the whole file in memory: the
text is decompressed as a stream and parsed in chunks, and each chunk is
filtered by state and reduced to the requested columns before being
kept. This is what makes it practical to extract one state (a few
million records for a large one) from a regional file of tens of
millions of records on a modest machine.

## Usage

``` r
rais_read(
  path,
  uf = NULL,
  columns = NULL,
  types = TRUE,
  year = NULL,
  chunk_size = 500000L,
  verbose = NULL
)
```

## Arguments

- path:

  Path to an archive, as returned by
  [`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md).

- uf:

  Optional states to keep, as IBGE two-digit codes (`26`) or two-letter
  abbreviations (`"PE"`). The state is derived from the first two digits
  of the establishment's municipality code (`municipio`). `NULL` keeps
  every record.

- columns:

  Optional character vector of columns to keep, using the normalized
  names listed by
  [`rais_layout()`](https://strategicprojects.github.io/raisr/reference/rais_layout.md).
  `NULL` keeps all columns. `municipio` is always read (it is needed for
  filtering) but is only returned when requested or when `columns` is
  `NULL`.

- types:

  Convert numeric columns? The Ministry's marker for ignored values (a
  token in braces, `{n class}` with a tilde on the n) becomes `NA` in
  every column; remuneration values and tenure become doubles; codes and
  counts whose values are all integers become integers; classification
  codes with leading zeros (CNAE, CBO) stay character. If `FALSE` every
  column is returned as character, exactly as in the file (trimmed).

- year:

  Reference year of the archive. Detected from the file name
  (`PE2017.7z`) or from the folder it sits in (`2024/`, `2023-legado/`),
  which is how
  [`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md)
  lays out the cache; pass it explicitly for a file kept elsewhere.

- chunk_size:

  Number of lines parsed per chunk. Larger chunks are faster but use
  more memory; the default (500,000 lines of 60 columns) uses well under
  1 GB.

- verbose:

  Emit progress messages? Defaults to
  `getOption("raisr.verbose", TRUE)`.

## Value

A tibble with the selected records and columns, plus two columns added
by the package: `rais_year` (the reference year) and `rais_type`
(`"vinculos"` or `"estabelecimentos"`). Column names are normalized:
accents removed, lower case, words separated by `_`, identical across
the two header generations. Returns an empty tibble when no record
matches.

## Details

The function handles the two generations of files published by the
Ministry: the `;`-separated files with decimal comma (up to the RAIS
2022, and the partial and legacy editions) and the `,`-separated files
with decimal point published from the RAIS 2023 onwards, whose header
names differ. Both are read into the same normalized column names (see
[`rais_layout()`](https://strategicprojects.github.io/raisr/reference/rais_layout.md)),
so that years can be stacked.

## See also

[`rais_layout()`](https://strategicprojects.github.io/raisr/reference/rais_layout.md)
for the meaning of every column,
[`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md)
for download and read in one call.

## Examples

``` r
# Small sample archives ship with the package (Pernambuco and Bahia rows).
f <- system.file("extdata", "2024", "RAIS_VINC_PUB_NORDESTE_sample.7z", package = "raisr")
x <- rais_read(f, verbose = FALSE)
dim(x)
#> [1] 32 64

# One state, a few columns
pe <- rais_read(f, uf = "PE",
                columns = c("municipio", "cnae_20_subclasse", "vinculo_ativo_31_12",
                            "vl_remun_media_nom"),
                verbose = FALSE)
pe
#> # A tibble: 24 × 6
#>    municipio cnae_20_subclasse vinculo_ativo_31_12 vl_remun_media_nom rais_year
#>        <int> <chr>                           <int>              <dbl>     <int>
#>  1    260960 8424800                             1              8601.      2024
#>  2    260410 8219999                             0              1231.      2024
#>  3    260410 4759899                             0              1426.      2024
#>  4    260410 8121400                             0              1511.      2024
#>  5    261160 8211300                             0              3220.      2024
#>  6    260410 8610102                             0              5478.      2024
#>  7    260790 4329103                             1              3459.      2024
#>  8    260960 8411600                             1              2025       2024
#>  9    261160 0161003                             1              1616.      2024
#> 10    260790 8112500                             1              1755.      2024
#> # ℹ 14 more rows
#> # ℹ 1 more variable: rais_type <chr>
```
