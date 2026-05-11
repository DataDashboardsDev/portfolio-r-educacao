# =============================================================================
# 06_diagnostico_base.R — Diagnóstico da PNAD Contínua
# =============================================================================
#
# Entrega EXPLÍCITA do TR ("Relatórios de Diagnóstico de Bases").
# Inclui:
#   1. Estatísticas descritivas (skimr)
#   2. Padrão de dados faltantes
#   3. Estrutura amostral (UPAs, estratos, pesos)
#   4. Validação cruzada: pop. total estimada × pop. divulgada pelo IBGE
#   5. Sanidade lógica (jovens NEET fazem sentido com taxas oficiais?)
# =============================================================================


#' Roda todos os checks de diagnóstico
#'
#' @param painel data.table com microdados limpos
#' @param dir_out Diretório de saída
#' @return Lista com tabelas de diagnóstico
rodar_diagnostico <- function(painel, dir_out = DIR_TABLES) {

  ensure_dir(dir_out)
  out <- list()

  log_msg("=== Diagnóstico de base — início ===")

  out$sumario        <- diag_sumario(painel, dir_out)
  out$missings       <- diag_missings(painel, dir_out)
  out$amostragem     <- diag_amostragem(painel, dir_out)
  out$validacao_ibge <- diag_validacao_ibge(painel, dir_out)
  out$sanidade       <- diag_sanidade(painel, dir_out)

  log_msg("=== Diagnóstico de base — concluído ===")
  out
}


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

diag_sumario <- function(painel, dir_out) {
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
  rownames(df) <- NULL    # remove rownames para não duplicar coluna no kable
  caminho <- file.path(dir_out, "diag_missings.csv")
  readr::write_csv(df, caminho)
  log_msg("Tabela de missings salva.")
  df
}


diag_amostragem <- function(painel, dir_out) {

  resumo <- data.frame(
    metrica = c("Observações na amostra",
                "UPAs distintas",
                "Estratos distintos",
                "Soma dos pesos (pop. representada)",
                "Peso médio",
                "Peso mediano"),
    valor   = c(
      format(nrow(painel), big.mark = "."),
      format(data.table::uniqueN(painel$upa), big.mark = "."),
      format(data.table::uniqueN(painel$estrato), big.mark = "."),
      format(round(sum(painel$v1028, na.rm = TRUE)), big.mark = "."),
      format(round(mean(painel$v1028, na.rm = TRUE), 1), big.mark = "."),
      format(round(stats::median(painel$v1028, na.rm = TRUE), 1), big.mark = ".")
    )
  )
  caminho <- file.path(dir_out, "diag_estrutura_amostral.csv")
  readr::write_csv(resumo, caminho)
  log_msg("Estrutura amostral exportada.")
  resumo
}


diag_validacao_ibge <- function(painel, dir_out) {

  # População estimada de jovens 15-29 no Brasil em 2023 segundo IBGE:
  # ~ 47-49 milhões (oscilação por trimestre). Tolerância: ±5%.
  pop_estimada <- sum(painel$v1028, na.rm = TRUE)
  pop_ref_ibge <- 48000000

  dif_pct <- 100 * (pop_estimada - pop_ref_ibge) / pop_ref_ibge

  resumo <- data.frame(
    indicador = c("População 15-29 estimada pelo pipeline",
                  "Referência IBGE (4ºT 2023, ~)",
                  "Diferença absoluta",
                  "Diferença relativa (%)"),
    valor     = c(
      format(round(pop_estimada),                 big.mark = ".", scientific = FALSE),
      format(pop_ref_ibge,                        big.mark = ".", scientific = FALSE),
      format(round(pop_estimada - pop_ref_ibge),  big.mark = ".", scientific = FALSE),
      sprintf("%.2f%%", dif_pct)
    ),
    stringsAsFactors = FALSE
  )
  caminho <- file.path(dir_out, "diag_validacao_ibge.csv")
  readr::write_csv(resumo, caminho)
  log_msg(sprintf("Validação IBGE: dif. = %.2f%% (limite ±5%%)", dif_pct))
  resumo
}


diag_sanidade <- function(painel, dir_out) {

  taxa_neet_global <- sum((painel$neet == 1) * painel$v1028, na.rm = TRUE) /
                       sum(painel$v1028, na.rm = TRUE)

  taxa_concluiu_em <- sum((painel$concluiu_em == 1) * painel$v1028,
                          na.rm = TRUE) /
                       sum(painel$v1028, na.rm = TRUE)

  taxa_estudando <- sum((painel$estudando == 1) * painel$v1028, na.rm = TRUE) /
                     sum(painel$v1028, na.rm = TRUE)

  resumo <- data.frame(
    indicador = c("Taxa NEET (15-29)",
                  "Taxa de conclusão EM (15-29)",
                  "Taxa estudando (15-29)"),
    valor_estimado = c(
      sprintf("%.2f%%", 100 * taxa_neet_global),
      sprintf("%.2f%%", 100 * taxa_concluiu_em),
      sprintf("%.2f%%", 100 * taxa_estudando)
    ),
    referencia_literatura = c(
      "~19-22% (IBGE/IPEA, 2023)",
      "~50-55% (PNADc histórica)",
      "~38-42% (PNADc 2023)"
    )
  )
  caminho <- file.path(dir_out, "diag_sanidade.csv")
  readr::write_csv(resumo, caminho)
  log_msg("Sanidade lógica exportada.")
  resumo
}
