# Builds the sample archives in inst/extdata from real public microdata
# downloaded from the PDET/MTE FTP server, keeping the exact byte format of
# each file generation (Latin-1, ";" with decimal comma up to the RAIS 2022,
# "," with decimal point from the RAIS 2023; original headers).
#
# Sources (set `raw` to a folder holding them, extracted from the .7z):
#   RAIS_VINC_PUB_NI.COMT   RAIS 2024, the "nao identificado" regional file
#   RAIS_VINC_PUB_NI.txt    RAIS 2022, idem
#   RR2017.txt              RAIS 2017, Roraima
#   RAIS_ESTAB_PUB.COMT     RAIS 2023, establishments
#   RAIS_ESTAB_PUB.txt      RAIS 2022, establishments
#
# The NI files have no municipality (999999); their rows receive real
# municipality codes of Pernambuco and Bahia so that the state filter can be
# exercised. Every other value is kept as published.
raw <- "/private/tmp/claude-501/-Users-leite-Github-raisr/ca41094c-a805-48cf-a856-347017be0095/scratchpad/dl/x"
set.seed(1)
pe <- c(260790L, 261160L, 260960L, 260410L)          # Recife, Petrolina, Olinda, Caruaru
ba <- c(292740L, 290570L, 291080L)                   # Salvador, Camacari, Feira de Santana

read_lines_bytes <- function(path, n = -1L) readLines(path, n = n, warn = FALSE)
write_sample <- function(lines, inner, out) {
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  tmp <- file.path(tempdir(), inner)
  writeLines(lines, tmp, useBytes = TRUE)
  if (file.exists(out)) unlink(out)
  archive::archive_write_files(out, tmp, format = "7zip")
  cat(out, ":", length(lines) - 1L, "rows,", file.size(out), "bytes\n")
}
# Replace the municipality fields (positions `pos`) of `lines` by codes of
# PE (first n_pe rows) and BA (the rest).
assign_uf <- function(lines, sep, pos, n_pe, n_ba) {
  vals <- c(sample(pe, n_pe, TRUE), sample(ba, n_ba, TRUE))
  vapply(seq_along(lines), function(i) {
    f <- strsplit(lines[i], sep, fixed = TRUE, useBytes = TRUE)[[1]]
    f[pos] <- as.character(vals[i])
    paste(f, collapse = sep)
  }, "", USE.NAMES = FALSE)
}

# RAIS 2024, "," files (vinculos): 24 PE + 8 BA rows
l <- read_lines_bytes(file.path(raw, "RAIS_VINC_PUB_NI.COMT"), 200)
rows <- l[-1][sample(199, 32)]
rows <- assign_uf(rows, ",", c(25, 26), 24, 8)
write_sample(c(l[1], rows), "RAIS_VINC_PUB_NORDESTE.COMT", "inst/extdata/2024/RAIS_VINC_PUB_NORDESTE_sample.7z")

# RAIS 2022, ";" files (vinculos): 24 PE + 8 BA rows
l <- read_lines_bytes(file.path(raw, "RAIS_VINC_PUB_NI.txt"), 200)
rows <- l[-1][sample(199, 32)]
rows <- assign_uf(rows, ";", c(25, 26), 24, 8)
write_sample(c(l[1], rows), "RAIS_VINC_PUB_NORDESTE.txt", "inst/extdata/2022/RAIS_VINC_PUB_NORDESTE_sample.7z")

# RAIS 2017, one file per state: 30 real rows of Roraima
l <- read_lines_bytes(file.path(raw, "RR2017.txt"), 31)
write_sample(l, "RR2017.txt", "inst/extdata/2017/RR2017_sample.7z")

# RAIS 2023, "," files (establishments): 20 PE + 8 BA real rows (UF is column 21)
f <- file.path(raw, "RAIS_ESTAB_PUB.COMT")
if (file.exists(f)) {
  con <- file(f, "r"); hdr <- readLines(con, 1, warn = FALSE); pe_rows <- ba_rows <- character()
  while (length(pe_rows) < 20L || length(ba_rows) < 8L) {
    chunk <- readLines(con, 20000, warn = FALSE); if (!length(chunk)) break
    uf <- vapply(strsplit(chunk, ",", fixed = TRUE, useBytes = TRUE), `[[`, "", 21)
    pe_rows <- c(pe_rows, chunk[uf == "26"]); ba_rows <- c(ba_rows, chunk[uf == "29"])
  }
  close(con)
  write_sample(c(hdr, head(pe_rows, 20), head(ba_rows, 8)), "RAIS_ESTAB_PUB.COMT",
               "inst/extdata/2023/RAIS_ESTAB_PUB_sample.7z")
}

# RAIS 2022, ";" files (establishments): 20 PE + 8 BA real rows (UF is column 22,
# after the two "Tipo Estab" columns)
f <- file.path(raw, "RAIS_ESTAB_PUB.txt")
if (file.exists(f)) {
  con <- file(f, "r"); hdr <- readLines(con, 1, warn = FALSE); pe_rows <- ba_rows <- character()
  while (length(pe_rows) < 20L || length(ba_rows) < 8L) {
    chunk <- readLines(con, 20000, warn = FALSE); if (!length(chunk)) break
    uf <- trimws(vapply(strsplit(chunk, ";", fixed = TRUE, useBytes = TRUE), `[[`, "", 22))
    pe_rows <- c(pe_rows, chunk[uf == "26"]); ba_rows <- c(ba_rows, chunk[uf == "29"])
  }
  close(con)
  write_sample(c(hdr, head(pe_rows, 20), head(ba_rows, 8)), "RAIS_ESTAB_PUB.txt",
               "inst/extdata/2022/RAIS_ESTAB_PUB_sample.7z")
}
