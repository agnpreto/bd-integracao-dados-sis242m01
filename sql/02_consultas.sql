-- Parte 2: Consultas SQL básicas

-- 1) Total vendido (quantidade e R$) por produto em fevereiro de 2025
SELECT
    v.produto_id,
    SUM(v.qtde_vendida)                    AS qtde_total,
    SUM(v.qtde_vendida * v.valor_unitario) AS valor_total
FROM venda v
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY v.produto_id;

-- 2) Produtos requisitados e não recebidos
-- Interpretação: linha de pedido_compra sem nenhuma entrada em entradas_mercadoria.
-- O vínculo é a ordem_compra (e o mesmo produto). Pedidos com ordem_compra = 0
-- (dado faltando na planilha) não casam com nenhuma entrada e aparecem aqui. Ver Parte 4.
SELECT
    p.pedido_id,
    p.ordem_compra,
    p.produto_id,
    p.descricao_produto,
    p.qtde_pedida
FROM pedido_compra p
LEFT JOIN entradas_mercadoria e
       ON e.ordem_compra = p.ordem_compra
      AND e.produto_id   = p.produto_id
WHERE e.ordem_compra IS NULL
ORDER BY p.produto_id, p.pedido_id;