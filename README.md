# Jovens brasileiros 15–29: trajetória educacional e produtiva

**Análise reprodutível da PNAD Contínua (IBGE, 4º trimestre 2023) com modelo logístico de NEET**

Pipeline reprodutível em R para diagnóstico, descrição e modelagem da situação educacional e ocupacional dos jovens brasileiros, com aderência às agendas de **Educação Profissional Tecnológica** e **Inclusão Produtiva** da Fundação Itaú para Educação e Cultura.

![R](https://img.shields.io/badge/R-4.3.0-blue)
![renv](https://img.shields.io/badge/deps-renv-2C7BB6)
![targets](https://img.shields.io/badge/pipeline-targets-1A8260)
![survey](https://img.shields.io/badge/svydesign-PNAD-orange)
![license](https://img.shields.io/badge/license-MIT-lightgrey)

---

## Por que este projeto

Demonstrar um **fluxo completo e auditável** de processamento de microdados oficiais brasileiros, alinhado às práticas exigidas em consultorias técnicas para fundações e órgãos públicos:

- **Download programático** via pacote oficial (`PNADcIBGE`), com cache local;
- **Limpeza e enriquecimento** com variáveis derivadas relevantes (NEET, conclusão EM, vínculo formal);
- **Análise exploratória sistemática** antes da modelagem — validação cruzada com literatura consolidada (IBGE/IPEA);
- **Plano amostral correto** (`survey::svydesign`) — pesos + UPAs + estratos, com tratamento de estratos singleton;
- **Diagnóstico sistemático** de qualidade (missings, estrutura amostral, validação populacional, sanidade lógica);
- **Modelagem estatística populacional** com `survey::svyglm` (logit ponderado);
- **Relatórios narrativos** em Quarto, com decisões metodológicas documentadas;
- **Anonimização e LGPD** explícitas;
- **Reprodutibilidade** garantida por `renv.lock` (97 dependências travadas).

## Eixos do TR cobertos

- **Acesso, permanência e conclusão dos jovens** (variável `concluiu_em` + análise por faixa etária)
- **Inclusão Produtiva** (variável `NEET` + ocupação formal/informal + análise interseccional)

## Estrutura do repositório

```
portfolio-r-educacao/
├── R/                          # scripts numerados (setup → download → clean → analysis)
│   ├── 00_setup.R             # paths, logger, constantes
│   ├── 01_download_pnadc.R    # download via PNADcIBGE
│   ├── 02_clean_pnadc.R       # filtragem + variáveis derivadas + survey design
│   ├── 04_descritivas.R       # 5 figuras-chave com pesos amostrais
│   ├── 05_modelo_neet.R       # logit ponderado via svyglm
│   ├── 06_diagnostico_base.R  # skimr + missings + validação IBGE + sanidade
│   └── utils_anonimizacao.R   # supressão k<5
├── data/
│   ├── raw/                   # cache local da PNAD (não versionado)
│   ├── processed/             # painel limpo em CSV/RDS (não versionado)
│   └── dicionarios/           # dicionários de variáveis em CSV
├── outputs/
│   ├── figures/               # PNG das descritivas
│   ├── tables/                # CSV/xlsx dos resultados
│   └── reports/               # Quarto (.qmd) → HTML autocontido
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
- `relatorio_analise.html` — descritivas + modelo logit ponderado de NEET.

## Pipeline (visão de alto nível)

```
pnadc_raw ──► painel_jovens ──► desenho_pnadc ──► modelo_neet ─► tabela_coefs
                            │
                            ├──► diagnostico
                            ├──► figuras
                            ├──► relatorio_diagnostico (Quarto)
                            └──► relatorio_analise (Quarto)
```

## Resultados principais

> *Detalhes completos em `outputs/reports/relatorio_analise.html` (renderizado neste repositório).*

- **Taxa de NEET nacional: 20,4%** (estimativa populacional ponderada pelos pesos amostrais) entre jovens 15-29 — n = 98.538 amostrados, representando 47,4 milhões de pessoas. Validação cruzada com IBGE: −1,2% de diferença, dentro de ±5%. A taxa amostral bruta (sem ponderação) é 22,4% — diferença de ~2 p.p. que ilustra a importância de aplicar o plano amostral.
- **Padrão etário em U invertido**: NEET de **5,3% (15-17)** → **27,8% (18-24, pico)** → **25,8% (25-29)**. A transição escola-trabalho 18-24 é o gargalo crítico.
- **Diferença marcante por sexo**: mulheres 29,0% vs. homens 15,9% (gap de 13 p.p.). Limitação conceitual da PNAD: trabalho doméstico não remunerado não é classificado como ocupação.
- **Conclusão do EM** é um obstáculo persistente: **~30% dos jovens 25-29 não concluíram** o Ensino Médio.
- **Modelo logit ponderado** (`svyglm`): mulheres têm chance ~120% maior de NEET que homens; jovens indígenas e pardos têm as maiores chances de NEET por raça; concluir o EM reduz a chance em ~10%. Todos os efeitos significativos a p < 0,001.

## Decisões metodológicas

Documentadas em [docs/metodologia.md](docs/metodologia.md):

- Por que PNAD Contínua e não Censo Escolar atual;
- Definição operacional de NEET, conclusão EM, vínculo formal;
- Por que `survey::svyglm` (e não `glm` ou `fixest`);
- Tratamento de missings;
- Anonimização (LGPD).

## Limitações conhecidas

- Dados **cross-sectional** (um trimestre) — não permitem inferência causal pura, apenas associações.
- **Trabalho doméstico não remunerado** não é classificado como ocupação pela PNAD, o que pode **inflar artificialmente a NEET feminina**.
- Análise é **nacional** — recortes mais finos (município, microrregião) ficam para Fase 2.

## Roadmap (Fase 2)

1. **Painel longitudinal PNADc** (estrutura rotativa de 5 visitas/domicílio) — análise de transições NEET ↔ ocupado.
2. **Censo Escolar agregado por escola** — perfil das escolas que oferecem EM em SP.
3. **RAIS** — validação da inserção formal por registro administrativo.
4. **DiD: Novo Ensino Médio sobre IDEB/SAEB** — avaliação de impacto causal.
5. **Dashboard Quarto estático** (GitHub Pages).

## Fontes

- IBGE. *PNAD Contínua, 4ºT 2023*. Acesso via pacote R [`PNADcIBGE`](https://cran.r-project.org/web/packages/PNADcIBGE/).
- Detalhes em [docs/fontes.md](docs/fontes.md).

## Autor

**Samuel Volpe** — Data Dashboards
samuel.volpe@datadashboards.com.br

## Licença

MIT — veja [LICENSE](LICENSE).
