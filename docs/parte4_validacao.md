# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

## 1. Pontos a validar

Para dar segurança ao cliente de que os dados migrados e as consultas refletem a operação real de **fevereiro de 2025**, a validação será dividida nos seguintes pontos:

- **Período e competência (fevereiro/2025):** conferir se as vendas (`venda.data_emissao`), pedidos (`pedido_compra.data_pedido` / `data_entrega`) e entradas (`entradas_mercadoria.data_entrada`) pertencem ao recorte esperado e se não há registros fora do mês ou deslocados por problemas de data/fuso.
- **Consumo e faturamento por produto:** validar quantidade vendida (`qtde_vendida`), preço unitário (`valor_unitario`), unidade de medida (`unidade_medida`) e valor total (`qtde_vendida * valor_unitario`) em reais (R$) para cada `produto_id` e `filial_id` em fevereiro/2025.
- **Requisições e pendências de recebimento:** conferir pedidos de compra emitidos e não totalmente recebidos (`qtde_pendente > 0` ou ausência/divergência de recebimento em `entradas_mercadoria`), bem como o vínculo via `ordem_compra`, `produto_id` e `item`.
- **Cadastro de produtos por filial e fornecedores:** verificar se todos os `produto_id` movimentados existem em `produtos_filial`, se as descrições estão coerentes e se os fornecedores estão íntegros sem perda de vínculo após a padronização numérica.
- **Inconsistências e anomalias intencionais da base:** apresentar ao cliente os desvios encontrados na carga/base (como valores zerados ou negativos, divergências entre quantidade pedida/entregue/pendente, códigos de fornecedor fora do padrão numérico como `F8`/`F9`, duplicidades ou divergências de descrição) e combinar o tratamento de cada caso.

## 2. Técnicas para garantir exatidão e precisão

- **Reconciliação de totais (batimento / controle de somas):** comparar somatórios de quantidades e valores financeiros no banco com totais de referência da origem (planilha/relatório do período) para garantir completude sem perdas nem duplicações.
- **Cruzamento relacional e de chaves (anti-join / left join):** cruzar `venda` com `produtos_filial`, `pedido_compra` com `entradas_mercadoria` (via `ordem_compra`, `produto_id` e `item`) e tabelas de compras/produtos com `fornecedor` para detectar órfãos ou quebras de integridade.
- **Validação de domínio, faixa e formato:** checar se datas estão no intervalo de `2025-02-01` a `2025-02-28`, se quantidades e preços obedecem regras de negócio (ex.: evitar quantidades/valores negativos ou nulos indevidos) e se textos/códigos seguem o padrão esperado.
- **Detecção de duplicidades e granularidade:** verificar se não há repetição indevida de chaves ou eventos no mesmo timestamp/documento/item que inflacionem totais de vendas ou contagens de requisições.
- **Amostragem dirigida com o cliente:** selecionar uma amostra prática de produtos (ex.: itens com maior faturamento em fev/2025, itens com pendência de entrega e itens com ajustes de cadastro) para conferência lado a lado com a operação.

## 3. Consultas preparadas para a reunião

As consultas ficam em `sql/04_validacao.sql`. Abaixo está o que cada uma mostra na reunião com o cliente:

- **Consulta 1 (linhas 4–11) — Resumo geral das vendas e faturamento em fevereiro de 2025:** exibe o total de registros de venda, a quantidade de produtos distintos, a quantidade total vendida e o valor total em reais (`SUM(qtde_vendida * valor_unitario)`) no período de `2025-02-01` a `2025-02-28`.
- **Consulta 2 (linhas 13–29) — Consumo por produto em fevereiro de 2025:** agrupa as vendas do mês por `produto_id` (buscando descrição em `produtos_filial` ou `pedido_compra`) e mostra quantidade vendida, valor total em R$ e menor/maior valor unitário praticado.
- **Consulta 3 (linhas 31–62) — Pedidos de compra x entradas de mercadoria:** agrupa `entradas_mercadoria` por `ordem_compra`, `produto_id` e `item` e cruza com `pedido_compra` para listar pedidos com quantidade pendente, entrega menor que a pedida ou diferença entre o pedido e o total recebido nas entradas.
- **Consulta 4 (linhas 64–78) — Vendas em fevereiro de 2025 sem produto correspondente em `produtos_filial`:** faz `LEFT JOIN` de `venda` com `produtos_filial` (por `idproduto` e `filial_id`) e filtra onde `pf.idproduto IS NULL`, apontando vendas sem cadastro correspondente.
- **Consulta 5 (linhas 80–108) — Valores zerados, negativos ou divergentes em vendas e pedidos de compra:** junta via `UNION ALL` as vendas de fevereiro/2025 com quantidade nula/zerada ou valor unitário negativo e os pedidos de compra com quantidades inválidas ou onde `qtde_entregue + qtde_pendente` difere de `qtde_pedida`.
- **Consulta 6 (linhas 110–114) — Fornecedores com códigos não numéricos:** consulta `fornecedor` filtrando `idfornecedor !~ '^[0-9]+$'` para mostrar registros com identificadores não numéricos (como `F8` ou `F9`) envolvidos na padronização.

## Erros encontrados nos dados

| Tabela | Problema | Quantidade | Consulta que mostra |
| --- | --- | --- | --- |
| `venda` | Vendas em fev/2025 sem produto correspondente em `produtos_filial` | Pendente de execução após carga | Consulta 4 |
| `venda` | Quantidade vendida nula/zerada ou valor unitário negativo em fev/2025 | Pendente de execução após carga | Consulta 5 |
| `pedido_compra` / `entradas_mercadoria` | Pedidos com pendência de recebimento ou divergência entre pedido, entregue, pendente e entradas | Pendente de execução após carga | Consultas 3 e 5 |
| `fornecedor` | Códigos de fornecedor não numéricos (ex.: `F8`, `F9`) | Pendente de execução após carga | Consulta 6 |