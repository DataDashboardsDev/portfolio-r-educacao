# =============================================================================
# 05_modelo_neet.R — Modelo logístico de probabilidade de NEET
# =============================================================================
#
# Pergunta: que características aumentam a probabilidade de um jovem (15-29)
# estar em situação de NEET (não estudar nem trabalhar)?
#
# Especificação:
#
#   logit(P(neet = 1)) = β0 + β1*idade + β2*sexo + β3*cor_raca
#                      + β4*regiao + β5*situacao_dom
#                      + β6*concluiu_em
#
# Usamos survey::svyglm para respeitar o plano amostral complexo da PNAD
# (estratificação + UPAs + pesos), garantindo erros padrão corretos para
# inferência populacional.
# =============================================================================


#' Estima modelo logit de NEET respeitando o desenho amostral da PNAD
#'
#' @param painel data.table com microdados limpos
#' @param desenho survey design construído por construir_desenho_amostral()
#' @return Objeto svyglm
estimar_modelo_neet <- function(painel, desenho) {

  log_msg("Preparando dados do modelo NEET...")

  # Filtra observações válidas
  validos <- !is.na(painel$neet) &
             !is.na(painel$idade) &
             !is.na(painel$sexo) &
             !is.na(painel$cor_raca) &
             painel$cor_raca != "Ignorada" &
             !is.na(painel$regiao) &
             !is.na(painel$concluiu_em)

  log_msg(sprintf("Observações válidas: %s de %s (%s%%)",
                  format(sum(validos), big.mark = "."),
                  format(length(validos), big.mark = "."),
                  round(100 * mean(validos), 1)))

  # Subset do desenho preservando a estrutura amostral
  desenho_valido <- subset(desenho, validos)

  log_msg("Estimando logit de NEET com plano amostral PNAD...")

  modelo <- survey::svyglm(
    neet ~ idade + sexo + cor_raca + regiao + concluiu_em,
    design = desenho_valido,
    family = quasibinomial(link = "logit")
  )

  log_msg("Modelo estimado.")
  modelo
}


#' Exporta tabela de coeficientes (CSV)
#'
#' @param modelo Objeto svyglm
#' @param dir_out Diretório de saída
#' @return Caminho do CSV gerado
exportar_coeficientes <- function(modelo, dir_out = DIR_TABLES) {

  ensure_dir(dir_out)

  coefs <- summary(modelo)$coefficients
  tab <- data.frame(
    termo      = rownames(coefs),
    estimativa = coefs[, "Estimate"],
    erro_pad   = coefs[, "Std. Error"],
    t_valor    = coefs[, "t value"],
    p_valor    = coefs[, "Pr(>|t|)"],
    odds_ratio = exp(coefs[, "Estimate"]),
    row.names  = NULL
  )

  caminho <- file.path(dir_out, "modelo_neet_coeficientes.csv")
  readr::write_csv(tab, caminho)

  caminho_txt <- file.path(dir_out, "modelo_neet_summary.txt")
  utils::capture.output(summary(modelo), file = caminho_txt)

  log_msg(sprintf("Coeficientes exportados (%d termos)", nrow(tab)))
  caminho
}
