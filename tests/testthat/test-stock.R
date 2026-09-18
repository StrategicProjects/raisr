sample <- function(...) system.file("extdata", ..., package = "raisr")

test_that("stock, admissions, separations and December payroll are aggregated", {
  x <- rais_read(sample("2024", "RAIS_VINC_PUB_NORDESTE_sample.7z"), verbose = FALSE)
  s <- rais_stock(x)
  expect_s3_class(s, "tbl_df")
  expect_equal(nrow(s), 1L)
  expect_equal(s$records, 32L)
  expect_equal(s$stock, sum(x$vinculo_ativo_31_12 == 1L))
  expect_equal(s$admissions, sum(x$mes_admissao > 0L))
  expect_equal(s$separations, sum(x$mes_desligamento > 0L))
  active <- x$vinculo_ativo_31_12 == 1L
  expect_equal(s$december_payroll, sum(x$vl_remun_dezembro_nom[active], na.rm = TRUE))
  paid <- active & !is.na(x$vl_remun_dezembro_nom) & x$vl_remun_dezembro_nom > 0
  expect_equal(s$mean_december_wage, s$december_payroll / sum(paid))
})

test_that("extra grouping columns are honored and years stack", {
  a <- rais_read(sample("2024", "RAIS_VINC_PUB_NORDESTE_sample.7z"), verbose = FALSE)
  b <- rais_read(sample("2022", "RAIS_VINC_PUB_NORDESTE_sample.7z"), verbose = FALSE)
  both <- raisr:::.bind_rows_fill(list(a, b))
  s <- rais_stock(both, by = "sexo_trabalhador")
  expect_equal(sum(s$records), 64L)
  expect_true(all(c("rais_year", "sexo_trabalhador") %in% names(s)))
  expect_equal(sort(unique(s$rais_year)), c(2022L, 2024L))
  s2 <- rais_stock(a, by = c("municipio"))
  expect_equal(sum(s2$stock), sum(a$vinculo_ativo_31_12 == 1L))
})

test_that("missing wage columns are tolerated and errors are reported", {
  x <- rais_read(sample("2024", "RAIS_VINC_PUB_NORDESTE_sample.7z"),
                 columns = c("municipio", "vinculo_ativo_31_12"), verbose = FALSE)
  s <- rais_stock(x, by = "municipio")
  expect_equal(names(s), c("rais_year", "municipio", "records", "stock"))
  expect_error(rais_stock(data.frame(a = 1)), "rais_read")
  expect_error(rais_stock(rais_read(sample("2024", "RAIS_VINC_PUB_NORDESTE_sample.7z"), verbose = FALSE), by = "nope"), "not in")
})
