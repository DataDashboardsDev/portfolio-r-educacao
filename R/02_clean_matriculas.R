# =============================================================================
# 02_clean_matriculas.R — Limpeza e padronização das matrículas
# =============================================================================
#
# Etapas:
#   1. Descompacta o zip de um ano específico
#   2. Localiza o arquivo MATRICULA_<REGIAO>.CSV referente a SP (Sudeste)
#   3. Lê em data.table com encoding latin1 (padrão histórico do INEP)
#   4. Filtra por UF=SP, idade 15-17 e nível EM
#   5. Padroniza nomes (snake_case via janitor)
#   6. Deriva variáveis analíticas (faixa, dependência, EJA, EPT)
#   7. Salva em parquet (mais compacto e tipado)
#
# Layout do CSV pode mudar entre anos — esta função trata cada ano isoladamente
# e harmoniza nomes esperados.
# =============================================================================


# Constantes de layout --------------------------------------------------------

# Códigos de etapa de ensino (Censo Escolar — dicionário INEP)
ETAPAS_EM <- c(
  25L, 26L, 27L, 28L, 29L,        # EM regular 1º ao 4º ano + não seriado
  30L, 31L, 32L, 33L, 34L,        # EM integrado à EPT
  35L, 36L, 37L, 38L, 39L, 40L,   # Normal/Magistério
  41L, 64L, 67L, 68L, 69L, 70L,   # EM tipos especiais
  71L, 72L, 73L, 74L              # EJA EM
)

ETAPAS_EPT_INT <- c(30L, 31L, 32L, 33L, 34L)        # Integrado à EPT
ETAPAS_EJA_EM  <- c(71L, 72L, 73L, 74L)


#' Limpa as matrículas de UM ano (recebe caminho do zip)
#'
#' @param caminho_zip Caminho do .zip do Censo Escolar
#' @param uf  Sigla da UF (default "SP")
#' @param idade_min Idade mínima
#' @param idade_max Idade máxima
#' @return data.table com colunas padronizadas
limpar_matriculas_ano <- function(caminho_zip,
                                  uf        = UF_ALVO,
                                  idade_min = IDADE_MIN,
                                  idade_max = IDADE_MAX) {

  ano <- extrair_ano_do_caminho(caminho_zip)
  log_msg(sprintf("[%d] limpeza iniciando", ano))

  # 1. Descompacta em diretório temporário
  tmp_dir <- tempfile(pattern = sprintf("censo_%d_", ano))
  dir.create(tmp_dir)
  utils::unzip(caminho_zip, exdir = tmp_dir)

  # 2. Localiza CSV de matrícula da região Sudeste (SP)
  csv_path <- localizar_csv_matricula(tmp_dir, regiao = "SUDESTE")
  log_msg(sprintf("[%d] arquivo localizado: %s", ano, basename(csv_path)))

  # 3. Lê com data.table (mais rápido para arquivos grandes)
  dt <- data.table::fread(
    csv_path,
    encoding = "Latin-1",
    sep      = "|",
    showProgress = FALSE
  )

  # 4. Padroniza nomes
  data.table::setnames(dt, janitor::make_clean_names(names(dt)))

  # 5. Filtra UF + idade + EM
  uf_col       <- detectar_coluna(dt, c("sg_uf", "co_uf"))
  idade_col    <- detectar_coluna(dt, c("nu_idade", "idade"))
  etapa_col    <- detectar_coluna(dt, c("tp_etapa_ensino", "etapa_ensino"))

  if (uf_col == "sg_uf") {
    dt <- dt[get(uf_col) == uf]
  } else {
    dt <- dt[get(uf_col) == COD_UF_SP]
  }

  dt <- dt[
    get(idade_col) >= idade_min &
    get(idade_col) <= idade_max &
    get(etapa_col) %in% ETAPAS_EM
  ]

  # 6. Deriva variáveis analíticas
  dt[, ano_censo  := ano]
  dt[, faixa_idade := factor(get(idade_col),
                             levels = idade_min:idade_max,
                             labels = paste0(idade_min:idade_max, " anos"))]
  dt[, eja_em      := as.integer(get(etapa_col) %in% ETAPAS_EJA_EM)]
  dt[, ept_int     := as.integer(get(etapa_col) %in% ETAPAS_EPT_INT)]

  # Dependência administrativa: padroniza para fator com 4 níveis
  dep_col <- detectar_coluna(dt, c("tp_dependencia", "dep_admin"))
  dt[, dep_admin := factor(get(dep_col),
                           levels = 1:4,
                           labels = c("Federal", "Estadual",
                                      "Municipal", "Privada"))]

  # Sexo
  sexo_col <- detectar_coluna(dt, c("tp_sexo", "sexo"))
  dt[, sexo := factor(get(sexo_col),
                      levels = 1:2,
                      labels = c("Masculino", "Feminino"))]

  # Cor/raça
  cor_col <- detectar_coluna(dt, c("tp_cor_raca", "cor_raca"))
  dt[, cor_raca := factor(get(cor_col),
                          levels = 0:5,
                          labels = c("Não declarada", "Branca", "Preta",
                                     "Parda", "Amarela", "Indígena"))]

  log_msg(sprintf("[%d] %s linhas após filtros", ano,
                  format(nrow(dt), big.mark = ".")))

  # 7. Persiste resultado em processed/
  ensure_dir(DIR_PROCESSED)
  saida <- file.path(DIR_PROCESSED,
                     sprintf("matriculas_%s_%d.parquet", tolower(uf), ano))

  if (requireNamespace("arrow", quietly = TRUE)) {
    arrow::write_parquet(dt, saida)
  } else {
    saida <- sub("\\.parquet$", ".rds", saida)
    saveRDS(dt, saida)
  }

  log_msg(sprintf("[%d] salvo em %s", ano, basename(saida)))

  # Limpa tmp
  unlink(tmp_dir, recursive = TRUE)

  dt
}


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

#' Extrai o ano de um caminho como ".../microdados_censo_escolar_2023.zip"
extrair_ano_do_caminho <- function(path) {
  m <- regmatches(path, regexpr("(19|20)\\d{2}", path))
  as.integer(m)
}


#' Procura o CSV de matrícula da região indicada
localizar_csv_matricula <- function(dir, regiao = "SUDESTE") {

  todos <- list.files(dir, pattern = "\\.CSV$|\\.csv$",
                      recursive = TRUE, full.names = TRUE)

  alvo <- todos[grepl(sprintf("(?i)matricula.*%s", regiao), todos, perl = TRUE)]

  if (length(alvo) == 0) {
    # Fallback: arquivo único de matrícula
    alvo <- todos[grepl("(?i)matricula", todos, perl = TRUE)]
  }

  if (length(alvo) == 0) {
    stop(sprintf("Não encontrei arquivo de matrícula em %s", dir))
  }

  alvo[1]
}


#' Detecta primeira coluna existente entre os candidatos
detectar_coluna <- function(dt, candidatos) {
  presentes <- intersect(candidatos, names(dt))
  if (length(presentes) == 0) {
    stop(sprintf("Nenhuma das colunas %s foi encontrada. Disponíveis: %s",
                 paste(candidatos, collapse = ", "),
                 paste(head(names(dt), 20), collapse = ", ")))
  }
  presentes[1]
}
