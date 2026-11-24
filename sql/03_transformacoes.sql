-- =====================================================================
-- Parte 3 - Transformações de dados  (PostgreSQL)
-- Versão MySQL: sql/03_transformacoes_mysql.sql
-- =====================================================================

-- ---------------------------------------------------------------------
-- 3.1  Concatenar produto_id e descricao_produto "onde houver", formato
--      "12345 - Detergente". CONCAT_WS ignora NULL: sem descrição sobra só
--      o código, sem " - " solto no fim. NULLIF(TRIM(..),'') trata também
--      descrição em branco.
-- ---------------------------------------------------------------------
-- pedido_compra (tem descricao_produto)
SELECT pedido_id,
       CONCAT_WS(' - ', produto_id, NULLIF(TRIM(descricao_produto), '')) AS produto
  FROM pedido_compra ORDER BY pedido_id;

-- venda NÃO tem descrição: busca no cadastro; produto fora do cadastro
-- (P21..P28) continua aparecendo, só com o código.
SELECT v.venda_id,
       CONCAT_WS(' - ', v.produto_id, NULLIF(TRIM(p.descricao), '')) AS produto
  FROM venda v
  LEFT JOIN (SELECT produto_id, MIN(descricao) AS descricao
               FROM produtos_filial GROUP BY produto_id) p ON p.produto_id = v.produto_id
 ORDER BY v.venda_id;

-- produtos_filial (a coluna se chama "descricao")
SELECT CONCAT_WS(' - ', produto_id, NULLIF(TRIM(descricao), '')) AS produto
  FROM produtos_filial ORDER BY filial_id, produto_id;

-- ---------------------------------------------------------------------
-- 3.2  Datas no formato DD/MM/YYYY (TO_CHAR devolve TEXTO: use só para
--      exibir; para filtrar/ordenar continue usando a coluna DATE).
-- ---------------------------------------------------------------------
SELECT pedido_id,
       TO_CHAR(data_pedido,  'DD/MM/YYYY') AS data_pedido,
       TO_CHAR(data_entrega, 'DD/MM/YYYY') AS data_entrega
  FROM pedido_compra ORDER BY pedido_id;

SELECT venda_id, TO_CHAR(data_emissao, 'DD/MM/YYYY') AS data_emissao FROM venda ORDER BY venda_id;
SELECT nro_nfe,  TO_CHAR(data_entrada, 'DD/MM/YYYY') AS data_entrada FROM entradas_mercadoria ORDER BY nro_nfe;

-- ---------------------------------------------------------------------
-- 3.3  Somente produtos "requisitados mais de 10 vezes no período".
--
-- INTERPRETAÇÃO ADOTADA: "vezes" = unidades requisitadas em uma requisição
-- (qtde_pedida > 10, estritamente maior: exatamente 10 NÃO entra).
-- Motivos: (a) o exemplo do enunciado mostra "12345 - Detergente | 15 |
-- 01/01/2025", ou seja, uma linha com quantidade 15 e data de solicitação;
-- (b) a leitura "número de pedidos > 10" retornaria ZERO linhas, pois nenhum
-- produto tem mais de 2 pedidos (consulta de prova mais abaixo).
-- "No período": os parâmetros abaixo; por padrão todo o período carregado.
-- Resultado no formato do exemplo: Produto | Qtde Requisitada | Data Solicitação.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_requisicoes_maiores_10 AS
SELECT CONCAT_WS(' - ', pc.produto_id, NULLIF(TRIM(pc.descricao_produto), '')) AS "Produto",
       TRIM_SCALE(pc.qtde_pedida)                  AS "Qtde Requisitada",
       TO_CHAR(pc.data_pedido, 'DD/MM/YYYY')       AS "Data Solicitação",
       pc.data_pedido                              AS data_ordenacao
  FROM pedido_compra pc
 WHERE pc.qtde_pedida > 10;

-- Parâmetros do período (altere aqui):
SELECT "Produto", "Qtde Requisitada", "Data Solicitação"
  FROM vw_requisicoes_maiores_10
 WHERE data_ordenacao BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
 ORDER BY data_ordenacao, "Produto";

-- Leitura alternativa A: soma requisitada por produto no período > 10
SELECT CONCAT_WS(' - ', produto_id, NULLIF(TRIM(MIN(descricao_produto)), '')) AS "Produto",
       TRIM_SCALE(SUM(qtde_pedida)) AS "Qtde Requisitada",
       TO_CHAR(MIN(data_pedido), 'DD/MM/YYYY') AS "Primeira Solicitação"
  FROM pedido_compra
 WHERE data_pedido BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
 GROUP BY produto_id
HAVING SUM(qtde_pedida) > 10
 ORDER BY produto_id;

-- Prova de que a leitura "mais de 10 pedidos" não serve: retorna 0 linhas
SELECT produto_id, COUNT(*) AS qtd_pedidos
  FROM pedido_compra GROUP BY produto_id HAVING COUNT(*) > 10;

-- ---------------------------------------------------------------------
-- 3.4  TRIGGER: gera idfornecedor numérico automático em produtos_filial,
--      já relacionado a fornecedor.
-- Regra: ao inserir um produto SEM fornecedor informado (idfornecedor NULL),
-- a trigger pega o próximo número de uma sequência, cria o fornecedor
-- correspondente (razão social provisória, a ser completada depois) e grava
-- esse número no produto. A FK produtos_filial -> fornecedor fica sempre
-- íntegra. Se o fornecedor for informado, nada muda.
-- ---------------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS seq_idfornecedor;
-- a carga trouxe ids 1..20 explícitos, então a sequência precisa partir do maior id + 1
SELECT setval('seq_idfornecedor', (SELECT COALESCE(MAX(idfornecedor), 0) + 1 FROM fornecedor), false);

CREATE OR REPLACE FUNCTION fn_gera_idfornecedor() RETURNS trigger AS $$
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        NEW.idfornecedor := nextval('seq_idfornecedor');
        INSERT INTO fornecedor (idfornecedor, razao_social)
        VALUES (NEW.idfornecedor, 'Fornecedor a cadastrar (produto ' || NEW.produto_id || ')');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gera_idfornecedor ON produtos_filial;
CREATE TRIGGER trg_gera_idfornecedor
BEFORE INSERT ON produtos_filial
FOR EACH ROW EXECUTE FUNCTION fn_gera_idfornecedor();

-- Teste (ROLLBACK não deixa lixo no banco; a sequência, como sempre, não volta atrás)
BEGIN;
INSERT INTO produtos_filial (filial_id, produto_id, descricao, estoque, preco_unitario, preco_compra, preco_venda)
VALUES (1, 'P99', 'Produto de teste', 5, 10, 5, 12);
SELECT p.produto_id, p.idfornecedor, f.razao_social
  FROM produtos_filial p JOIN fornecedor f ON f.idfornecedor = p.idfornecedor
 WHERE p.produto_id = 'P99';
ROLLBACK;
