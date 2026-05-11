# =============================================================================
# 04_descritivas.R — Estatísticas descritivas e figuras
# =============================================================================
#
# Gera as 5 figuras principais usando pesos amostrais da PNAD:
#   1. Pirâmide etária dos jovens (15-29) por sexo
#   2. Distribuição da situação (estudando/ocupado/NEET) por faixa etária
#   3. Taxa de NEET por região e sexo
#   4. Taxa de NEET por cor/raça
#   5. Conclusão do EM por faixa etária e região
#
# Todas as estatísticas usam survey design para representação populacional.
# =============================================================================


#' Orquestrador — gera todas as figuras descritivas
#'
#' @param painel data.table com os microdados limpos
#' @param desenho survey design com pesos amostrais
#' @param dir_out Diretório de saída para PNGs
#' @return Vetor de caminhos de arquivos gerados
gerar_descritivas <- function(painel, desenho, dir_out = DIR_FIGURES) {

  ensure_dir(dir_out)
  arquivos <- character()

  arquivos["fig1"] <- fig_piramide_etaria(painel, dir_out)
  arquivos["fig2"] <- fig_situacao_por_idade(painel, dir_out)
  arquivos["fig3"] <- fig_neet_por_regiao_sexo(painel, dir_out)
  arquivos["fig4"] <- fig_neet_por_raca(painel, dir_out)
  arquivos["fig5"] <- fig_conclusao_em(painel, dir_out)

  exportar_tabelas_resumo(painel)

  log_msg(sprintf("Geradas %d figuras", length(arquivos)))
  arquivos
}


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

#' Soma de pesos por grupos
pop_por_grupo <- function(painel, grupos) {
  painel[, .(pop = sum(v1028, na.rm = TRUE)),
         by = c(grupos)]
}


# -----------------------------------------------------------------------------
# Figuras
# -----------------------------------------------------------------------------

fig_piramide_etaria <- function(painel, dir_out) {

  resumo <- pop_por_grupo(painel, c("idade", "sexo"))
  resumo[, pop_sign := ifelse(sexo == "Homem", -pop, pop)]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = idade, y = pop_sign, fill = sexo)
  ) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = function(x) format(abs(x), big.mark = ".")) +
    ggplot2::scale_fill_manual(values = c("Homem" = "#3B82F6", "Mulher" = "#EC4899")) +
    ggplot2::labs(
      title    = "Pirâmide etária dos jovens brasileiros (15-29 anos)",
      subtitle = "Estimativas populacionais com pesos amostrais",
      x = "Idade", y = "População", fill = NULL,
      caption = "Fonte: PNAD Contínua / IBGE, 4º trimestre 2023."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig1_piramide_etaria.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 6, dpi = 150)
  caminho
}


fig_situacao_por_idade <- function(painel, dir_out) {

  d <- data.table::copy(painel)
  d[, situacao := data.table::fcase(
    estudando == 1 & ocupado == 1, "Estuda e trabalha",
    estudando == 1 & ocupado == 0, "Só estuda",
    estudando == 0 & ocupado == 1, "Só trabalha",
    estudando == 0 & ocupado == 0, "NEET"
  )]
  d[, situacao := factor(situacao,
                         levels = c("Só estuda", "Estuda e trabalha",
                                    "Só trabalha", "NEET"))]

  resumo <- d[!is.na(situacao),
              .(pop = sum(v1028, na.rm = TRUE)),
              by = .(faixa_idade, situacao)]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = faixa_idade, y = pop, fill = situacao)
  ) +
    ggplot2::geom_col(position = "fill") +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::scale_fill_manual(values = c(
      "Só estuda"          = "#22C55E",
      "Estuda e trabalha"  = "#3B82F6",
      "Só trabalha"        = "#F59E0B",
      "NEET"               = "#EF4444"
    )) +
    ggplot2::labs(
      title    = "Situação de jovens por faixa etária",
      subtitle = "Distribuição de estudantes, trabalhadores e NEET",
      x = "Faixa etária", y = "% da população", fill = "Situação",
      caption = "Fonte: PNAD Contínua / IBGE, 4º trimestre 2023."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig2_situacao_por_idade.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 6, dpi = 150)
  caminho
}


fig_neet_por_regiao_sexo <- function(painel, dir_out) {

  resumo <- painel[!is.na(neet) & !is.na(regiao),
                   .(taxa_neet = sum((neet == 1) * v1028, na.rm = TRUE) /
                                 sum(v1028, na.rm = TRUE)),
                   by = .(regiao, sexo)]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = regiao, y = taxa_neet, fill = sexo)
  ) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::scale_fill_manual(values = c("Homem" = "#3B82F6", "Mulher" = "#EC4899")) +
    ggplot2::labs(
      title    = "Taxa de NEET por região e sexo",
      subtitle = "Jovens 15-29 anos que não estudam nem trabalham",
      x = NULL, y = "% NEET", fill = NULL,
      caption = "Fonte: PNAD Contínua / IBGE, 4º trimestre 2023."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig3_neet_regiao_sexo.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 6, dpi = 150)
  caminho
}


fig_neet_por_raca <- function(painel, dir_out) {

  resumo <- painel[
    !is.na(neet) & !is.na(cor_raca) & cor_raca != "Ignorada",
    .(taxa_neet = sum((neet == 1) * v1028, na.rm = TRUE) /
                  sum(v1028, na.rm = TRUE)),
    by = .(cor_raca, sexo)
  ]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = reorder(cor_raca, taxa_neet),
                 y = taxa_neet, fill = sexo)
  ) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::scale_fill_manual(values = c("Homem" = "#3B82F6", "Mulher" = "#EC4899")) +
    ggplot2::labs(
      title    = "Taxa de NEET por cor/raça e sexo",
      subtitle = "Recorte interseccional — jovens 15-29 anos",
      x = NULL, y = "% NEET", fill = NULL,
      caption = "Fonte: PNAD Contínua / IBGE, 4º trimestre 2023."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig4_neet_raca.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 6, dpi = 150)
  caminho
}


fig_conclusao_em <- function(painel, dir_out) {

  resumo <- painel[
    !is.na(concluiu_em) & !is.na(regiao) & idade >= 18,
    .(taxa_conclusao = sum((concluiu_em == 1) * v1028, na.rm = TRUE) /
                       sum(v1028, na.rm = TRUE)),
    by = .(regiao, faixa_idade)
  ][faixa_idade != "15-17"]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = regiao, y = taxa_conclusao, fill = faixa_idade)
  ) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    ggplot2::scale_fill_brewer(palette = "Set2") +
    ggplot2::labs(
      title    = "Taxa de conclusão do Ensino Médio",
      subtitle = "Jovens 18-29 anos por região",
      x = NULL, y = "% que concluiu EM", fill = "Faixa etária",
      caption = "Fonte: PNAD Contínua / IBGE, 4º trimestre 2023."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig5_conclusao_em.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 6, dpi = 150)
  caminho
}


# -----------------------------------------------------------------------------
# Tabelas
# -----------------------------------------------------------------------------

exportar_tabelas_resumo <- function(painel, dir_out = DIR_TABLES) {

  ensure_dir(dir_out)

  # População estimada por faixa etária
  t1 <- painel[, .(pop = sum(v1028, na.rm = TRUE)),
               by = faixa_idade][order(faixa_idade)]
  readr::write_csv(t1, file.path(dir_out, "tabela_pop_por_faixa.csv"))

  # Taxas-chave por região
  t2 <- painel[!is.na(neet) & !is.na(regiao),
               .(
                 pop          = sum(v1028, na.rm = TRUE),
                 taxa_neet    = sum((neet == 1) * v1028, na.rm = TRUE) /
                                sum(v1028, na.rm = TRUE),
                 taxa_estudo  = sum((estudando == 1) * v1028, na.rm = TRUE) /
                                sum(v1028, na.rm = TRUE),
                 taxa_ocupado = sum((ocupado == 1) * v1028, na.rm = TRUE) /
                                sum(v1028, na.rm = TRUE)
               ),
               by = regiao][order(regiao)]
  readr::write_csv(t2, file.path(dir_out, "tabela_taxas_por_regiao.csv"))

  log_msg("Tabelas resumo exportadas em outputs/tables/")
}
