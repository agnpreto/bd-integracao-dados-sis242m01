-- =====================================================================
-- 03_transformacoes.sql  |  Parte 3: transformações de dados (PostgreSQL)
-- Nome: Franklin Mendonça
-- Rodar depois de 01_ddl_postgres.sql + scripts/importar.py
-- =====================================================================


-- ---------------------------------------------------------------------
-- 3.1 Concatenar produto_id e descricao_produto, formato '12345 - Detergente'
-- Onde não há descrição, devolve só o produto_id (sem " - " sobrando).
-- CONCAT_WS ignora NULL; NULLIF(TRIM(..), '') também trata descrição vazia.
-- ---------------------------------------------------------------------

-- pedido_compra (tem descricao_produto)
SELECT pedido_id,
       CONCAT_WS(' - ', produto_id, NULLIF(TRIM(descricao_produto), '')) AS produto
FROM public.pedido_compra
ORDER BY pedido_id;

-- venda (não tem descrição: busca em produtos_filial; P22 a P28 não existem lá)
SELECT v.venda_id,
       CONCAT_WS(' - ', v.produto_id, NULLIF(TRIM(MIN(p.descricao)), '')) AS produto
FROM public.venda v
LEFT JOIN public.produtos_filial p ON p.produto_id = v.produto_id
GROUP BY v.venda_id, v.produto_id
ORDER BY v.venda_id;

-- produtos_filial
SELECT filial_id,
       CONCAT_WS(' - ', produto_id, NULLIF(TRIM(descricao), '')) AS produto
FROM public.produtos_filial
ORDER BY filial_id, produto_id;


-- ---------------------------------------------------------------------
-- 3.2 Datas no formato DD/MM/YYYY
-- TO_CHAR devolve texto (só para exibir). Para filtrar ou ordenar, use o
-- campo DATE original, pois texto DD/MM/YYYY ordena errado.
-- ---------------------------------------------------------------------
SELECT pedido_id,
       TO_CHAR(data_pedido,  'DD/MM/YYYY') AS data_pedido,
       TO_CHAR(data_entrega, 'DD/MM/YYYY') AS data_entrega
FROM public.pedido_compra
ORDER BY pedido_id;

SELECT venda_id,
       TO_CHAR(data_emissao, 'DD/MM/YYYY') AS data_emissao
FROM public.venda
ORDER BY venda_id;


-- ---------------------------------------------------------------------
-- 3.3 Somente produtos requisitados "mais de 10 vezes" no período
-- INTERPRETAÇÃO ADOTADA: "vezes" = unidades requisitadas, isto é,
-- SUM(qtde_pedida) do produto no período > 10. Motivo: o exemplo do
-- enunciado mostra a coluna "Qtde Requisitada" (15) por data de solicitação.
-- Contar linhas de pedido não serve: no máximo 2 pedidos por produto, então
-- a consulta voltaria vazia (confira com a variante abaixo).
-- O período está no CTE "periodo" (padrão: todo o intervalo da planilha).
-- Resultado no layout do exemplo: Produto | Qtde Requisitada | Data Solicitação.
-- ---------------------------------------------------------------------
WITH periodo AS (
    SELECT DATE '2025-01-01' AS inicio, DATE '2025-03-31' AS fim
),
req AS (
    SELECT pc.produto_id,
           pc.descricao_produto,
           pc.qtde_pedida,
           pc.data_pedido,
           SUM(pc.qtde_pedida) OVER (PARTITION BY pc.produto_id) AS total_produto
    FROM public.pedido_compra pc, periodo
    WHERE pc.data_pedido BETWEEN periodo.inicio AND periodo.fim
)
SELECT CONCAT_WS(' - ', produto_id, NULLIF(TRIM(descricao_produto), '')) AS "Produto",
       qtde_pedida                                                        AS "Qtde Requisitada",
       TO_CHAR(data_pedido, 'DD/MM/YYYY')                                 AS "Data Solicitação"
FROM req
WHERE total_produto > 10
ORDER BY produto_id, data_pedido;

-- Variante para comparação: interpretando como NÚMERO DE PEDIDOS > 10.
-- Retorna 0 linhas com os dados da planilha (máximo de 2 pedidos por produto).
SELECT produto_id, COUNT(*) AS vezes_requisitado
FROM public.pedido_compra
WHERE data_pedido BETWEEN DATE '2025-01-01' AND DATE '2025-03-31'
GROUP BY produto_id
HAVING COUNT(*) > 10;


-- ---------------------------------------------------------------------
-- 3.4 Trigger que gera automaticamente um novo idfornecedor em produtos_filial
-- Regra: se um produto for inserido SEM idfornecedor, a trigger
--   1) pega o próximo número de uma sequence (numérica),
--   2) cria o fornecedor correspondente na tabela fornecedor, e
--   3) grava esse código no produto, mantendo a FK/relacionamento.
-- Como a planilha usa códigos textuais (F1..F20, ver Erro 08 do DDL), o
-- código gerado segue o mesmo padrão: 'F' || número da sequence (F21, F22...).
-- Se o idfornecedor vier preenchido, a trigger não mexe em nada.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_gera_idfornecedor ON public.produtos_filial;
DROP FUNCTION IF EXISTS public.fn_gera_idfornecedor();
DROP SEQUENCE IF EXISTS public.seq_idfornecedor;

CREATE SEQUENCE public.seq_idfornecedor;

-- Começa depois do maior número já existente (F20 => próximo é 21).
SELECT setval(
    'public.seq_idfornecedor',
    COALESCE(MAX(NULLIF(REGEXP_REPLACE(idfornecedor, '\D', '', 'g'), '')::BIGINT), 0) + 1,
    false)
FROM public.fornecedor;

CREATE FUNCTION public.fn_gera_idfornecedor() RETURNS trigger AS $$
DECLARE
    novo_id VARCHAR(25);
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        novo_id := 'F' || nextval('public.seq_idfornecedor');
        INSERT INTO public.fornecedor (idfornecedor, razao_social)
        VALUES (novo_id, 'Fornecedor ' || SUBSTRING(novo_id FROM 2) || ' (gerado automaticamente)');
        NEW.idfornecedor := novo_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gera_idfornecedor
BEFORE INSERT ON public.produtos_filial
FOR EACH ROW EXECUTE FUNCTION public.fn_gera_idfornecedor();

-- Teste (desfeito com ROLLBACK; não deixa lixo no banco):
-- BEGIN;
--   INSERT INTO public.produtos_filial (filial_id, produto_id, descricao)
--   VALUES (1, 'P99', 'Produto de teste');
--   SELECT p.produto_id, p.idfornecedor, f.razao_social
--   FROM public.produtos_filial p JOIN public.fornecedor f USING (idfornecedor)
--   WHERE p.produto_id = 'P99';
-- ROLLBACK;
-- (a sequence não volta no ROLLBACK, comportamento normal do PostgreSQL)

-- Equivalente em MySQL 8 (não executado aqui): BEFORE INSERT, sem sequence;
-- usar uma tabela auxiliar com AUTO_INCREMENT ou
--   SELECT COALESCE(MAX(CAST(SUBSTRING(idfornecedor, 2) AS UNSIGNED)), 0) + 1
-- dentro da trigger, inserindo antes o fornecedor e fazendo SET NEW.idfornecedor.
