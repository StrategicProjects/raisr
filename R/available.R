#' List the RAIS archives published on the PDET/MTE FTP server
#'
#' Queries the public FTP server of the Ministry of Labour and Employment and
#' returns every RAIS archive currently published, one row per file, with
#' its size and the date it was last modified on the server. The Ministry
#' publishes the RAIS of a year around the second half of the following
#' year, sometimes preceded by a partial edition (`"parcial"`), and keeps the
#' previous files in a `Legado` folder when a year is re-published
#' (`"legado"`).
#'
#' @param year Optional integer vector of years to restrict the listing
#'   (for example `2020:2025`). `NULL` (the default) lists every year since
#'   1985, which takes one FTP request per year folder.
#' @param timeout Connection timeout in seconds for each FTP request.
#' @param verbose Emit progress messages? Defaults to
#'   `getOption("raisr.verbose", TRUE)`.
#'
#' @return A tibble with one row per archive and columns `year`, `edition`
#'   (`"final"`, `"parcial"` or `"legado"`), `type` (`"vinculos"` or
#'   `"estabelecimentos"`), `group` (the region of a regional file, the
#'   state of a pre-2018 file, or `NA`), `file`, `size_bytes`, `modified`
#'   (`POSIXct`, server time) and `url`. Sorted from the most recent to the
#'   oldest year. Returns an empty tibble, with a warning, when the server
#'   cannot be reached.
#' @export
#' @seealso [rais_files()] to build the same table offline for a given
#'   year and set of states, [rais_download()] to fetch the archives.
#' @examples
#' \donttest{
#' # Requires network access to ftp.mtps.gov.br
#' files <- tryCatch(rais_available(year = 2024), error = function(e) NULL)
#' if (!is.null(files)) files[, c("edition", "type", "group", "size_bytes")]
#' }
rais_available <- function(year = NULL, timeout = 30, verbose = NULL) {
  verbose <- .verbose(verbose)
  empty <- tibble::tibble(year = integer(), edition = character(), type = character(),
                          group = character(), file = character(), size_bytes = numeric(),
                          modified = as.POSIXct(character()), url = character())

  base <- .rais_ftp_base   # local: cli reads a leading dot as a style
  root <- .ftp_listing(base, timeout = timeout)
  if (is.null(root)) {
    cli::cli_warn(c(
      "Could not reach the PDET/MTE FTP server ({.url {base}}).",
      "i" = "Outbound FTP (port 21 plus passive-mode ports) may be blocked on this network."
    ))
    return(empty)
  }
  entries <- .parse_ftp_listing(root)
  entries <- entries[entries$is_dir & grepl("^\\d{4}( Parcial)?$", entries$name), , drop = FALSE]
  folders <- data.frame(
    year    = as.integer(substr(entries$name, 1L, 4L)),
    edition = ifelse(grepl("Parcial$", entries$name), "parcial", "final"),
    stringsAsFactors = FALSE
  )
  if (!is.null(year)) folders <- folders[folders$year %in% as.integer(year), , drop = FALSE]
  if (nrow(folders) == 0L) return(empty)

  list_folder <- function(y, ed) {
    url <- .rais_folder_url(y, ed)
    txt <- .ftp_listing(url, timeout = timeout)
    if (is.null(txt)) return(NULL)
    e <- .parse_ftp_listing(txt)
    out <- .listing_to_files(e, y, ed, url)
    if (ed == "final" && any(e$is_dir & e$name == "Legado")) {
      out <- rbind(out, list_folder(y, "legado"))
    }
    out
  }
  rows <- Map(list_folder, folders$year, folders$edition)
  out <- do.call(rbind, rows)
  if (is.null(out) || nrow(out) == 0L) return(empty)

  out <- out[order(-out$year, match(out$edition, .rais_editions), out$type, out$file), ]
  rownames(out) <- NULL
  if (verbose) {
    cli::cli_alert_success(
      "{nrow(out)} archive{?s} on the server ({min(out$year)} to {max(out$year)})."
    )
  }
  tibble::as_tibble(out)
}

#' Turn the parsed listing of one server folder into rows of the
#' `rais_available()` table (only `.7z` archives the package understands).
#' @noRd
.listing_to_files <- function(entries, year, edition, folder_url) {
  e <- entries[!entries$is_dir & grepl("\\.7z$", entries$name, ignore.case = TRUE), , drop = FALSE]
  if (nrow(e) == 0L) return(NULL)
  info <- lapply(e$name, .detect_file)
  type  <- vapply(info, `[[`, "", "type")
  group <- vapply(info, `[[`, "", "group")
  keep <- !is.na(type)
  data.frame(
    year       = rep(year, sum(keep)),
    edition    = rep(edition, sum(keep)),
    type       = type[keep],
    group      = group[keep],
    file       = e$name[keep],
    size_bytes = e$size[keep],
    modified   = e$modified[keep],
    url        = paste0(folder_url, "/", e$name[keep]),
    stringsAsFactors = FALSE
  )
}

#' Archives needed for a year and a set of states (offline)
#'
#' Builds, without touching the network, the list of archives that hold the
#' RAIS microdata of one or more years for the requested states. This is the
#' routing rule of the server:
#'
#' * from the RAIS **2018** onwards, the employment relationships
#'   (`vinculos`) are published in one file per group of states
#'   (`RAIS_VINC_PUB_NORTE.7z`, `..._NORDESTE.7z`, `..._MG_ES_RJ.7z`,
#'   `..._SP.7z`, `..._SUL.7z`, `..._CENTRO_OESTE.7z`), plus a small
#'   `RAIS_VINC_PUB_NI.7z` with records whose municipality is not
#'   identified; the establishments are in a single national
#'   `RAIS_ESTAB_PUB.7z`;
#' * up to the RAIS **2017**, there is one file per state
#'   (`PE2017.7z`, `SP2017.7z`, ...) and a national `ESTB2017.7z`.
#'
#' @param year Reference years (integer or character vector).
#' @param uf Optional states to cover, as IBGE two-digit codes (`26`) or
#'   two-letter abbreviations (`"PE"`). `NULL` covers every state (all
#'   regional files, or all 27 state files).
#' @param type Which files: `"vinculos"` (employment relationships, the
#'   default), `"estabelecimentos"` (establishments) or both.
#' @param edition `"final"` (the default), `"parcial"` (the preliminary
#'   edition some years receive before the final one) or `"legado"` (the
#'   previous files, kept in a `Legado` sub-folder when a year is
#'   re-published).
#'
#' @return A tibble with one row per archive and columns `year`, `edition`,
#'   `type`, `group`, `file` and `url`.
#' @export
#' @examples
#' rais_files(2024, uf = "PE")
#' rais_files(2017, uf = c(26, 29), type = c("vinculos", "estabelecimentos"))
#' rais_files(2024)$file
rais_files <- function(year, uf = NULL, type = "vinculos", edition = "final") {
  year    <- .as_year(year)
  uf      <- .as_uf(uf)
  type    <- .as_type(type, several.ok = TRUE)
  edition <- .as_edition(edition)
  tab     <- .rais_uf_table

  rows <- lapply(year, function(y) {
    folder <- .rais_folder_url(y, edition)
    out <- NULL
    if ("vinculos" %in% type) {
      if (y >= .rais_regional_from) {
        regions <- if (is.null(uf)) .rais_regions else unique(tab$region[tab$uf %in% uf])
        regions <- .rais_regions[.rais_regions %in% regions]
        files <- sprintf("RAIS_VINC_PUB_%s.7z", regions)
        out <- rbind(out, data.frame(year = y, edition = edition, type = "vinculos",
                                     group = regions, file = files, stringsAsFactors = FALSE))
      } else {
        siglas <- if (is.null(uf)) tab$sigla else tab$sigla[tab$uf %in% uf]
        siglas <- tab$sigla[tab$sigla %in% siglas]
        out <- rbind(out, data.frame(year = y, edition = edition, type = "vinculos",
                                     group = siglas, file = sprintf("%s%d.7z", siglas, y),
                                     stringsAsFactors = FALSE))
      }
    }
    if ("estabelecimentos" %in% type) {
      file <- if (y >= .rais_regional_from) "RAIS_ESTAB_PUB.7z" else sprintf("ESTB%d.7z", y)
      out <- rbind(out, data.frame(year = y, edition = edition, type = "estabelecimentos",
                                   group = NA_character_, file = file, stringsAsFactors = FALSE))
    }
    out$url <- paste0(folder, "/", out$file)
    out
  })
  tibble::as_tibble(do.call(rbind, rows))
}

#' The 27 Brazilian states and the regional file that carries each one
#'
#' Offline reference table used by the package to translate state codes
#' and abbreviations and to route a state to its regional archive from the
#' RAIS 2018 onwards.
#'
#' @return A tibble with columns `uf` (IBGE two-digit code), `sigla`
#'   (two-letter abbreviation), `name` and `region` (the suffix of the
#'   `RAIS_VINC_PUB_<region>.7z` file).
#' @export
#' @examples
#' rais_ufs()
#' subset(rais_ufs(), region == "NORDESTE")
rais_ufs <- function() {
  tibble::as_tibble(.rais_uf_table)
}
