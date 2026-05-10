# =============================================================================
# 04_descritivas.R — Estatísticas descritivas e figuras
# =============================================================================
#
# Gera as 5 figuras-chave do projeto:
#   1. Evolução de matrículas por ano e dependência administrativa
#   2. Distribuição por idade × ano
#   3. Composição por cor/raça (proporção)
#   4. Participação EPT integrada × ano
#   5. Heatmap: município top-20 × ano (matrículas)
#
# Também exporta tabelas resumo em outputs/tables/.
# =============================================================================


#' Função orquestradora — gera todas as figuras descritivas
#'
#' @param painel data.table do painel longitudinal
#' @param dir_out Diretório de saída para PNGs
#' @return Vetor de caminhos de arquivos gerados (para tar_target file)
gerar_descritivas <- function(painel, dir_out = DIR_FIGURES) {

  ensure_dir(dir_out)
  arquivos <- character()

  arquivos["fig1"] <- fig_evolucao_dependencia(painel, dir_out)
  arquivos["fig2"] <- fig_distribuicao_idade(painel, dir_out)
  arquivos["fig3"] <- fig_composicao_cor_raca(painel, dir_out)
  arquivos["fig4"] <- fig_participacao_ept(painel, dir_out)
  arquivos["fig5"] <- fig_heatmap_municipios(painel, dir_out)

  exportar_tabelas_resumo(painel)

  log_msg(sprintf("Geradas %d figuras", length(arquivos)))
  arquivos
}


# -----------------------------------------------------------------------------
# Figuras
# -----------------------------------------------------------------------------

fig_evolucao_dependencia <- function(painel, dir_out) {

  resumo <- painel[, .(n = .N), by = .(ano_censo, dep_admin)]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = ano_censo, y = n, color = dep_admin)
  ) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_y_continuous(labels = scales::label_number(big.mark = ".")) +
    ggplot2::labs(
      title    = "Matrículas no EM (15-17 anos) em SP, por dependência",
      subtitle = "Censo Escolar | 2019-2023",
      x = NULL, y = "Matrículas", color = "Dependência",
      caption = "Fonte: INEP, Microdados do Censo Escolar."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig1_evolucao_dependencia.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 5, dpi = 150)
  caminho
}


fig_distribuicao_idade <- function(painel, dir_out) {

  resumo <- painel[, .(n = .N), by = .(ano_censo, faixa_idade)]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = factor(ano_censo), y = n, fill = faixa_idade)
  ) +
    ggplot2::geom_col(position = "fill") +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::labs(
      title    = "Composição etária das matrículas no EM em SP",
      subtitle = "Proporção por idade (15, 16, 17 anos)",
      x = NULL, y = "%", fill = "Faixa",
      caption = "Fonte: INEP, Microdados do Censo Escolar."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig2_distribuicao_idade.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 5, dpi = 150)
  caminho
}


fig_composicao_cor_raca <- function(painel, dir_out) {

  resumo <- painel[!is.na(cor_raca),
                   .(n = .N), by = .(ano_censo, cor_raca)]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = factor(ano_censo), y = n, fill = cor_raca)
  ) +
    ggplot2::geom_col(position = "fill") +
    ggplot2::scale_y_continuous(labels = scales::percent_format()) +
    ggplot2::labs(
      title    = "Composição por cor/raça das matrículas",
      subtitle = "Jovens 15-17 anos em SP, 2019-2023",
      x = NULL, y = "%", fill = "Cor/Raça",
      caption = "Fonte: INEP, Microdados do Censo Escolar."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig3_composicao_cor_raca.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 5, dpi = 150)
  caminho
}


fig_participacao_ept <- function(painel, dir_out) {

  resumo <- painel[, .(prop_ept = mean(ept_int)), by = .(ano_censo, dep_admin)]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = ano_censo, y = prop_ept,
                 color = dep_admin, group = dep_admin)
  ) +
    ggplot2::geom_line(linewidth = 1.1) +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 0.1)) +
    ggplot2::labs(
      title    = "Participação do EM integrado à EPT em SP",
      subtitle = "% de matrículas no EM integrado, por dependência",
      x = NULL, y = "% EPT integrada", color = "Dependência",
      caption = "Fonte: INEP, Microdados do Censo Escolar."
    ) +
    ggplot2::theme_minimal(base_size = 12)

  caminho <- file.path(dir_out, "fig4_participacao_ept.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 5, dpi = 150)
  caminho
}


fig_heatmap_municipios <- function(painel, dir_out) {

  if (!"co_municipio" %in% names(painel)) {
    log_msg("co_municipio ausente — pulando heatmap", "WARN")
    return(NA_character_)
  }

  # Top 20 municípios por volume total
  top <- painel[, .N, by = co_municipio][order(-N)][1:20, co_municipio]

  resumo <- painel[
    co_municipio %in% top,
    .(n = .N),
    by = .(co_municipio, ano_censo)
  ]

  p <- ggplot2::ggplot(
    resumo,
    ggplot2::aes(x = factor(ano_censo),
                 y = reorder(factor(co_municipio), n),
                 fill = n)
  ) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_viridis_c(labels = scales::label_number(big.mark = ".")) +
    ggplot2::labs(
      title    = "Top 20 municípios paulistas — matrículas EM 15-17 anos",
      x = NULL, y = "Código do município", fill = "Matrículas",
      caption = "Fonte: INEP, Microdados do Censo Escolar."
    ) +
    ggplot2::theme_minimal(base_size = 11)

  caminho <- file.path(dir_out, "fig5_heatmap_municipios.png")
  ggplot2::ggsave(caminho, p, width = 9, height = 7, dpi = 150)
  caminho
}


# -----------------------------------------------------------------------------
# Tabelas
# -----------------------------------------------------------------------------

exportar_tabelas_resumo <- function(painel, dir_out = DIR_TABLES) {

  ensure_dir(dir_out)

  # 1. Contagem por ano
  t1 <- painel[, .(matriculas = .N), by = ano_censo][order(ano_censo)]
  readr::write_csv(t1, file.path(dir_out, "tabela_matriculas_por_ano.csv"))

  # 2. Cruzamento idade × dep_admin × ano
  t2 <- painel[, .(matriculas = .N),
               by = .(ano_censo, faixa_idade, dep_admin)][
                 order(ano_censo, faixa_idade, dep_admin)
               ]
  readr::write_csv(t2, file.path(dir_out, "tabela_idade_x_dep_x_ano.csv"))

  log_msg("Tabelas resumo exportadas em outputs/tables/")
}
