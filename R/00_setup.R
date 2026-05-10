# =============================================================================
# 00_setup.R — Configuração e utilitários gerais
# =============================================================================
#
# Carregado por _targets.R via source(). Define:
#   - paths padrão (raw, processed, outputs)
#   - logger simples para registro de execução
#   - função utilitária de checagem MD5
#
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
#'
#' @param msg Mensagem
#' @param level "INFO" | "WARN" | "ERROR"
log_msg <- function(msg, level = "INFO") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %-5s %s\n", ts, level, msg))
}

# Checagem de integridade -----------------------------------------------------

#' Calcula MD5 de um arquivo
#'
#' @param path Caminho do arquivo
#' @return string md5
checksum_md5 <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  tools::md5sum(path) |> unname()
}

#' Garante que um diretório exista
#'
#' @param path Caminho
ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    log_msg(paste("Diretório criado:", path))
  }
  invisible(path)
}

# Constantes do recorte -------------------------------------------------------

UF_ALVO     <- "SP"
COD_UF_SP   <- 35L
IDADE_MIN   <- 15L
IDADE_MAX   <- 17L
ANOS_ALVO   <- 2019:2023
