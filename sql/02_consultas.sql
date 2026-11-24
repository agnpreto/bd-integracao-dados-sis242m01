-- 02_consultas
-- Nome: Emilly Melissa e Bruna Muro

SELECT
    v.produto_id,
    COALESCE(MAX(pf.decricao), MAX(pc.descricao_produto), 'Sem descricao') AS descricao_produto,
    SUM(v.qtde_vendida) AS quantidade_vendida,
    SUM(v.qtde_vendida * v.valor_unitario) AS valor_total_reais
FROM public.venda v
LEFT JOIN public.produtos_filial pf
       ON pf.idproduto = v.produto_id
      AND pf.filial_id = v.filial_id
LEFT JOIN public.pedido_compra pc
       ON pc.produto_id = v.produto_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY valor_total_reais DESC NULLS LAST;

WITH entradas_por_ordem AS (
    SELECT
        ordem_compra,
        produto_id,
        item,
        SUM(qtde_recebida) AS total_recebido
    FROM public.entradas_mercadoria
    GROUP BY ordem_compra, produto_id, item
)
SELECT
    pc.ordem_compra,
    pc.pedido_id,
    pc.item,
    pc.produto_id,
    COALESCE(NULLIF(TRIM(pc.descricao_produto), ''), pf.decricao, 'Sem descricao') AS descricao_produto,
    pc.data_pedido,
    pc.data_entrega,
    pc.qtde_pedida,
    pc.qtde_entregue,
    pc.qtde_pendente,
    COALESCE(eo.total_recebido, 0) AS qtde_recebida_entradas
FROM public.pedido_compra pc
LEFT JOIN entradas_por_ordem eo
       ON eo.ordem_compra = pc.ordem_compra
      AND eo.produto_id   = pc.produto_id
      AND eo.item         = pc.item
LEFT JOIN public.produtos_filial pf
       ON pf.idproduto = pc.produto_id
      AND pf.filial_id = pc.filial_id
WHERE COALESCE(pc.qtde_pendente, 0) > 0
   OR pc.qtde_entregue < pc.qtde_pedida
   OR COALESCE(eo.total_recebido, 0) < pc.qtde_pedida
ORDER BY pc.data_pedido, pc.ordem_compra, pc.item;

