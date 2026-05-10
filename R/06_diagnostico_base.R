# =============================================================================
# 06_diagnostico_base.R — Diagnóstico de qualidade dos microdados
# =============================================================================
#
# Esta é uma entrega EXPLÍCITA do TR ("Relatórios de Diagnóstico de Bases").
# Inclui:
#   1. Estatísticas descritivas (skimr)
#   2. Padrão de missings (naniar)
#   3. Validação cruzada com totais oficiais publicados pelo INEP
#   4. Detecção de duplicatas
#   5. Consistência temporal (séries esperadas vs observadas)
# =============================================================================


#' Roda todos os checks de diagnóstico
#'
#' @param painel data.table
#' @param dir_out Diretório de saída
#' @return Lista com tabelas de diagnóstico
rodar_diagnostico <- function(painel, dir_out = DIR_TABLES) {

  ensure_dir(dir_out)
  out <- list()

  log_msg("=== Diagnóstico de base — início ===")

  # 1. Sumário tipo skim
  out$sumario <- diag_sumario(painel, dir_out)

  # 2. Padrão de missings
  out$missings <- diag_missings(painel, dir_out)

  # 3. Duplicatas
  out$duplicatas <- diag_duplicatas(painel, dir_out)

  # 4. Consistência temporal (matrículas por ano)
  out$consistencia <- diag_consistencia_temporal(painel, dir_out)

  # 5. Validação cruzada com INEP
  out$validacao_inep <- diag_validacao_inep(painel, dir_out)

  log_msg("=== Diagnóstico de base — concluído ===")
  out
}


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

diag_sumario <- function(painel, dir_out) {

  # skimr::skim() devolve um data.frame "enriquecido"
  sk <- skimr::skim(painel)
  caminho <- file.path(dir_out, "diag_sumario_variaveis.csv")
  utils::write.csv(as.data.frame(sk), caminho, row.names = FALSE)
  log_msg("Sumário de variáveis salvo.")
  sk
}


diag_missings <- function(painel, dir_out) {

  mis <- vapply(painel, function(x) mean(is.na(x)), numeric(1))
  df <- data.frame(
    variavel    = names(mis),
    pct_missing = round(mis * 100, 2),
    stringsAsFactors = FALSE
  )
  df <- df[order(-df$pct_missing), ]
  caminho <- file.path(dir_out, "diag_missings.csv")
  readr::write_csv(df, caminho)
  log_msg("Tabela de missings salva.")
  df
}


diag_duplicatas <- function(painel, dir_out) {

  chave <- intersect(
    c("co_pessoa_fisica", "co_entidade", "ano_censo"),
    names(painel)
  )

  if (length(chave) == 0) {
    log_msg("Sem chave para checar duplicatas — pulando", "WARN")
    return(NULL)
  }

  n_dup <- painel[, .N, by = chave][N > 1, .N]
  df <- data.frame(
    chave_usada = paste(chave, collapse = " + "),
    duplicatas  = n_dup,
    stringsAsFactors = FALSE
  )
  readr::write_csv(df, file.path(dir_out, "diag_duplicatas.csv"))
  log_msg(sprintf("Duplicatas detectadas: %d", n_dup))
  df
}


diag_consistencia_temporal <- function(painel, dir_out) {

  df <- painel[, .(matriculas = .N), by = ano_censo][order(ano_censo)]
  df[, var_pct := round(100 * (matriculas / data.table::shift(matriculas) - 1), 2)]

  readr::write_csv(df, file.path(dir_out, "diag_consistencia_temporal.csv"))
  log_msg("Consistência temporal exportada.")
  df
}


diag_validacao_inep <- function(painel, dir_out) {

  # Totais oficiais do INEP para EM em SP (sinopse estatística, ordens
  # de grandeza — devem ser revisados manualmente antes do envio).
  oficial <- data.frame(
    ano_censo            = 2019:2023,
    matriculas_em_sp_oficial = c(1745000L, 1735000L, 1700000L, 1700000L, 1730000L)
  )

  obs <- painel[, .(matriculas_em_sp_obs = .N), by = ano_censo]

  comp <- merge(obs, oficial, by = "ano_censo", all = TRUE)
  comp$dif_abs <- comp$matriculas_em_sp_obs - comp$matriculas_em_sp_oficial
  comp$dif_pct <- round(100 * comp$dif_abs / comp$matriculas_em_sp_oficial, 2)

  readr::write_csv(comp, file.path(dir_out, "diag_validacao_inep.csv"))
  log_msg("Validação contra INEP exportada.")
  comp
}
