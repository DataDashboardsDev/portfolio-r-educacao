# =============================================================================
# 03_build_painel.R — Construção do painel longitudinal 2019–2023
# =============================================================================
#
# Empilha os data.tables ano a ano produzidos por 02_clean_matriculas.R e
# resolve diferenças de layout entre anos.
#
# Output: painel "tidy" com 1 linha por matrícula × ano, pronto para descritivas
# e modelo.
# =============================================================================


#' Constrói painel longitudinal a partir da lista de matrículas por ano
#'
#' @param matriculas_por_ano Lista de data.tables, uma por ano
#' @return data.table empilhada e harmonizada
construir_painel <- function(matriculas_por_ano) {

  # `targets` pode passar uma lista ou um data.table único (se houver só 1 ano).
  if (data.table::is.data.table(matriculas_por_ano)) {
    matriculas_por_ano <- list(matriculas_por_ano)
  }

  log_msg(sprintf("Empilhando %d anos no painel...", length(matriculas_por_ano)))

  # Identifica colunas comuns a todos os anos (interseção)
  cols_comuns <- Reduce(intersect, lapply(matriculas_por_ano, names))

  # Garante presença das chaves analíticas
  chaves_obrigatorias <- c(
    "ano_censo", "faixa_idade", "sexo", "cor_raca",
    "dep_admin", "eja_em", "ept_int"
  )

  faltantes <- setdiff(chaves_obrigatorias, cols_comuns)
  if (length(faltantes) > 0) {
    log_msg(sprintf("ATENÇÃO: chaves ausentes em algum ano: %s",
                    paste(faltantes, collapse = ", ")), "WARN")
  }

  # Empilha mantendo apenas colunas comuns + as 100 primeiras por ano (evita
  # explosão de memória; recortes específicos podem rodar pipeline customizado)
  painel <- data.table::rbindlist(
    lapply(matriculas_por_ano, function(dt) dt[, ..cols_comuns]),
    use.names = TRUE,
    fill      = FALSE
  )

  log_msg(sprintf("Painel final: %s linhas × %d colunas",
                  format(nrow(painel), big.mark = "."), ncol(painel)))

  # Persiste em processed/
  ensure_dir(DIR_PROCESSED)
  saida_csv <- file.path(DIR_PROCESSED, "painel_em_sp_2019_2023.csv")
  data.table::fwrite(painel, saida_csv)
  log_msg(sprintf("Painel salvo em %s", basename(saida_csv)))

  # Salva também em parquet (para análises mais leves)
  if (requireNamespace("arrow", quietly = TRUE)) {
    saida_pq <- sub("\\.csv$", ".parquet", saida_csv)
    arrow::write_parquet(painel, saida_pq)
    log_msg(sprintf("Painel também em parquet: %s", basename(saida_pq)))
  }

  painel
}


#' Sumário-síntese do painel (para logging e validação)
#'
#' @param painel data.table
#' @return data.frame com contagem por ano
resumir_painel <- function(painel) {
  painel[, .(matriculas = .N), by = ano_censo][order(ano_censo)]
}
