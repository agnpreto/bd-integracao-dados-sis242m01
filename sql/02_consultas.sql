
-- 1. Consumo por produto em fevereiro de 2025

SELECT
    produto_id,
    SUM(qtde_vendida) AS total_quantidade_vendida,
    SUM(qtde_vendida * valor_unitario) AS total_vendas_reais
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao < '2025-03-01'
GROUP BY produto_id
ORDER BY produto_id;

-- Produtos requisitados, mas ainda não totalmente recebidos
SELECT
    p.ordem_compra,
    p.produto_id,
    p.descricao_produto,
    p.qtde_pedida,
    COALESCE(e.qtde_recebida, 0) AS qtde_recebida,
    p.qtde_pedida - COALESCE(e.qtde_recebida, 0) AS qtde_pendente
FROM (
    SELECT
        ordem_compra,
        produto_id,
        MAX(descricao_produto) AS descricao_produto,
        SUM(COALESCE(qtde_pedida, 0)) AS qtde_pedida
    FROM pedido_compra
    GROUP BY ordem_compra, produto_id
) p
LEFT JOIN (
    SELECT
        ordem_compra,
        produto_id,
        SUM(COALESCE(qtde_recebida, 0)) AS qtde_recebida
    FROM entradas_mercadoria
    GROUP BY ordem_compra, produto_id
) e
    ON p.ordem_compra = e.ordem_compra
   AND p.produto_id = e.produto_id
WHERE p.qtde_pedida > COALESCE(e.qtde_recebida, 0)
ORDER BY p.ordem_compra, p.produto_id;
