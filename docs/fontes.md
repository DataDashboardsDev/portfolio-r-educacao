# Fontes de dados

## Base utilizada

| Base | Fonte | Período | Forma de acesso |
|------|-------|---------|------------------|
| PNAD Contínua | IBGE | 4º trimestre de 2023 | Pacote R `PNADcIBGE` (oficial) |

## Acesso programático

O download é totalmente automatizado pelo pacote R `PNADcIBGE`, mantido pelo IBGE/UFRJ:

- **Pacote**: [`PNADcIBGE` no CRAN](https://cran.r-project.org/web/packages/PNADcIBGE/)
- **Repositório fonte (IBGE)**: [Portal IBGE PNADc](https://www.ibge.gov.br/estatisticas/sociais/trabalho/17270-pnad-continua.html)
- **FTP oficial**: [ftp.ibge.gov.br/Trabalho_e_Rendimento/](https://ftp.ibge.gov.br/Trabalho_e_Rendimento/Pesquisa_Nacional_por_Amostra_de_Domicilios_continua/)

O download é feito em `R/01_download_pnadc.R` com cache local em `data/raw/pnadc_2023T4.rds` para evitar re-downloads.

## Variáveis solicitadas

O script seleciona ~25 variáveis explicitamente em `R/01_download_pnadc.R` (constante `VARS_PNADC`). A lista completa está documentada em `data/dicionarios/dicionario_pnadc.csv`.

## Validação cruzada — referências oficiais

| Indicador | Valor de referência | Fonte |
|-----------|---------------------|-------|
| População 15-29 (BR, 4ºT 2023) | ~48 milhões | [IBGE, projeção populacional 2023](https://www.ibge.gov.br/estatisticas/sociais/populacao/9103-estimativas-de-populacao.html) |
| Taxa NEET (15-29, BR 2023) | ~19-22% | [IPEA — Carta de Conjuntura](https://www.ipea.gov.br/portal/) |
| Taxa de conclusão do EM (18-24) | ~50-55% | PNADc séries históricas |

## Pacotes R utilizados

| Pacote | Função |
|--------|--------|
| `PNADcIBGE` | Download oficial da PNAD Contínua |
| `survey` | Plano amostral complexo (svydesign, svyglm) |
| `targets` / `tarchetypes` | Orquestração do pipeline |
| `renv` | Lockfile de dependências |
| `here` | Caminhos portáveis |
| `data.table` / `dplyr` / `tidyr` | Manipulação |
| `janitor` | Padronização de nomes |
| `fixest` | Reserva para modelos com efeitos fixos (uso futuro) |
| `skimr` / `naniar` | Diagnóstico de bases |
| `ggplot2` / `scales` | Visualização |
| `quarto` | Renderização de relatórios HTML |

## Quando atualizar este documento

- Quando uma nova base for incorporada;
- Quando o pacote `PNADcIBGE` mudar a interface (raro, mas possível);
- Quando o IBGE divulgar nova safra (anualmente, em maio/junho do ano seguinte);
- Quando se adicionar nova dependência R.

## Datas de acesso

| Data | Ação |
|------|------|
| 2026-05-10 | Setup inicial do projeto |
| 2026-05-10 | Pipeline reescrito para PNAD Contínua (substituindo Censo Escolar) |
