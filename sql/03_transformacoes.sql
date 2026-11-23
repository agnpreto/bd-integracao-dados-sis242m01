-- Parte 3: Transformações de dados

-- 1) Concatenar produto_id e descrição (onde houver), no formato "12345 - Detergente".
-- Em venda não existe descrição: vem de produtos_filial. Produto sem cadastro mostra só o código.
SELECT
    v.venda_id,
    v.produto_id || COALESCE(' - ' || NULLIF(TRIM(pf.descricao), ''), '') AS produto
FROM venda v
LEFT JOIN produtos_filial pf
       ON pf.produto_id = v.produto_id
      AND pf.filial_id  = v.filial_id
ORDER BY v.venda_id;

-- 1b) Conferência: vendas cujo produto não tem descrição cadastrada
SELECT COUNT(*) AS vendas_sem_descricao
FROM venda v
LEFT JOIN produtos_filial pf
       ON pf.produto_id = v.produto_id
      AND pf.filial_id  = v.filial_id
WHERE pf.produto_id IS NULL;

-- 2) Datas no formato DD/MM/YYYY
SELECT pedido_id, produto_id,
       TO_CHAR(data_pedido,  'DD/MM/YYYY') AS data_pedido,
       TO_CHAR(data_entrega, 'DD/MM/YYYY') AS data_entrega
FROM pedido_compra
ORDER BY pedido_id;

SELECT venda_id, produto_id,
       TO_CHAR(data_emissao, 'DD/MM/YYYY') AS data_emissao
FROM venda
ORDER BY venda_id;

SELECT ordem_compra, produto_id,
       TO_CHAR(data_entrada, 'DD/MM/YYYY') AS data_entrada
FROM entradas_mercadoria
ORDER BY ordem_compra;

-- 3) Produtos requisitados mais de 10 vezes no período.
-- Interpretação de "mais de 10 vezes": QUANTIDADE requisitada (soma de qtde_pedida) maior que 10,
-- porque o exemplo do enunciado mostra a coluna "Qtde Requisitada" (15). A outra leitura
-- (mais de 10 pedidos do produto) trocaria o HAVING por COUNT(*) > 10; com estes dados ela não
-- devolve nenhuma linha (o máximo é 2 pedidos por produto).
-- Período: fevereiro/2025 (mesmo mês das Partes 2 e 4); ajuste as duas datas do WHERE.
-- "Data Solicitação" = primeira solicitação do produto no período.
SELECT
    p.produto_id || COALESCE(' - ' || NULLIF(TRIM(MAX(p.descricao_produto)), ''), '') AS "Produto",
    SUM(p.qtde_pedida)                        AS "Qtde Requisitada",
    TO_CHAR(MIN(p.data_pedido), 'DD/MM/YYYY') AS "Data Solicitação"
FROM pedido_compra p
WHERE p.data_pedido >= DATE '2025-02-01'
  AND p.data_pedido <  DATE '2025-03-01'
GROUP BY p.produto_id
HAVING SUM(p.qtde_pedida) > 10
ORDER BY SUM(p.qtde_pedida) DESC, p.produto_id;