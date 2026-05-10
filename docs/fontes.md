# Fontes de dados

## Microdados utilizados

| Base | Fonte | Período | URL |
|------|-------|---------|-----|
| Censo Escolar | INEP | 2019–2023 | [https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar) |

Download direto (zip por ano):

```
https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_2019.zip
https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_2020.zip
https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_2021.zip
https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_2022.zip
https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_2023.zip
```

## Validação cruzada

Os totais usados para validação cruzada (script `06_diagnostico_base.R::diag_validacao_inep`) vêm das **Sinopses Estatísticas da Educação Básica** do INEP:

[https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/sinopses-estatisticas/educacao-basica](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/sinopses-estatisticas/educacao-basica)

> **Nota:** os números no script são placeholders representativos; antes do envio final, devem ser substituídos pelos valores exatos publicados pelo INEP para o EM em SP em cada ano (consultar a respectiva Sinopse).

## Dicionários do Censo Escolar

Cada zip do INEP contém o dicionário de variáveis em `dicionario.xlsx` (na pasta `Anexos/`). Há também versão consolidada em PDF disponível em:

[https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_2023.zip](https://download.inep.gov.br/dados_abertos/microdados_censo_escolar_2023.zip) (incluso no pacote)

## Pacotes R utilizados (resumo)

| Pacote | Função |
|---|---|
| `targets`     | Orquestração do pipeline reprodutível |
| `tarchetypes` | Targets especiais (Quarto, files) |
| `renv`        | Lockfile de dependências |
| `here`        | Paths portáveis |
| `data.table`  | Leitura e manipulação de microdados grandes |
| `dplyr`/`tidyr` | Manipulação tidy |
| `janitor`     | Padronização de nomes |
| `fixest`      | Modelos com efeitos fixos (logit, lpm) |
| `skimr`       | Sumários descritivos |
| `naniar`      | Análise de missings |
| `ggplot2`     | Visualização |
| `scales`      | Formatação de eixos |
| `arrow`       | Suporte a parquet (opcional) |
| `digest`      | Hashing SHA-256 (LGPD) |
| `quarto`      | Renderização de relatórios |

## Quando atualizar este documento

- Toda vez que uma nova base for incorporada;
- Toda vez que o link oficial mudar;
- Toda vez que a versão do INEP for atualizada (anualmente, em geral em dezembro);
- Toda vez que se adicionar uma nova dependência R.

## Datas de acesso

| Data | Ação |
|------|------|
| 2026-05-10 | Setup inicial do projeto; downloads ainda não executados |
