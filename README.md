# Trajetória de matrícula e conclusão do EM em SP

**Microdados do Censo Escolar (INEP) — 2019 a 2023 — Jovens 15 a 17 anos**

Pipeline reprodutível em R para **diagnóstico, descrição e modelagem** de matrículas no Ensino Médio no estado de São Paulo, com foco em jovens de 15 a 17 anos e participação em Educação Profissional Tecnológica (EPT) integrada.

![R](https://img.shields.io/badge/R-%E2%89%A54.3.0-blue)
![renv](https://img.shields.io/badge/deps-renv-2C7BB6)
![targets](https://img.shields.io/badge/pipeline-targets-1A8260)
![license](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Por que este projeto

Demonstrar um **fluxo completo e auditável** de processamento de microdados educacionais, alinhado às práticas exigidas em consultorias técnicas para fundações e órgãos públicos:

- Download direto da fonte primária (INEP), com **fallback** via BigQuery (`basedosdados`);
- **Limpeza ano a ano** com harmonização de layout entre safras;
- **Painel longitudinal** para análises temporais;
- **Diagnóstico de qualidade** (missings, duplicatas, consistência, validação cruzada);
- **Anonimização (LGPD)**: hash de IDs e supressão de células com n < 5;
- **Modelagem econométrica** com efeitos fixos municipais e anuais (logit/LPM via `fixest`);
- **Relatórios narrativos** em Quarto, com decisões metodológicas documentadas.

## Eixos temáticos cobertos

- **Censo Escolar** (base primária)
- **Acesso, permanência e conclusão dos jovens** (variável-resposta do modelo)
- Tangencia **EPT / Aprendizagem Profissional** (indicador `ept_int`)

## Estrutura do repositório

```
portfolio-r-educacao/
├── R/                          # scripts numerados (setup → download → clean → model)
├── data/
│   ├── raw/                   # zips do INEP (não versionados)
│   ├── processed/             # bases tratadas (não versionadas)
│   └── dicionarios/           # dicionário de variáveis (CSV)
├── outputs/
│   ├── figures/               # PNG das descritivas
│   ├── tables/                # CSV/xlsx dos resultados
│   └── reports/               # Quarto (.qmd) renderizados em HTML
├── docs/
│   ├── metodologia.md
│   └── fontes.md
├── _targets.R                  # orquestração do pipeline
├── DESCRIPTION                 # metadados do projeto
├── renv.lock                   # versões exatas dos pacotes
└── README.md
```

## Como reproduzir

Pré-requisitos: **R ≥ 4.3.0** e Quarto (para os relatórios).

```r
# 1. Restaurar dependências
install.packages("renv")
renv::restore()

# 2. Rodar pipeline (faz download, limpeza, modelagem, relatórios)
targets::tar_make()

# 3. Visualizar grafo de dependências
targets::tar_visnetwork()
```

Os relatórios HTML serão gerados em `outputs/reports/`:

- `relatorio_diagnostico.html` — diagnóstico de qualidade da base;
- `relatorio_analise.html` — descritivas + modelo logit com FE municipal.

## Pipeline (visão de alto nível)

```
arquivos_brutos ─► matriculas_por_ano ─► painel_em ──► descritivas → figuras
                                                  │
                                                  ├─► diagnostico
                                                  │
                                                  ├─► modelo_logit ─► tabela_coefs
                                                  │
                                                  ├─► relatorio_diagnostico (Quarto)
                                                  └─► relatorio_analise (Quarto)
```

## Resultados principais (preview)

> *Resultados consolidados disponíveis em `outputs/reports/relatorio_analise.html` após rodar o pipeline.*

- **Migração entre redes:** queda relativa da rede estadual e aumento das redes privada e federal entre 2019 e 2023.
- **EPT integrada:** participação cresce em todas as dependências, com pico na rede federal.
- **Heterogeneidade municipal:** efeitos fixos de município capturam parcela relevante da variância, indicando que políticas estaduais homogêneas convivem com forte heterogeneidade local de implementação.

## Decisões metodológicas

Documentadas em [docs/metodologia.md](docs/metodologia.md):

- Recorte do universo (UF, idade, anos);
- Definição da variável-resposta `y_concluiu`;
- Justificativa para FE municipal + anual;
- Tratamento de missings;
- Anonimização (LGPD).

## Limitações conhecidas

- O período 2020–2021 sofre impacto pandêmico — modelos longitudinais futuros devem incorporar dummies específicas ou testes de robustez.
- A variável-resposta usa **proxy** (idade 17 ou etapa final). A versão definitiva (Fase 2) incorporará `tp_situacao` consolidada.
- Sem variável de NSE individual — controles socioeconômicos absorvidos pelo FE municipal.

## Roadmap (Fase 2)

Caso o projeto evolua, próximos módulos previstos:

1. **PNAD Contínua + jovens NEET** (eixo Inclusão Produtiva).
2. **RAIS + Aprendizagem Profissional** (eixo direto da Lei 10.097).
3. **DiD: Novo Ensino Médio sobre IDEB/SAEB** — avaliação de impacto causal.
4. **Cruzamento Censo Escolar × RAIS** — egressos do EM e inserção no mercado formal.
5. **Dashboard Quarto estático** (gh-pages) — consolidação visual.

## Fontes

- INEP. *Microdados do Censo Escolar*. Disponível em [gov.br/inep](https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/microdados/censo-escolar).
- Lista completa em [docs/fontes.md](docs/fontes.md).

## Autor

**Samuel Volpe**
samuvolpe1@gmail.com

## Licença

MIT — veja [LICENSE](LICENSE).
