-- Parte 4: consultas de validação com o cliente (dados de fevereiro/2025 e integridade geral)
-- V = conferências de fechamento. E = cada erro encontrado nos dados da planilha.
-- V1) Linhas por tabela. Esperado: 20, 20, 29, 20 e 33 (iguais à planilha).
SELECT 'fornecedor' AS tabela, COUNT() AS linhas FROM fornecedor
UNION ALL SELECT 'produtos_filial', COUNT() FROM produtos_filial
UNION ALL SELECT 'pedido_compra', COUNT() FROM pedido_compra
UNION ALL SELECT 'entradas_mercadoria', COUNT() FROM entradas_mercadoria
UNION ALL SELECT 'venda', COUNT(*) FROM venda;
-- V2) Fechamento de fevereiro/2025 para conferir com o cliente.
-- Esperado: 14 produtos, 14 vendas, 173,22 unidades e R$ 14.093,17.
SELECT COUNT(DISTINCT produto_id)           AS produtos,
COUNT(*)                             AS vendas,
SUM(qtde_vendida)                    AS qtde_total,
SUM(qtde_vendida * valor_unitario)   AS valor_total
FROM venda
WHERE data_emissao >= DATE '2025-02-01' AND data_emissao < DATE '2025-03-01';
-- E1) Pedidos sem ordem de compra (ordem_compra = 0): não se ligam a nenhuma entrada. Esperado: 11 (pedidos 19 a 29).
SELECT pedido_id, produto_id, ordem_compra, qtde_pedida
FROM pedido_compra
WHERE ordem_compra = 0
ORDER BY pedido_id;
-- E2) Entradas cuja ordem não existe em pedido_compra. Esperado: 2 (ordens 19 e 20).
SELECT e.ordem_compra, e.produto_id, e.nro_nfe
FROM entradas_mercadoria e
LEFT JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra
WHERE p.ordem_compra IS NULL
ORDER BY e.ordem_compra;
-- E3) Pedidos com data de entrega anterior à data do pedido. Esperado: 20.
SELECT pedido_id, produto_id, data_pedido, data_entrega
FROM pedido_compra
WHERE data_entrega < data_pedido
ORDER BY pedido_id;
-- E4) Pedidos possivelmente duplicados (mesmo produto, datas e preço). Esperado: 9 grupos (pedidos 12 e 21, 13 e 22, ..., 20 e 29).
SELECT produto_id, data_pedido, data_entrega, preco_compra,
COUNT() AS ocorrencias,
STRING_AGG(pedido_id::text, ', ' ORDER BY pedido_id) AS pedidos
FROM pedido_compra
GROUP BY produto_id, data_pedido, data_entrega, preco_compra
HAVING COUNT() > 1
ORDER BY produto_id;
-- E5) Entrada anterior à data do pedido. Esperado: 9 (ordens 6, 7, 11, 12, 13, 14, 15, 16 e 18).
SELECT e.ordem_compra, e.produto_id, p.data_pedido, e.data_entrada
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.data_entrada < p.data_pedido
ORDER BY e.ordem_compra;
-- E6) Quantidade recebida maior que a pedida. Esperado: 7 (ordens 2, 3, 5, 7, 11, 15 e 16).
SELECT e.ordem_compra, e.produto_id, p.qtde_pedida, e.qtde_recebida
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.qtde_recebida > p.qtde_pedida
ORDER BY e.ordem_compra;
-- E7) Quantidade recebida diferente da entregue registrada no pedido. Esperado: 18 (todas as ordens ligadas).
SELECT e.ordem_compra, e.produto_id, p.qtde_entregue, e.qtde_recebida
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.qtde_recebida <> p.qtde_entregue
ORDER BY e.ordem_compra;
-- E8) Custo da entrada diferente do preço do pedido. Esperado: 18 (todas as ordens ligadas).
SELECT e.ordem_compra, e.produto_id, p.preco_compra, e.custo_unitario
FROM entradas_mercadoria e
JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
WHERE e.custo_unitario <> p.preco_compra
ORDER BY e.ordem_compra;
-- E9) Fornecedor do pedido diferente do fornecedor cadastrado para o produto. Esperado: 22.
SELECT p.pedido_id, p.produto_id, p.fornecedor_id AS fornecedor_no_pedido, pf.idfornecedor AS fornecedor_no_cadastro
FROM pedido_compra p
JOIN produtos_filial pf ON pf.produto_id = p.produto_id AND pf.filial_id = p.filial_id
WHERE p.fornecedor_id <> pf.idfornecedor
ORDER BY p.pedido_id;
-- E10) Fornecedores sem nenhum produto. Esperado: 3 (14, 15 e 16).
SELECT f.idfornecedor, f.razao_social
FROM fornecedor f
LEFT JOIN produtos_filial pf ON pf.idfornecedor = f.idfornecedor
WHERE pf.idfornecedor IS NULL
ORDER BY f.idfornecedor;
-- E11) Produtos vendidos sem cadastro em produtos_filial. Esperado: 8 produtos (P21 a P28), 13 vendas.
SELECT v.produto_id, COUNT(*) AS vendas
FROM venda v
LEFT JOIN produtos_filial pf ON pf.produto_id = v.produto_id AND pf.filial_id = v.filial_id
WHERE pf.produto_id IS NULL
GROUP BY v.produto_id
ORDER BY LENGTH(v.produto_id), v.produto_id;
-- E12) Vendas em filiais sem produtos cadastrados (só a filial 1 tem). Esperado: 4 (vendas 27, 28, 32 e 33).
SELECT venda_id, filial_id, produto_id
FROM venda
WHERE filial_id NOT IN (SELECT DISTINCT filial_id FROM produtos_filial)
ORDER BY venda_id;
-- E13) Quantidade fracionada em unidade UN. Esperado: 5 (vendas 4, 8, 12, 16 e 26).
SELECT venda_id, produto_id, qtde_vendida, unidade_medida
FROM venda
WHERE unidade_medida = 'UN' AND qtde_vendida <> TRUNC(qtde_vendida)
ORDER BY venda_id;
-- E14) Vendas por mês: só fevereiro entra na validação. Esperado: 01/2025 = 12, 02/2025 = 14, 03/2025 = 7.
SELECT TO_CHAR(data_emissao, 'MM/YYYY') AS mes, COUNT(*) AS vendas
FROM venda
GROUP BY 1
ORDER BY MIN(data_emissao);
-- E15) Produtos com preço de venda menor que o de compra. Esperado: 4 (P1, P8, P15 e P18).
SELECT produto_id, descricao, preco_compra, preco_venda
FROM produtos_filial
WHERE preco_venda < preco_compra
ORDER BY LENGTH(produto_id), produto_id;
