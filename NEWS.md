# raisr 0.1.0

Initial release.

* `rais_available()` lists every archive published on the PDET/MTE FTP
  server, with size, modification date and edition (final, partial,
  legacy).
* `rais_files()` resolves offline which archive holds a state in a year
  (one file per state up to 2017, regional files from 2018) and `rais_ufs()`
  gives the state table behind it.
* `rais_download()` fetches the archives into an idempotent local cache that
  mirrors the server layout (`rais_cache_dir()`, `rais_cache_list()`,
  `rais_cache_clear()`).
* `rais_read()` stream-reads a `.7z` archive, filtering by state and
  selecting columns chunk by chunk, detecting the file generation (`;` with
  decimal comma up to the RAIS 2022, `,` with decimal point from the RAIS
  2023) and mapping both to the same normalized column names;
  `rais_fetch()` combines download and read for several years.
* `rais_stock()` consolidates the stock on 31 December, admissions,
  separations and December payroll by any grouping.
* `rais_layout()` documents the columns of the employment and establishment
  files, with the two header spellings of each.
* Sample archives in `inst/extdata` (both generations, employment and
  establishments, plus a pre-2018 state file) allow every reading function
  to be tried offline.
