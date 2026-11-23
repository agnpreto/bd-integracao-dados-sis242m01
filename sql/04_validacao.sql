-- =====================================================================
-- 04_validacao.sql  |  Parte 4: consultas para a reunião de validação
-- Nome: Franklin Mendonça
-- Foco: dados de fevereiro/2025 (as consultas de erros olham a base toda,
-- para mostrar também o que está fora do mês). PostgreSQL.
-- Ordem: A) conferência de totais, B) resumo de erros, C) detalhe de cada erro.
-- =====================================================================


-- =====================================================================
-- A) CONFERÊNCIA DE TOTAIS (bater com os números do cliente / planilha)
-- =====================================================================

-- A1. Linhas por tabela (deve bater com a planilha: 20 / 20 / 29 / 20 / 33)
SELECT 'fornecedor' AS tabela, COUNT(*) AS linhas FROM public.fornecedor
UNION ALL SELECT 'produtos_filial',     COUNT(*) FROM public.produtos_filial
UNION ALL SELECT 'pedido_compra',       COUNT(*) FROM public.pedido_compra
UNION ALL SELECT 'entradas_mercadoria', COUNT(*) FROM public.entradas_mercadoria
UNION ALL SELECT 'venda',               COUNT(*) FROM public.venda;

-- A2. Totais de vendas de fevereiro/2025 por filial (linhas, quantidade, R$)
SELECT filial_id,
       COUNT(*)                                          AS linhas,
       COUNT(DISTINCT produto_id)                        AS produtos,
       SUM(qtde_vendida)                                 AS qtde_total,
       ROUND(SUM(qtde_vendida * valor_unitario)::numeric, 2) AS total_rs
FROM public.venda
WHERE data_emissao >= DATE '2025-02-01' AND data_emissao < DATE '2025-03-01'
GROUP BY ROLLUP (filial_id)
ORDER BY filial_id NULLS LAST;

-- A3. Pedidos de compra e entradas em fevereiro/2025 (volume e valor)
SELECT 'pedidos (data_pedido)' AS origem, COUNT(*) AS linhas,
       SUM(qtde_pedida) AS qtde,
       ROUND(SUM(qtde_pedida * preco_compra)::numeric, 2) AS valor_rs
FROM public.pedido_compra
WHERE data_pedido >= DATE '2025-02-01' AND data_pedido < DATE '2025-03-01'
UNION ALL
SELECT 'entradas (data_entrada)', COUNT(*), SUM(qtde_recebida),
       ROUND(SUM(qtde_recebida * custo_unitario)::numeric, 2)
FROM public.entradas_mercadoria
WHERE data_entrada >= DATE '2025-02-01' AND data_entrada < DATE '2025-03-01';

-- A4. Distribuição das vendas por mês (mostra o que está fora de fevereiro)
SELECT TO_CHAR(data_emissao, 'YYYY-MM') AS mes, COUNT(*) AS linhas,
       ROUND(SUM(qtde_vendida * valor_unitario)::numeric, 2) AS total_rs
FROM public.venda GROUP BY 1 ORDER BY 1;

-- A5. Chaves duplicadas (esperado: 0 linhas; as PKs já impedem, é prova)
SELECT 'venda' AS tabela, filial_id, venda_id, data_emissao, produto_id, item, horariomov, COUNT(*)
FROM public.venda GROUP BY filial_id, venda_id, data_emissao, produto_id, item, horariomov HAVING COUNT(*) > 1;


-- =====================================================================
-- B) RESUMO DOS ERROS DE DADOS (uma linha por problema, com a quantidade)
-- Cada código E01.. tem a consulta de detalhe na seção C.
-- =====================================================================
SELECT * FROM (
    SELECT 'E01' AS cod, 'pedido_compra com ordem_compra = 0 (sem ordem)' AS problema, COUNT(*) AS qtde
      FROM public.pedido_compra WHERE ordem_compra = 0
    UNION ALL SELECT 'E02', 'pedido_compra com data_entrega anterior à data_pedido', COUNT(*)
      FROM public.pedido_compra WHERE data_entrega < data_pedido
    UNION ALL SELECT 'E03', 'pedido_compra com fornecedor diferente do cadastrado no produto', COUNT(*)
      FROM public.pedido_compra pc JOIN public.produtos_filial p
        ON p.produto_id = pc.produto_id AND p.filial_id = pc.filial_id
      WHERE pc.fornecedor_id <> p.idfornecedor
    UNION ALL SELECT 'E04', 'entrada com quantidade recebida maior que a pedida', COUNT(*)
      FROM public.entradas_mercadoria e JOIN public.pedido_compra pc
        ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
      WHERE e.qtde_recebida > pc.qtde_pedida
    UNION ALL SELECT 'E05', 'entrada com data anterior ao pedido de compra', COUNT(*)
      FROM public.entradas_mercadoria e JOIN public.pedido_compra pc
        ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
      WHERE e.data_entrada < pc.data_pedido
    UNION ALL SELECT 'E06', 'entrada sem pedido de compra ligado pela ordem_compra', COUNT(*)
      FROM public.entradas_mercadoria e
      WHERE NOT EXISTS (SELECT 1 FROM public.pedido_compra pc
                        WHERE pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id)
    UNION ALL SELECT 'E07', 'qtde_entregue do pedido diferente da qtde_recebida na entrada', COUNT(*)
      FROM public.pedido_compra pc JOIN public.entradas_mercadoria e
        ON e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id
      WHERE pc.qtde_entregue <> e.qtde_recebida
    UNION ALL SELECT 'E08', 'custo da entrada diferente do preço do pedido de compra', COUNT(*)
      FROM public.pedido_compra pc JOIN public.entradas_mercadoria e
        ON e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id
      WHERE ROUND(e.custo_unitario::numeric, 2) <> ROUND(pc.preco_compra::numeric, 2)
    UNION ALL SELECT 'E09', 'pedidos repetidos (mesmo produto e data de pedido)', COUNT(*)
      FROM (SELECT produto_id, data_pedido FROM public.pedido_compra
            GROUP BY produto_id, data_pedido HAVING COUNT(*) > 1) d
    UNION ALL SELECT 'E10', 'venda de produto que não existe no cadastro (produtos_filial)', COUNT(*)
      FROM public.venda v
      WHERE NOT EXISTS (SELECT 1 FROM public.produtos_filial p WHERE p.produto_id = v.produto_id)
    UNION ALL SELECT 'E11', 'venda em filial sem nenhum produto cadastrado (filiais 2 e 3)', COUNT(*)
      FROM public.venda v
      WHERE NOT EXISTS (SELECT 1 FROM public.produtos_filial p WHERE p.filial_id = v.filial_id)
    UNION ALL SELECT 'E12', 'venda com quantidade fracionada em unidade UN', COUNT(*)
      FROM public.venda WHERE unidade_medida = 'UN' AND qtde_vendida <> TRUNC(qtde_vendida)
    UNION ALL SELECT 'E13', 'venda com valor_unitario diferente do preco_venda do cadastro', COUNT(*)
      FROM public.venda v JOIN public.produtos_filial p
        ON p.produto_id = v.produto_id AND p.filial_id = v.filial_id
      WHERE ROUND(v.valor_unitario::numeric, 2) <> ROUND(p.preco_venda::numeric, 2)
    UNION ALL SELECT 'E14', 'mesmo valor_unitario repetido em produtos diferentes (suspeita de cópia)', COUNT(*)
      FROM (SELECT valor_unitario FROM public.venda
            GROUP BY valor_unitario HAVING COUNT(DISTINCT produto_id) > 1) d
    UNION ALL SELECT 'E15', 'produto com preço de compra maior que o preço de venda (margem negativa)', COUNT(*)
      FROM public.produtos_filial WHERE preco_compra > preco_venda
    UNION ALL SELECT 'E16', 'vendas fora de fevereiro/2025 na base de teste (informativo)', COUNT(*)
      FROM public.venda
      WHERE data_emissao < DATE '2025-02-01' OR data_emissao >= DATE '2025-03-01'
) x ORDER BY cod;


-- =====================================================================
-- C) DETALHE DE CADA ERRO (as linhas que o cliente precisa corrigir)
-- =====================================================================

-- E01. Pedidos sem ordem_compra (impede ligar com a entrada de mercadoria)
SELECT pedido_id, produto_id, data_pedido, ordem_compra, qtde_pedida, qtde_entregue
FROM public.pedido_compra WHERE ordem_compra = 0 ORDER BY pedido_id;

-- E02. Entrega prevista antes de o pedido existir
SELECT pedido_id, produto_id, data_pedido, data_entrega
FROM public.pedido_compra WHERE data_entrega < data_pedido ORDER BY pedido_id;

-- E03. Fornecedor do pedido x fornecedor do cadastro do produto
SELECT pc.pedido_id, pc.produto_id, pc.fornecedor_id AS fornecedor_no_pedido,
       p.idfornecedor AS fornecedor_no_cadastro
FROM public.pedido_compra pc
JOIN public.produtos_filial p ON p.produto_id = pc.produto_id AND p.filial_id = pc.filial_id
WHERE pc.fornecedor_id <> p.idfornecedor ORDER BY pc.pedido_id;

-- E04. Recebeu mais do que pediu
SELECT e.nro_nfe, e.produto_id, pc.qtde_pedida, e.qtde_recebida,
       e.qtde_recebida - pc.qtde_pedida AS excedente
FROM public.entradas_mercadoria e
JOIN public.pedido_compra pc ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
WHERE e.qtde_recebida > pc.qtde_pedida ORDER BY e.nro_nfe;

-- E05. Mercadoria entrou antes de o pedido ser feito
SELECT e.nro_nfe, e.produto_id, pc.data_pedido, e.data_entrada
FROM public.entradas_mercadoria e
JOIN public.pedido_compra pc ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
WHERE e.data_entrada < pc.data_pedido ORDER BY e.nro_nfe;

-- E06. Notas de entrada sem pedido ligado (P19 e P20: pedido está com ordem_compra = 0)
SELECT e.nro_nfe, e.produto_id, e.ordem_compra, e.data_entrada, e.qtde_recebida
FROM public.entradas_mercadoria e
WHERE NOT EXISTS (SELECT 1 FROM public.pedido_compra pc
                  WHERE pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id)
ORDER BY e.nro_nfe;

-- E07. Quantidade "entregue" no pedido x quantidade "recebida" na nota
SELECT pc.pedido_id, pc.produto_id, pc.qtde_entregue AS entregue_no_pedido,
       e.qtde_recebida AS recebida_na_nota, e.nro_nfe
FROM public.pedido_compra pc
JOIN public.entradas_mercadoria e ON e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id
WHERE pc.qtde_entregue <> e.qtde_recebida ORDER BY pc.pedido_id;

-- E08. Custo da nota x preço combinado no pedido
SELECT pc.pedido_id, pc.produto_id, pc.preco_compra AS preco_pedido,
       e.custo_unitario AS custo_nota, e.nro_nfe
FROM public.pedido_compra pc
JOIN public.entradas_mercadoria e ON e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id
WHERE ROUND(e.custo_unitario::numeric, 2) <> ROUND(pc.preco_compra::numeric, 2)
ORDER BY pc.pedido_id;

-- E09. Pedidos repetidos: mesmo produto na mesma data de pedido (pedidos 21 a 29)
SELECT produto_id, data_pedido, COUNT(*) AS pedidos,
       STRING_AGG(pedido_id::text, ', ' ORDER BY pedido_id) AS pedido_ids
FROM public.pedido_compra GROUP BY produto_id, data_pedido HAVING COUNT(*) > 1
ORDER BY produto_id;

-- E10. Vendas de produtos que não existem no cadastro
SELECT v.produto_id, COUNT(*) AS vendas, SUM(v.qtde_vendida) AS qtde,
       ROUND(SUM(v.qtde_vendida * v.valor_unitario)::numeric, 2) AS total_rs
FROM public.venda v
WHERE NOT EXISTS (SELECT 1 FROM public.produtos_filial p WHERE p.produto_id = v.produto_id)
GROUP BY v.produto_id ORDER BY v.produto_id;

-- E11. Vendas em filiais que não têm nenhum produto cadastrado (só existe a filial 1)
SELECT v.venda_id, v.filial_id, v.produto_id, v.data_emissao
FROM public.venda v
WHERE NOT EXISTS (SELECT 1 FROM public.produtos_filial p WHERE p.filial_id = v.filial_id)
ORDER BY v.venda_id;

-- E12. Quantidade com casas decimais em unidade "UN"
SELECT venda_id, produto_id, qtde_vendida, unidade_medida
FROM public.venda WHERE unidade_medida = 'UN' AND qtde_vendida <> TRUNC(qtde_vendida)
ORDER BY venda_id;

-- E13. Preço vendido x preço de venda do cadastro
SELECT v.venda_id, v.produto_id, v.valor_unitario AS vendido, p.preco_venda AS cadastro
FROM public.venda v
JOIN public.produtos_filial p ON p.produto_id = v.produto_id AND p.filial_id = v.filial_id
WHERE ROUND(v.valor_unitario::numeric, 2) <> ROUND(p.preco_venda::numeric, 2)
ORDER BY v.venda_id;

-- E14. Mesmo preço em produtos diferentes (ex.: P13 e P21 a 61,85)
SELECT valor_unitario, STRING_AGG(DISTINCT produto_id, ', ' ORDER BY produto_id) AS produtos
FROM public.venda
GROUP BY valor_unitario HAVING COUNT(DISTINCT produto_id) > 1
ORDER BY valor_unitario;

-- E15. Preço de compra acima do preço de venda
SELECT filial_id, produto_id, preco_compra, preco_venda,
       ROUND((preco_venda - preco_compra)::numeric, 2) AS margem
FROM public.produtos_filial WHERE preco_compra > preco_venda ORDER BY margem;

-- E16. (informativo) Vendas fora de fevereiro (o que não entra na validação do mês)
SELECT venda_id, data_emissao, produto_id FROM public.venda
WHERE data_emissao < DATE '2025-02-01' OR data_emissao >= DATE '2025-03-01'
ORDER BY data_emissao, venda_id;
