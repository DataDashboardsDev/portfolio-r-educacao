# =============================================================================
# 02_clean_pnadc.R — Limpeza e padronização da PNAD Contínua
# =============================================================================
#
# Etapas:
#   1. Filtra jovens 15-29 anos
#   2. Padroniza nomes (snake_case)
#   3. Deriva variáveis analíticas:
#      - faixa_idade: 15-17, 18-24, 25-29
#      - sexo, cor_raca, situacao_dom, regiao (factor com labels)
#      - estudando: 1 se frequenta escola/curso
#      - concluiu_em: 1 se concluiu ensino médio
#      - ocupado: 1 se está ocupado
#      - formal: 1 se vínculo formal (CLT, militar, estatutário)
#      - NEET: 1 se nem trabalha nem estuda
#   4. Salva painel processado em CSV + RDS
# =============================================================================


REGIOES_BR <- c(
  "11" = "Norte",      "12" = "Norte",      "13" = "Norte",
  "14" = "Norte",      "15" = "Norte",      "16" = "Norte",
  "17" = "Norte",
  "21" = "Nordeste",   "22" = "Nordeste",   "23" = "Nordeste",
  "24" = "Nordeste",   "25" = "Nordeste",   "26" = "Nordeste",
  "27" = "Nordeste",   "28" = "Nordeste",   "29" = "Nordeste",
  "31" = "Sudeste",    "32" = "Sudeste",    "33" = "Sudeste",
  "35" = "Sudeste",
  "41" = "Sul",        "42" = "Sul",        "43" = "Sul",
  "50" = "Centro-Oeste","51"= "Centro-Oeste","52"= "Centro-Oeste",
  "53" = "Centro-Oeste"
)


#' Limpa e enriquece os dados da PNAD para análise de jovens
#'
#' @param dados data.frame baixado por baixar_pnadc()
#' @param idade_min Idade mínima
#' @param idade_max Idade máxima
#' @return data.table com variáveis derivadas e factors limpos
limpar_pnadc_jovens <- function(dados,
                                 idade_min = IDADE_MIN,
                                 idade_max = IDADE_MAX) {

  log_msg(sprintf("Limpeza iniciando — %s linhas brutas",
                  format(nrow(dados), big.mark = ".")))

  dt <- data.table::as.data.table(dados)

  # 1. Padroniza nomes para snake_case
  data.table::setnames(dt, janitor::make_clean_names(names(dt)))

  # 2. Filtra faixa etária jovem
  if (!"v2009" %in% names(dt)) {
    stop("Coluna v2009 (idade) não encontrada. Disponíveis: ",
         paste(head(names(dt), 20), collapse = ", "))
  }
  dt[, idade := as.integer(v2009)]
  dt <- dt[idade >= idade_min & idade <= idade_max]

  log_msg(sprintf("Após filtro 15-29 anos: %s linhas",
                  format(nrow(dt), big.mark = ".")))

  # 3. Deriva variáveis analíticas ----------------------------------------

  # Faixa etária
  dt[, faixa_idade := cut(
    idade,
    breaks = c(14, 17, 24, 29),
    labels = c("15-17", "18-24", "25-29"),
    right  = TRUE
  )]

  # Sexo
  dt[, sexo := factor(v2007, levels = c(1, 2),
                      labels = c("Homem", "Mulher"))]

  # Cor/raça
  dt[, cor_raca := factor(v2010,
                          levels = c(1, 2, 3, 4, 5, 9),
                          labels = c("Branca", "Preta", "Amarela",
                                     "Parda", "Indígena", "Ignorada"))]

  # Situação do domicílio
  if ("v1022" %in% names(dt)) {
    dt[, situacao_dom := factor(v1022, levels = c(1, 2),
                                labels = c("Urbano", "Rural"))]
  }

  # Região geográfica (a partir do código de UF)
  dt[, regiao := factor(REGIOES_BR[as.character(uf)],
                        levels = c("Norte", "Nordeste", "Sudeste",
                                   "Sul", "Centro-Oeste"))]

  # Estudando agora?
  # V3002: 1=Sim, 2=Não. Tratamos NA como "não estuda" (codigo conservador).
  if ("v3002" %in% names(dt)) {
    dt[, estudando := data.table::fifelse(v3002 == 1, 1L, 0L)]
    dt[is.na(estudando), estudando := 0L]
  } else {
    dt[, estudando := NA_integer_]
  }

  # Concluiu o ensino médio?
  # VD3004 = nível mais elevado alcançado.
  # Códigos: 1=Sem instrução; 2=Fund. incompl.; 3=Fund. completo;
  #          4=Médio incompl.; 5=Médio completo; 6=Superior incompl.;
  #          7=Superior completo.
  if ("vd3004" %in% names(dt)) {
    dt[, nivel_instrucao := as.integer(vd3004)]
    dt[, concluiu_em := as.integer(nivel_instrucao >= 5L)]
  }

  # Ocupado na semana de referência?
  # VD4002: 1=Ocupado, 2=Desocupado. NA = fora da força de trabalho (não-PIA
  # ou não-respondente). Para a definição de NEET, NA conta como "não ocupado".
  if ("vd4002" %in% names(dt)) {
    dt[, ocupado := data.table::fifelse(vd4002 == 1, 1L, 0L)]
    dt[is.na(ocupado), ocupado := 0L]
  }

  # Vínculo formal? VD4009 — códigos 1, 3, 5, 7 (CLT/militar/estatutário/conta
  # própria contribuinte). Códigos 2, 4, 6, 8, 9 (informal/sem carteira).
  if ("vd4009" %in% names(dt)) {
    dt[, formal := as.integer(vd4009 %in% c(1L, 3L, 5L, 7L))]
  }

  # NEET (Not in Education, Employment or Training)
  # Definição OCDE: jovem que NÃO está ocupado E NÃO está em educação.
  # Após o tratamento acima de estudando/ocupado, NA já virou 0 em ambos
  # (pessoa fora da força conta como não-ocupado; quem não respondeu
  # frequência escolar conta como não-estudante).
  dt[, neet := as.integer(estudando == 0L & ocupado == 0L)]

  # 4. Persiste em processed/ ---------------------------------------------
  ensure_dir(DIR_PROCESSED)

  saida_csv <- file.path(DIR_PROCESSED, "painel_jovens_pnadc.csv")
  data.table::fwrite(dt, saida_csv)
  log_msg(sprintf("Painel salvo em %s", basename(saida_csv)))

  saida_rds <- file.path(DIR_PROCESSED, "painel_jovens_pnadc.rds")
  saveRDS(dt, saida_rds)

  dt
}


#' Constrói o desenho amostral (survey design) com pesos da PNAD
#'
#' Crítico para estatísticas representativas da população, não da amostra.
#'
#' @param painel data.table com colunas v1028, upa, estrato
#' @return survey.design2
construir_desenho_amostral <- function(painel) {

  log_msg("Construindo desenho amostral PNAD (pesos + UPA + estrato)...")

  # Ajusta opção global para tratar estratos singleton (com 1 UPA).
  # "adjust" usa a contribuição média dos estratos restantes — abordagem
  # padrão recomendada para microdados PNAD.
  options(survey.lonely.psu = "adjust")

  desenho <- survey::svydesign(
    ids     = ~upa,
    strata  = ~estrato,
    weights = ~v1028,
    data    = painel,
    nest    = TRUE
  )

  log_msg(sprintf("Desenho amostral construído. População representada: %s",
                  format(round(sum(painel$v1028)), big.mark = ".")))

  desenho
}
