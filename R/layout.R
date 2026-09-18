#' Record layout of the RAIS microdata
#'
#' The columns of the files, with the normalized name returned by
#' [rais_read()], the header used by the Ministry in the `;` files (up to the
#' RAIS 2022, and the partial and legacy editions), the header used in the
#' `,` files (RAIS 2023 onwards), the type assigned when `types = TRUE` and a
#' short description. The official layouts (one spreadsheet per period,
#' "RAIS_vinculos_layout*.xls" and "RAIS_estabelecimento_layout*.xls") are
#' published in the `Layouts` folder of the FTP server; the categories of
#' every code are listed there.
#'
#' Files before the RAIS 2018 have fewer columns (for example the monthly
#' remuneration columns start in 2015 and are named `vl_rem_<mes>_cc` up to
#' 2017 and `vl_rem_<mes>_sc` from 2018), and the oldest years use a
#' different classification of occupations (`cbo_ocupacao`) and education
#' (`grau_instrucao_2005_1985`). Two columns exist only from the RAIS 2023
#' onwards: `ind_vinculo_abandonado` and `categoria_trabalhador`.
#'
#' @param type `"vinculos"` (employment relationships, the default) or
#'   `"estabelecimentos"` (establishments).
#'
#' @return A tibble with columns `column` (normalized name), `original`
#'   (header of the `;` files), `original_2023` (header of the `,` files),
#'   `type` and `description`.
#' @export
#' @examples
#' rais_layout()
#' rais_layout("estabelecimentos")
#' subset(rais_layout(), type == "double")$column
rais_layout <- function(type = "vinculos") {
  type <- .as_type(type)
  if (type == "vinculos") .rais_layout_vinculos() else .rais_layout_estabelecimentos()
}

.rais_layout_vinculos <- function() {
  tibble::tribble(
    ~column,                   ~original,                  ~original_2023,                                      ~type,       ~description,
    "bairros_sp",              "Bairros SP",               "Bairros SP - C\u00f3digo",                          "integer",   "Neighborhood code, municipality of Sao Paulo only.",
    "bairros_fortaleza",       "Bairros Fortaleza",        "Bairros Fortaleza - C\u00f3digo",                   "integer",   "Neighborhood code, municipality of Fortaleza only.",
    "bairros_rj",              "Bairros RJ",               "Bairros RJ - C\u00f3digo",                          "integer",   "Neighborhood code, municipality of Rio de Janeiro only.",
    "causa_afastamento_1",     "Causa Afastamento 1",      "Causa Afastamento 1 - C\u00f3digo",                 "integer",   "Cause of the first leave of absence in the year (99 none).",
    "causa_afastamento_2",     "Causa Afastamento 2",      "Causa Afastamento 2 - C\u00f3digo",                 "integer",   "Cause of the second leave of absence in the year.",
    "causa_afastamento_3",     "Causa Afastamento 3",      "Causa Afastamento 3 - C\u00f3digo",                 "integer",   "Cause of the third leave of absence in the year.",
    "motivo_desligamento",     "Motivo Desligamento",      "Motivo Desligamento - C\u00f3digo",                 "integer",   "Reason of separation (0 not separated in the year; 10/11 dismissal with/without cause, 20/21 resignation, ...).",
    "cbo_ocupacao_2002",       "CBO Ocupa\u00e7\u00e3o 2002", "CBO 2002 Ocupa\u00e7\u00e3o - C\u00f3digo",      "character", "Occupation code (CBO 2002, six digits).",
    "cnae_20_classe",          "CNAE 2.0 Classe",          "CNAE 2.0 Classe - C\u00f3digo",                     "character", "CNAE 2.0 class (five digits, with leading zeros) of the establishment.",
    "cnae_95_classe",          "CNAE 95 Classe",           "CNAE 95 Classe - C\u00f3digo",                      "character", "CNAE 1.0/95 class (five digits) of the establishment.",
    "distritos_sp",            "Distritos SP",             "Distritos SP - C\u00f3digo",                        "integer",   "District code, municipality of Sao Paulo only.",
    "vinculo_ativo_31_12",     "V\u00ednculo Ativo 31/12", "Ind V\u00ednculo Ativo 31/12 - C\u00f3digo",        "integer",   "1 if the employment relationship was active on 31 December (the stock), 0 otherwise.",
    "faixa_etaria",            "Faixa Et\u00e1ria",        "Faixa Et\u00e1ria - C\u00f3digo",                   "integer",   "Age band (1 = 10 to 14 ... 8 = 65 or more).",
    "faixa_hora_contrat",      "Faixa Hora Contrat",       "Faixa Hora Contrat - C\u00f3digo",                  "integer",   "Weekly contractual hours band.",
    "faixa_remun_dezem_sm",    "Faixa Remun Dezem (SM)",   "Faixa Rem Dez (SM) - C\u00f3digo",                  "integer",   "December wage band in minimum wages.",
    "faixa_remun_media_sm",    "Faixa Remun M\u00e9dia (SM)", "Faixa Rem M\u00e9dia (SM) - C\u00f3digo",        "integer",   "Mean wage band in minimum wages.",
    "faixa_tempo_emprego",     "Faixa Tempo Emprego",      "Faixa Tempo Emprego - C\u00f3digo",                 "integer",   "Tenure band.",
    "escolaridade_apos_2005",  "Escolaridade ap\u00f3s 2005", "Escolaridade Ap\u00f3s 2005 - C\u00f3digo",      "integer",   "Education level (1 illiterate ... 9 higher education complete, 10 master, 11 doctorate).",
    "qtd_hora_contr",          "Qtd Hora Contr",           "Qtd Hora Contr",                                    "integer",   "Weekly contractual hours.",
    "idade",                   "Idade",                    "Idade",                                             "integer",   "Worker age in years.",
    "ind_cei_vinculado",       "Ind CEI Vinculado",        "Ind CEI Vinculado - C\u00f3digo",                   "integer",   "Establishment identified by a CEI linked to a CNPJ (0 no, 1 yes).",
    "ind_simples",             "Ind Simples",              "Ind Estabelecimento Participante SIMPLES - C\u00f3digo", "integer", "Establishment opted for the SIMPLES tax regime (0 no, 1 yes).",
    "mes_admissao",            "M\u00eas Admiss\u00e3o",   "M\u00eas Admiss\u00e3o - C\u00f3digo",              "integer",   "Month of admission (0 when admitted in an earlier year).",
    "mes_desligamento",        "M\u00eas Desligamento",    "M\u00eas Desligamento - C\u00f3digo",               "integer",   "Month of separation (0 when not separated in the year).",
    "mun_trab",                "Mun Trab",                 "Munic\u00edpio Trab - C\u00f3digo",                 "integer",   "IBGE municipality (six digits) where the worker actually works, when different.",
    "municipio",               "Munic\u00edpio",           "Munic\u00edpio - C\u00f3digo",                      "integer",   "IBGE municipality of the establishment (six digits; the first two are the state code).",
    "nacionalidade",           "Nacionalidade",            "Nacionalidade - C\u00f3digo",                       "integer",   "Nationality code (10 Brazilian).",
    "natureza_juridica",       "Natureza Jur\u00eddica",   "Natureza Jur\u00eddica - C\u00f3digo",              "integer",   "Legal nature of the employer (CONCLA, four digits).",
    "ind_portador_defic",      "Ind Portador Defic",       "Ind Portador Defic - C\u00f3digo",                  "integer",   "Worker with a disability (0 no, 1 yes).",
    "qtd_dias_afastamento",    "Qtd Dias Afastamento",     "Qtd Dias Afastamento",                              "integer",   "Total days of leave in the year.",
    "raca_cor",                "Ra\u00e7a Cor",            "Ra\u00e7a Cor - C\u00f3digo",                       "integer",   "Race/color (1 indigenous, 2 white, 4 black, 6 yellow, 8 brown, 9 not identified).",
    "regioes_adm_df",          "Regi\u00f5es Adm DF",      "Regi\u00e3o Adm DF - C\u00f3digo",                  "integer",   "Administrative region, Federal District only.",
    "vl_remun_dezembro_nom",   "Vl Remun Dezembro Nom",    "Vl Rem Dezembro Nom",                               "double",    "December wage, nominal BRL.",
    "vl_remun_dezembro_sm",    "Vl Remun Dezembro (SM)",   "Vl Rem Dezembro (SM)",                              "double",    "December wage in minimum wages.",
    "vl_remun_media_nom",      "Vl Remun M\u00e9dia Nom",  "Vl Rem M\u00e9dia Nom",                             "double",    "Mean monthly wage of the year, nominal BRL.",
    "vl_remun_media_sm",       "Vl Remun M\u00e9dia (SM)", "Vl Rem M\u00e9dia (SM)",                            "double",    "Mean monthly wage of the year in minimum wages.",
    "cnae_20_subclasse",       "CNAE 2.0 Subclasse",       "CNAE 2.0 Subclasse - Codigo",                       "character", "CNAE 2.0 subclass (seven digits, with leading zeros) of the establishment.",
    "sexo_trabalhador",        "Sexo Trabalhador",         "Sexo - C\u00f3digo",                                "integer",   "Sex (1 male, 2 female).",
    "tamanho_estabelecimento", "Tamanho Estabelecimento",  "Tamanho Estabelecimento - C\u00f3digo",             "integer",   "Establishment size band by active employees on 31/12 (1 zero ... 10 more than 1,000).",
    "tempo_emprego",           "Tempo Emprego",            "Tempo Emprego",                                     "double",    "Tenure in months (one decimal).",
    "tipo_admissao",           "Tipo Admiss\u00e3o",       "Tipo Admiss\u00e3o Trabalhador - C\u00f3digo",      "integer",   "Admission type (0 not admitted in the year, 1 first job, 2 re-employment, ...).",
    "tipo_estab",              "Tipo Estab",               "Tipo Estabelecimento - C\u00f3digo",                "integer",   "Establishment identifier type (1 CNPJ, 3 CEI/CAEPF, 6 CNO, ...).",
    "tipo_estab_nome",         "Tipo Estab",               "Tipo Estabelecimento - Nome",                       "character", "Establishment identifier type, as text (the second 'Tipo Estab' column of the older files).",
    "tipo_defic",              "Tipo Defic",               "Tipo Defici\u00eancia - C\u00f3digo",               "integer",   "Disability type (0 none, 1 physical, 2 hearing, 3 visual, 4 intellectual, 5 multiple, 6 rehabilitated).",
    "tipo_vinculo",            "Tipo V\u00ednculo",        "Tipo V\u00ednculo - C\u00f3digo",                   "integer",   "Employment relationship type (10 CLT urban, 30 statutory, 50 temporary, 55 apprentice, ...).",
    "ibge_subsetor",           "IBGE Subsetor",            "IBGE Subsetor - C\u00f3digo",                       "integer",   "IBGE economic subsector of the establishment (25 categories).",
    "vl_rem_janeiro_sc",       "Vl Rem Janeiro SC",        "Vl Rem Janeiro SC",                                 "double",    "January wage, nominal BRL (from 2015; named '... CC' up to 2017).",
    "vl_rem_fevereiro_sc",     "Vl Rem Fevereiro SC",      "Vl Rem Fevereiro SC",                               "double",    "February wage, nominal BRL.",
    "vl_rem_marco_sc",         "Vl Rem Mar\u00e7o SC",     "Vl Rem Mar\u00e7o SC",                              "double",    "March wage, nominal BRL.",
    "vl_rem_abril_sc",         "Vl Rem Abril SC",          "Vl Rem Abril SC",                                   "double",    "April wage, nominal BRL.",
    "vl_rem_maio_sc",          "Vl Rem Maio SC",           "Vl Rem Maio SC",                                    "double",    "May wage, nominal BRL.",
    "vl_rem_junho_sc",         "Vl Rem Junho SC",          "Vl Rem Junho SC",                                   "double",    "June wage, nominal BRL.",
    "vl_rem_julho_sc",         "Vl Rem Julho SC",          "Vl Rem Julho SC",                                   "double",    "July wage, nominal BRL.",
    "vl_rem_agosto_sc",        "Vl Rem Agosto SC",         "Vl Rem Agosto SC",                                  "double",    "August wage, nominal BRL.",
    "vl_rem_setembro_sc",      "Vl Rem Setembro SC",       "Vl Rem Setembro SC",                                "double",    "September wage, nominal BRL.",
    "vl_rem_outubro_sc",       "Vl Rem Outubro SC",        "Vl Rem Outubro SC",                                 "double",    "October wage, nominal BRL.",
    "vl_rem_novembro_sc",      "Vl Rem Novembro SC",       "Vl Rem Novembro SC",                                "double",    "November wage, nominal BRL.",
    "ano_chegada_brasil",      "Ano Chegada Brasil",       "Ano Chegada Brasil",                                "integer",   "Year of arrival in Brazil of a foreign worker (0 or 1198 when not applicable).",
    "ind_trab_intermitente",   "Ind Trab Intermitente",    "Ind Trabalho Intermitente - C\u00f3digo",           "integer",   "Intermittent contract (0 no, 1 yes; from 2017).",
    "ind_trab_parcial",        "Ind Trab Parcial",         "Ind Trabalho Parcial - C\u00f3digo",                "integer",   "Part-time contract (0 no, 1 yes; from 2017).",
    "ind_vinculo_abandonado",  NA_character_,              "Ind V\u00ednculo Abandonado - C\u00f3digo",         "integer",   "Relationship abandoned by the worker (0 no, 1 yes; from the RAIS 2023).",
    "categoria_trabalhador",   NA_character_,              "Categoria Trabalhador - C\u00f3digo",               "integer",   "Worker category as in eSocial (101 urban employee under CLT, ...; from the RAIS 2023)."
  )
}

.rais_layout_estabelecimentos <- function() {
  tibble::tribble(
    ~column,                     ~original,                    ~original_2023,                              ~type,       ~description,
    "bairros_sp",                "Bairros SP",                 "Bairros SP - C\u00f3digo",                  "integer",   "Neighborhood code, municipality of Sao Paulo only.",
    "bairros_fortaleza",         "Bairros Fortaleza",          "Bairros Fortaleza - C\u00f3digo",           "integer",   "Neighborhood code, municipality of Fortaleza only.",
    "bairros_rj",                "Bairros RJ",                 "Bairros RJ - C\u00f3digo",                  "integer",   "Neighborhood code, municipality of Rio de Janeiro only.",
    "cnae_20_classe",            "CNAE 2.0 Classe",            "CNAE 2.0 Classe - C\u00f3digo",             "character", "CNAE 2.0 class (five digits, with leading zeros; the 2023 files carry the seven-digit subclass here).",
    "cnae_95_classe",            "CNAE 95 Classe",             "CNAE 95 Classe - C\u00f3digo",              "character", "CNAE 1.0/95 class.",
    "distritos_sp",              "Distritos SP",               "Distritos SP - C\u00f3digo",                "integer",   "District code, municipality of Sao Paulo only.",
    "qtd_vinculos_clt",          "Qtd V\u00ednculos CLT",     "Qtd V\u00ednculos CLT",                     "integer",   "Employment relationships under CLT and other non-statutory regimes active on 31/12.",
    "qtd_vinculos_ativos",       "Qtd V\u00ednculos Ativos",  "Qtd V\u00ednculos Ativos",                  "integer",   "Employment relationships active on 31/12 (the establishment's stock).",
    "qtd_vinculos_estatutarios", "Qtd V\u00ednculos Estatut\u00e1rios", "Qtd V\u00ednculos Estatut\u00e1rios", "integer", "Statutory (public servant) relationships active on 31/12.",
    "ind_atividade_ano",         "Ind Atividade Ano",          "Ind Atividade Ano - C\u00f3digo",           "integer",   "Establishment was active during the year (0 no, 1 yes).",
    "ind_cei_vinculado",         "Ind CEI Vinculado",          "Ind CEI Vinculado - C\u00f3digo",           "integer",   "Establishment identified by a CEI linked to a CNPJ (0 no, 1 yes).",
    "ind_estab_participa_pat",   "Ind Estab Participa PAT",    "Ind Estab Participante PAT - C\u00f3digo",  "integer",   "Establishment takes part in the PAT workers' meal programme (0 no, 1 yes, 9 not informed).",
    "ind_rais_negativa",         "Ind Rais Negativa",          "Ind RAIS Negativa - C\u00f3digo",           "integer",   "Establishment filed a 'RAIS negativa' (no employees in the year; 0 no, 1 yes).",
    "ind_simples",               "Ind Simples",                "Ind Estab Participante SIMPLES - C\u00f3digo", "integer", "Establishment opted for the SIMPLES tax regime (0 no, 1 yes).",
    "municipio",                 "Munic\u00edpio",            "Munic\u00edpio - C\u00f3digo",             "integer",   "IBGE municipality of the establishment (six digits; the first two are the state code).",
    "natureza_juridica",         "Natureza Jur\u00eddica",    "Natureza Jur\u00eddica - C\u00f3digo",     "integer",   "Legal nature of the employer (CONCLA, four digits).",
    "regioes_adm_df",            "Regi\u00f5es Adm DF",       "Regi\u00e3o Adm DF - C\u00f3digo",         "integer",   "Administrative region, Federal District only.",
    "cnae_20_subclasse",         "CNAE 2.0 Subclasse",         "CNAE 2.0 Subclasse - Codigo",               "character", "CNAE 2.0 subclass (seven digits, with leading zeros).",
    "tamanho_estabelecimento",   "Tamanho Estabelecimento",    "Tamanho Estabelecimento - C\u00f3digo",     "integer",   "Establishment size band by active employees on 31/12 (1 zero ... 10 more than 1,000).",
    "tipo_estab",                "Tipo Estab",                 "Tipo Estabelecimento - C\u00f3digo",        "integer",   "Establishment identifier type (1 CNPJ, 3 CEI/CAEPF, ...).",
    "tipo_estab_nome",           "Tipo Estab",                 NA_character_,                               "character", "Establishment identifier type, as text (second 'Tipo Estab' column; up to the RAIS 2022 only).",
    "uf",                        "UF",                         "UF - C\u00f3digo",                          "integer",   "IBGE state code (two digits, e.g. 26 = Pernambuco).",
    "ibge_subsetor",             "IBGE Subsetor",              "IBGE Subsetor - C\u00f3digo",               "integer",   "IBGE economic subsector (25 categories).",
    "cep_estab",                 "CEP Estab",                  "CEP Estab",                                 "character", "Postal code (CEP, eight digits) declared by the establishment."
  )
}
