sample <- function(...) system.file("extdata", ..., package = "raisr")
v24 <- function() sample("2024", "RAIS_VINC_PUB_NORDESTE_sample.7z")
v22 <- function() sample("2022", "RAIS_VINC_PUB_NORDESTE_sample.7z")
v17 <- function() sample("2017", "RR2017_sample.7z")
e23 <- function() sample("2023", "RAIS_ESTAB_PUB_sample.7z")
e22 <- function() sample("2022", "RAIS_ESTAB_PUB_sample.7z")

test_that("a 2023-generation archive (comma, decimal point) is read with normalized names and types", {
  x <- rais_read(v24(), verbose = FALSE)
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 32L)
  expect_false(any(grepl("[^a-z0-9_]", names(x))))
  expect_type(x$municipio, "integer")
  expect_type(x$vinculo_ativo_31_12, "integer")
  expect_type(x$vl_remun_media_nom, "double")
  expect_type(x$tempo_emprego, "double")
  expect_type(x$cbo_ocupacao_2002, "character")
  expect_type(x$cnae_20_subclasse, "character")
  expect_type(x$tipo_estab_nome, "character")
  expect_equal(unique(x$rais_year), 2024L)
  expect_equal(unique(x$rais_type), "vinculos")
  expect_setequal(unique(substr(x$municipio, 1, 2)), c("26", "29"))
  expect_true(all(c("ind_vinculo_abandonado", "categoria_trabalhador") %in% names(x)))
})

test_that("a 2022-generation archive (semicolon, decimal comma) gives the same names", {
  a <- rais_read(v24(), verbose = FALSE)
  b <- rais_read(v22(), verbose = FALSE)
  expect_equal(nrow(b), 32L)
  expect_equal(setdiff(names(a), names(b)), c("ind_vinculo_abandonado", "categoria_trabalhador"))
  expect_equal(setdiff(names(b), names(a)), character())
  expect_type(b$vl_remun_media_nom, "double")
  expect_true(any(b$vl_remun_media_nom %% 1 != 0))   # decimal comma was parsed
  expect_type(b$mes_desligamento, "integer")        # "{n class}" became NA
  expect_equal(unique(b$rais_year), 2022L)
  both <- raisr:::.bind_rows_fill(list(a, b))
  expect_equal(nrow(both), 64L)
  expect_true(all(is.na(both$categoria_trabalhador[both$rais_year == 2022L])))
})

test_that("a pre-2018 state archive is read and its year comes from the name", {
  x <- rais_read(v17(), verbose = FALSE)
  expect_equal(nrow(x), 30L)
  expect_equal(unique(x$rais_year), 2017L)
  expect_true("vl_rem_janeiro_cc" %in% names(x))
  expect_true(all(substr(x$municipio, 1, 2) == "14"))
  expect_equal(nrow(rais_read(v17(), uf = "RR", verbose = FALSE)), 30L)
  expect_equal(nrow(rais_read(v17(), uf = "PE", verbose = FALSE)), 0L)
})

test_that("establishment archives of both generations are read", {
  a <- rais_read(e23(), verbose = FALSE)
  b <- rais_read(e22(), verbose = FALSE)
  expect_equal(unique(a$rais_type), "estabelecimentos")
  expect_equal(nrow(a), 28L); expect_equal(nrow(b), 28L)
  expect_equal(setdiff(names(b), names(a)), "tipo_estab_nome")
  expect_equal(setdiff(names(a), names(b)), character())
  expect_type(a$qtd_vinculos_ativos, "integer")
  expect_type(b$qtd_vinculos_ativos, "integer")
  expect_type(a$uf, "integer")
  expect_type(a$cep_estab, "character")
  expect_equal(table(a$uf)[["26"]], 20L)
  expect_equal(nrow(rais_read(e22(), uf = 29, verbose = FALSE)), 8L)
})

test_that("uf filter and column selection work and municipio is dropped when not asked", {
  pe <- rais_read(v24(), uf = 26, verbose = FALSE)
  expect_equal(nrow(pe), 24L)
  expect_true(all(substr(pe$municipio, 1, 2) == "26"))
  expect_equal(nrow(rais_read(v24(), uf = c("PE", "BA"), verbose = FALSE)), 32L)

  sel <- rais_read(v24(), uf = 29, columns = c("idade", "vl_remun_media_nom"), verbose = FALSE)
  expect_equal(names(sel), c("idade", "vl_remun_media_nom", "rais_year", "rais_type"))
  expect_equal(nrow(sel), 8L)

  with_mun <- rais_read(v24(), columns = c("municipio", "idade"), verbose = FALSE)
  expect_equal(names(with_mun), c("municipio", "idade", "rais_year", "rais_type"))
})

test_that("small chunks give the same result as one chunk", {
  a <- rais_read(v22(), chunk_size = 5L, verbose = FALSE)
  b <- rais_read(v22(), chunk_size = 100000L, verbose = FALSE)
  expect_equal(a, b)
})

test_that("no match returns an empty tibble with the expected columns", {
  x <- rais_read(v24(), uf = 11, verbose = FALSE)
  expect_equal(nrow(x), 0L)
  expect_true(all(c("municipio", "rais_year") %in% names(x)))
})

test_that("types = FALSE keeps everything as character", {
  x <- rais_read(v22(), types = FALSE, verbose = FALSE)
  expect_type(x$vl_remun_media_nom, "character")
  expect_true(any(grepl(",", x$vl_remun_media_nom, fixed = TRUE)))
  expect_type(x$municipio, "character")
})

test_that("an explicit year overrides detection and errors are actionable", {
  x <- rais_read(v24(), year = 2030, verbose = FALSE)
  expect_equal(unique(x$rais_year), 2030L)
  expect_error(rais_read("does-not-exist.7z"), "existing archive")
  expect_error(rais_read(v24(), columns = "nope", verbose = FALSE), "rais_layout")
})

test_that("the layout documents every column of the sample files", {
  lay <- rais_layout()
  cols <- setdiff(union(names(rais_read(v24(), verbose = FALSE)), names(rais_read(v22(), verbose = FALSE))),
                  c("rais_year", "rais_type"))
  expect_setequal(cols, lay$column)
  expect_equal(nrow(lay), 62L)
  est <- rais_layout("estabelecimentos")
  cols <- setdiff(union(names(rais_read(e23(), verbose = FALSE)), names(rais_read(e22(), verbose = FALSE))),
                  c("rais_year", "rais_type"))
  expect_setequal(cols, est$column)
  # the documented headers normalize to the documented column names
  for (l in list(lay, est)) {
    o1 <- ifelse(is.na(l$original), l$column, l$original)
    o2 <- ifelse(is.na(l$original_2023), l$column, l$original_2023)
    expect_equal(raisr:::.normalize_names(o1), l$column)
    expect_equal(raisr:::.normalize_names(o2), l$column)
  }
  expect_error(rais_layout("nope"))
})
