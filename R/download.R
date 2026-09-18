# -- Cache directory -----------------------------------------------------------

#' Cache directory used by raisr
#'
#' Downloaded archives are stored in a local cache so that a file is never
#' downloaded twice. Inside the cache, archives keep their server names in
#' one sub-folder per year and edition (`2024/RAIS_VINC_PUB_NORDESTE.7z`,
#' `2023-parcial/RAIS_ESTAB_PUB.7z`, `2017/PE2017.7z`). The location is
#' resolved in this order:
#'
#' 1. the `cache_dir` argument;
#' 2. the `RAISR_CACHE_DIR` environment variable;
#' 3. the `raisr.cache_dir` R option;
#' 4. a session-scoped folder under [tempdir()], which R removes when the
#'    session ends.
#'
#' Set one of the first three to keep the archives between sessions. The
#' regional files are large (from about 130 MB for the North region to
#' more than 1 GB for Sao Paulo) and change only when a year is
#' re-published, so a persistent cache is strongly recommended.
#'
#' @param cache_dir Optional path. When given, it is returned as is (after
#'   creating the folder).
#'
#' @return The cache directory path, created if needed.
#' @export
#' @examples
#' rais_cache_dir()
#' \dontrun{
#' # Persistent cache for every session:
#' Sys.setenv(RAISR_CACHE_DIR = "~/dados/rais")
#' }
rais_cache_dir <- function(cache_dir = NULL) {
  env <- Sys.getenv("RAISR_CACHE_DIR", unset = "")
  dir <- cache_dir %||%
    (if (nzchar(env)) env else NULL) %||%
    getOption("raisr.cache_dir") %||%
    file.path(tempdir(), "raisr-cache")
  dir <- path.expand(dir)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

#' List the archives currently in the cache
#'
#' @inheritParams rais_cache_dir
#' @return A tibble with columns `path`, `year`, `edition`, `type`, `group`,
#'   `file`, `size_bytes` and `modified`.
#' @export
#' @examples
#' rais_cache_list()
rais_cache_list <- function(cache_dir = NULL) {
  dir <- rais_cache_dir(cache_dir)
  paths <- list.files(dir, pattern = "\\.7z$", recursive = TRUE, full.names = TRUE)
  info <- lapply(paths, .detect_file)
  folder <- lapply(paths, .detect_folder)
  type <- vapply(info, `[[`, "", "type")
  keep <- !is.na(type)
  paths <- paths[keep]; info <- info[keep]; folder <- folder[keep]
  finfo <- file.info(paths)
  year <- vapply(info, `[[`, NA_integer_, "year")
  fyear <- vapply(folder, `[[`, NA_integer_, "year")
  year[is.na(year)] <- fyear[is.na(year)]
  edition <- vapply(folder, `[[`, NA_character_, "edition")
  edition[is.na(edition)] <- "final"
  tibble::tibble(
    path       = paths,
    year       = year,
    edition    = edition,
    type       = type[keep],
    group      = vapply(info, `[[`, "", "group"),
    file       = basename(paths),
    size_bytes = as.numeric(finfo$size),
    modified   = finfo$mtime
  )
}

#' Remove archives from the cache
#'
#' @inheritParams rais_cache_dir
#' @param year Optional reference years whose archives are removed. `NULL`
#'   removes every cached archive.
#' @return Invisibly, the number of files removed.
#' @export
#' @examples
#' rais_cache_clear()
rais_cache_clear <- function(year = NULL, cache_dir = NULL) {
  cached <- rais_cache_list(cache_dir)
  if (!is.null(year)) cached <- cached[cached$year %in% .as_year(year), ]
  if (nrow(cached) > 0L) unlink(cached$path)
  invisible(nrow(cached))
}

# -- Download ------------------------------------------------------------------

#' One curl download with retries. Returns "ok", "not_found" or "error".
#' Wrapped in its own function so tests can mock it.
#' @noRd
.rais_curl_download <- function(url, destfile, timeout = 3600, retries = 3L) {
  for (attempt in seq_len(retries)) {
    res <- tryCatch({
      h <- curl::new_handle(connecttimeout = 30L, timeout = timeout)
      curl::curl_download(url, destfile, handle = h, quiet = TRUE)
      "ok"
    }, error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("550|RETR response|not found|does not exist", msg, ignore.case = TRUE)) {
        "not_found"
      } else {
        "error"
      }
    })
    if (identical(res, "ok") && file.exists(destfile) && file.size(destfile) > 0) return("ok")
    if (file.exists(destfile)) unlink(destfile)
    if (identical(res, "not_found")) return("not_found")
    if (attempt < retries) Sys.sleep(5 * attempt)
  }
  "error"
}

#' Download RAIS archives
#'
#' Fetches from the PDET/MTE FTP server the `.7z` archives that hold the
#' RAIS microdata of one or more years for the requested states, into the
#' local cache (see [rais_cache_dir()]). The archives to fetch are chosen by
#' the routing rule described in [rais_files()]: one regional file per
#' group of states from 2018 onwards, one file per state before that, and a
#' national establishments file in both cases. Archives already in the
#' cache are not downloaded again unless `force = TRUE`.
#'
#' The files are large: a regional employment file has from about 130 MB
#' (North) to more than 1 GB (Sao Paulo) compressed, and the Ministry's
#' server is slow at times. The default timeout allows one hour per file.
#'
#' @inheritParams rais_files
#' @param cache_dir Optional cache directory (see [rais_cache_dir()]).
#' @param force Re-download archives already in the cache?
#' @param timeout Timeout in seconds for each file.
#' @param verbose Emit progress messages? Defaults to
#'   `getOption("raisr.verbose", TRUE)`.
#'
#' @return A tibble with one row per archive and columns `year`, `edition`,
#'   `type`, `group`, `file`, `path` (local path, `NA` when not available),
#'   `status` (`"downloaded"`, `"cached"`, `"not_found"` or `"error"`) and
#'   `url`.
#' @export
#' @seealso [rais_read()] to read a downloaded archive, [rais_fetch()] for
#'   download and read in one call.
#' @examples
#' # Which archives would be fetched (offline):
#' rais_files(2024, uf = "PE", type = c("vinculos", "estabelecimentos"))
#' \dontrun{
#' # Pernambuco, RAIS 2024: the NORDESTE regional file (about 600 MB)
#' rais_download(2024, uf = "PE")
#' }
rais_download <- function(year, uf = NULL, type = "vinculos", edition = "final",
                          cache_dir = NULL, force = FALSE, timeout = 3600,
                          verbose = NULL) {
  verbose <- .verbose(verbose)
  files   <- rais_files(year, uf = uf, type = type, edition = edition)
  dir     <- rais_cache_dir(cache_dir)

  rows <- lapply(seq_len(nrow(files)), function(i) {
    f <- files[i, , drop = FALSE]
    sub <- file.path(dir, .rais_folder_name(f$year, f$edition))
    if (!dir.exists(sub)) dir.create(sub, recursive = TRUE, showWarnings = FALSE)
    dest <- file.path(sub, f$file)
    row <- tibble::tibble(year = f$year, edition = f$edition, type = f$type, group = f$group,
                          file = f$file, path = dest, status = "cached", url = f$url)
    if (file.exists(dest) && file.size(dest) > 0 && !force) return(row)
    if (verbose) cli::cli_alert_info("Downloading {f$file} ({f$year}, {f$edition})...")
    st <- .rais_curl_download(f$url, dest, timeout = timeout)
    if (st == "ok") {
      if (verbose) {
        cli::cli_alert_success("{f$file} ({f$year}): {format(file.size(dest), big.mark = ',')} bytes.")
      }
      row$status <- "downloaded"
    } else {
      if (verbose && st == "not_found") cli::cli_alert_warning("{f$file} ({f$year}, {f$edition}): not on the server.")
      if (st == "error") cli::cli_warn("{f$file} ({f$year}): download failed after retries ({.url {f$url}}).")
      row$path <- NA_character_
      row$status <- st
    }
    row
  })
  tibble::as_tibble(do.call(rbind, rows))
}
