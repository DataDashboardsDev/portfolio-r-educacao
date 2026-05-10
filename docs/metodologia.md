# Decisões metodológicas

Este documento registra as **decisões metodológicas** tomadas no projeto, com a respectiva justificativa. Decisões metodológicas precisam ser explícitas: qualquer revisor (interno ou externo) deve ser capaz de reproduzir os resultados e contestar premissas com clareza.

## 1. Recorte do universo

| Decisão | Justificativa |
|---|---|
| **UF = São Paulo** | Maior peso demográfico no EM brasileiro (~13% das matrículas nacionais). Permite sinal estatístico claro em municípios mesmo após filtros etários. |
| **Idade 15–17 anos** | Idade "regular" para o EM segundo a normativa do MEC. Captura distorção idade-série quando combinada com etapa. |
| **Anos 2019–2023** | Inclui o período pré, durante e pós-pandemia — interessante para análise de impacto. Cinco safras dão poder para painel longitudinal. |
| **Excluir EJA** do universo principal | EJA tem dinâmica de matrícula muito distinta (entradas/saídas no meio do ano). Mantido como variável (`eja_em`) para análises de robustez. |

## 2. Variável-resposta `y_concluiu`

A definição ideal de conclusão exigiria cruzar `tp_situacao` (status final) do ano _t_ com a matrícula em ano superior em _t+1_. No MVP, usamos uma **proxy** com duas condições:

1. Matrícula em ano final do EM (3ª série regular ou 4º ano do integrado), OU
2. Idade = 17 anos (próxima da idade modal de conclusão regular).

**Limitações:** a proxy superestima conclusões (alguns 17 anos reprovam) e subestima conclusões precoces (jovens que terminam antes dos 17). Quando `tp_situacao` for incorporada na Fase 2, a definição será revista.

## 3. Modelo logit com efeitos fixos municipais

### Por que logit (e não LPM)?

A variável de interesse é binária (`y_concluiu`); o **logit** preserva a fronteira [0,1] das probabilidades preditas e é o padrão da literatura econométrica. Quando há problema de convergência com FE de alta cardinalidade, fazemos *fallback* automático para **LPM** (`fixest::feols` linear) — também válido e mais robusto.

### Por que FE de município (e não cluster)?

- FE de **município** absorve heterogeneidade não observada estrutural: qualidade da gestão municipal, recursos, perfil socioeconômico médio, mercado de trabalho local etc.
- Em SP há ~645 municípios — cardinalidade alta, mas `fixest::feglm` lida bem (usa demeaning iterativo).
- Alternativa de cluster (apenas erro padrão clusterizado) não controla o viés de variável omitida, apenas corrige inferência.

### Por que FE de ano?

Controla **choques temporais comuns** a todas as escolas paulistas (pandemia, mudanças no Novo Ensino Médio, alterações de matrícula).

## 4. Anonimização (LGPD)

- **Hash SHA-256 truncado** (12 caracteres) do código INEP da escola quando exposto publicamente.
- **Supressão de células com n < 5** em qualquer agregação publicável (`utils_anonimizacao.R::suprimir_celulas_pequenas`).
- **Nunca commitamos** microdados brutos no Git: `data/raw/` está no `.gitignore`.
- Microdados do Censo Escolar publicados pelo INEP já não contém dados nominais individuais (já vêm com IDs). Ainda assim, agregações finas podem permitir re-identificação — daí a supressão por k mínimo.

## 5. Tratamento de missings

- Variáveis com **>20% de missing** são excluídas do modelo (documentadas em `outputs/tables/diag_missings.csv`).
- Variáveis com **<5% de missing** entram com listwise deletion (registros sem valor são removidos).
- Variáveis com **5%–20% de missing** são analisadas caso a caso (a pandemia gerou padrões inesperados em algumas colunas).

## 6. Validação cruzada

Cada execução do pipeline gera `outputs/tables/diag_validacao_inep.csv`, comparando os totais observados pelo pipeline com os totais publicados pelo INEP nas Sinopses Estatísticas. Discrepâncias **maiores que ±2%** disparam revisão dos filtros antes de modelagem.

## 7. Estrutura computacional

- **renv** garante reprodutibilidade exata das versões dos pacotes.
- **targets** orquestra o pipeline; só re-roda etapas cujos inputs mudaram.
- **here** torna o projeto portátil entre máquinas (Windows, Linux, macOS).
- Microdados ficam em `data/raw/` (não versionados); resultados intermediários em `data/processed/` (também não versionados, mas reprodutíveis).
