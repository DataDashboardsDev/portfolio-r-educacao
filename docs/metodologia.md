# Decisões metodológicas

Este documento registra as **decisões metodológicas** do projeto, com a respectiva justificativa. Decisões metodológicas precisam ser explícitas: qualquer revisor (interno ou externo) deve ser capaz de reproduzir os resultados e contestar premissas com clareza.

## 1. Escolha da base — PNAD Contínua

Após avaliação técnica das três bases citadas pelo TR (Censo Escolar, RAIS, PNAD Contínua), optou-se pela **PNAD Contínua** como base primária do projeto-demonstração.

| Critério | Censo Escolar | RAIS | PNAD Contínua |
|----------|--------------|------|----------------|
| Granularidade individual | Só agregada por escola desde 2015 (publicação aberta) | Sim, mas exige solicitação ao MTE | **Sim, pública e por pessoa** |
| Acesso programático | Manual (zip) | Manual + termo de uso | **Pacote oficial `PNADcIBGE`** |
| Cobertura de ocupação | Não | Só formal | **Formal + informal + desocupação + NEET** |
| Permite análise interseccional | Limitada | Sim | **Sim (sexo, raça, região, escolaridade)** |
| Tempo de execução | Alto (download e tratamento) | Muito alto | **Baixo (pacote nativo)** |

A PNAD Contínua atende com folga aos **eixos 2 e 5 do TR** (Acesso/Permanência/Conclusão e Inclusão Produtiva) e permite análise individual com pesos amostrais — superior ao Censo Escolar atual (que perdeu microdado de aluno).

## 2. Recorte analítico

| Decisão | Justificativa |
|---------|---------------|
| **Faixa etária 15-29 anos** | Definição padrão de "juventude" no Brasil (Estatuto da Juventude, Lei 12.852/2013) e padrão da OCDE para indicadores NEET. |
| **4º trimestre de 2023** | Visita anual da PNAD com módulo de **Educação** (acesso, frequência, conclusão). |
| **Variável-resposta NEET** | "Not in Education, Employment or Training" — indicador internacional adotado pela OCDE e pelo IBGE. Operacionalizado como `estudando == 0 & ocupado == 0`. |

## 3. Plano amostral

A PNAD Contínua tem **amostragem complexa em 3 estágios**:

1. **UPA (Unidade Primária de Amostragem)** — setor censitário sorteado dentro do estrato
2. **Domicílio** — sorteado dentro da UPA
3. **Pessoa** — todos os moradores são entrevistados

Com **estratificação** por região, capital, densidade demográfica, etc.

**Implicação prática:** qualquer estatística para a população exige uso do `survey::svydesign()` com:
- `weights = ~v1028` (peso da pessoa)
- `ids = ~upa`
- `strata = ~estrato`
- `nest = TRUE` (UPAs aninhadas em estratos)

Análises ingênuas (média simples, sem pesos) **produzem estimativas viesadas** das taxas populacionais.

## 4. Modelo logit com survey design

### Por que `survey::svyglm` em vez de `glm` ou `fixest::feglm`?

A PNAD tem **pesos amostrais não inteiros** e **clusterização** (pessoas dentro de UPAs não são independentes). Modelos padrão produzem:

- **Coeficientes possivelmente enviesados** (se os pesos refletem prob. de seleção informativa)
- **Erros padrão fortemente subestimados** (ignorar cluster infla artificialmente significância)

`svyglm` resolve isso integrando o desenho amostral ao processo de estimação.

### Por que `quasibinomial` em vez de `binomial`?

`svyglm` com pesos não inteiros exige `family = quasibinomial(link = "logit")` — é exigência técnica do pacote, não escolha analítica. Os coeficientes são idênticos a um logit; só a função de variância é mais flexível.

## 5. Variáveis derivadas

Todas as variáveis derivadas estão documentadas em `data/dicionarios/dicionario_derivadas.csv`. Decisões importantes:

- **`concluiu_em`**: derivada de `VD3004 >= 5` (Médio completo). Não exige conclusão do superior — apenas EM.
- **`formal`**: posições 1, 3, 5, 7 (CLT, militar, estatutário, conta-própria contribuinte). Demais códigos são tratados como informal.
- **`estudando`**: 1 se `V3002 == 1` (frequenta escola/curso); **NA tratado como 0** (não-estudante). Esta escolha é conservadora e segue a definição operacional padrão da OCDE para a métrica NEET.
- **`ocupado`**: 1 se `VD4002 == 1` (Ocupado); **NA tratado como 0**. NA na PNAD aqui significa "fora da força de trabalho" (pessoa não-PIA ou não-respondente da seção ocupacional) — para a definição OCDE de NEET, essa pessoa **não está ocupada** e portanto a codificação como 0 é correta.
- **`NEET`**: variável-resposta principal. Operacionalizada como `estudando == 0 & ocupado == 0` após os tratamentos acima. Por convenção da OCDE, **não inclui trabalho doméstico não remunerado como "ocupação"** — o que pode inflar artificialmente a NEET feminina (limitação conceitual documentada no relatório).

### Sobre o tratamento de NA em `estudando` e `ocupado`

A primeira versão do código tratava `estudando == 0 & ocupado == 0` com NA propagado, o que produzia taxa de NEET amostral de apenas **5,3%** — incompatível com a literatura (~20%). O motivo: pessoas com `ocupado = NA` (fora da força de trabalho) eram excluídas do cálculo de NEET, quando na verdade deveriam contar como **não-ocupadas**.

Após correção (NA → 0), a taxa amostral bruta passou para **22,4%**, e a estimativa populacional ponderada chegou a **20,4%** — ambas dentro da faixa esperada de 19-22% para o 4ºT 2023. A diferença de ~17 p.p. entre a codificação errada e a correta ilustra a importância de validar definições operacionais contra a literatura **antes** da modelagem — princípio aplicado neste projeto via análise exploratória sistemática prévia ao `svyglm`.

### Sobre ponderação amostral nas taxas reportadas

Os números reportados nos relatórios distinguem dois tipos de estimativa:

- **Amostral bruta** — calculada com `mean()` ou `prop.table()` sem pesos. Útil para checagens internas e diagnóstico. Não representa a população.
- **Populacional ponderada** — calculada com `svymean()` ou `svytotal()` aplicando o desenho amostral (`weights = v1028`, `ids = upa`, `strata = estrato`). É a estimativa válida para relatórios oficiais.

A diferença entre as duas (no nosso caso, 22,4% vs. 20,4%) reflete o fato de a amostra **não ser representativa por construção** — jovens em domicílios com peso maior (geralmente rurais) têm padrão diferente dos com peso menor (urbanos/capital). Ignorar isso enviesa estimativas em ~2 p.p. neste recorte.

## 6. Tratamento de missings

- Variáveis ocupacionais (VD4002, VD4009) têm missing **por design** — só aplicável a pessoas em idade ativa que responderam à seção.
- Pessoas com missing nas variáveis-chave do modelo (`neet`, `idade`, `sexo`, `cor_raca`, `regiao`, `concluiu_em`) são **excluídas** do modelo via `subset(desenho, validos)` — preservando a estrutura amostral.
- Variáveis com **>20% de missing** seriam excluídas, mas no recorte atual nenhuma das variáveis usadas no modelo excede 5%.

## 7. Anonimização (LGPD)

- A PNAD publicada pelo IBGE **já é anonimizada** — não há identificadores nominais, apenas códigos amostrais.
- Mesmo assim, células com **n < 5** em qualquer agregação publicável são suprimidas (`utils_anonimizacao.R::suprimir_celulas_pequenas`).
- O painel processado contém apenas códigos UPA/estrato — não dá pra re-identificar indivíduos.

## 8. Validação cruzada

O pipeline produz `outputs/tables/diag_validacao_ibge.csv` comparando a **população estimada** (soma dos pesos) com a **referência oficial do IBGE** para o trimestre. Diferenças até ±5% são aceitas.

A `tabela_sanidade.csv` valida as taxas estimadas contra a literatura consolidada (IPEA, IBGE), garantindo que o pipeline reproduz ordens de grandeza esperadas.

## 9. Estrutura computacional

- **`renv`** trava versões exatas dos pacotes — reprodutibilidade idêntica.
- **`targets`** orquestra o pipeline; só re-roda etapas cujos inputs mudaram.
- **`here`** torna o projeto portátil entre máquinas (Windows, Linux, macOS).
- **Microdados** ficam em `data/raw/` (não versionados); processados em `data/processed/` (também não versionados mas reprodutíveis via `tar_make()`).
