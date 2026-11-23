-- =====================================================================
-- 02_consultas.sql  |  Parte 2: consultas SQL básicas (PostgreSQL)
-- Nome: Franklin Mendonça
-- Rodar depois de 01_ddl_postgres.sql + scripts/importar.py
-- =====================================================================


-- ---------------------------------------------------------------------
-- 2.1 Consumo por produto em fevereiro de 2025
-- Total vendido em quantidade e em R$ (qtde_vendida * valor_unitario).
-- O filtro usa intervalo semiaberto [01/02, 01/03) em vez de BETWEEN para
-- funcionar também se data_emissao um dia ganhar horário.
-- A descrição vem de produtos_filial (MIN evita duplicar a linha se o
-- produto existir em mais de uma filial). Produtos vendidos mas não
-- cadastrados (P22 a P27) aparecem com descrição vazia: é erro de dado do
-- cliente, tratado em 04_validacao.sql.
-- ---------------------------------------------------------------------
SELECT
    v.produto_id,
    MIN(p.descricao)                              AS descricao,
    SUM(v.qtde_vendida)                           AS qtde_vendida,
    ROUND(SUM(v.qtde_vendida * v.valor_unitario)::numeric, 2) AS total_vendido_rs
FROM public.venda v
LEFT JOIN public.produtos_filial p ON p.produto_id = v.produto_id
WHERE v.data_emissao >= DATE '2025-02-01'
  AND v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id
ORDER BY v.produto_id;


-- ---------------------------------------------------------------------
-- 2.2 Produtos com requisição pendente (requisitados e não recebidos)
-- Requisição = linha de pedido_compra. A entrada de mercadoria se liga ao
-- pedido pela ordem_compra (enunciado), e também confiro produto e filial.
-- "Não recebido" = nenhuma entrada ligada à requisição.
-- ATENÇÃO: os pedidos 19 a 29 têm ordem_compra = 0 (sem ordem). Por isso
-- nenhum casa com uma entrada. Os pedidos 19 e 20 são um caso à parte:
-- existem as notas NFE19 e NFE20 para P19 e P20 (ordem 19 e 20), então
-- provavelmente já foram recebidos e estão sem a ordem preenchida. Deixo
-- na lista (a regra do vínculo é a ordem_compra) e levo a dúvida ao
-- cliente em 04_validacao.sql.
-- ---------------------------------------------------------------------
SELECT
    pc.pedido_id,
    pc.produto_id,
    pc.descricao_produto,
    pc.data_pedido,
    pc.ordem_compra,
    pc.qtde_pedida
FROM public.pedido_compra pc
WHERE NOT EXISTS (
    SELECT 1
    FROM public.entradas_mercadoria e
    WHERE e.ordem_compra = pc.ordem_compra
      AND e.produto_id   = pc.produto_id
      AND e.filial_id    = pc.filial_id
)
ORDER BY pc.pedido_id;

-- Resumo por produto (um produto pode ter mais de um pedido sem entrada):
SELECT
    pc.produto_id,
    MIN(pc.descricao_produto) AS descricao_produto,
    COUNT(*)                  AS pedidos_sem_entrada,
    SUM(pc.qtde_pedida)       AS qtde_pendente_total
FROM public.pedido_compra pc
WHERE NOT EXISTS (
    SELECT 1
    FROM public.entradas_mercadoria e
    WHERE e.ordem_compra = pc.ordem_compra
      AND e.produto_id   = pc.produto_id
      AND e.filial_id    = pc.filial_id
)
GROUP BY pc.produto_id
ORDER BY pc.produto_id;

-- Complemento: requisições recebidas só em parte (entrada menor que o pedido).
SELECT
    pc.pedido_id,
    pc.produto_id,
    pc.qtde_pedida,
    SUM(e.qtde_recebida)                  AS qtde_recebida,
    pc.qtde_pedida - SUM(e.qtde_recebida) AS saldo_pendente
FROM public.pedido_compra pc
JOIN public.entradas_mercadoria e
  ON e.ordem_compra = pc.ordem_compra
 AND e.produto_id   = pc.produto_id
 AND e.filial_id    = pc.filial_id
GROUP BY pc.pedido_id, pc.produto_id, pc.qtde_pedida
HAVING SUM(e.qtde_recebida) < pc.qtde_pedida
ORDER BY pc.pedido_id;
