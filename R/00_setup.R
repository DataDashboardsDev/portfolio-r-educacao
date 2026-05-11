# =============================================================================
# 00_setup.R — Configuração e utilitários gerais
# =============================================================================
#
# Carregado por _targets.R via source(). Define:
#   - paths padrão (raw, processed, outputs)
#   - logger simples para registro de execução
#   - constantes do recorte analítico
# =============================================================================

# Paths -----------------------------------------------------------------------

DIR_RAW       <- here::here("data", "raw")
DIR_PROCESSED <- here::here("data", "processed")
DIR_DICT      <- here::here("data", "dicionarios")
DIR_FIGURES   <- here::here("outputs", "figures")
DIR_TABLES    <- here::here("outputs", "tables")
DIR_REPORTS   <- here::here("outputs", "reports")

# Logger ----------------------------------------------------------------------

#' Imprime mensagem com timestamp
log_msg <- function(msg, level = "INFO") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %-5s %s\n", ts, level, msg))
}

#' Garante que um diretório exista
ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    log_msg(paste("Diretório criado:", path))
  }
  invisible(path)
}

# Constantes do recorte analítico ---------------------------------------------

ANO_ALVO       <- 2023L
TRIMESTRE_ALVO <- 4L
IDADE_MIN      <- 15L
IDADE_MAX      <- 29L
