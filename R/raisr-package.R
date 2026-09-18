#' @keywords internal
"_PACKAGE"

#' @importFrom rlang %||%
#' @importFrom tibble tibble as_tibble
#' @importFrom cli cli_abort cli_warn cli_inform cli_alert_info
#'   cli_alert_success cli_alert_warning
NULL

# Column names used in non-standard evaluation (silence R CMD check NOTEs)
utils::globalVariables(c(
  "municipio", "vinculo_ativo_31_12", "vl_remun_dezembro_nom", "vl_remun_media_nom",
  "mes_admissao", "mes_desligamento", "rais_type", "rais_year"
))
