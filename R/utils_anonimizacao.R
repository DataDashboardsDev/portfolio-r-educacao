# =============================================================================
# utils_anonimizacao.R — Utilitários de anonimização (LGPD)
# =============================================================================
#
# A PNAD Contínua publicada pelo IBGE já é anonimizada (não há identificadores
# nominais; apenas códigos de UPA e estrato amostral).
#
# Política adotada neste projeto:
#   - Suprimir células com n < k_min (k = 5) em qualquer agregação publicável
#   - Não publicar microdados em nível de pessoa em formato facilmente
#     reidentificável
#   - Documentar todos os procedimentos
#
# Referência: LGPD (Lei 13.709/2018) art. 12.
# =============================================================================


#' Aplica supressão estatística em um data.frame agregado
#'
#' Substitui o valor das células com contagem < k_min por NA e marca-as.
#'
#' @param df Data.frame com colunas de contagem
#' @param colunas_n Vetor de nomes de colunas que contém contagens
#' @param k_min Limiar de supressão (default 5)
#' @return Data.frame com células sensíveis suprimidas
suprimir_celulas_pequenas <- function(df, colunas_n, k_min = 5L) {

  for (col in colunas_n) {
    flag_col <- paste0(col, "_suprimido")
    df[[flag_col]] <- df[[col]] < k_min & !is.na(df[[col]])
    df[[col]][df[[flag_col]]] <- NA_integer_
  }

  df
}
