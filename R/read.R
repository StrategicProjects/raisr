# Columns converted to double when `types = TRUE` (normalized names). All
# remuneration values and the tenure in months have decimals.
.rais_dbl_cols <- c(
  "vl_remun_dezembro_nom", "vl_remun_dezembro_sm", "vl_remun_media_nom", "vl_remun_media_sm",
  "tempo_emprego",
  paste0("vl_rem_", c("janeiro", "fevereiro", "marco", "abril", "maio", "junho", "julho",
                      "agosto", "setembro", "outubro", "novembro"), "_sc"),
  paste0("vl_rem_", c("janeiro", "fevereiro", "marco", "abril", "maio", "junho", "julho",
                      "agosto", "setembro", "outubro", "novembro"), "_cc")
)

# Codes kept as character because they carry leading zeros or letters.
.rais_chr_cols <- c(
  "cbo_ocupacao_2002", "cbo_ocupacao", "cnae_20_classe", "cnae_95_classe",
  "cnae_20_subclasse", "tipo_estab_nome", "cep_estab", "subs_ibge"
)

#' Convert the columns of a table read as character. The Ministry's marker
#' for ignored values (a token in braces, "{n class}" with a tilde, sometimes
#' truncated) becomes NA in every column; then the doubles of the list above are converted (decimal
#' comma or point according to the file), and any other column whose
#' non-empty values are all integers becomes integer.
#' @noRd
.rais_type_columns <- function(out, decimal_mark) {
  for (cl in names(out)) {
    v <- out[[cl]]
    ign <- !is.na(v) & startsWith(v, "{")
    if (any(ign)) { v[ign] <- NA_character_; out[[cl]] <- v }
  }
  for (cl in intersect(names(out), .rais_dbl_cols)) {
    v <- out[[cl]]
    if (decimal_mark == ",") v <- sub(",", ".", v, fixed = TRUE)
    out[[cl]] <- suppressWarnings(as.numeric(v))
  }
  rest <- setdiff(names(out), c(.rais_dbl_cols, .rais_chr_cols))
  for (cl in rest) {
    v <- out[[cl]]
    ok <- is.na(v) | v == "" | grepl("^-?[0-9]+$", v)
    if (all(ok)) out[[cl]] <- suppressWarnings(as.integer(v))
  }
  out
}

#' Read a RAIS archive as a stream
#'
#' Reads the text file inside a `.7z` archive of the RAIS without extracting
#' it to disk and without loading the whole file in memory: the text is
#' decompressed as a stream and parsed in chunks, and each chunk is filtered
#' by state and reduced to the requested columns before being kept. This is
#' what makes it practical to extract one state (a few million records for
#' a large one) from a regional file of tens of millions of records on a
#' modest machine.
#'
#' The function handles the two generations of files published by the
#' Ministry: the `;`-separated files with decimal comma (up to the RAIS
#' 2022, and the partial and legacy editions) and the `,`-separated files
#' with decimal point published from the RAIS 2023 onwards, whose header
#' names differ. Both are read into the same normalized column names (see
#' [rais_layout()]), so that years can be stacked.
#'
#' @param path Path to an archive, as returned by [rais_download()].
#' @param uf Optional states to keep, as IBGE two-digit codes (`26`) or
#'   two-letter abbreviations (`"PE"`). The state is derived from the first
#'   two digits of the establishment's municipality code (`municipio`).
#'   `NULL` keeps every record.
#' @param columns Optional character vector of columns to keep, using the
#'   normalized names listed by [rais_layout()]. `NULL` keeps all columns.
#'   `municipio` is always read (it is needed for filtering) but is only
#'   returned when requested or when `columns` is `NULL`.
#' @param types Convert numeric columns? The Ministry's marker for ignored
#'   values (a token in braces, `{n class}` with a tilde on the n) becomes
#'   `NA` in every column; remuneration values and tenure
#'   become doubles; codes and counts whose values are all integers become
#'   integers; classification codes with leading zeros (CNAE, CBO) stay
#'   character. If `FALSE` every column is returned as character, exactly
#'   as in the file (trimmed).
#' @param year Reference year of the archive. Detected from the file name
#'   (`PE2017.7z`) or from the folder it sits in (`2024/`, `2023-legado/`),
#'   which is how [rais_download()] lays out the cache; pass it explicitly
#'   for a file kept elsewhere.
#' @param chunk_size Number of lines parsed per chunk. Larger chunks are
#'   faster but use more memory; the default (500,000 lines of 60 columns)
#'   uses well under 1 GB.
#' @param verbose Emit progress messages? Defaults to
#'   `getOption("raisr.verbose", TRUE)`.
#'
#' @return A tibble with the selected records and columns, plus two columns
#'   added by the package: `rais_year` (the reference year) and `rais_type`
#'   (`"vinculos"` or `"estabelecimentos"`). Column names are normalized:
#'   accents removed, lower case, words separated by `_`, identical across
#'   the two header generations. Returns an empty tibble when no record
#'   matches.
#' @export
#' @seealso [rais_layout()] for the meaning of every column,
#'   [rais_fetch()] for download and read in one call.
#' @examples
#' # Small sample archives ship with the package (Pernambuco and Bahia rows).
#' f <- system.file("extdata", "2024", "RAIS_VINC_PUB_NORDESTE_sample.7z", package = "raisr")
#' x <- rais_read(f, verbose = FALSE)
#' dim(x)
#'
#' # One state, a few columns
#' pe <- rais_read(f, uf = "PE",
#'                 columns = c("municipio", "cnae_20_subclasse", "vinculo_ativo_31_12",
#'                             "vl_remun_media_nom"),
#'                 verbose = FALSE)
#' pe
rais_read <- function(path, uf = NULL, columns = NULL, types = TRUE, year = NULL,
                      chunk_size = 500000L, verbose = NULL) {
  verbose <- .verbose(verbose)
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    cli::cli_abort("{.arg path} must be the path of an existing archive.")
  }
  uf   <- .as_uf(uf)
  info <- .detect_file(path)
  year <- if (is.null(year)) .detect_year(path) else .as_year(year)
  if (is.na(year) && verbose) {
    cli::cli_alert_warning("Could not tell the reference year of {.file {basename(path)}}; pass {.arg year}.")
  }

  entries <- archive::archive(path)
  inner <- entries$path[entries$size > 0 & !grepl("/$", entries$path)]
  if (length(inner) == 0L) cli::cli_abort("No data file inside {.file {basename(path)}}.")
  inner <- inner[[1]]

  # Header: detect the separator (";" in the older files, "," from the RAIS
  # 2023 onwards) and normalize the names. The files are Latin-1.
  con <- archive::archive_read(path, file = inner)
  header <- readLines(con, n = 1L, warn = FALSE)
  close(con)
  header <- iconv(header, from = "latin1", to = "UTF-8", sub = "?")
  delim <- if (grepl(";", header, fixed = TRUE)) ";" else ","
  decimal_mark <- if (delim == ";") "," else "."
  raw_names <- scan(text = header, what = "", sep = delim, quote = "\"", quiet = TRUE,
                    strip.white = TRUE, encoding = "UTF-8")
  nms <- .normalize_names(raw_names)

  if (!is.null(uf) && !"municipio" %in% nms) {
    cli::cli_abort("Cannot filter by state: no {.field municipio} column in {.file {basename(path)}}.")
  }
  if (!is.null(columns)) {
    missing_cols <- setdiff(columns, nms)
    if (length(missing_cols)) {
      cli::cli_abort(c("Column{?s} not in this file: {.val {missing_cols}}.",
                       "i" = "See {.fn rais_layout} for the available columns."))
    }
  }
  keep <- if (is.null(columns)) nms else if (is.null(uf)) columns else union(columns, "municipio")
  uf_keep <- if (is.null(uf)) NULL else sprintf("%02d", uf)

  cb <- function(chunk, pos) {
    if (!is.null(uf_keep)) {
      chunk <- chunk[substr(trimws(chunk$municipio), 1L, 2L) %in% uf_keep, , drop = FALSE]
    }
    chunk[, keep, drop = FALSE]
  }

  con <- archive::archive_read(path, file = inner)
  on.exit(try(close(con), silent = TRUE), add = TRUE)
  out <- readr::read_delim_chunked(
    con,
    callback   = readr::DataFrameCallback$new(cb),
    chunk_size = chunk_size,
    delim      = delim,
    quote      = "\"",
    col_names  = nms,
    skip       = 1L,
    col_types  = readr::cols(.default = readr::col_character()),
    locale     = readr::locale(encoding = "latin1", decimal_mark = decimal_mark,
                               grouping_mark = if (decimal_mark == ",") "." else ","),
    trim_ws    = TRUE,
    na         = c("", "NA"),
    progress   = FALSE
  )
  if (is.null(out) || nrow(out) == 0L) {
    out <- as.data.frame(stats::setNames(replicate(length(keep), character(), simplify = FALSE), keep))
  }
  out <- tibble::as_tibble(out)

  if (isTRUE(types)) out <- .rais_type_columns(out, decimal_mark)
  if (!is.null(columns) && !"municipio" %in% columns) out$municipio <- NULL

  out$rais_year <- rep(year, nrow(out))
  out$rais_type <- rep(info$type, nrow(out))
  if (verbose) {
    cli::cli_alert_success(
      "{basename(path)}: {format(nrow(out), big.mark = ',')} record{?s} kept{if (!is.null(uf)) paste0(' (uf ', paste(uf, collapse = ', '), ')') else ''}."
    )
  }
  out
}

#' Download and read RAIS microdata in one call
#'
#' Convenience wrapper: [rais_download()] followed by [rais_read()] on
#' every archive found, with the results stacked. Archives missing on the
#' server are skipped with a message.
#'
#' @inheritParams rais_download
#' @inheritParams rais_read
#'
#' @return A tibble with the records of every archive read (see
#'   [rais_read()] for the columns), or an empty tibble when nothing was
#'   available. The attribute `"download"` holds the tibble returned by
#'   [rais_download()], so that `not_found` and `error` files can be
#'   inspected.
#' @export
#' @examples
#' \dontrun{
#' # Pernambuco, RAIS 2024, a few columns (downloads the 600 MB NORDESTE file)
#' pe <- rais_fetch(2024, uf = "PE",
#'                  columns = c("municipio", "cnae_20_subclasse", "vinculo_ativo_31_12",
#'                              "vl_remun_dezembro_nom"))
#' rais_stock(pe, by = "municipio")
#' }
rais_fetch <- function(year, uf = NULL, type = "vinculos", edition = "final",
                       columns = NULL, cache_dir = NULL, force = FALSE,
                       types = TRUE, chunk_size = 500000L, timeout = 3600,
                       verbose = NULL) {
  verbose <- .verbose(verbose)
  dl <- rais_download(year, uf = uf, type = type, edition = edition,
                      cache_dir = cache_dir, force = force, timeout = timeout,
                      verbose = verbose)
  ok <- dl[!is.na(dl$path), , drop = FALSE]
  parts <- lapply(seq_len(nrow(ok)), function(i) {
    rais_read(ok$path[i], uf = uf, columns = columns, types = types, year = ok$year[i],
              chunk_size = chunk_size, verbose = verbose)
  })
  out <- .bind_rows_fill(parts)
  attr(out, "download") <- dl
  out
}
