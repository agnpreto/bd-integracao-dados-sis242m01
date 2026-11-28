-- 03_transformacoes
-- Nome:Emilly Melissa e Bruna Muro
-- Objetivo: Transformacoes de dados e trigger de idfornecedor numerico (PostgreSQL)

SELECT
    CONCAT(
        TRIM(pc.produto_id),
        ' - ',
        COALESCE(NULLIF(TRIM(pc.descricao_produto), ''), NULLIF(TRIM(pf.decricao), ''), 'Sem descricao')
    ) AS "Produto",
    pc.qtde_pedida AS "Qtde Requisitada",
    TO_CHAR(pc.data_pedido, 'DD/MM/YYYY') AS "Data Solicitação"
FROM public.pedido_compra pc
LEFT JOIN public.produtos_filial pf
       ON pf.idproduto = pc.produto_id
      AND pf.filial_id = pc.filial_id
WHERE pc.data_pedido IS NOT NULL
ORDER BY pc.data_pedido, pc.produto_id;

SELECT
    CONCAT(
        TRIM(v.produto_id),
        ' - ',
        COALESCE(NULLIF(TRIM(pf.decricao), ''), 'Sem descricao')
    ) AS "Produto",
    v.qtde_vendida AS "Qtde Vendida",
    TO_CHAR(v.data_emissao, 'DD/MM/YYYY') AS "Data Emissão"
FROM public.venda v
LEFT JOIN public.produtos_filial pf
       ON pf.idproduto = v.produto_id
      AND pf.filial_id = v.filial_id
WHERE v.data_emissao IS NOT NULL
ORDER BY v.data_emissao, v.produto_id;

SELECT
    CONCAT(
        TRIM(pc.produto_id),
        ' - ',
        COALESCE(NULLIF(TRIM(MAX(pc.descricao_produto)), ''), NULLIF(TRIM(MAX(pf.decricao)), ''), 'Sem descricao')
    ) AS "Produto",
    COUNT(*) AS "Qtd Requisicoes",
    SUM(pc.qtde_pedida) AS "Qtde Requisitada",
    TO_CHAR(MIN(pc.data_pedido), 'DD/MM/YYYY') AS "Primeira Solicitação",
    TO_CHAR(MAX(pc.data_pedido), 'DD/MM/YYYY') AS "Última Solicitação"
FROM public.pedido_compra pc
LEFT JOIN public.produtos_filial pf
       ON pf.idproduto = pc.produto_id
      AND pf.filial_id = pc.filial_id
WHERE pc.data_pedido >= DATE '2025-02-01'
  AND pc.data_pedido <  DATE '2025-03-01'
GROUP BY pc.produto_id
HAVING COUNT(*) > 10
ORDER BY "Qtd Requisicoes" DESC, "Produto";

CREATE OR REPLACE FUNCTION public.fn_gerar_idfornecedor_numerico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_numerico_texto TEXT;
    v_proximo_num BIGINT;
    v_razao_origem TEXT;
BEGIN
    IF NEW.idfornecedor IS NOT NULL AND TRIM(NEW.idfornecedor) ~ '^[0-9]+$' THEN
        v_id_numerico_texto := TRIM(NEW.idfornecedor);
    ELSE
        -- Tenta extrair digitos caso venha algo como 'F8' ou 'F9'
        v_id_numerico_texto := NULLIF(regexp_replace(COALESCE(NEW.idfornecedor, ''), '[^0-9]', '', 'g'), '');

        -- Se nao houver digitos ou ja existir outro codigo usando esse numero, gera o proximo sequencial
        IF v_id_numerico_texto IS NULL OR EXISTS (
            SELECT 1
            FROM public.fornecedor f
            WHERE f.idfornecedor = v_id_numerico_texto
              AND COALESCE(NEW.idfornecedor, '') <> v_id_numerico_texto
        ) THEN
            SELECT COALESCE(MAX(CAST(idfornecedor AS BIGINT)), 0) + 1
              INTO v_proximo_num
              FROM public.fornecedor
             WHERE idfornecedor ~ '^[0-9]+$';

            v_id_numerico_texto := v_proximo_num::TEXT;
        END IF;
    END IF;

    SELECT COALESCE(f.razao_social, 'Fornecedor ' || v_id_numerico_texto)
      INTO v_razao_origem
      FROM public.fornecedor f
     WHERE f.idfornecedor = NEW.idfornecedor;

    IF v_razao_origem IS NULL THEN
        v_razao_origem := 'Fornecedor ' || v_id_numerico_texto;
    END IF;

    INSERT INTO public.fornecedor (idfornecedor, razao_social)
    VALUES (v_id_numerico_texto, v_razao_origem)
    ON CONFLICT (idfornecedor) DO NOTHING;

    NEW.idfornecedor := v_id_numerico_texto;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_produtos_filial_idfornecedor_num ON public.produtos_filial;

CREATE TRIGGER trg_produtos_filial_idfornecedor_num
BEFORE INSERT OR UPDATE OF idfornecedor ON public.produtos_filial
FOR EACH ROW
EXECUTE FUNCTION public.fn_gerar_idfornecedor_numerico();

