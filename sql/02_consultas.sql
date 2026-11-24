-- =====================================================================
-- Parte 2 - Consultas SQL básicas  (rodam sem alteração em PostgreSQL e MySQL 8)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 2.1 Consumo por produto em FEVEREIRO/2025: total em quantidade e em R$.
-- * Valor = SUM(qtde_vendida * valor_unitario): o valor é calculado linha a
--   linha ANTES de somar (somar quantidade e multiplicar pelo preço médio
--   daria resultado errado se o preço variasse).
-- * Filtro de data com intervalo [01/02, 01/03): pega o mês inteiro, inclusive
--   o dia 28, e ainda aproveita o índice em data_emissao.
-- * LEFT JOIN: os produtos P21..P27 vendidos em fevereiro NÃO existem em
--   produtos_filial; com INNER JOIN essas vendas sumiriam do total.
-- ---------------------------------------------------------------------
SELECT v.produto_id,
       COALESCE(p.descricao, '(produto não cadastrado)') AS descricao,
       COUNT(*)                                          AS qtd_vendas,
       SUM(v.qtde_vendida)                               AS total_quantidade,
       SUM(v.qtde_vendida * v.valor_unitario)            AS total_valor_rs
  FROM venda v
  LEFT JOIN (SELECT produto_id, MIN(descricao) AS descricao
               FROM produtos_filial
              GROUP BY produto_id) p ON p.produto_id = v.produto_id
 WHERE v.data_emissao >= '2025-02-01'
   AND v.data_emissao <  '2025-03-01'
 GROUP BY v.produto_id, p.descricao
 ORDER BY total_valor_rs DESC;

-- Conferência: total geral do mês (a soma da consulta acima precisa bater).
SELECT COUNT(*) AS qtd_vendas, SUM(qtde_vendida) AS total_quantidade,
       SUM(qtde_vendida * valor_unitario) AS total_valor_rs
  FROM venda
 WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01';

-- ---------------------------------------------------------------------
-- 2.2 Produtos REQUISITADOS e NÃO RECEBIDOS.
-- Regra: um pedido foi recebido se existe entrada com o MESMO ordem_compra e
-- o MESMO produto (elo definido no enunciado). NOT EXISTS (e não NOT IN) para
-- não ser enganado por NULL.
-- ATENÇÃO: os pedidos 19 a 29 vêm com ordem_compra = 0 na planilha, logo não
-- se ligam a nenhuma entrada e aparecem como "não recebidos". Para P19 e P20
-- existem entradas com ordem 19 e 20, mas o pedido não traz essa ordem: é um
-- erro de dado (ver 04_validacao.sql, item E5) e deve ser confirmado com o
-- cliente antes de cobrar o fornecedor.
-- ---------------------------------------------------------------------
SELECT pc.produto_id,
       pc.descricao_produto,
       pc.pedido_id,
       pc.ordem_compra,
       pc.data_pedido,
       pc.qtde_pedida
  FROM pedido_compra pc
 WHERE NOT EXISTS (SELECT 1
                     FROM entradas_mercadoria e
                    WHERE e.ordem_compra = pc.ordem_compra
                      AND e.produto_id   = pc.produto_id)
 ORDER BY pc.pedido_id;

-- Variação (recebimento PARCIAL): pedido recebido em quantidade menor que a
-- pedida, comparando com a soma das entradas da mesma ordem/produto.
SELECT pc.pedido_id, pc.ordem_compra, pc.produto_id, pc.qtde_pedida,
       COALESCE(SUM(e.qtde_recebida), 0)                  AS qtde_recebida,
       pc.qtde_pedida - COALESCE(SUM(e.qtde_recebida), 0) AS faltou_receber
  FROM pedido_compra pc
  LEFT JOIN entradas_mercadoria e
         ON e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id
 GROUP BY pc.pedido_id, pc.ordem_compra, pc.produto_id, pc.qtde_pedida
HAVING pc.qtde_pedida > COALESCE(SUM(e.qtde_recebida), 0)
 ORDER BY pc.pedido_id;
