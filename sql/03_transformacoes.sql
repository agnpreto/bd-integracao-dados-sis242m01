-- =====================================================================
-- 03_transformacoes.sql : Parte 3 - Transformações de dados (PostgreSQL)
-- Rode DEPOIS do scripts/importar.py.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Funções auxiliares (itens 1 e 2)
-- ---------------------------------------------------------------------
-- 1) "12345 - Detergente". "Onde houver": sem descrição, devolve só o
--    código (sem um " - " sobrando no fim).
CREATE OR REPLACE FUNCTION fn_produto_desc(p_id varchar, p_desc varchar)
RETURNS varchar LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE WHEN NULLIF(TRIM(p_desc), '') IS NULL THEN TRIM(p_id)
                ELSE TRIM(p_id) || ' - ' || TRIM(p_desc) END
$$;

-- 2) Data no formato DD/MM/YYYY
CREATE OR REPLACE FUNCTION fn_data_br(p_data date)
RETURNS varchar LANGUAGE sql IMMUTABLE AS $$
    SELECT TO_CHAR(p_data, 'DD/MM/YYYY')
$$;
-- No MySQL: CONCAT(produto_id, ' - ', descricao) e DATE_FORMAT(data, '%d/%m/%Y')


-- ---------------------------------------------------------------------
-- Itens 1 e 2 aplicados a pedidos de compra, vendas e produtos
-- ---------------------------------------------------------------------
-- Pedidos: usa a descrição do pedido; se faltar, a do cadastro
CREATE OR REPLACE VIEW vw_pedido_compra_formatado AS
SELECT  fn_produto_desc(pc.produto_id, COALESCE(pc.descricao_produto, p.descricao)) AS "Produto",
        pc.pedido_id                AS "Pedido",
        pc.qtde_pedida              AS "Qtde Requisitada",
        fn_data_br(pc.data_pedido)  AS "Data Solicitação",
        fn_data_br(pc.data_entrega) AS "Data Entrega"
FROM    pedido_compra pc
LEFT JOIN produtos_filial p ON p.filial_id = pc.filial_id AND p.produto_id = pc.produto_id;

-- Vendas: a tabela venda não tem descrição, que vem do cadastro. P21 a P28
-- não têm cadastro, então aparece só o código ("onde houver").
CREATE OR REPLACE VIEW vw_venda_formatada AS
SELECT  fn_produto_desc(v.produto_id, p.descricao)  AS "Produto",
        v.venda_id                                  AS "Venda",
        v.qtde_vendida                              AS "Qtde Vendida",
        ROUND(v.qtde_vendida * v.valor_unitario, 2) AS "Valor Total",
        fn_data_br(v.data_emissao)                  AS "Data Emissão"
FROM    venda v
LEFT JOIN produtos_filial p ON p.filial_id = v.filial_id AND p.produto_id = v.produto_id;

-- Produtos
CREATE OR REPLACE VIEW vw_produtos_formatado AS
SELECT  fn_produto_desc(p.produto_id, p.descricao) AS "Produto",
        p.filial_id   AS "Filial",
        p.estoque     AS "Estoque",
        p.preco_venda AS "Preço Venda",
        f.razao_social AS "Fornecedor"
FROM    produtos_filial p
LEFT JOIN fornecedor f ON f.idfornecedor = p.idfornecedor;

SELECT * FROM vw_pedido_compra_formatado ORDER BY "Pedido";
SELECT * FROM vw_venda_formatada         ORDER BY "Venda";
SELECT * FROM vw_produtos_formatado      ORDER BY "Produto";


-- ---------------------------------------------------------------------
-- 3) Somente os produtos requisitados "MAIS DE 10 VEZES" no período
-- ---------------------------------------------------------------------
-- COMO INTERPRETEI:
--   Leitura literal: "10 vezes" = 10 requisições (pedidos distintos) do mesmo
--   produto. Nesta base nenhum produto tem mais de 2 pedidos (consulta 3.3-b),
--   então a leitura literal devolve ZERO linhas (consulta 3.3-a).
--   O exemplo do enunciado ("12345 - Detergente | 15 | 01/01/2025") mostra UMA
--   linha por solicitação, com "Qtde Requisitada" = 15, maior que 10. Por isso
--   a interpretação adotada é:
--     "mais de 10" = requisições (linhas de pedido) com QUANTIDADE requisitada
--     maior que 10 unidades.
--   Resultado nesta base: 21 das 29 requisições. Ficam de fora os pedidos 22 a
--   29 (de 2 a 9 unidades).
--   Período = todo o intervalo da base (data_pedido de 02/01/2025 a
--   01/03/2025). Para só fevereiro, troque as datas no CTE "periodo".
--   Pedidos sem data_pedido ficariam de fora (não há como saber o período).
WITH periodo AS (
    SELECT MIN(data_pedido) AS ini, MAX(data_pedido) AS fim FROM pedido_compra
    -- SELECT DATE '2025-02-01', DATE '2025-02-28'     -- só fevereiro/2025
)
SELECT  fn_produto_desc(pc.produto_id, pc.descricao_produto) AS "Produto",
        pc.qtde_pedida                                     AS "Qtde Requisitada",
        fn_data_br(pc.data_pedido)                         AS "Data Solicitação"
FROM    pedido_compra pc
CROSS JOIN periodo
WHERE   pc.data_pedido BETWEEN periodo.ini AND periodo.fim
  AND   pc.qtde_pedida > 10
ORDER BY pc.data_pedido, pc.produto_id;

-- Variação: total do produto no período > 10 (uma linha por produto)
SELECT  fn_produto_desc(produto_id, MAX(descricao_produto)) AS "Produto",
        SUM(qtde_pedida)                                    AS "Qtde Requisitada",
        fn_data_br(MIN(data_pedido))                        AS "1ª Solicitação"
FROM    pedido_compra
GROUP BY produto_id
HAVING  SUM(qtde_pedida) > 10
ORDER BY produto_id;

-- 3.3-a  Prova da leitura literal (nº de requisições por produto > 10):
--        retorna 0 linhas nesta base (o máximo é 2)
SELECT  fn_produto_desc(produto_id, MAX(descricao_produto)) AS "Produto",
        COUNT(DISTINCT pedido_id)                           AS "Nº de requisições",
        SUM(qtde_pedida)                                    AS "Qtde Requisitada"
FROM    pedido_compra
GROUP BY produto_id
HAVING  COUNT(DISTINCT pedido_id) > 10;

-- 3.3-b  Conferência: requisições por produto (mostra o máximo = 2)
SELECT  produto_id, COUNT(DISTINCT pedido_id) AS requisicoes, SUM(qtde_pedida) AS qtde
FROM    pedido_compra
GROUP BY produto_id
ORDER BY requisicoes DESC, produto_id;


-- ---------------------------------------------------------------------
-- 4) TRIGGER: novo idfornecedor NUMÉRICO na tabela de produtos,
--    relacionado à tabela fornecedor
-- ---------------------------------------------------------------------
-- Contexto: na planilha o fornecedor vem como 'F1', 'F2'... (texto). No banco
-- o id é integer (fornecedor.idfornecedor IDENTITY) e o importar.py converte
-- 'F8' para 8.
-- Regra (BEFORE INSERT OR UPDATE OF idfornecedor ON produtos_filial):
--   a) idfornecedor NULL: pega o próximo número da IDENTITY de fornecedor,
--      cria o fornecedor "A CADASTRAR" e grava o id no produto;
--   b) idfornecedor informado mas inexistente: cria o fornecedor com esse id
--      (a FK não barra o produto) e avança a sequência;
--   c) idfornecedor existente: não faz nada.
-- Usar a sequência (e não MAX()+1) evita que dois INSERTs simultâneos gerem o
-- mesmo número. O importar.py faz o setval da sequência depois da carga;
-- sem isso, o 1º número gerado seria 1, que já existe.
CREATE OR REPLACE FUNCTION fn_produtos_filial_fornecedor()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    v_seq text := pg_get_serial_sequence('fornecedor', 'idfornecedor');
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        NEW.idfornecedor := nextval(v_seq);
        INSERT INTO fornecedor (idfornecedor, razao_social)
        VALUES (NEW.idfornecedor, 'FORNECEDOR A CADASTRAR - produto ' || NEW.produto_id);

    ELSIF NOT EXISTS (SELECT 1 FROM fornecedor WHERE idfornecedor = NEW.idfornecedor) THEN
        INSERT INTO fornecedor (idfornecedor, razao_social)
        VALUES (NEW.idfornecedor, 'FORNECEDOR A CADASTRAR - id ' || NEW.idfornecedor);
        PERFORM setval(v_seq, GREATEST(NEW.idfornecedor,
                                       (SELECT MAX(idfornecedor) FROM fornecedor)));
    END IF;
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_produtos_filial_fornecedor ON produtos_filial;
CREATE TRIGGER trg_produtos_filial_fornecedor
BEFORE INSERT OR UPDATE OF idfornecedor ON produtos_filial
FOR EACH ROW EXECUTE FUNCTION fn_produtos_filial_fornecedor();

-- Teste da trigger dentro de uma transação desfeita (não altera a base).
-- Exemplo prático: cadastrar P21 (vendido, mas sem cadastro) sem fornecedor.
BEGIN;
INSERT INTO produtos_filial (filial_id, produto_id, descricao) VALUES (1, 'P21', 'Produto 21');
INSERT INTO produtos_filial (filial_id, produto_id, descricao, idfornecedor) VALUES (1, 'P22', 'Produto 22', 50);
SELECT p.produto_id, p.idfornecedor, f.razao_social
FROM produtos_filial p JOIN fornecedor f ON f.idfornecedor = p.idfornecedor
WHERE p.produto_id IN ('P21', 'P22');
ROLLBACK;
