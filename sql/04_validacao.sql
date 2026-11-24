-- 04_validacao
-- Nome:Emilly Melissa e Bruna Muro

SELECT
    COUNT(*) AS total_registros_venda,
    COUNT(DISTINCT produto_id) AS produtos_distintos,
    SUM(qtde_vendida) AS quantidade_total_vendida,
    SUM(qtde_vendida * valor_unitario) AS valor_total_reais
FROM public.venda
WHERE data_emissao >= DATE '2025-02-01'
  AND data_emissao <  DATE '2025-03-01';

SELECT
    v.produto_id,
    COALESCE(MAX(pf.decricao), MAX(pc.descricao_produto), 'Sem descricao') AS descricao_produto,
    SUM(v.qtde_vendida) AS quantidade_vendida,
    SUM(v.qtde_vendida * v.valor_unitario) AS valor_total_reais,
    MIN(v.valor_unitario) AS menor_valor_unitario,
    MAX(v.valor_unitario) AS maior_valor_unitario
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

WITH entradas_agrupadas AS (
    SELECT
        ordem_compra,
        produto_id,
        item,
        SUM(qtde_recebida) AS qtde_recebida_total,
        COUNT(*) AS qtd_notas_fiscais
    FROM public.entradas_mercadoria
    GROUP BY ordem_compra, produto_id, item
)
SELECT
    pc.ordem_compra,
    pc.pedido_id,
    pc.item,
    pc.produto_id,
    pc.descricao_produto,
    pc.data_pedido,
    pc.data_entrega,
    pc.qtde_pedida,
    pc.qtde_entregue,
    pc.qtde_pendente,
    COALESCE(ea.qtde_recebida_total, 0) AS qtde_recebida_entradas,
    (pc.qtde_pedida - COALESCE(ea.qtde_recebida_total, 0)) AS diferenca_nao_recebida
FROM public.pedido_compra pc
LEFT JOIN entradas_agrupadas ea
       ON ea.ordem_compra = pc.ordem_compra
      AND ea.produto_id   = pc.produto_id
      AND ea.item         = pc.item
WHERE COALESCE(pc.qtde_pendente, 0) > 0
   OR pc.qtde_entregue < pc.qtde_pedida
   OR COALESCE(ea.qtde_recebida_total, 0) < pc.qtde_pedida
ORDER BY pc.data_pedido, pc.ordem_compra, pc.item;

SELECT
    v.filial_id,
    v.produto_id,
    COUNT(*) AS total_linhas,
    SUM(v.qtde_vendida) AS quantidade_vendida,
    SUM(v.qtde_vendida * v.valor_unitario) AS valor_total_reais
FROM public.venda v
LEFT JOIN public.produtos_filial pf
       ON pf.idproduto = v.produto_id
      AND pf.filial_id = v.filial_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
  AND pf.idproduto IS NULL
GROUP BY v.filial_id, v.produto_id
ORDER BY valor_total_reais DESC NULLS LAST;

SELECT
    'venda' AS tabela_origem,
    CAST(venda_id AS TEXT) AS referencia_documento,
    produto_id,
    CAST(data_emissao AS TEXT) AS data_referencia,
    qtde_vendida AS valor_1,
    valor_unitario AS valor_2,
    NULL::NUMERIC AS valor_3
FROM public.venda
WHERE data_emissao >= DATE '2025-02-01'
  AND data_emissao <  DATE '2025-03-01'
  AND (qtde_vendida IS NULL OR qtde_vendida <= 0 OR valor_unitario < 0)

UNION ALL

SELECT
    'pedido_compra' AS tabela_origem,
    CAST(ordem_compra AS TEXT) AS referencia_documento,
    produto_id,
    CAST(data_pedido AS TEXT) AS data_referencia,
    qtde_pedida AS valor_1,
    qtde_entregue AS valor_2,
    qtde_pendente AS valor_3
FROM public.pedido_compra
WHERE qtde_pedida IS NULL
   OR qtde_pedida <= 0
   OR qtde_entregue < 0
   OR qtde_pendente < 0
   OR (qtde_entregue + qtde_pendente) <> qtde_pedida;

SELECT
    idfornecedor,
    razao_social
FROM public.fornecedor
WHERE idfornecedor !~ '^[0-9]+$';

