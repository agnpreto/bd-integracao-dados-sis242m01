-- 03_transformacoes  
-- Nome: Mikael Coelho Ramos e Kauã Monteiro Coelho

-- 1 - Concatenar produto_id e descrição, "onde houver", no formato "12345 - Detergente"

-- 1a) pedido_compra 
SELECT p.pedido_id,
       CONCAT_WS(' - ', p.produto_id, NULLIF(TRIM(p.descricao_produto), '')) AS produto
FROM pedido_compra p
ORDER BY p.pedido_id;

-- 1b) venda 

SELECT v.venda_id,
       CONCAT_WS(' - ', v.produto_id, NULLIF(TRIM(d.descricao), '')) AS produto
FROM venda v
LEFT JOIN (SELECT produto_id, MIN(descricao) AS descricao
           FROM produtos_filial
           GROUP BY produto_id) d ON d.produto_id = v.produto_id
ORDER BY v.venda_id;

-- 1c) produtos_filial
SELECT pf.filial_id,
       CONCAT_WS(' - ', pf.produto_id, NULLIF(TRIM(pf.descricao), '')) AS produto
FROM produtos_filial pf
ORDER BY pf.filial_id, LENGTH(pf.produto_id), pf.produto_id;


-- 2 - Datas no formato DD/MM/YYYY

-- 2a) pedido_compra
SELECT p.pedido_id,
       TO_CHAR(p.data_pedido,  'DD/MM/YYYY') AS data_pedido,    
       TO_CHAR(p.data_entrega, 'DD/MM/YYYY') AS data_entrega    
FROM pedido_compra p
ORDER BY p.data_pedido, p.pedido_id;

-- 2b) venda
SELECT v.venda_id,
       TO_CHAR(v.data_emissao, 'DD/MM/YYYY') AS data_emissao    
ORDER BY v.data_emissao, v.venda_id;

-- 2c) entradas_mercadoria
SELECT e.nro_nfe,
       TO_CHAR(e.data_entrada, 'DD/MM/YYYY') AS data_entrada     
FROM entradas_mercadoria e
ORDER BY e.data_entrada, e.nro_nfe;

--  3 - Só os produtos requisitados mais de 10 vezes no período

SELECT produto_id, COUNT(*) AS vezes_requisitado
FROM pedido_compra
WHERE data_pedido BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
GROUP BY produto_id
HAVING COUNT(*) > 10;


-- 4. Trigger para gerar automaticamente idfornecedor numérico em produtos_filial
CREATE OR REPLACE FUNCTION fn_gera_idfornecedor() RETURNS trigger AS $$
DECLARE
    novo_id int4;
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        PERFORM pg_advisory_xact_lock(hashtext('fornecedor.idfornecedor'));
        SELECT COALESCE(MAX(idfornecedor), 0) + 1 INTO novo_id FROM fornecedor;

        INSERT INTO fornecedor (idfornecedor, razao_social)
        VALUES (novo_id, 'Fornecedor do produto ' || NEW.produto_id || ' (gerado automaticamente)');

        NEW.idfornecedor := novo_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_produtos_filial_idfornecedor ON produtos_filial;
CREATE TRIGGER trg_produtos_filial_idfornecedor
    BEFORE INSERT ON produtos_filial
    FOR EACH ROW
    EXECUTE FUNCTION fn_gera_idfornecedor();

-- Teste da trigger 
INSERT INTO produtos_filial (filial_id, produto_id, descricao, idfornecedor)
VALUES (1, 'P98', 'Teste: fornecedor informado', 5);

INSERT INTO produtos_filial (filial_id, produto_id, descricao)
VALUES (1, 'P99', 'Teste: fornecedor gerado automaticamente');

SELECT pf.produto_id, pf.idfornecedor, f.razao_social
FROM produtos_filial pf
JOIN fornecedor f ON f.idfornecedor = pf.idfornecedor
WHERE pf.produto_id IN ('P98', 'P99')
ORDER BY pf.produto_id;

-- Limpeza do teste
DELETE FROM produtos_filial WHERE produto_id IN ('P98', 'P99');
DELETE FROM fornecedor WHERE razao_social = 'Fornecedor do produto P99 (gerado automaticamente)';




