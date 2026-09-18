# Changelog

## raisr 0.1.0

Initial release.

- [`rais_available()`](https://strategicprojects.github.io/raisr/reference/rais_available.md)
  lists every archive published on the PDET/MTE FTP server, with size,
  modification date and edition (final, partial, legacy).
- [`rais_files()`](https://strategicprojects.github.io/raisr/reference/rais_files.md)
  resolves offline which archive holds a state in a year (one file per
  state up to 2017, regional files from 2018) and
  [`rais_ufs()`](https://strategicprojects.github.io/raisr/reference/rais_ufs.md)
  gives the state table behind it.
- [`rais_download()`](https://strategicprojects.github.io/raisr/reference/rais_download.md)
  fetches the archives into an idempotent local cache that mirrors the
  server layout
  ([`rais_cache_dir()`](https://strategicprojects.github.io/raisr/reference/rais_cache_dir.md),
  [`rais_cache_list()`](https://strategicprojects.github.io/raisr/reference/rais_cache_list.md),
  [`rais_cache_clear()`](https://strategicprojects.github.io/raisr/reference/rais_cache_clear.md)).
- [`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md)
  stream-reads a `.7z` archive, filtering by state and selecting columns
  chunk by chunk, detecting the file generation (`;` with decimal comma
  up to the RAIS 2022, `,` with decimal point from the RAIS
  2023. and mapping both to the same normalized column names;
        [`rais_fetch()`](https://strategicprojects.github.io/raisr/reference/rais_fetch.md)
        combines download and read for several years.
- [`rais_stock()`](https://strategicprojects.github.io/raisr/reference/rais_stock.md)
  consolidates the stock on 31 December, admissions, separations and
  December payroll by any grouping.
- [`rais_layout()`](https://strategicprojects.github.io/raisr/reference/rais_layout.md)
  documents the columns of the employment and establishment files, with
  the two header spellings of each.
- Sample archives in `inst/extdata` (both generations, employment and
  establishments, plus a pre-2018 state file) allow every reading
  function to be tried offline.
