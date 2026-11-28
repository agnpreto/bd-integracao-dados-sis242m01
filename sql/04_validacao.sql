-- 04_validacao
-- Nome:Consultas de Validacao e Auditoria de Erros

-- 1. Resumo executivo de vendas de Fevereiro de 2025 por filial e produto
SELECT
    v.filial_id,
    v.produto_id,
    COALESCE(pf.descricao, '[NAO CADASTRADO]') AS descricao,
    COUNT(*) AS qtd_cupons,
    SUM(v.qtde_vendida) AS total_itens,
    ROUND(SUM(v.qtde_vendida * v.valor_unitario)::numeric, 2) AS faturamento_rs
FROM public.venda v
LEFT JOIN public.produtos_filial pf
    ON pf.filial_id = v.filial_id
   AND pf.produto_id = v.produto_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.filial_id, v.produto_id, pf.descricao
ORDER BY v.filial_id, faturamento_rs DESC;

-- 2. Erro: Vendas de produtos (P21 a P28) ou filiais (2 e 3) inexistentes em produtos_filial
SELECT
    v.venda_id,
    v.data_emissao,
    v.filial_id,
    v.produto_id,
    v.qtde_vendida,
    v.valor_unitario
FROM public.venda v
LEFT JOIN public.produtos_filial pf
    ON pf.filial_id = v.filial_id
   AND pf.produto_id = v.produto_id
WHERE pf.produto_id IS NULL
ORDER BY v.venda_id;

-- 3. Erro: Pedidos de compra com data_entrega anterior a data_pedido
SELECT
    pedido_id,
    ordem_compra,
    produto_id,
    data_pedido,
    data_entrega,
    (data_entrega - data_pedido) AS dias_diferenca
FROM public.pedido_compra
WHERE data_entrega < data_pedido
ORDER BY pedido_id;

-- 4. Erro: Divergencia entre qtde_entregue em pedido_compra e qtde_recebida em entradas_mercadoria
SELECT
    pc.pedido_id,
    pc.ordem_compra,
    pc.produto_id,
    pc.qtde_pedida,
    pc.qtde_entregue AS entregue_no_pedido,
    COALESCE(SUM(em.qtde_recebida), 0) AS recebido_na_nfe,
    (COALESCE(SUM(em.qtde_recebida), 0) - pc.qtde_entregue) AS diferenca_apontamento
FROM public.pedido_compra pc
LEFT JOIN public.entradas_mercadoria em
    ON em.ordem_compra = pc.ordem_compra
   AND em.produto_id = pc.produto_id
GROUP BY
    pc.pedido_id, pc.ordem_compra, pc.produto_id, pc.qtde_pedida, pc.qtde_entregue
HAVING COALESCE(SUM(em.qtde_recebida), 0) <> pc.qtde_entregue
ORDER BY pc.pedido_id;

-- 5. Erro: Pedidos de compra com ordem_compra = 0 (pedidos 19 a 29, incluindo linhas deslocadas)
SELECT
    pedido_id,
    data_pedido,
    produto_id,
    ordem_compra,
    qtde_pedida,
    qtde_entregue
FROM public.pedido_compra
WHERE ordem_compra = 0
ORDER BY pedido_id;

-- 6. Erro: Produtos com preco de venda menor que o preco de compra
SELECT
    filial_id,
    produto_id,
    descricao,
    preco_compra,
    preco_venda,
    (preco_venda - preco_compra) AS margem_unitaria
FROM public.produtos_filial
WHERE preco_venda < preco_compra
ORDER BY margem_unitaria ASC;

-- 7. Erro: Padronizacao divergente de IDs de fornecedor (F1..F20 vs 1..20)
SELECT DISTINCT
    pc.fornecedor_id AS id_no_pedido_compra,
    f.idfornecedor AS id_na_tabela_fornecedor,
    f.razao_social
FROM public.pedido_compra pc
LEFT JOIN public.fornecedor f
    ON f.idfornecedor = 'F' || pc.fornecedor_id::text
ORDER BY pc.fornecedor_id;