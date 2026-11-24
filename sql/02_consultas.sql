-- 02_consultas
-- Nome: Maria Eduarda Marques da Silva
-- Banco de dados: PostgreSQL


-- CONSULTA 1: Consumo por produto em fevereiro de 2025
-- Apresenta a quantidade total vendida e o valor total por produto.

SELECT
    v.produto_id,
    MAX(p.descricao) AS descricao_produto,
    SUM(v.qtde_vendida) AS quantidade_total_vendida,
    ROUND(SUM(v.qtde_vendida * v.valor_unitario), 2) AS valor_total_vendido
FROM venda AS v
LEFT JOIN produtos_filial AS p
    ON p.produto_id = v.produto_id
   AND p.filial_id = v.filial_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao < DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY v.produto_id;


-- CONSULTA 2: Produtos com requisição pendente
-- Lista os pedidos cuja quantidade entregue é menor que a quantidade pedida.

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
ORDER BY produto_id, pedido_id;
