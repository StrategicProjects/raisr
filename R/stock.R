#' Consolidate employment stock, admissions and separations
#'
#' Aggregates employment records read with [rais_read()] or [rais_fetch()]
#' into the figures the Ministry publishes from the RAIS: the **stock** of
#' employment relationships active on 31 December (`vinculo_ativo_31_12 ==
#' 1`), the admissions and separations that happened during the year
#' (records with a non-zero `mes_admissao` / `mes_desligamento`) and the
#' December payroll and mean wage of the active stock. The aggregation is
#' by `rais_year` plus any grouping columns you ask for.
#'
#' @param data A tibble returned by [rais_read()] or [rais_fetch()] for
#'   `vinculos` files. Must contain `vinculo_ativo_31_12` and `rais_year`;
#'   the other columns are used when present.
#' @param by Character vector of additional grouping columns (for example
#'   `"municipio"`, `"cnae_20_subclasse"`, `"sexo_trabalhador"`).
#'
#' @return A tibble with the grouping columns and `records` (records
#'   aggregated), `stock` (relationships active on 31/12), `admissions`
#'   and `separations` (when `mes_admissao` / `mes_desligamento` are
#'   present), `december_payroll` (sum of `vl_remun_dezembro_nom` over the
#'   active stock) and `mean_december_wage` (that sum divided by the stock
#'   with a positive December wage), the last two when
#'   `vl_remun_dezembro_nom` is present.
#' @export
#' @examples
#' f <- system.file("extdata", "2024", "RAIS_VINC_PUB_NORDESTE_sample.7z", package = "raisr")
#' x <- rais_read(f, verbose = FALSE)
#' rais_stock(x, by = "municipio")
rais_stock <- function(data, by = NULL) {
  need <- c("vinculo_ativo_31_12", "rais_year")
  missing_cols <- setdiff(need, names(data))
  if (length(missing_cols)) {
    cli::cli_abort("{.arg data} lacks column{?s} {.val {missing_cols}}; read it with {.fn rais_read}.")
  }
  by <- unique(c("rais_year", by))
  bad <- setdiff(by, names(data))
  if (length(bad)) cli::cli_abort("Grouping column{?s} not in {.arg data}: {.val {bad}}.")

  active <- as.integer(data$vinculo_ativo_31_12) == 1L
  active[is.na(active)] <- FALSE
  keys <- as.data.frame(data[, by, drop = FALSE])
  g <- interaction(keys, drop = TRUE, lex.order = TRUE)

  out <- unique(keys[order(g), , drop = FALSE])
  idx <- match(interaction(out, drop = TRUE, lex.order = TRUE), levels(g))
  sum_by <- function(x) as.numeric(tapply(x, g, sum, na.rm = TRUE))[idx]

  out$records <- as.integer(sum_by(rep(1L, nrow(data))))
  out$stock   <- as.integer(sum_by(as.integer(active)))
  if ("mes_admissao" %in% names(data)) {
    adm <- as.integer(data$mes_admissao)
    out$admissions <- as.integer(sum_by(as.integer(!is.na(adm) & adm > 0L)))
  }
  if ("mes_desligamento" %in% names(data)) {
    des <- as.integer(data$mes_desligamento)
    out$separations <- as.integer(sum_by(as.integer(!is.na(des) & des > 0L)))
  }
  if ("vl_remun_dezembro_nom" %in% names(data)) {
    wage <- as.numeric(data$vl_remun_dezembro_nom)
    paid <- active & !is.na(wage) & wage > 0
    out$december_payroll   <- sum_by(ifelse(active, wage, 0))
    n_paid <- sum_by(as.integer(paid))
    out$mean_december_wage <- ifelse(n_paid > 0, out$december_payroll / n_paid, NA_real_)
  }
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
