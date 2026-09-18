## Initial submission

This is the first submission of raisr to CRAN.

## Test environments

* local macOS (R 4.6.0)
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release,
  oldrel-1)
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 0 notes

## Notes for the reviewers

* All examples that touch the network are wrapped in `\donttest{}` or
  `\dontrun{}` and in `tryCatch()`, so they never fail when the PDET/MTE FTP
  server is unreachable from the check machine. Every other example runs
  offline on the small sample archives shipped in `inst/extdata` (about
  10 KB in total).
* The package never writes outside `tempdir()` unless the user opts in
  through an argument, an environment variable or an option (documented in
  `?rais_cache_dir`).
* Tests use `testthat::local_mocked_bindings()` to replace the download
  function and the FTP listing, so the test suite does not need network
  access.
* The URL of the data source is an FTP URL (`ftp://ftp.mtps.gov.br/...`); it
  is the only public location of these files.
