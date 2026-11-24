-- 04_validacao
-- Nome: Maria Eduarda Marques da Silva
-- Banco de dados: PostgreSQL
-- Período principal de validação: fevereiro de 2025

-- 1. CONFERÊNCIA DA QUANTIDADE DE REGISTROS IMPORTADOS
-- Totais esperados: fornecedor 20, produtos_filial 20,
-- pedido_compra 29, entradas_mercadoria 20 e venda 33.

SELECT 'fornecedor' AS tabela, COUNT(*) AS total FROM fornecedor
UNION ALL
SELECT 'produtos_filial', COUNT(*) FROM produtos_filial
UNION ALL
SELECT 'pedido_compra', COUNT(*) FROM pedido_compra
UNION ALL
SELECT 'entradas_mercadoria', COUNT(*) FROM entradas_mercadoria
UNION ALL
SELECT 'venda', COUNT(*) FROM venda;


-- 2. VENDAS DE FEVEREIRO DE 2025 POR PRODUTO
-- Compara quantidade vendida e valor total.
-- LEFT JOIN permite identificar vendas sem cadastro correspondente.

SELECT
    v.produto_id,
    p.descricao,
    SUM(v.qtde_vendida) AS quantidade_vendida,
    ROUND(SUM(v.qtde_vendida * v.valor_unitario), 2) AS valor_total
FROM venda AS v
LEFT JOIN produtos_filial AS p
    ON p.produto_id = v.produto_id
   AND p.filial_id = v.filial_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao < DATE '2025-03-01'
GROUP BY v.produto_id, p.descricao
ORDER BY v.produto_id;


-- 3. PEDIDOS COM QUANTIDADE PENDENTE

SELECT
    pedido_id,
    ordem_compra,
    produto_id,
    descricao_produto,
    qtde_pedida,
    qtde_entregue,
    COALESCE(qtde_pedida, 0) - COALESCE(qtde_entregue, 0)
        AS quantidade_pendente
FROM pedido_compra
WHERE COALESCE(qtde_pedida, 0) > COALESCE(qtde_entregue, 0)
ORDER BY pedido_id;


-- 4. PEDIDOS COM DATAS INCONSISTENTES
-- Data de entrega anterior à data do pedido.

SELECT
    pedido_id,
    produto_id,
    data_pedido,
    data_entrega
FROM pedido_compra
WHERE data_pedido IS NOT NULL
  AND data_entrega IS NOT NULL
  AND data_entrega < data_pedido
ORDER BY pedido_id;


-- 5. PEDIDOS SEM NÚMERO DE ORDEM DE COMPRA VÁLIDO
-- O valor zero é tratado como possível ausência de identificação.

SELECT
    pedido_id,
    produto_id,
    descricao_produto,
    ordem_compra
FROM pedido_compra
WHERE ordem_compra IS NULL
   OR ordem_compra = 0
ORDER BY pedido_id;


-- 6. ENTRADAS DE MERCADORIA SEM PEDIDO DE COMPRA CORRESPONDENTE
-- A relação indicada no enunciado é feita pelo campo ordem_compra.

SELECT
    e.ordem_compra,
    e.nro_nfe,
    e.produto_id,
    e.qtde_recebida
FROM entradas_mercadoria AS e
WHERE NOT EXISTS (
    SELECT 1
    FROM pedido_compra AS p
    WHERE p.ordem_compra = e.ordem_compra
      AND p.ordem_compra <> 0
)
ORDER BY e.ordem_compra, e.produto_id;


-- 7. VENDAS CUJO PRODUTO NÃO ESTÁ CADASTRADO NA MESMA FILIAL

SELECT
    v.venda_id,
    v.data_emissao,
    v.produto_id,
    v.filial_id,
    v.qtde_vendida
FROM venda AS v
LEFT JOIN produtos_filial AS p
    ON p.produto_id = v.produto_id
   AND p.filial_id = v.filial_id
WHERE p.produto_id IS NULL
ORDER BY v.data_emissao, v.produto_id;


-- 8. CONFERÊNCIA DOS VÍNCULOS NUMÉRICOS DE FORNECEDORES

SELECT
    p.produto_id,
    p.idfornecedor,
    p.idfornecedor_num,
    f.razao_social
FROM produtos_filial AS p
LEFT JOIN fornecedor AS f
    ON f.idfornecedor = p.idfornecedor
   AND f.idfornecedor_num = p.idfornecedor_num
WHERE f.idfornecedor IS NULL
ORDER BY p.produto_id;


-- 9. RESUMO GERAL DAS VENDAS DE FEVEREIRO DE 2025

SELECT
    COUNT(*) AS quantidade_de_lancamentos,
    COALESCE(SUM(qtde_vendida), 0) AS quantidade_total_vendida,
    ROUND(COALESCE(SUM(qtde_vendida * valor_unitario), 0), 2)
        AS valor_total_vendido
FROM venda
WHERE data_emissao >= DATE '2025-02-01'
  AND data_emissao < DATE '2025-03-01';

