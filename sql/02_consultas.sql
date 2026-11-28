-- 02_consultas
-- Nome:Consulta sql basica

-- 1. Total vendido em quantidade e em R$ por produto no mes de fevereiro de 2025
SELECT
    v.produto_id,
    COALESCE(pf.descricao, 'Produto nao cadastrado na filial') AS descricao_produto,
    SUM(v.qtde_vendida) AS total_quantidade_vendida,
    ROUND(SUM(v.qtde_vendida * v.valor_unitario)::numeric, 2) AS total_valor_vendido_rs
FROM public.venda v
LEFT JOIN public.produtos_filial pf
    ON pf.produto_id = v.produto_id
   AND pf.filial_id = v.filial_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id, pf.descricao
ORDER BY total_valor_vendido_rs DESC;

-- 2. Produtos requisitados e nao recebidos
-- Vincula pedido_compra com entradas_mercadoria pelo campo ordem_compra
SELECT
    pc.pedido_id,
    pc.ordem_compra,
    pc.data_pedido,
    pc.filial_id,
    pc.produto_id,
    pc.descricao_produto,
    pc.qtde_pedida,
    pc.qtde_entregue,
    COALESCE(SUM(em.qtde_recebida), 0) AS qtde_recebida_nfe,
    (pc.qtde_pedida - COALESCE(SUM(em.qtde_recebida), 0)) AS saldo_nao_recebido
FROM public.pedido_compra pc
LEFT JOIN public.entradas_mercadoria em
    ON em.ordem_compra = pc.ordem_compra
   AND em.produto_id = pc.produto_id
   AND em.item = pc.item
GROUP BY
    pc.pedido_id,
    pc.ordem_compra,
    pc.data_pedido,
    pc.filial_id,
    pc.produto_id,
    pc.descricao_produto,
    pc.qtde_pedida,
    pc.qtde_entregue
HAVING COALESCE(SUM(em.qtde_recebida), 0) = 0
    OR pc.qtde_pedida > COALESCE(SUM(em.qtde_recebida), 0)
ORDER BY pc.data_pedido, pc.pedido_id;

