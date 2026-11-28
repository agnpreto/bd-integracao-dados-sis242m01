-- 02_consultas  
-- Nome: Mikael Coelho Ramos e Kauã Monteiro Coelho

-- CONSULTA 1 - Consumo por produto e mês
SELECT v.produto_id AS produto_id,
       COALESCE(d.descricao, '(produto sem cadastro)') AS descricao,
       SUM(v.qtde_vendida) AS qtde_vendida,
       CAST(SUM(v.qtde_vendida * v.valor_unitario) AS DECIMAL(14,2)) AS valor_vendido_rs
FROM venda v
LEFT JOIN (SELECT produto_id, MIN(descricao) AS descricao
           FROM produtos_filial
           GROUP BY produto_id) d ON d.produto_id = v.produto_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id, d.descricao
ORDER BY LENGTH(v.produto_id), v.produto_id; 

-- CONSULTA 2 - Produtos com requisição pendente (requisitados, mas não recebidos)
SELECT p.pedido_id,
       p.item,
       p.produto_id,
       p.descricao_produto,
       p.data_pedido,
       p.ordem_compra,
       p.qtde_pedida,
       p.qtde_pendente
FROM pedido_compra p
WHERE NOT EXISTS (SELECT 1
                  FROM entradas_mercadoria e
                  WHERE e.ordem_compra = p.ordem_compra
                    AND e.produto_id   = p.produto_id
                    AND e.item         = p.item)
ORDER BY p.pedido_id;


