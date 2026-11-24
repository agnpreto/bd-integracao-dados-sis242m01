-- =====================================================================
-- 02_consultas.sql : Parte 2 - Consultas SQL básicas (PostgreSQL)
-- Escritas para PostgreSQL. No MySQL: troque STRING_AGG(x, ', ') por
-- GROUP_CONCAT(x SEPARATOR ', ') e o operador || por CONCAT(). A 2.1 roda igual.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 2.1  Total vendido em QUANTIDADE e em R$ por produto, fevereiro/2025
-- ---------------------------------------------------------------------
-- * Período semiaberto [01/02/2025, 01/03/2025): pega o dia 28 inteiro e
--   usa o índice de data_emissao (melhor do que EXTRACT(MONTH ...)).
-- * Valor (R$) = qtde_vendida * valor_unitario (não existe coluna de total).
-- * LEFT JOIN com o cadastro: as vendas de produtos sem cadastro (P21 a P28)
--   continuam no total e aparecem como "(sem cadastro)". Com INNER JOIN,
--   R$ 3.241,24 de fevereiro (6 vendas, 23% do mês) sumiriam do relatório.
-- * O cadastro é ligado por filial + produto (PK de produtos_filial).
SELECT  v.produto_id,
        COALESCE(p.descricao, '(sem cadastro)')          AS descricao,
        SUM(v.qtde_vendida)                              AS qtde_vendida,
        ROUND(SUM(v.qtde_vendida * v.valor_unitario), 2) AS valor_total_rs
FROM    venda v
LEFT JOIN produtos_filial p
       ON p.filial_id  = v.filial_id
      AND p.produto_id = v.produto_id
WHERE   v.data_emissao >= DATE '2025-02-01'
  AND   v.data_emissao <  DATE '2025-03-01'
GROUP BY v.produto_id, p.descricao
ORDER BY valor_total_rs DESC;

-- Total geral de fevereiro (conferência do relatório acima)
SELECT  COUNT(*)                                         AS linhas_de_venda,
        SUM(qtde_vendida)                                AS qtde_total,
        ROUND(SUM(qtde_vendida * valor_unitario), 2)     AS valor_total_rs
FROM    venda
WHERE   data_emissao >= DATE '2025-02-01'
  AND   data_emissao <  DATE '2025-03-01';


-- ---------------------------------------------------------------------
-- 2.2  Produtos REQUISITADOS e NÃO RECEBIDOS
-- ---------------------------------------------------------------------
-- Requisitado = linha de pedido_compra.
-- Recebido    = entrada com a MESMA ordem_compra (regra do enunciado) e o
--               mesmo produto_id.
-- Quantidade recebida = soma das entradas (notas fiscais). Não uso a
-- coluna qtde_entregue do pedido porque ela não bate com as entradas em
-- quase todos os pedidos (ver Parte 4).
-- Situações:
--   NÃO RECEBIDO          nenhuma entrada para a ordem/produto
--   RECEBIDO PARCIALMENTE soma das entradas < quantidade pedida
-- A coluna "observacao" marca os pedidos com ordem_compra = 0: o vínculo
-- é impossível e existe entrada do mesmo produto em outra ordem (NFE19 e
-- NFE20). O cliente precisa confirmar se esses itens chegaram.
WITH recebido AS (
    SELECT ordem_compra, produto_id,
           SUM(qtde_recebida) AS qtde_recebida,
           STRING_AGG(nro_nfe, ', ') AS notas
    FROM entradas_mercadoria
    GROUP BY ordem_compra, produto_id
)
SELECT  pc.pedido_id,
        pc.ordem_compra,
        pc.produto_id,
        pc.descricao_produto,
        pc.data_pedido,
        pc.qtde_pedida,
        COALESCE(r.qtde_recebida, 0)                    AS qtde_recebida,
        pc.qtde_pedida - COALESCE(r.qtde_recebida, 0)   AS qtde_nao_recebida,
        CASE WHEN r.ordem_compra IS NULL THEN 'NÃO RECEBIDO'
             ELSE 'RECEBIDO PARCIALMENTE' END           AS situacao,
        r.notas,
        CASE WHEN pc.ordem_compra = 0 THEN
                 'ordem_compra = 0 (sem vínculo)'
                 || COALESCE('; existe entrada do produto: '
                    || (SELECT STRING_AGG(e.nro_nfe || ' (ordem ' || e.ordem_compra || ')', ', ')
                        FROM entradas_mercadoria e
                        WHERE e.produto_id = pc.produto_id), '')
        END                                             AS observacao
FROM    pedido_compra pc
LEFT JOIN recebido r
       ON r.ordem_compra = pc.ordem_compra
      AND r.produto_id   = pc.produto_id
WHERE   COALESCE(r.qtde_recebida, 0) < pc.qtde_pedida
ORDER BY situacao, pc.pedido_id;

-- Versão resumida por produto
WITH recebido AS (
    SELECT ordem_compra, produto_id, SUM(qtde_recebida) AS qtde_recebida
    FROM entradas_mercadoria
    GROUP BY ordem_compra, produto_id
)
SELECT  pc.produto_id,
        MAX(pc.descricao_produto)                                 AS descricao,
        COUNT(*)                                                  AS pedidos_pendentes,
        SUM(pc.qtde_pedida)                                       AS qtde_pedida,
        SUM(pc.qtde_pedida - COALESCE(r.qtde_recebida, 0))        AS qtde_nao_recebida
FROM    pedido_compra pc
LEFT JOIN recebido r ON r.ordem_compra = pc.ordem_compra AND r.produto_id = pc.produto_id
WHERE   COALESCE(r.qtde_recebida, 0) < pc.qtde_pedida
GROUP BY pc.produto_id
ORDER BY qtde_nao_recebida DESC;
