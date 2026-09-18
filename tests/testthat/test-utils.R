test_that("column names are normalized and the two header generations coincide", {
  old <- c("\ufeffBairros SP", "CBO Ocupa\u00e7\u00e3o 2002", "CNAE 2.0 Classe", "V\u00ednculo Ativo 31/12",
           "Faixa Remun M\u00e9dia (SM)", "Vl Remun Dezembro Nom", "Tipo Estab", "Tipo Estab", "Ind Simples")
  new <- c("Bairros SP - C\u00f3digo", "CBO 2002 Ocupa\u00e7\u00e3o - C\u00f3digo", "CNAE 2.0 Classe - C\u00f3digo",
           "Ind V\u00ednculo Ativo 31/12 - C\u00f3digo", "Faixa Rem M\u00e9dia (SM) - C\u00f3digo", "Vl Rem Dezembro Nom",
           "Tipo Estabelecimento - C\u00f3digo", "Tipo Estabelecimento - Nome",
           "Ind Estabelecimento Participante SIMPLES - C\u00f3digo")
  want <- c("bairros_sp", "cbo_ocupacao_2002", "cnae_20_classe", "vinculo_ativo_31_12",
            "faixa_remun_media_sm", "vl_remun_dezembro_nom", "tipo_estab", "tipo_estab_nome", "ind_simples")
  expect_equal(raisr:::.normalize_names(old), want)
  expect_equal(raisr:::.normalize_names(new), want)
  expect_equal(raisr:::.normalize_names(c("UF", "CEP Estab", "Ind Estab Participa PAT", "Ind Estab Participante PAT - C\u00f3digo")),
               c("uf", "cep_estab", "ind_estab_participa_pat", "ind_estab_participa_pat"))
})

test_that("years and states are validated", {
  expect_equal(raisr:::.as_year(c("2024", 2017)), c(2024L, 2017L))
  expect_error(raisr:::.as_year(1984), "starts in")
  expect_error(raisr:::.as_year("abc"), "AAAA")
  expect_error(raisr:::.as_year(NULL), "at least one")
  expect_equal(raisr:::.as_uf(c("PE", "pe", 26, "29")), c(26L, 29L))
  expect_null(raisr:::.as_uf(NULL))
  expect_error(raisr:::.as_uf("XX"), "Unknown")
  expect_error(raisr:::.as_uf(99), "Unknown")
})

test_that("archives are recognized from their names and folders", {
  d <- raisr:::.detect_file("2024/RAIS_VINC_PUB_NORDESTE.7z")
  expect_equal(d$type, "vinculos"); expect_equal(d$group, "NORDESTE"); expect_true(is.na(d$year))
  d <- raisr:::.detect_file("x/RAIS_VINC_PUB_NORDESTE_sample.7z")
  expect_equal(d$group, "NORDESTE")
  d <- raisr:::.detect_file("RAIS_ESTAB_PUB.7z")
  expect_equal(d$type, "estabelecimentos"); expect_true(is.na(d$group))
  d <- raisr:::.detect_file("PE2017.7z")
  expect_equal(d$type, "vinculos"); expect_equal(d$group, "PE"); expect_equal(d$year, 2017L)
  d <- raisr:::.detect_file("ESTB2010.7z")
  expect_equal(d$type, "estabelecimentos"); expect_equal(d$year, 2010L)
  expect_true(is.na(raisr:::.detect_file("Leia-me.txt")$type))
  expect_true(is.na(raisr:::.detect_file("XX2017.7z")$type))

  expect_equal(raisr:::.detect_folder("/a/2023/RAIS_ESTAB_PUB.7z"), list(year = 2023L, edition = "final"))
  expect_equal(raisr:::.detect_folder("/a/2023-legado/RAIS_ESTAB_PUB.7z"), list(year = 2023L, edition = "legado"))
  expect_equal(raisr:::.detect_folder("/a/2024-parcial/RAIS_ESTAB_PUB.7z"), list(year = 2024L, edition = "parcial"))
  expect_true(is.na(raisr:::.detect_folder("/a/b/RAIS_ESTAB_PUB.7z")$year))
  expect_equal(raisr:::.detect_year("/a/2023/RAIS_ESTAB_PUB.7z"), 2023L)
  expect_equal(raisr:::.detect_year("/a/b/PE2017.7z"), 2017L)
})

test_that("server folders follow the FTP layout", {
  expect_equal(raisr:::.rais_folder_url(2024L, "final"), "ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/2024")
  expect_equal(raisr:::.rais_folder_url(2023L, "parcial"), "ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/2023%20Parcial")
  expect_equal(raisr:::.rais_folder_url(2019L, "legado"), "ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/2019/Legado")
  expect_equal(raisr:::.rais_folder_name(2023L, "final"), "2023")
  expect_equal(raisr:::.rais_folder_name(2023L, "legado"), "2023-legado")
})

test_that("the FTP listing parser handles IIS listings", {
  txt <- paste("05-18-26  05:35PM       <DIR>          Legado",
               "05-18-26  05:35PM            127348274 RAIS_ESTAB_PUB.7z",
               "05-18-26  05:16PM                56135 RAIS_VINC_PUB_NI.7z", sep = "\r\n")
  e <- raisr:::.parse_ftp_listing(txt)
  expect_equal(e$name, c("Legado", "RAIS_ESTAB_PUB.7z", "RAIS_VINC_PUB_NI.7z"))
  expect_equal(e$is_dir, c(TRUE, FALSE, FALSE))
  expect_equal(e$size, c(NA, 127348274, 56135))
  expect_equal(format(e$modified[2], "%Y-%m-%d %H:%M"), "2026-05-18 17:35")
  expect_equal(nrow(raisr:::.parse_ftp_listing(NULL)), 0L)
})

test_that("rais_files routes states to the right archives", {
  f <- rais_files(2024, uf = "PE")
  expect_equal(f$file, "RAIS_VINC_PUB_NORDESTE.7z")
  expect_equal(f$url, "ftp://ftp.mtps.gov.br/pdet/microdados/RAIS/2024/RAIS_VINC_PUB_NORDESTE.7z")
  f <- rais_files(2024, uf = c(26, 35, "RS"))
  expect_equal(f$group, c("NORDESTE", "SP", "SUL"))
  f <- rais_files(2024)
  expect_equal(f$group, c("NORTE", "NORDESTE", "MG_ES_RJ", "SP", "SUL", "CENTRO_OESTE", "NI"))
  f <- rais_files(2017, uf = c(29, 26), type = c("vinculos", "estabelecimentos"))
  expect_equal(f$file, c("PE2017.7z", "BA2017.7z", "ESTB2017.7z"))
  expect_equal(f$type, c("vinculos", "vinculos", "estabelecimentos"))
  expect_equal(nrow(rais_files(2010)), 27L)
  f <- rais_files(2023, uf = "PE", type = "estabelecimentos", edition = "parcial")
  expect_equal(f$file, "RAIS_ESTAB_PUB.7z")
  expect_match(f$url, "2023%20Parcial/RAIS_ESTAB_PUB.7z$")
  f <- rais_files(c(2017, 2018), uf = "PE")
  expect_equal(f$file, c("PE2017.7z", "RAIS_VINC_PUB_NORDESTE.7z"))
  expect_error(rais_files(2024, type = "nope"))
})

test_that("rais_ufs lists the 27 states", {
  u <- rais_ufs()
  expect_equal(nrow(u), 27L)
  expect_equal(u$sigla[u$uf == 26], "PE")
  expect_equal(u$region[u$uf == 26], "NORDESTE")
  expect_setequal(unique(u$region), c("NORTE", "NORDESTE", "MG_ES_RJ", "SP", "SUL", "CENTRO_OESTE"))
})
