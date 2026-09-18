# Record layout of the RAIS microdata

The columns of the files, with the normalized name returned by
[`rais_read()`](https://strategicprojects.github.io/raisr/reference/rais_read.md),
the header used by the Ministry in the `;` files (up to the RAIS 2022,
and the partial and legacy editions), the header used in the `,` files
(RAIS 2023 onwards), the type assigned when `types = TRUE` and a short
description. The official layouts (one spreadsheet per period,
"RAIS_vinculos_layout\*.xls" and "RAIS_estabelecimento_layout\*.xls")
are published in the `Layouts` folder of the FTP server; the categories
of every code are listed there.

## Usage

``` r
rais_layout(type = "vinculos")
```

## Arguments

- type:

  `"vinculos"` (employment relationships, the default) or
  `"estabelecimentos"` (establishments).

## Value

A tibble with columns `column` (normalized name), `original` (header of
the `;` files), `original_2023` (header of the `,` files), `type` and
`description`.

## Details

Files before the RAIS 2018 have fewer columns (for example the monthly
remuneration columns start in 2015 and are named `vl_rem_<mes>_cc` up to
2017 and `vl_rem_<mes>_sc` from 2018), and the oldest years use a
different classification of occupations (`cbo_ocupacao`) and education
(`grau_instrucao_2005_1985`). Two columns exist only from the RAIS 2023
onwards: `ind_vinculo_abandonado` and `categoria_trabalhador`.

## Examples

``` r
rais_layout()
#> # A tibble: 62 × 5
#>    column              original            original_2023       type  description
#>    <chr>               <chr>               <chr>               <chr> <chr>      
#>  1 bairros_sp          Bairros SP          Bairros SP - Código inte… Neighbourh…
#>  2 bairros_fortaleza   Bairros Fortaleza   Bairros Fortaleza … inte… Neighbourh…
#>  3 bairros_rj          Bairros RJ          Bairros RJ - Código inte… Neighbourh…
#>  4 causa_afastamento_1 Causa Afastamento 1 Causa Afastamento … inte… Cause of t…
#>  5 causa_afastamento_2 Causa Afastamento 2 Causa Afastamento … inte… Cause of t…
#>  6 causa_afastamento_3 Causa Afastamento 3 Causa Afastamento … inte… Cause of t…
#>  7 motivo_desligamento Motivo Desligamento Motivo Desligament… inte… Reason of …
#>  8 cbo_ocupacao_2002   CBO Ocupação 2002   CBO 2002 Ocupação … char… Occupation…
#>  9 cnae_20_classe      CNAE 2.0 Classe     CNAE 2.0 Classe - … char… CNAE 2.0 c…
#> 10 cnae_95_classe      CNAE 95 Classe      CNAE 95 Classe - C… char… CNAE 1.0/9…
#> # ℹ 52 more rows
rais_layout("estabelecimentos")
#> # A tibble: 24 × 5
#>    column                    original            original_2023 type  description
#>    <chr>                     <chr>               <chr>         <chr> <chr>      
#>  1 bairros_sp                Bairros SP          Bairros SP -… inte… Neighbourh…
#>  2 bairros_fortaleza         Bairros Fortaleza   Bairros Fort… inte… Neighbourh…
#>  3 bairros_rj                Bairros RJ          Bairros RJ -… inte… Neighbourh…
#>  4 cnae_20_classe            CNAE 2.0 Classe     CNAE 2.0 Cla… char… CNAE 2.0 c…
#>  5 cnae_95_classe            CNAE 95 Classe      CNAE 95 Clas… char… CNAE 1.0/9…
#>  6 distritos_sp              Distritos SP        Distritos SP… inte… District c…
#>  7 qtd_vinculos_clt          Qtd Vínculos CLT    Qtd Vínculos… inte… Employment…
#>  8 qtd_vinculos_ativos       Qtd Vínculos Ativos Qtd Vínculos… inte… Employment…
#>  9 qtd_vinculos_estatutarios Qtd Vínculos Estat… Qtd Vínculos… inte… Statutory …
#> 10 ind_atividade_ano         Ind Atividade Ano   Ind Atividad… inte… Establishm…
#> # ℹ 14 more rows
subset(rais_layout(), type == "double")$column
#>  [1] "vl_remun_dezembro_nom" "vl_remun_dezembro_sm"  "vl_remun_media_nom"   
#>  [4] "vl_remun_media_sm"     "tempo_emprego"         "vl_rem_janeiro_sc"    
#>  [7] "vl_rem_fevereiro_sc"   "vl_rem_marco_sc"       "vl_rem_abril_sc"      
#> [10] "vl_rem_maio_sc"        "vl_rem_junho_sc"       "vl_rem_julho_sc"      
#> [13] "vl_rem_agosto_sc"      "vl_rem_setembro_sc"    "vl_rem_outubro_sc"    
#> [16] "vl_rem_novembro_sc"   
```
