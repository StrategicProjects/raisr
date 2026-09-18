# Internal utilities for raisr. Nothing here is exported.

# -- Constants -----------------------------------------------------------------

#' Base URL of the PDET/MTE FTP folder for the RAIS microdata.
#' @noRd
.rais_ftp_base <- "ftp://ftp.mtps.gov.br/pdet/microdados/RAIS"

#' First year of the RAIS series on the server.
#' @noRd
.rais_first_year <- 1985L

#' First year published in regional files (`RAIS_VINC_PUB_<REGION>.7z`)
#' instead of one file per state (`<UF><AAAA>.7z`).
#' @noRd
.rais_regional_from <- 2018L

#' Editions of a year that can exist on the server: the final files, the
#' partial ("Parcial") files published before them, and the legacy
#' ("Legado") files kept after a re-publication.
#' @noRd
.rais_editions <- c("final", "parcial", "legado")

#' The two kinds of files.
#' @noRd
.rais_types <- c("vinculos", "estabelecimentos")

#' The regional files of the vinculos data from 2018 onwards, in server order.
#' `NI` is the "nao identificado" file (records without a known municipality).
#' @noRd
.rais_regions <- c("NORTE", "NORDESTE", "MG_ES_RJ", "SP", "SUL", "CENTRO_OESTE", "NI")

#' The 27 federative units: IBGE code, abbreviation, name and the regional
#' vinculos file that carries the state from 2018 onwards.
#' @noRd
.rais_uf_table <- data.frame(
  uf = c(11L, 12L, 13L, 14L, 15L, 16L, 17L,
         21L, 22L, 23L, 24L, 25L, 26L, 27L, 28L, 29L,
         31L, 32L, 33L, 35L,
         41L, 42L, 43L,
         50L, 51L, 52L, 53L),
  sigla = c("RO", "AC", "AM", "RR", "PA", "AP", "TO",
            "MA", "PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA",
            "MG", "ES", "RJ", "SP",
            "PR", "SC", "RS",
            "MS", "MT", "GO", "DF"),
  name = c("Rond\u00f4nia", "Acre", "Amazonas", "Roraima", "Par\u00e1", "Amap\u00e1", "Tocantins",
           "Maranh\u00e3o", "Piau\u00ed", "Cear\u00e1", "Rio Grande do Norte", "Para\u00edba",
           "Pernambuco", "Alagoas", "Sergipe", "Bahia",
           "Minas Gerais", "Esp\u00edrito Santo", "Rio de Janeiro", "S\u00e3o Paulo",
           "Paran\u00e1", "Santa Catarina", "Rio Grande do Sul",
           "Mato Grosso do Sul", "Mato Grosso", "Goi\u00e1s", "Distrito Federal"),
  region = c(rep("NORTE", 7L), rep("NORDESTE", 9L), rep("MG_ES_RJ", 3L), "SP",
             rep("SUL", 3L), rep("CENTRO_OESTE", 4L)),
  stringsAsFactors = FALSE
)

# -- Verbosity -----------------------------------------------------------------

#' Are progress messages enabled? Controlled by `options(raisr.verbose)`.
#' @noRd
.verbose <- function(verbose = NULL) {
  verbose %||% getOption("raisr.verbose", TRUE)
}

# -- Arguments -----------------------------------------------------------------

#' Validate reference years (integer or character). Returns an integer vector.
#' @noRd
.as_year <- function(x, arg = "year") {
  if (is.null(x) || length(x) == 0L) {
    cli::cli_abort("{.arg {arg}} must have at least one reference year.")
  }
  y <- suppressWarnings(as.integer(as.character(x)))
  first <- .rais_first_year   # local: cli reads a leading dot as a style
  bad <- is.na(y) | y < 1000L | y > 9999L
  if (any(bad)) {
    cli::cli_abort(c(
      "{.arg {arg}} must be reference years in {.code AAAA} format.",
      "x" = "Invalid value{?s}: {.val {x[bad]}}."
    ))
  }
  if (any(y < first)) {
    cli::cli_abort(c(
      "The RAIS series on the server starts in {.val {first}}.",
      "x" = "Earlier year{?s} requested: {.val {y[y < first]}}."
    ))
  }
  y
}

#' Validate state identifiers given as IBGE codes (26, "26") or two-letter
#' abbreviations ("PE", "pe"). Returns integer IBGE codes, or NULL for NULL.
#' @noRd
.as_uf <- function(x, arg = "uf") {
  if (is.null(x)) return(NULL)
  tab <- .rais_uf_table
  x <- as.character(x)
  code <- suppressWarnings(as.integer(x))
  by_sigla <- match(toupper(trimws(x)), tab$sigla)
  code[is.na(code)] <- tab$uf[by_sigla[is.na(code)]]
  bad <- is.na(code) | !code %in% tab$uf
  if (any(bad)) {
    cli::cli_abort(c(
      "{.arg {arg}} must be IBGE state codes or two-letter abbreviations.",
      "x" = "Unknown value{?s}: {.val {x[bad]}}."
    ))
  }
  unique(code)
}

#' Validate the edition argument.
#' @noRd
.as_edition <- function(x) {
  match.arg(tolower(x), .rais_editions)
}

#' Validate the type argument (one or both kinds of files).
#' @noRd
.as_type <- function(x, several.ok = FALSE) {
  match.arg(tolower(x), .rais_types, several.ok = several.ok)
}

# -- URLs and paths ------------------------------------------------------------

#' Server folder of one year and edition, URL-encoded.
#' @noRd
.rais_folder_url <- function(year, edition = "final") {
  switch(edition,
    final   = sprintf("%s/%d", .rais_ftp_base, year),
    parcial = sprintf("%s/%d%%20Parcial", .rais_ftp_base, year),
    legado  = sprintf("%s/%d/Legado", .rais_ftp_base, year)
  )
}

#' Cache sub-folder of one year and edition (`2023`, `2023-parcial`,
#' `2023-legado`).
#' @noRd
.rais_folder_name <- function(year, edition = "final") {
  if (edition == "final") as.character(year) else paste0(year, "-", edition)
}

#' Detect year and edition from the folder that contains an archive.
#' Returns a list with `year` (integer or NA) and `edition`.
#' @noRd
.detect_folder <- function(path) {
  d <- basename(dirname(path))
  m <- regmatches(d, regexec("^(\\d{4})(?:-(parcial|legado))?$", d, perl = TRUE))[[1]]
  if (length(m) == 0L) return(list(year = NA_integer_, edition = NA_character_))
  list(year = as.integer(m[2]), edition = if (nzchar(m[3])) m[3] else "final")
}

#' Detect what an archive is from its file name. Returns a list with `type`
#' ("vinculos" / "estabelecimentos" / NA), `group` (region name, state
#' abbreviation or NA) and `year` (from the name, for pre-2018 files).
#' A `_sample` suffix (used by the package's own fixtures) is tolerated.
#' @noRd
.detect_file <- function(path) {
  nm <- sub("_sample\\.7z$", ".7z", basename(path), ignore.case = TRUE)
  none <- list(type = NA_character_, group = NA_character_, year = NA_integer_)
  m <- regmatches(nm, regexec("^RAIS_VINC_PUB_([A-Z_]+)\\.7z$", nm, ignore.case = TRUE))[[1]]
  if (length(m)) return(list(type = "vinculos", group = toupper(m[2]), year = NA_integer_))
  if (grepl("^RAIS_ESTAB_PUB\\.7z$", nm, ignore.case = TRUE)) {
    return(list(type = "estabelecimentos", group = NA_character_, year = NA_integer_))
  }
  m <- regmatches(nm, regexec("^ESTB(\\d{4})\\.(7z|txt)$", nm, ignore.case = TRUE))[[1]]
  if (length(m)) return(list(type = "estabelecimentos", group = NA_character_, year = as.integer(m[2])))
  m <- regmatches(nm, regexec("^([A-Z]{2})(\\d{4})\\.7z$", nm, ignore.case = TRUE))[[1]]
  if (length(m) && toupper(m[2]) %in% .rais_uf_table$sigla) {
    return(list(type = "vinculos", group = toupper(m[2]), year = as.integer(m[3])))
  }
  m <- regmatches(nm, regexec("^IGNORANDOS(\\d{4})\\.7z$", nm, ignore.case = TRUE))[[1]]
  if (length(m)) return(list(type = "vinculos", group = "IGNORADOS", year = as.integer(m[2])))
  none
}

#' Year of an archive: from the file name (pre-2018 files) or from the
#' folder that contains it (regional files). NA when neither is available.
#' @noRd
.detect_year <- function(path) {
  y <- .detect_file(path)$year
  if (is.na(y)) y <- .detect_folder(path)$year
  y
}

# -- FTP listing ---------------------------------------------------------------

#' Fetch the raw text of an FTP directory listing. Returns NULL when the
#' directory does not exist or the server is unreachable.
#' @noRd
.ftp_listing <- function(url, timeout = 30) {
  h <- curl::new_handle(connecttimeout = timeout, timeout = timeout * 4)
  res <- tryCatch(curl::curl_fetch_memory(paste0(url, "/"), handle = h),
                  error = function(e) NULL)
  if (is.null(res) || res$status_code >= 400L) return(NULL)
  # The server has folder and file names in Latin-1: decode before splitting.
  iconv(rawToChar(res$content), from = "latin1", to = "UTF-8", sub = "?")
}

#' Parse an IIS-style FTP listing (`MM-DD-YY HH:MMAM <DIR> name` or
#' `MM-DD-YY HH:MMAM size name`) into a tibble of entries.
#' @noRd
.parse_ftp_listing <- function(txt) {
  empty <- tibble::tibble(name = character(), is_dir = logical(),
                          size = numeric(), modified = as.POSIXct(character()))
  lines <- strsplit(txt %||% "", "\r?\n")[[1]]
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines) == 0L) return(empty)
  m <- regmatches(lines, regexec(
    "^\\s*(\\d{2}-\\d{2}-\\d{2})\\s+(\\d{2}:\\d{2}[AP]M)\\s+(<DIR>|\\d+)\\s+(.*?)\\s*$",
    lines))
  m <- m[lengths(m) == 5L]
  if (length(m) == 0L) return(empty)
  date <- vapply(m, `[[`, "", 2L)
  time <- vapply(m, `[[`, "", 3L)
  what <- vapply(m, `[[`, "", 4L)
  name <- vapply(m, `[[`, "", 5L)
  # Locale-independent 12-hour clock: "%p" does not parse AM/PM outside
  # English locales, so convert to 24 h by hand.
  hh <- as.integer(substr(time, 1L, 2L)) %% 12L + ifelse(grepl("PM$", time), 12L, 0L)
  mm <- substr(time, 4L, 5L)
  tibble::tibble(
    name     = name,
    is_dir   = what == "<DIR>",
    size     = ifelse(what == "<DIR>", NA_real_, suppressWarnings(as.numeric(what))),
    modified = as.POSIXct(sprintf("%s %02d:%s", date, hh, mm), format = "%m-%d-%y %H:%M", tz = "UTC")
  )
}

# -- Column names --------------------------------------------------------------

#' Header names that changed between the `;` files (up to the RAIS 2022 and
#' the legacy/partial editions) and the `,` files (RAIS 2023 onwards), after
#' normalization. The canonical name is the one of the older files, which
#' most users already know.
#' @noRd
.rais_aliases <- c(
  ind_vinculo_ativo_31_12                  = "vinculo_ativo_31_12",
  cnae_2_0_classe                          = "cnae_20_classe",
  cnae_2_0_subclasse                       = "cnae_20_subclasse",
  cbo_2002_ocupacao                        = "cbo_ocupacao_2002",
  faixa_rem_media_sm                       = "faixa_remun_media_sm",
  faixa_rem_dez_sm                         = "faixa_remun_dezem_sm",
  ind_estabelecimento_participante_simples = "ind_simples",
  municipio_trab                           = "mun_trab",
  regiao_adm_df                            = "regioes_adm_df",
  vl_rem_dezembro_nom                      = "vl_remun_dezembro_nom",
  vl_rem_dezembro_sm                       = "vl_remun_dezembro_sm",
  vl_rem_media_nom                         = "vl_remun_media_nom",
  vl_rem_media_sm                          = "vl_remun_media_sm",
  sexo                                     = "sexo_trabalhador",
  tipo_admissao_trabalhador                = "tipo_admissao",
  tipo_estabelecimento                     = "tipo_estab",
  tipo_estabelecimento_nome                = "tipo_estab_nome",
  tipo_estab_2                             = "tipo_estab_nome",
  tipo_deficiencia                         = "tipo_defic",
  ind_trabalho_intermitente                = "ind_trab_intermitente",
  ind_trabalho_parcial                     = "ind_trab_parcial",
  ind_estab_participante_pat               = "ind_estab_participa_pat",
  ind_estab_participante_simples           = "ind_simples"
)

#' Normalize the Ministry's column names to stable `snake_case` ASCII names:
#' strip a UTF-8 BOM, remove accents, lower case, drop the `- Codigo` suffix
#' of the newer files (`- Nome` becomes `_nome`), replace everything that is
#' not `[a-z0-9]` by `_`, make duplicated names unique (`_2`, `_3`) and
#' apply the alias table so that the two header generations coincide.
#' @noRd
.normalize_names <- function(x) {
  x <- sub("^\ufeff", "", x)
  x <- stringi::stri_trans_general(x, "Latin-ASCII")
  x <- tolower(trimws(x))
  x <- sub("\\s*-\\s*codigo$", "", x)
  x <- sub("\\s*-\\s*nome$", "_nome", x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  # duplicated headers (the old files have "Tipo Estab" twice)
  dup <- duplicated(x)
  if (any(dup)) {
    for (i in which(dup)) {
      k <- sum(x[seq_len(i)] == x[i])
      x[i] <- paste0(x[i], "_", k)
    }
  }
  hit <- match(x, names(.rais_aliases))
  x[!is.na(hit)] <- unname(.rais_aliases[hit[!is.na(hit)]])
  x
}

# -- Row binding ---------------------------------------------------------------

#' Stack data frames whose columns differ (for example a 2022 and a 2023
#' file), filling missing columns with NA. Column order follows first
#' appearance.
#' @noRd
.bind_rows_fill <- function(parts) {
  parts <- parts[vapply(parts, function(p) !is.null(p) && nrow(p) > 0L, logical(1))]
  if (length(parts) == 0L) return(tibble::tibble())
  cols <- unique(unlist(lapply(parts, names)))
  parts <- lapply(parts, function(p) {
    for (cl in setdiff(cols, names(p))) p[[cl]] <- rep(NA, nrow(p))
    p[, cols, drop = FALSE]
  })
  tibble::as_tibble(do.call(rbind, parts))
}
