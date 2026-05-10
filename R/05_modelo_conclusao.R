# =============================================================================
# 05_modelo_conclusao.R — Modelo de probabilidade de conclusão
# =============================================================================
#
# Especificação:
#
#   logit(P(y_concluiu = 1)) = β0 + β1*idade + β2*sexo + β3*cor_raca
#                            + β4*ept_int  + β5*ano_censo
#                            + α_municipio
#
# Onde:
#   y_concluiu = 1 se a matrícula foi aprovada/concluída no ano (derivada
#                de tp_situacao quando disponível; caso contrário, usamos
#                proxy via etapas terminais — documentado em
#                docs/metodologia.md)
#   α_municipio = efeito fixo de município (controla heterogeneidade
#                 estrutural entre regiões — qualidade de gestão, recursos,
#                 perfil socioeconômico não observado etc.)
#
# Pacote: `fixest::feglm` (rápido para FE de alta cardinalidade).
# =============================================================================


#' Estima modelo logit com efeitos fixos de município
#'
#' @param painel data.table do painel
#' @return Objeto fixest
estimar_modelo_conclusao <- function(painel) {

  df <- preparar_dados_modelo(painel)

  log_msg(sprintf("Estimando modelo logit em %s observações...",
                  format(nrow(df), big.mark = ".")))

  modelo <- tryCatch(
    fixest::feglm(
      y_concluiu ~
        nu_idade + sexo + cor_raca + ept_int + dep_admin
        | co_municipio + ano_censo,
      data   = df,
      family = "logit",
      vcov   = "hetero"
    ),
    error = function(e) {
      log_msg(sprintf("Logit não convergiu (%s) — fallback para LPM",
                      conditionMessage(e)), "WARN")
      fixest::feols(
        y_concluiu ~
          nu_idade + sexo + cor_raca + ept_int + dep_admin
          | co_municipio + ano_censo,
        data = df,
        vcov = "hetero"
      )
    }
  )

  log_msg("Modelo estimado.")
  modelo
}


#' Prepara os dados para o modelo: cria y_concluiu e filtra missings
#'
#' @param painel data.table
#' @return data.table pronto para regressão
preparar_dados_modelo <- function(painel) {

  if (!data.table::is.data.table(painel)) {
    painel <- data.table::as.data.table(painel)
  }

  df <- data.table::copy(painel)

  # y_concluiu — proxy: matrícula em ano final do EM (3a série ou EM integrado 4o)
  # Em ausência de tp_situacao consolidada, usamos esta proxy descritiva
  # (decisão documentada em docs/metodologia.md).
  df[, y_concluiu := as.integer(
    nu_idade == 17L |
      tp_etapa_ensino %in% c(27L, 28L, 33L, 34L)
  )]

  # Remove linhas com missing nas covariáveis principais
  df <- df[
    !is.na(nu_idade)   &
    !is.na(sexo)       &
    !is.na(cor_raca)   &
    !is.na(ept_int)    &
    !is.na(dep_admin)  &
    !is.na(co_municipio)
  ]

  log_msg(sprintf("Dados preparados: %s observações, %s municípios",
                  format(nrow(df), big.mark = "."),
                  format(uniqueN(df$co_municipio), big.mark = ".")))

  df
}


#' Exporta tabela de coeficientes (CSV + texto)
#'
#' @param modelo Objeto fixest
#' @param dir_out Diretório de saída
#' @return Caminho do CSV gerado
exportar_coeficientes <- function(modelo, dir_out = DIR_TABLES) {

  ensure_dir(dir_out)

  tab <- broom_like(modelo)
  caminho_csv <- file.path(dir_out, "modelo_coeficientes.csv")
  readr::write_csv(tab, caminho_csv)

  caminho_txt <- file.path(dir_out, "modelo_summary.txt")
  utils::capture.output(summary(modelo), file = caminho_txt)

  log_msg("Coeficientes exportados.")
  caminho_csv
}


#' Substituto leve para broom::tidy(), independente de pacote externo
#'
#' @param modelo Objeto fixest
broom_like <- function(modelo) {
  coefs <- modelo$coefficients
  ses   <- modelo$se
  data.frame(
    termo     = names(coefs),
    estimativa = unname(coefs),
    se        = unname(ses),
    z         = unname(coefs / ses),
    p_valor   = 2 * stats::pnorm(-abs(coefs / ses)),
    stringsAsFactors = FALSE
  )
}
