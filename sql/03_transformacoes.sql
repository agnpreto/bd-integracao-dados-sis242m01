-- 03_transformacoes
-- Nome: Izabelly Cantalice

-- Explicação da interpretação de "requisitados mais de 10 vezes no período":
-- Interpretou-se de duas formas complementares:
-- 1) Produtos cujo código aparece em mais de 10 registros de pedido_compra (COUNT(*) > 10).
-- 2) Produtos cuja quantidade requisitada (qtde_pedida) no pedido é superior a 10 unidades.

-- 1, 2 e 3 ( Critério A: produtos solicitados em mais de 10 pedidos distintos no período ):
SELECT
    CONCAT(pc.produto_id, ' - ', COALESCE(pc.descricao_produto, pf.descricao, 'Sem descrição')) AS "Produto",
    pc.qtde_pedida AS "Qtde Requisitada",
    TO_CHAR(pc.data_pedido, 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc
LEFT JOIN public.produtos_filial pf
    ON pf.produto_id = pc.produto_id
   AND pf.filial_id = pc.filial_id
WHERE pc.produto_id IN (
    SELECT produto_id
    FROM public.pedido_compra
    GROUP BY produto_id
    HAVING COUNT(*) > 10
)
ORDER BY pc.produto_id, pc.data_pedido;

-- 1, 2 e 3 ( Critério B: pedidos com quantidade requisitada > 10 ):
SELECT
    CONCAT(pc.produto_id, ' - ', COALESCE(pc.descricao_produto, pf.descricao, 'Sem descrição')) AS "Produto",
    pc.qtde_pedida AS "Qtde Requisitada",
    TO_CHAR(pc.data_pedido, 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc
LEFT JOIN public.produtos_filial pf
    ON pf.produto_id = pc.produto_id
   AND pf.filial_id = pc.filial_id
WHERE pc.qtde_pedida > 10
ORDER BY pc.qtde_pedida DESC, pc.data_pedido;

-- 4. Trigger que gera automaticamente um novo idfornecedor numérico na tabela de produtos
-- e garante o vínculo na tabela fornecedor:
CREATE SEQUENCE IF NOT EXISTS seq_idfornecedor START WITH 1000 INCREMENT BY 1;

CREATE OR REPLACE FUNCTION public.fn_gerar_idfornecedor_produto()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.idfornecedor IS NULL OR TRIM(NEW.idfornecedor) = '' OR TRIM(NEW.idfornecedor) = '0' THEN
        NEW.idfornecedor := NEXTVAL('seq_idfornecedor')::varchar;
    END IF;

    INSERT INTO public.fornecedor (idfornecedor, razao_social)
    VALUES (NEW.idfornecedor, 'Fornecedor Automático ' || NEW.idfornecedor)
    ON CONFLICT (idfornecedor) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_gerar_idfornecedor_produto ON public.produtos_filial;

CREATE TRIGGER trg_gerar_idfornecedor_produto
BEFORE INSERT ON public.produtos_filial
FOR EACH ROW
EXECUTE FUNCTION public.fn_gerar_idfornecedor_produto();