-- =====================================================================
-- Parte 3 - Transformações de dados  (MySQL 8)  - mesma lógica de
-- 03_transformacoes.sql (leia lá a justificativa da interpretação).
-- Diferenças: DATE_FORMAT no lugar de TO_CHAR, trigger com AUTO_INCREMENT.
-- =====================================================================
USE integracao;

-- 3.1 concatenação
SELECT pedido_id, CONCAT_WS(' - ', produto_id, NULLIF(TRIM(descricao_produto), '')) AS produto
  FROM pedido_compra ORDER BY pedido_id;
SELECT v.venda_id, CONCAT_WS(' - ', v.produto_id, NULLIF(TRIM(p.descricao), '')) AS produto
  FROM venda v
  LEFT JOIN (SELECT produto_id, MIN(descricao) AS descricao FROM produtos_filial GROUP BY produto_id) p
         ON p.produto_id = v.produto_id
 ORDER BY v.venda_id;
SELECT CONCAT_WS(' - ', produto_id, NULLIF(TRIM(descricao), '')) AS produto
  FROM produtos_filial ORDER BY filial_id, produto_id;

-- 3.2 datas DD/MM/YYYY
SELECT pedido_id, DATE_FORMAT(data_pedido, '%d/%m/%Y') AS data_pedido,
       DATE_FORMAT(data_entrega, '%d/%m/%Y') AS data_entrega
  FROM pedido_compra ORDER BY pedido_id;
SELECT venda_id, DATE_FORMAT(data_emissao, '%d/%m/%Y') AS data_emissao FROM venda ORDER BY venda_id;
SELECT nro_nfe, DATE_FORMAT(data_entrada, '%d/%m/%Y') AS data_entrada FROM entradas_mercadoria ORDER BY nro_nfe;

-- 3.3 requisitados "mais de 10 vezes" = qtde_pedida > 10 por requisição
CREATE OR REPLACE VIEW vw_requisicoes_maiores_10 AS
SELECT CONCAT_WS(' - ', pc.produto_id, NULLIF(TRIM(pc.descricao_produto), '')) AS `Produto`,
       CAST(pc.qtde_pedida AS DOUBLE)              AS `Qtde Requisitada`,
       DATE_FORMAT(pc.data_pedido, '%d/%m/%Y')     AS `Data Solicitação`,
       pc.data_pedido                              AS data_ordenacao
  FROM pedido_compra pc
 WHERE pc.qtde_pedida > 10;

SELECT `Produto`, `Qtde Requisitada`, `Data Solicitação`
  FROM vw_requisicoes_maiores_10
 WHERE data_ordenacao BETWEEN '2025-01-01' AND '2025-03-31'
 ORDER BY data_ordenacao, `Produto`;

SELECT CONCAT_WS(' - ', produto_id, NULLIF(TRIM(MIN(descricao_produto)), '')) AS `Produto`,
       CAST(SUM(qtde_pedida) AS DOUBLE) AS `Qtde Requisitada`,
       DATE_FORMAT(MIN(data_pedido), '%d/%m/%Y') AS `Primeira Solicitação`
  FROM pedido_compra
 WHERE data_pedido BETWEEN '2025-01-01' AND '2025-03-31'
 GROUP BY produto_id
HAVING SUM(qtde_pedida) > 10
 ORDER BY produto_id;

SELECT produto_id, COUNT(*) AS qtd_pedidos FROM pedido_compra GROUP BY produto_id HAVING COUNT(*) > 10;

-- 3.4 trigger: fornecedor.idfornecedor é AUTO_INCREMENT (ver 01_ddl_mysql.sql)
DROP TRIGGER IF EXISTS trg_gera_idfornecedor;
DELIMITER $$
CREATE TRIGGER trg_gera_idfornecedor
BEFORE INSERT ON produtos_filial
FOR EACH ROW
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        INSERT INTO fornecedor (razao_social)
        VALUES (CONCAT('Fornecedor a cadastrar (produto ', NEW.produto_id, ')'));
        SET NEW.idfornecedor = LAST_INSERT_ID();
    END IF;
END$$
DELIMITER ;

-- Teste
START TRANSACTION;
INSERT INTO produtos_filial (filial_id, produto_id, descricao, estoque, preco_unitario, preco_compra, preco_venda)
VALUES (1, 'P99', 'Produto de teste', 5, 10, 5, 12);
SELECT p.produto_id, p.idfornecedor, f.razao_social
  FROM produtos_filial p JOIN fornecedor f ON f.idfornecedor = p.idfornecedor
 WHERE p.produto_id = 'P99';
ROLLBACK;
