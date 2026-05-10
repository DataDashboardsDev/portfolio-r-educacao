# =============================================================================
# _targets.R — Pipeline reprodutível
# Projeto: Trajetória de matrícula e conclusão do EM em SP (Censo Escolar)
# Autor:   Samuel Volpe
# =============================================================================
#
# Como executar:
#   targets::tar_make()           # roda todas as etapas faltantes
#   targets::tar_visnetwork()     # visualiza o grafo de dependências
#   targets::tar_read(painel_em)  # lê um alvo específico
#
# A ordem real do fluxo está implícita nas dependências entre os tar_target().
# =============================================================================

library(targets)
library(tarchetypes)

# Pacotes carregados em CADA etapa (mantém-se enxuto).
tar_option_set(
  packages = c(
    "here", "dplyr", "tidyr", "readr", "data.table",
    "stringr", "janitor", "fixest", "skimr", "naniar", "ggplot2", "scales"
  ),
  format   = "rds",
  error    = "continue"
)

# Funções customizadas
source(here::here("R", "00_setup.R"))
source(here::here("R", "01_download_censo.R"))
source(here::here("R", "02_clean_matriculas.R"))
source(here::here("R", "03_build_painel.R"))
source(here::here("R", "04_descritivas.R"))
source(here::here("R", "05_modelo_conclusao.R"))
source(here::here("R", "06_diagnostico_base.R"))
source(here::here("R", "utils_anonimizacao.R"))

# -----------------------------------------------------------------------------
# Pipeline
# -----------------------------------------------------------------------------
list(

  # 1. Downloads ---------------------------------------------------------------
  tar_target(anos_alvo, 2019:2023),
  tar_target(uf_alvo,   "SP"),

  # Branch sobre cada ano (gera um arquivo por ano via dynamic branching)
  tar_target(
    ano_alvo_branch,
    anos_alvo,
    pattern = map(anos_alvo)
  ),

  tar_target(
    arquivos_brutos,
    baixar_um_ano(ano_alvo_branch, dir = here::here("data", "raw")),
    pattern = map(ano_alvo_branch),
    format  = "file"
  ),

  # 2. Limpeza ano a ano -------------------------------------------------------
  tar_target(
    matriculas_por_ano,
    limpar_matriculas_ano(
      caminho_zip = arquivos_brutos,
      uf          = uf_alvo,
      idade_min   = 15,
      idade_max   = 17
    ),
    pattern = map(arquivos_brutos)
  ),

  # 3. Painel longitudinal ----------------------------------------------------
  tar_target(
    painel_em,
    construir_painel(matriculas_por_ano)
  ),

  tar_target(
    painel_anonimizado,
    anonimizar_painel(painel_em, k_min = 5),
    format = "rds"
  ),

  # 4. Diagnóstico de base ----------------------------------------------------
  tar_target(
    diagnostico,
    rodar_diagnostico(painel_em, dir_out = here::here("outputs", "tables"))
  ),

  # 5. Descritivas + figuras --------------------------------------------------
  tar_target(
    figuras,
    gerar_descritivas(painel_em, dir_out = here::here("outputs", "figures")),
    format = "file"
  ),

  # 6. Modelo logit com FE municipal ------------------------------------------
  tar_target(
    modelo_logit,
    estimar_modelo_conclusao(painel_em)
  ),

  tar_target(
    tabela_coefs,
    exportar_coeficientes(modelo_logit, dir_out = here::here("outputs", "tables")),
    format = "file"
  ),

  # 7. Relatórios Quarto ------------------------------------------------------
  tar_quarto(
    relatorio_diagnostico,
    path = here::here("outputs", "reports", "relatorio_diagnostico.qmd")
  ),

  tar_quarto(
    relatorio_analise,
    path = here::here("outputs", "reports", "relatorio_analise.qmd")
  )
)
