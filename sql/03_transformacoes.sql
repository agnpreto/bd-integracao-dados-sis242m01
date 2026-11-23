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

-- 4) Trigger: gera automaticamente um idfornecedor numérico para o produto que chega sem fornecedor.
-- Funcionamento: antes de inserir em produtos_filial, se idfornecedor vier NULL, a trigger pega o próximo
-- número da sequência, cria o fornecedor correspondente (razão social provisória, a cadastrar) e preenche
-- o idfornecedor do produto. A chave estrangeira garante a relação com a tabela fornecedor.

-- Conferência prévia: produtos apontando para fornecedor inexistente (esperado: 0)
SELECT COUNT(*) AS orfaos
FROM produtos_filial pf
LEFT JOIN fornecedor f ON f.idfornecedor = pf.idfornecedor
WHERE pf.idfornecedor IS NOT NULL AND f.idfornecedor IS NULL;

ALTER TABLE produtos_filial DROP CONSTRAINT IF EXISTS fk_produtos_fornecedor;
ALTER TABLE produtos_filial
    ADD CONSTRAINT fk_produtos_fornecedor
    FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor);

-- Sequência alinhada ao maior id existente (o próximo gerado será max + 1)
CREATE SEQUENCE IF NOT EXISTS seq_idfornecedor;
SELECT setval('seq_idfornecedor', COALESCE(MAX(idfornecedor), 1), MAX(idfornecedor) IS NOT NULL)
FROM fornecedor;

CREATE OR REPLACE FUNCTION fn_gera_idfornecedor()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    novo integer;
BEGIN
    IF NEW.idfornecedor IS NULL THEN
        novo := nextval('seq_idfornecedor');
        INSERT INTO fornecedor (idfornecedor, razao_social)
        VALUES (novo, 'FORNECEDOR ' || novo || ' - A CADASTRAR');
        NEW.idfornecedor := novo;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_produtos_gera_idfornecedor ON produtos_filial;
CREATE TRIGGER trg_produtos_gera_idfornecedor
BEFORE INSERT ON produtos_filial
FOR EACH ROW
EXECUTE FUNCTION fn_gera_idfornecedor();
