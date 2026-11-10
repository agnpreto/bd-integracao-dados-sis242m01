-- 02_consultas
-- Nome: Izabelly Cantalice

-- 1. Consumo por produto e mês (fevereiro de 2025):
SELECT
    v.produto_id,
    pf.descricao AS descricao_produto,
    SUM(v.qtde_vendida) AS total_quantidade_vendida,
    ROUND(SUM(v.qtde_vendida * v.valor_unitario)::numeric, 2) AS valor_total_reais
FROM public.venda v
LEFT JOIN public.produtos_filial pf
    ON pf.produto_id = v.produto_id
   AND pf.filial_id = v.filial_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id, pf.descricao
ORDER BY valor_total_reais DESC;

-- 2. Produtos requisitados, mas não recebidos (ou com entrega pendente):
SELECT
    pc.pedido_id,
    pc.ordem_compra,
    pc.produto_id,
    pc.descricao_produto,
    pc.data_pedido,
    pc.qtde_pedida,
    pc.qtde_entregue,
    pc.qtde_pendente,
    COALESCE(SUM(em.qtde_recebida), 0) AS qtde_recebida_nfe
FROM public.pedido_compra pc
LEFT JOIN public.entradas_mercadoria em
    ON em.ordem_compra = pc.ordem_compra
   AND em.produto_id = pc.produto_id
GROUP BY
    pc.pedido_id, pc.ordem_compra, pc.produto_id,
    pc.descricao_produto, pc.data_pedido,
    pc.qtde_pedida, pc.qtde_entregue, pc.qtde_pendente
HAVING pc.qtde_entregue = 0
    OR pc.qtde_pendente > 0
    OR COALESCE(SUM(em.qtde_recebida), 0) < pc.qtde_pedida
ORDER BY pc.data_pedido, pc.produto_id;