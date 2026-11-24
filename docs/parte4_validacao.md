# Parte 4 —Roteiro de Validação com o Cliente (Fevereiro de 2025)

## 1. Pontos a validar

### Abertura e Alinhamento de Escopo (10 min)
- Apresentar a arquitetura implantada e confirmar que 100% dos registros das 5 abas (`fornecedor`, `produtos_filial`, `pedido_compra`, `entradas_mercadoria` e `venda`) foram carregados sem perda silenciosa.

### Bloco 1: Fechamento Comercial de Fevereiro de 2025 (15 min)
- Validar com o gestor comercial os números consolidados de **quantidade vendida** e **faturamento bruto (R$)** por produto e por filial no período de `01/02/2025` a `28/02/2025` (Consulta 1 de `sql/04_validacao.sql`).
- Confirmar o tratamento dos **produtos `P21` a `P28`** e das **filiais `2` e `3`**, que possuem vendas registradas em fevereiro e março de 2025, mas ainda não constam no cadastro mestre `produtos_filial` (Consulta 2).

### Bloco 2: Compras, Recebimentos e Estoque (15 min)
- Revisar a lista de **pedidos pendentes / não recebidos** vinculados via `ordem_compra` e validar se as ordens de compra zeradas (`ordem_compra = 0`, pedidos 19 a 29) são requisições internas ainda não aprovadas ou erros de exportação do ERP legado (Consultas 4 e 5).
- Validar as divergências entre `qtde_entregue` informada no pedido de compra e `qtde_recebida` registrada nas Notas Fiscais de Entrada (ex.: `ordem_compra = 1` com 96 unidades pedidas, 10 apontadas no pedido e 77 recebidas na `NFE1`).

### Bloco 3: Saneamento de Cadastro e Regras de Negócio (10 min)
- Confirmar a padronização dos códigos de fornecedor (`F1..F20` vs. numérico `1..20`) e a ativação da trigger de geração automática de `idfornecedor` para novos produtos.
- Validar com a área de precificação os itens com `preco_venda < preco_compra` (ex.: `P1`, `P6`, `P7`, `P8`, `P11`, `P15`, `P18`) para confirmar se são promoções/queima de estoque ou inversão de colunas na planilha original (Consulta 6).

## 2. Técnicas Utilizadas para Garantir Exatidão e Precisão dos Dados
1. **Reconciliação Volumétrica (`COUNT` Origem vs. Destino):** Conferência automatizada linha a linha comparando o total de registros de cada aba do Excel com `SELECT COUNT(*)` no banco após o commit.
2. **Integridade Referencial e Chaves Compostas:** Definição de chaves primárias compostas nas tabelas transacionais e chave estrangeira entre `produtos_filial` e `fornecedor`, impedindo duplicidade de lançamentos em reprocessamentos (`ON CONFLICT DO NOTHING`).
3. **Tipagem Numérica Exata (`NUMERIC(12, 4)`):** Conversão de campos monetários de ponto flutuante (`float8`) para decimal de precisão fixa, eliminando dízimas de arredondamento em fechamentos financeiros.
4. **Saneamento Estrutural Pré-Carga:** Remoção de colunas deslocadas (`Unnamed: 12..22`) em `pedido_compra` e normalização unificada de datas (`excel_para_data`).
5. **Auditoria por Exceção (Queries de Diagnóstico):** Execução de consultas dedicadas em `sql/04_validacao.sql` para isolar anomalias temporais, financeiras e de vínculo antes da virada para produção.

## 3. Lista Completa de Erros Encontrados nos Dados e Consultas de Evidência

Todas as consultas abaixo estão salvas em **`sql/04_validacao.sql`**:

| # | Categoria do Erro | Descrição Detalhada da Anomalia | Consulta em `sql/04_validacao.sql` |
| :---: | :--- | :--- | :--- |
| **1** | **Integridade Referencial (Vendas)** | 13 registros de venda (`venda_id` 21 a 33) referenciam produtos (`P21` a `P28`) e filiais (`2` e `3`) inexistentes na tabela `produtos_filial`. | **Consulta 2** (`LEFT JOIN ... WHERE pf.produto_id IS NULL`) |
| **2** | **Inconsistência Temporal (Compras)** | 12 pedidos de compra apresentam `data_entrega` anterior à própria `data_pedido` (ex.: `pedido_id = 6`, pedido em `22/02/2025` e entrega em `05/01/2025`). | **Consulta 3** (`WHERE data_entrega < data_pedido`) |
| **3** | **Divergência de Quantidades (Pedido vs. NFe)** | Em todas as 20 ordens de compra com NFe, a `qtde_entregue` registrada em `pedido_compra` diverge da `qtde_recebida` em `entradas_mercadoria` (inclusive com recebimentos acima da `qtde_pedida`, como na `ordem_compra = 2`: 14 pedidas vs. 64 recebidas). | **Consulta 4** (`HAVING COALESCE(SUM(em.qtde_recebida), 0) <> pc.qtde_entregue`) |
| **4** | **Chave de Vínculo Zerada e Colunas Deslocadas** | Os pedidos de compra `19` a `29` possuem `ordem_compra = 0` e `qtde_entregue = 0`, impedindo vínculo com `entradas_mercadoria`. Além disso, na planilha original, os pedidos `21` a `29` tinham dados duplicados deslocados nas colunas `Unnamed: 12` a `Unnamed: 22`. | **Consulta 5** (`WHERE ordem_compra = 0`) |
| **5** | **Anomalia de Precificação (Margem Negativa)** | 7 produtos em `produtos_filial` (`P1`, `P6`, `P7`, `P8`, `P11`, `P15`, `P18`) possuem `preco_venda` inferior ao `preco_compra` (ex.: `P1` com compra a R$ 144,13 e venda a R$ 40,79). | **Consulta 6** (`WHERE preco_venda < preco_compra`) |
| **6** | **Padronização de Chaves de Fornecedor** | As tabelas `fornecedor` e `produtos_filial` utilizam o prefixo alfanumérico `'F1'`..`'F20'`, enquanto `pedido_compra` armazena apenas o número inteiro `1`..`20`. | **Consulta 7** (`ON f.idfornecedor = 'F' \|\| pc.fornecedor_id::text`) |
| **7** | **Erros Estruturais no DDL e Script Legado** | Coluna `ordem_compra` ausente em `entradas_mercadoria`, erros de grafia (`decricao`, `idfonecedor`, `idforncedor`), vírgula faltante antes de `CONSTRAINT`, PKs apontando para colunas inexistentes (`idproduto`) e falha de conversão de `Timestamp` no `importar.py`. | Documentado em `docs/parte1_importacao.md` e corrigido em `sql/01_ddl_*.sql` |