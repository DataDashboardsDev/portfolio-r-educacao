# =============================================================================
# 01_download_pnadc.R — Download da PNAD Contínua via pacote oficial
# =============================================================================
#
# Usa o pacote PNADcIBGE (mantido pelo IBGE) para baixar diretamente do FTP
# oficial. Faz cache local (data/raw/) para evitar re-download.
#
# Variáveis selecionadas: identificação, demografia, educação, ocupação,
# rendimento. Lista enxuta para reduzir tamanho do download.
# =============================================================================


# Variáveis essenciais para análise de jovens (15-29) -------------------------
# Códigos PNAD Contínua — referência: dicionário do IBGE.
VARS_PNADC <- c(
  # Identificação e geografia
  "UF",            # Unidade da Federação
  "Capital",       # Indicador de capital
  "RM_RIDE",       # Região metropolitana
  "V1022",         # Situação do domicílio (urbano/rural)

  # Demografia
  "V2007",         # Sexo
  "V2009",         # Idade do morador
  "V2010",         # Cor ou raça

  # Educação
  "V3001",         # Sabe ler e escrever
  "V3002",         # Frequenta escola/creche
  "V3003A",        # Curso que frequenta
  "V3009A",        # Curso mais elevado frequentado anteriormente
  "V3014",         # Concluiu o curso mais elevado frequentado anteriormente
  "VD3004",        # Nível de instrução mais elevado alcançado (var derivada)
  "VD3005",        # Anos de estudo (var derivada)

  # Ocupação (PIA = pessoa em idade ativa, 14+)
  "VD4001",        # Condição de força de trabalho (na semana de referência)
  "VD4002",        # Condição de ocupação
  "VD4003",        # Força de trabalho potencial
  "VD4004A",       # Subocupação
  "VD4009",        # Posição na ocupação (formal/informal)
  "VD4019",        # Rendimento efetivo (habitual + outras fontes)
  "VD4020",        # Rendimento efetivo de todos os trabalhos

  # Peso amostral e plano amostral
  "V1028",         # Peso da pessoa
  "UPA",           # Unidade primária de amostragem
  "Estrato"        # Estrato amostral
)


#' Baixa a PNAD Contínua de um trimestre específico
#'
#' @param ano Ano (ex: 2023)
#' @param trimestre Trimestre do ano (1-4). Default 4 (visita anual de educação).
#' @return Data.frame com os microdados filtrados pelas variáveis selecionadas
baixar_pnadc <- function(ano = ANO_ALVO, trimestre = TRIMESTRE_ALVO) {

  ensure_dir(DIR_RAW)

  # Cache local: se já tiver arquivo .rds, reusa
  cache_path <- file.path(DIR_RAW,
                          sprintf("pnadc_%dT%d.rds", ano, trimestre))

  if (file.exists(cache_path)) {
    log_msg(sprintf("Cache encontrado: %s", basename(cache_path)))
    return(readRDS(cache_path))
  }

  log_msg(sprintf("Baixando PNAD Contínua %dT%d via PNADcIBGE...", ano, trimestre))

  # Download via pacote oficial do IBGE
  dados <- PNADcIBGE::get_pnadc(
    year       = ano,
    quarter    = trimestre,
    vars       = VARS_PNADC,
    labels     = FALSE,
    deflator   = FALSE,
    design     = FALSE,
    savedir    = tempdir()
  )

  log_msg(sprintf("Download concluído: %s linhas × %s colunas",
                  format(nrow(dados), big.mark = "."),
                  format(ncol(dados), big.mark = ".")))

  # Salva cache em RDS (mais compacto que o original do IBGE)
  saveRDS(dados, cache_path)
  log_msg(sprintf("Cache salvo em %s", basename(cache_path)))

  dados
}
