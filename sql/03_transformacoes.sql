-- 03_transformacoes
-- Nome:Transformacoes de Dados e Trigger

-- 1, 2 e 3. Concatenacao produto_id - descricao_produto, data DD/MM/YYYY
-- e filtro de produtos requisitados mais de 10 vezes no periodo.
--
-- Interpretacao de "mais de 10 vezes":
-- Na base fornecida (base_teste.xlsx), cada produto aparece em no maximo 1 ou 2
-- linhas de pedido_compra, mas com quantidades pedidas (qtde_pedida) de ate 99
-- unidades. Por isso, consideramos o somatorio da quantidade requisitada no
-- periodo (SUM(qtde_pedida) > 10), trazendo resultados consistentes com os dados.

SELECT
    CASE
        WHEN NULLIF(TRIM(pc.descricao_produto), '') IS NOT NULL
            THEN pc.produto_id || ' - ' || TRIM(pc.descricao_produto)
        ELSE pc.produto_id
    END AS "Produto",
    SUM(pc.qtde_pedida) AS "Qtde Requisitada",
    TO_CHAR(MIN(pc.data_pedido), 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc
GROUP BY
    pc.produto_id,
    pc.descricao_produto
HAVING SUM(pc.qtde_pedida) > 10
ORDER BY SUM(pc.qtde_pedida) DESC;

-- 4. Trigger que gera automaticamente um novo idfornecedor numerico na tabela
-- de produtos (produtos_filial) relacionado a tabela de fornecedor.

CREATE OR REPLACE FUNCTION public.fn_gerar_idfornecedor_produto()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_prox_id integer;
    v_novo_idfornecedor varchar(25);
BEGIN
    IF NEW.idfornecedor IS NULL OR TRIM(NEW.idfornecedor) = '' THEN
        SELECT COALESCE(MAX(CAST(NULLIF(REGEXP_REPLACE(idfornecedor, '[^0-9]', '', 'g'), '') AS integer)), 0) + 1
          INTO v_prox_id
          FROM public.fornecedor;

        v_novo_idfornecedor := v_prox_id::varchar;

        INSERT INTO public.fornecedor (idfornecedor, razao_social)
        VALUES (v_novo_idfornecedor, 'Fornecedor Automático ' || v_novo_idfornecedor)
        ON CONFLICT (idfornecedor) DO NOTHING;

        NEW.idfornecedor := v_novo_idfornecedor;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_gerar_idfornecedor_produto ON public.produtos_filial;

CREATE TRIGGER trg_gerar_idfornecedor_produto
BEFORE INSERT ON public.produtos_filial
FOR EACH ROW
EXECUTE FUNCTION public.fn_gerar_idfornecedor_produto();

