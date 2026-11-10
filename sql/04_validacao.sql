-- 04_validacao
-- Nome: Izabelly Cantalice

-- Consulta 1: Vendas de produtos sem cadastro na tabela produtos_filial
SELECT v.filial_id, v.produto_id, COUNT(*) AS qtd_ocorrencias
FROM public.venda v
LEFT JOIN public.produtos_filial pf
    ON pf.produto_id = v.produto_id AND pf.filial_id = v.filial_id
WHERE pf.produto_id IS NULL
GROUP BY v.filial_id, v.produto_id;

-- Consulta 2: Produtos cujo idfornecedor não existe na tabela fornecedor
SELECT pf.filial_id, pf.produto_id, pf.descricao, pf.idfornecedor
FROM public.produtos_filial pf
LEFT JOIN public.fornecedor f
    ON f.idfornecedor = pf.idfornecedor
WHERE f.idfornecedor IS NULL;

-- Consulta 3: Entradas de mercadoria sem pedido_compra correspondente (via ordem_compra)
SELECT em.nro_nfe, em.ordem_compra, em.produto_id, em.qtde_recebida, em.data_entrada
FROM public.entradas_mercadoria em
LEFT JOIN public.pedido_compra pc
    ON pc.ordem_compra = em.ordem_compra AND pc.produto_id = em.produto_id
WHERE pc.ordem_compra IS NULL;

-- Consulta 4: Vendas com quantidade ou valor unitário inválido (<= 0 ou nulo)
SELECT venda_id, data_emissao, produto_id, qtde_vendida, valor_unitario
FROM public.venda
WHERE qtde_vendida IS NULL OR qtde_vendida <= 0
   OR valor_unitario IS NULL OR valor_unitario <= 0;

-- Consulta 5: Pedidos de compra com data de entrega anterior à data do pedido
SELECT pedido_id, ordem_compra, produto_id, data_pedido, data_entrega
FROM public.pedido_compra
WHERE data_entrega < data_pedido;

-- Consulta 6: Resumo consolidado de vendas de fevereiro/2025 para validação com o cliente
SELECT
    COUNT(DISTINCT venda_id) AS total_vendas_fev_2025,
    COUNT(*) AS total_itens_fev_2025,
    SUM(qtde_vendida) AS quantidade_total_fev_2025,
    ROUND(SUM(qtde_vendida * valor_unitario)::numeric, 2) AS valor_total_fev_2025
FROM public.venda
WHERE data_emissao >= DATE '2025-02-01'
  AND data_emissao <  DATE '2025-03-01';