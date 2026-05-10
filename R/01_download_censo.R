# =============================================================================
# 01_download_censo.R — Download dos microdados do Censo Escolar
# =============================================================================
#
# Estratégia em duas camadas:
#   (A) Caminho primário: download direto dos zips no servidor do INEP.
#       URL: https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_<ANO>.zip
#
#   (B) Fallback: leitura via pacote `basedosdados` (BigQuery) quando o
#       servidor do INEP estiver indisponível ou o usuário preferir
#       não armazenar zips locais. Requer token gratuito do BigQuery
#       (até 1TB/mês de query gratuito).
#
# Idempotente: se o zip já existir e o MD5 bater, pula o download.
# =============================================================================


URL_INEP_BASE <- "https://download.inep.gov.br/dados_abertos"


#' Baixa Censo Escolar para um conjunto de anos
#'
#' @param anos Vetor de anos (ex: 2019:2023)
#' @param dir  Diretório de destino
#' @return Vetor de caminhos para os zips baixados
baixar_censo_escolar <- function(anos, dir = DIR_RAW) {

  ensure_dir(dir)

  caminhos <- vapply(
    anos,
    FUN = function(ano) baixar_um_ano(ano, dir),
    FUN.VALUE = character(1)
  )

  log_msg(sprintf("Total de %d arquivos disponíveis em %s", length(caminhos), dir))
  caminhos
}


#' Baixa o zip de um ano específico, idempotente
#'
#' @param ano Ano alvo
#' @param dir Diretório de destino
#' @return Caminho do arquivo (existente ou recém-baixado)
baixar_um_ano <- function(ano, dir) {

  arquivo <- sprintf("microdados_censo_escolar_%d.zip", ano)
  destino <- file.path(dir, arquivo)
  url     <- sprintf("%s/%s", URL_INEP_BASE, arquivo)

  if (file.exists(destino) && file.info(destino)$size > 0) {
    log_msg(sprintf("[%d] já existe — %s", ano, basename(destino)))
    return(destino)
  }

  log_msg(sprintf("[%d] iniciando download de %s", ano, url))
  tryCatch(
    utils::download.file(
      url      = url,
      destfile = destino,
      mode     = "wb",
      quiet    = FALSE
    ),
    error = function(e) {
      log_msg(sprintf("[%d] FALHOU: %s", ano, conditionMessage(e)), "ERROR")
      log_msg("Considere rodar baixar_censo_basedosdados() como fallback.", "WARN")
      stop(e)
    }
  )

  log_msg(sprintf("[%d] OK — MD5: %s", ano, checksum_md5(destino)))
  destino
}


# -----------------------------------------------------------------------------
# Fallback: basedosdados (BigQuery)
# -----------------------------------------------------------------------------

#' Baixa subset do Censo Escolar via basedosdados (fallback)
#'
#' Útil quando:
#'   - Servidor do INEP está indisponível
#'   - Usuário não quer manter zips locais (usa apenas dataframe)
#'
#' Requer:
#'   - Pacote `basedosdados` instalado
#'   - billing_id (projeto BigQuery do usuário) configurado
#'
#' @param anos Vetor de anos
#' @param uf_cod Código da UF (35 = SP)
#' @param billing_id Projeto BigQuery do usuário
#' @return data.frame
baixar_censo_basedosdados <- function(anos    = ANOS_ALVO,
                                      uf_cod  = COD_UF_SP,
                                      billing_id = NULL) {

  if (!requireNamespace("basedosdados", quietly = TRUE)) {
    stop("Pacote 'basedosdados' não está instalado. ",
         "Rode: install.packages('basedosdados')")
  }

  if (is.null(billing_id)) {
    stop("Forneça o billing_id (projeto BigQuery). ",
         "Veja https://basedosdados.org/docs/access_data_packages")
  }

  basedosdados::set_billing_id(billing_id)

  query <- sprintf("
    SELECT *
    FROM `basedosdados.br_inep_censo_escolar.matricula`
    WHERE ano IN (%s) AND id_uf = %d
      AND idade BETWEEN %d AND %d
  ", paste(anos, collapse = ","), uf_cod, IDADE_MIN, IDADE_MAX)

  log_msg("Consultando BigQuery (basedosdados)...")
  df <- basedosdados::read_sql(query)
  log_msg(sprintf("Recebidas %d linhas via BigQuery", nrow(df)))
  df
}
