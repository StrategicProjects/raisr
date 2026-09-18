sample_for <- function(url) {
  ext <- system.file("extdata", package = "raisr")
  nm <- basename(url)
  if (grepl("^RAIS_VINC_PUB_", nm)) {
    f <- if (grepl("2023%20Parcial|2022", url)) "2022" else "2024"
    return(file.path(ext, f, "RAIS_VINC_PUB_NORDESTE_sample.7z"))
  }
  if (nm == "RAIS_ESTAB_PUB.7z") return(file.path(ext, "2023", "RAIS_ESTAB_PUB_sample.7z"))
  file.path(ext, "2017", "RR2017_sample.7z")
}

# Pretend to download: copy a sample archive of the same kind, or report
# the file as missing / failing, without touching the network.
fake_download <- function(behavior = c("ok", "not_found", "error")) {
  behavior <- match.arg(behavior)
  function(url, destfile, timeout = 3600, retries = 3L) {
    if (behavior != "ok") return(behavior)
    file.copy(sample_for(url), destfile, overwrite = TRUE)
    "ok"
  }
}

test_that("download populates the cache with the server layout and reuses it", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.rais_curl_download = fake_download("ok"), .package = "raisr")

  d1 <- rais_download(2024, uf = c("PE", "SP"), type = c("vinculos", "estabelecimentos"),
                      cache_dir = dir, verbose = FALSE)
  expect_equal(d1$file, c("RAIS_VINC_PUB_NORDESTE.7z", "RAIS_VINC_PUB_SP.7z", "RAIS_ESTAB_PUB.7z"))
  expect_true(all(d1$status == "downloaded"))
  expect_true(all(file.exists(d1$path)))
  expect_equal(basename(dirname(d1$path)), rep("2024", 3L))

  d2 <- rais_download(2024, uf = c("PE", "SP"), type = c("vinculos", "estabelecimentos"),
                      cache_dir = dir, verbose = FALSE)
  expect_true(all(d2$status == "cached"))

  d3 <- rais_download(2023, uf = "PE", edition = "legado", cache_dir = dir, verbose = FALSE)
  expect_equal(basename(dirname(d3$path)), "2023-legado")

  lst <- rais_cache_list(dir)
  expect_equal(nrow(lst), 4L)
  expect_setequal(lst$year, c(2024L, 2023L))
  expect_equal(lst$edition[lst$year == 2023L], "legado")
  expect_setequal(lst$type, c("vinculos", "estabelecimentos"))

  expect_equal(rais_cache_clear(2024, cache_dir = dir), 3L)
  expect_equal(nrow(rais_cache_list(dir)), 1L)
  expect_equal(rais_cache_clear(cache_dir = dir), 1L)
})

test_that("pre-2018 archives are cached under their year with the state name", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.rais_curl_download = fake_download("ok"), .package = "raisr")
  d <- rais_download(2017, uf = "RR", cache_dir = dir, verbose = FALSE)
  expect_equal(d$file, "RR2017.7z")
  expect_equal(basename(dirname(d$path)), "2017")
  lst <- rais_cache_list(dir)
  expect_equal(lst$year, 2017L); expect_equal(lst$group, "RR")
})

test_that("files missing on the server are reported, not raised", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.rais_curl_download = fake_download("not_found"), .package = "raisr")
  d <- rais_download(2024, uf = "PE", edition = "parcial", cache_dir = dir, verbose = FALSE)
  expect_equal(d$status, "not_found")
  expect_true(is.na(d$path))
})

test_that("download errors warn and are reported", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.rais_curl_download = fake_download("error"), .package = "raisr")
  expect_warning(d <- rais_download(2024, uf = "PE", cache_dir = dir, verbose = FALSE), "download failed")
  expect_equal(d$status, "error")
})

test_that("fetch downloads, reads, filters and stacks", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.rais_curl_download = fake_download("ok"), .package = "raisr")
  x <- rais_fetch(2024, uf = 26, cache_dir = dir, verbose = FALSE)
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 24L)
  expect_equal(unique(x$rais_year), 2024L)
  expect_equal(nrow(attr(x, "download")), 1L)

  # Two years with different header generations stack on the same names
  y <- rais_fetch(c(2022, 2024), uf = 26, columns = c("municipio", "vl_remun_media_nom"),
                  cache_dir = dir, verbose = FALSE)
  expect_equal(nrow(y), 48L)
  expect_equal(names(y), c("municipio", "vl_remun_media_nom", "rais_year", "rais_type"))
  expect_equal(sort(unique(y$rais_year)), c(2022L, 2024L))
})

test_that("the cache directory is resolved from argument, env var, option, tempdir", {
  withr::local_envvar(RAISR_CACHE_DIR = "")
  withr::local_options(raisr.cache_dir = NULL)
  expect_equal(rais_cache_dir(), file.path(tempdir(), "raisr-cache"))
  d <- withr::local_tempdir()
  expect_equal(rais_cache_dir(d), d)
  withr::local_options(raisr.cache_dir = d)
  expect_equal(rais_cache_dir(), d)
  d2 <- withr::local_tempdir()
  withr::local_envvar(RAISR_CACHE_DIR = d2)
  expect_equal(rais_cache_dir(), d2)
})

test_that("rais_available returns an empty tibble with a warning when offline", {
  testthat::local_mocked_bindings(.ftp_listing = function(url, timeout = 30) NULL, .package = "raisr")
  expect_warning(a <- rais_available(verbose = FALSE), "Could not reach")
  expect_equal(nrow(a), 0L)
  expect_equal(names(a), c("year", "edition", "type", "group", "file", "size_bytes", "modified", "url"))
})

test_that("rais_available parses a mocked server, including partial and legacy editions", {
  listings <- list(
    root = paste("04-24-26  03:48PM       <DIR>          2017",
                 "05-18-26  05:35PM       <DIR>          2023",
                 "08-12-25  11:30AM       <DIR>          2023 Parcial",
                 "08-08-25  10:00AM       <DIR>          Layouts", sep = "\r\n"),
    y2017 = paste("10-01-18  10:17AM             97158386 ESTB2017.7z",
                  "10-01-18  10:17AM             73836375 PE2017.7z", sep = "\r\n"),
    y2023 = paste("12-30-25  03:39PM       <DIR>          Legado",
                  "05-18-26  05:35PM            127348274 RAIS_ESTAB_PUB.7z",
                  "05-18-26  05:20PM            567231199 RAIS_VINC_PUB_NORDESTE.7z",
                  "12-30-25  04:01PM               275623 Comunicado.htm", sep = "\r\n"),
    legado = "12-30-25  03:35PM            513915990 RAIS_VINC_PUB_NORDESTE.7z\r\n",
    parcial = "08-12-25  11:30AM            385611427 RAIS_VINC_PUB_NORDESTE.7z\r\n"
  )
  testthat::local_mocked_bindings(
    .ftp_listing = function(url, timeout = 30) {
      if (grepl("/2017$", url)) listings$y2017
      else if (grepl("/2023/Legado$", url)) listings$legado
      else if (grepl("/2023%20Parcial$", url)) listings$parcial
      else if (grepl("/2023$", url)) listings$y2023
      else listings$root
    },
    .package = "raisr"
  )
  a <- rais_available(verbose = FALSE)
  expect_equal(nrow(a), 6L)
  expect_equal(a$year, c(2023L, 2023L, 2023L, 2023L, 2017L, 2017L))
  expect_equal(a$edition, c("final", "final", "parcial", "legado", "final", "final"))
  expect_equal(a$type[1:2], c("estabelecimentos", "vinculos"))
  expect_equal(a$group[a$year == 2017L], c(NA, "PE"))
  expect_match(a$url[a$edition == "parcial"], "2023%20Parcial/RAIS_VINC_PUB_NORDESTE.7z$")
  expect_equal(a$size_bytes[a$edition == "legado"], 513915990)
  a17 <- rais_available(year = 2017, verbose = FALSE)
  expect_equal(nrow(a17), 2L)
})
