# =============================================================================
# _targets.R — Pipeline reprodutível
# Projeto: Trajetória educacional e ocupacional dos jovens brasileiros
#          (PNAD Contínua, microdados de pessoa)
# Autor:   Samuel Volpe
# =============================================================================
#
# Como executar:
#   targets::tar_make()           # roda todas as etapas faltantes
#   targets::tar_visnetwork()     # visualiza o grafo de dependências
#   targets::tar_read(painel_jovens)  # lê um alvo específico
#
# =============================================================================

library(targets)
library(tarchetypes)

tar_option_set(
  packages = c(
    "here", "dplyr", "tidyr", "readr", "data.table",
    "stringr", "janitor", "fixest", "skimr", "naniar",
    "ggplot2", "scales", "PNADcIBGE", "survey"
  ),
  format = "rds",
  error  = "continue"
)

source(here::here("R", "00_setup.R"))
source(here::here("R", "01_download_pnadc.R"))
source(here::here("R", "02_clean_pnadc.R"))
source(here::here("R", "04_descritivas.R"))
source(here::here("R", "05_modelo_neet.R"))
source(here::here("R", "06_diagnostico_base.R"))
source(here::here("R", "utils_anonimizacao.R"))

# -----------------------------------------------------------------------------
# Pipeline
# -----------------------------------------------------------------------------
list(

  # 1. Parâmetros do recorte ---------------------------------------------------
  tar_target(ano_alvo,      2023L),
  tar_target(trimestre_alvo, 4L),       # 4º trimestre = visita anual de educação
  tar_target(idade_min,     15L),
  tar_target(idade_max,     29L),

  # 2. Download da PNAD Contínua ----------------------------------------------
  tar_target(
    pnadc_raw,
    baixar_pnadc(ano = ano_alvo, trimestre = trimestre_alvo)
  ),

  # 3. Limpeza e filtragem (jovens 15-29) -------------------------------------
  tar_target(
    painel_jovens,
    limpar_pnadc_jovens(pnadc_raw,
                       idade_min = idade_min,
                       idade_max = idade_max)
  ),

  # 4. Desenho amostral (survey design com pesos) -----------------------------
  tar_target(
    desenho_pnadc,
    construir_desenho_amostral(painel_jovens)
  ),

  # 5. Diagnóstico de base ----------------------------------------------------
  tar_target(
    diagnostico,
    rodar_diagnostico(painel_jovens, dir_out = here::here("outputs", "tables"))
  ),

  # 6. Descritivas + figuras --------------------------------------------------
  tar_target(
    figuras,
    gerar_descritivas(painel_jovens, desenho_pnadc,
                      dir_out = here::here("outputs", "figures")),
    format = "file"
  ),

  # 7. Modelo logit de NEET ---------------------------------------------------
  tar_target(
    modelo_neet,
    estimar_modelo_neet(painel_jovens, desenho_pnadc)
  ),

  tar_target(
    tabela_coefs,
    exportar_coeficientes(modelo_neet,
                          dir_out = here::here("outputs", "tables")),
    format = "file"
  ),

  # 8. Relatórios Quarto ------------------------------------------------------
  tar_quarto(
    relatorio_diagnostico,
    path = here::here("outputs", "reports", "relatorio_diagnostico.qmd")
  ),

  tar_quarto(
    relatorio_analise,
    path = here::here("outputs", "reports", "relatorio_analise.qmd")
  )
)
