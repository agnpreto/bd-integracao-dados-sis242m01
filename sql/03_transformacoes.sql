-- 03_transformacoes
-- Nome:

-- 1

SELECT
    CONCAT(produto_id, ' - ', descricao_produto) AS produto,
    qtde_pedida AS quantidade_requisitada,
    data_pedido
FROM pedido_compra;

-- 2

SELECT
    CONCAT(produto_id, ' - ', descricao_produto) AS produto,
    qtde_pedida AS quantidade_requisitada,
    TO_CHAR(data_pedido, 'DD/MM/YYYY') AS data_solicitacao
FROM pedido_compra;

-- 3
-- FEVEREIRO DE 2025

SELECT
    CONCAT(produto_id, ' - ', MAX(descricao_produto)) AS produto,
    SUM(qtde_pedida) AS qtde_requisitada,
    TO_CHAR(data_pedido, 'DD/MM/YYYY') AS data_solicitacao
FROM pedido_compra
WHERE data_pedido >= '2025-02-01'
  AND data_pedido < '2025-03-01'
GROUP BY produto_id, data_pedido
HAVING SUM(qtde_pedida) > 10
ORDER BY data_pedido, produto_id;

-- 4

SELECT
    CONCAT(v.produto_id, ' - ', p.descricao) AS produto,
    v.qtde_vendida AS quantidade_vendida,
    TO_CHAR(v.data_emissao, 'DD/MM/YYYY') AS data_venda,
    v.valor_unitario,
    (v.qtde_vendida * v.valor_unitario) AS valor_total
FROM venda v
LEFT JOIN produtos_filial p
    ON v.produto_id = p.produto_id
   AND v.filial_id = p.filial_id
WHERE v.data_emissao >= '2025-02-01'
  AND v.data_emissao < '2025-03-01'
ORDER BY v.data_emissao;

-- 5

CREATE SEQUENCE fornecedor_id_seq;

SELECT setval(
    'fornecedor_id_seq',
    COALESCE(MAX(idfornecedor::BIGINT), 0) + 1,
    false
)
FROM fornecedor
WHERE idfornecedor ~ '^[0-9]+$';

CREATE OR REPLACE FUNCTION gerar_idfornecedor()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.idfornecedor IS NULL OR NEW.idfornecedor = '' THEN
        NEW.idfornecedor := nextval('fornecedor_id_seq')::VARCHAR;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gerar_idfornecedor
BEFORE INSERT ON fornecedor
FOR EACH ROW
EXECUTE FUNCTION gerar_idfornecedor();

