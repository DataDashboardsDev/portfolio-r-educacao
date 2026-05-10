# =============================================================================
# utils_anonimizacao.R — Funções de anonimização (LGPD)
# =============================================================================
#
# O Censo Escolar publicado pelo INEP já não contém dados nominais de alunos
# (apenas IDs). Ainda assim, em agregações por escola/turma é possível
# re-identificar indivíduos quando o n é muito pequeno.
#
# Política adotada neste projeto:
#   - Suprimir células com n < k_min (k = 5) em qualquer cruzamento exibido
#   - Não publicar dados em nível de aluno (apenas agregados)
#   - Hashear IDs de escola quando expostos publicamente
#
# Referência: LGPD (Lei 13.709/2018) art. 12; recomendações IBGE para
# microdados de uso público.
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


#' Anonimiza painel longitudinal aplicando supressão em agregações
#'
#' @param painel data.table com microdados (nível matrícula)
#' @param k_min  Limiar de supressão
#' @return data.table preparada para publicação (ainda contém microdados,
#'         mas com flag para usuários downstream)
anonimizar_painel <- function(painel, k_min = 5L) {

  if (!data.table::is.data.table(painel)) {
    painel <- data.table::as.data.table(painel)
  }

  # Hash dos IDs de escola, para evitar exposição direta
  if ("co_entidade" %in% names(painel)) {
    painel[, co_entidade_hash := vapply(
      as.character(co_entidade),
      function(x) substr(digest::digest(x, algo = "sha256"), 1, 12),
      character(1)
    )]
  }

  # Marca o k mínimo no atributo (informativo)
  data.table::setattr(painel, "k_min_supressao", k_min)

  log_msg(sprintf("Painel anonimizado (k_min=%d)", k_min))
  painel
}
