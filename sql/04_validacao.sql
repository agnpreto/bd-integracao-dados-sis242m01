-- 04_validacao

-- 1
SELECT
    COUNT(*) AS total_registros,
    SUM(qtde_vendida) AS quantidade_total,
    SUM(qtde_vendida * valor_unitario) AS valor_total
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao < '2025-03-01';

-- 2
SELECT
    produto_id,
    SUM(qtde_vendida) AS quantidade_vendida,
    SUM(qtde_vendida * valor_unitario) AS valor_total
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao < '2025-03-01'
GROUP BY produto_id
ORDER BY valor_total DESC;

-- 3
SELECT
    data_emissao,
    COUNT(*) AS total_registros,
    SUM(qtde_vendida) AS quantidade_vendida,
    SUM(qtde_vendida * valor_unitario) AS valor_total
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao < '2025-03-01'
GROUP BY data_emissao
ORDER BY data_emissao;

-- 4
SELECT *
FROM venda
WHERE data_emissao IS NULL
   OR produto_id IS NULL
   OR qtde_vendida IS NULL
   OR valor_unitario IS NULL;

-- 5
SELECT *
FROM venda
WHERE qtde_vendida <= 0
   OR valor_unitario < 0;


-- 6
SELECT
    v.produto_id,
    v.filial_id,
    COUNT(*) AS total_vendas
FROM venda v
LEFT JOIN produtos_filial p
    ON v.produto_id = p.produto_id
   AND v.filial_id = p.filial_id
WHERE v.data_emissao >= '2025-02-01'
  AND v.data_emissao < '2025-03-01'
  AND p.produto_id IS NULL
GROUP BY v.produto_id, v.filial_id;


-- 7
SELECT
    data_emissao,
    filial_id,
    produto_id,
    qtde_vendida,
    valor_unitario,
    COUNT(*) AS ocorrencias
FROM venda
WHERE data_emissao >= '2025-02-01'
  AND data_emissao < '2025-03-01'
GROUP BY
    data_emissao,
    filial_id,
    produto_id,
    qtde_vendida,
    valor_unitario
HAVING COUNT(*) > 1;
