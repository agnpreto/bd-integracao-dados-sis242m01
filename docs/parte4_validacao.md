# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

## 1. Pontos a validar
- **Volume e faturamento de fevereiro/2025:** Conferir com o fechamento financeiro do cliente as 14 vendas realizadas em fevereiro de 2025 (162,22 unidades vendidas, somando R$ 12.192,41), das quais 6 vendas referem-se a produtos não cadastrados (`P22` a `P27`).
- **Integridade cadastral de produtos, filiais e fornecedores:** Validar as 13 vendas de produtos inexistentes em `produtos_filial` (`P21` a `P28`, incluindo vendas nas filiais `2` e `3` não cadastradas) e a divergência de padrão nos códigos de fornecedores (`fornecedor_id` numérico `1` a `20` em `pedido_compra` contra `'F1'` a `'F20'` em `fornecedor`).
- **Conciliação entre compras, datas e entradas de NFe:** Revisar as 2 notas fiscais (`NFE19` e `NFE20`) cujas ordens de compra (`19` e `20`) não constam em `pedido_compra`, os 11 pedidos com `ordem_compra = 0`, os 20 pedidos com `data_entrega < data_pedido` e os 17 pedidos em que a `qtde_entregue` diverge da `qtde_recebida` na NFe.

## 2. Técnicas para garantir exatidão e precisão
- **Batimento de totais (Reconciliação):** Comparação direta entre contagens (`COUNT`) e somatórios (`SUM`) da planilha original `base_teste.xlsx` e os registros carregados no PostgreSQL.
- **Auditoria de integridade referencial:** Uso de consultas com `LEFT JOIN ... WHERE chave IS NULL` para identificar registros órfãos entre vendas, produtos, pedidos, entradas e fornecedores.
- **Validação de domínio e consistência temporal:** Verificação de quantidades fracionadas em unidade `'UN'`, preços de venda abaixo do preço de compra (`preco_venda < preco_compra`) e datas invertidas (`data_entrega < data_pedido`).

## 3. Consultas preparadas para a reunião
- **Consulta 1 (`sql/04_validacao.sql`):** Lista vendas cujo `produto_id`/`filial_id` não possui cadastro em `produtos_filial` (retorna 8 grupos de produtos, `P21` a `P28`, totalizando 13 vendas).
- **Consulta 2 (`sql/04_validacao.sql`):** Verifica vínculos de fornecedores entre as tabelas (0 órfãos em `produtos_filial`, mas 29 pedidos em `pedido_compra` com `fornecedor_id` numérico `1..20` sem o prefixo `'F'`).
- **Consulta 3 (`sql/04_validacao.sql`):** Mostra notas fiscais em `entradas_mercadoria` cuja `ordem_compra` não existe em `pedido_compra` (retorna 2 registros: `NFE19` e `NFE20`).
- **Consulta 4 (`sql/04_validacao.sql`):** Audita anomalias de quantidades e preços (0 vendas `<= 0`, mas 5 vendas com quantidade decimal para unidade `'UN'` e 4 produtos com `preco_venda < preco_compra`).
- **Consulta 5 (`sql/04_validacao.sql`):** Aponta pedidos de compra com `data_entrega` anterior à `data_pedido` (retorna 20 registros).
- **Consulta 6 (`sql/04_validacao.sql`):** Exibe o consolidado de vendas e faturamento de fevereiro de 2025 (14 vendas, 162,22 unidades e R$ 12.192,41).

## Erros encontrados nos dados

| Tabela | Problema | Quantidade | Consulta que mostra |
| :--- | :--- | :--- | :--- |
| venda | Vendas de produtos/filiais sem cadastro correspondente em `produtos_filial` (`P21` a `P28`, filiais 1, 2 e 3) | 13 registros de venda (8 produtos distintos) | Consulta 1 (`sql/04_validacao.sql`) |
| produtos_filial / pedido_compra | `idfornecedor` em `produtos_filial` sem cadastro (`0`) e `fornecedor_id` em `pedido_compra` numérico (`1` a `20`) divergente do código `'F1'` a `'F20'` | 0 em `produtos_filial` / 29 em `pedido_compra` | Consulta 2 (`sql/04_validacao.sql`) |
| entradas_mercadoria | Notas fiscais (`NFE19` e `NFE20`) cuja `ordem_compra` (`19` e `20`) não existe em `pedido_compra` (onde os pedidos 19 a 29 estão com `ordem_compra = 0`) | 2 registros em `entradas_mercadoria` (e 11 pedidos com `ordem_compra = 0`) | Consulta 3 (`sql/04_validacao.sql`) |
| venda / produtos_filial | Vendas com valor/qtde `<= 0` (`0`), vendas com quantidade decimal em unidade `'UN'` (`venda_id` 4, 8, 12, 16, 26) e produtos com `preco_venda < preco_compra` (`P1`, `P8`, `P15`, `P18`) | 0 (`<= 0`) / 5 vendas fracionadas em `'UN'` / 4 produtos com margem negativa | Consulta 4 (`sql/04_validacao.sql`) |
| pedido_compra | Pedidos de compra com `data_entrega` anterior à `data_pedido` (`data_entrega < data_pedido`) | 20 registros | Consulta 5 (`sql/04_validacao.sql`) |
| pedido_compra / entradas_mercadoria | Divergência entre `qtde_entregue` registrada no pedido de compra e `qtde_recebida` na NFe de entrada (ordens 1 a 18, exceto ordem 9) | 17 registros | Consulta complementar (`sql/02_consultas.sql` / `sql/04_validacao.sql`) |