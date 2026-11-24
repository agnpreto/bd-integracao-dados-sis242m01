-- =====================================================================
-- 04_validacao.sql : Parte 4 - Consultas da reunião de validação
--                    Mês de referência: FEVEREIRO/2025 (PostgreSQL)
-- Rode depois do scripts/importar.py (usa as tabelas stg.* e
-- importacao_rejeicoes que ele cria).
--   BLOCO A (A01-A06)  números para conferir com o cliente
--   BLOCO E (E01-E22)  erros nos dados, uma consulta por erro
--   BLOCO R (R01)      resumo: quantidade de cada erro
-- =====================================================================


-- #####################################################################
-- BLOCO A - Números de fevereiro/2025
-- #####################################################################

-- A01 - Carga: linhas na planilha x no banco (nada foi perdido)
SELECT 'fornecedor' AS tabela, (SELECT COUNT(*) FROM stg.fornecedor) AS planilha, (SELECT COUNT(*) FROM fornecedor) AS banco
UNION ALL SELECT 'produtos_filial',     (SELECT COUNT(*) FROM stg.produtos_filial),     (SELECT COUNT(*) FROM produtos_filial)
UNION ALL SELECT 'pedido_compra',       (SELECT COUNT(*) FROM stg.pedido_compra),       (SELECT COUNT(*) FROM pedido_compra)
UNION ALL SELECT 'entradas_mercadoria', (SELECT COUNT(*) FROM stg.entradas_mercadoria), (SELECT COUNT(*) FROM entradas_mercadoria)
UNION ALL SELECT 'venda',               (SELECT COUNT(*) FROM stg.venda),               (SELECT COUNT(*) FROM venda);

-- A02 - Vendas de fevereiro: totais de controle (cliente compara com o caixa/ERP)
SELECT  COUNT(*)                                     AS vendas,
        COUNT(DISTINCT produto_id)                   AS produtos,
        SUM(qtde_vendida)                            AS qtde_total,
        ROUND(SUM(qtde_vendida * valor_unitario), 2) AS faturamento_rs,
        MIN(data_emissao) AS primeira, MAX(data_emissao) AS ultima
FROM venda
WHERE data_emissao >= DATE '2025-02-01' AND data_emissao < DATE '2025-03-01';

-- A03 - Vendas de fevereiro por filial e por dia
SELECT  filial_id, data_emissao, COUNT(*) AS vendas,
        ROUND(SUM(qtde_vendida * valor_unitario), 2) AS faturamento_rs
FROM venda
WHERE data_emissao >= DATE '2025-02-01' AND data_emissao < DATE '2025-03-01'
GROUP BY ROLLUP (filial_id, data_emissao)
ORDER BY filial_id, data_emissao;

-- A04 - Fevereiro: quanto do faturamento é de produto COM e SEM cadastro
SELECT  CASE WHEN p.produto_id IS NULL THEN 'sem cadastro' ELSE 'com cadastro' END AS situacao,
        COUNT(*) AS vendas,
        ROUND(SUM(v.qtde_vendida * v.valor_unitario), 2) AS faturamento_rs
FROM venda v
LEFT JOIN produtos_filial p ON p.filial_id = v.filial_id AND p.produto_id = v.produto_id
WHERE v.data_emissao >= DATE '2025-02-01' AND v.data_emissao < DATE '2025-03-01'
GROUP BY 1;

-- A05 - Compras de fevereiro: pedido x recebido (pelas notas)
WITH rec AS (SELECT ordem_compra, produto_id, SUM(qtde_recebida) q
             FROM entradas_mercadoria GROUP BY 1, 2)
SELECT  COUNT(*)                                     AS pedidos,
        SUM(pc.qtde_pedida)                          AS qtde_pedida,
        SUM(COALESCE(r.q, 0))                        AS qtde_recebida,
        ROUND(SUM(pc.qtde_pedida * pc.preco_compra), 2) AS valor_pedidos_rs
FROM pedido_compra pc
LEFT JOIN rec r ON r.ordem_compra = pc.ordem_compra AND r.produto_id = pc.produto_id
WHERE pc.data_pedido >= DATE '2025-02-01' AND pc.data_pedido < DATE '2025-03-01';

-- A06 - Entradas de fevereiro (notas fiscais recebidas no mês)
SELECT  COUNT(*) AS notas, SUM(qtde_recebida) AS qtde,
        ROUND(SUM(qtde_recebida * custo_unitario), 2) AS valor_rs
FROM entradas_mercadoria
WHERE data_entrada >= DATE '2025-02-01' AND data_entrada < DATE '2025-03-01';


-- #####################################################################
-- BLOCO E - Erros nos dados (cada consulta lista as linhas com problema)
-- #####################################################################

-- ---------- Estrutura da planilha -------------------------------------
-- E01 - pedido_compra: valores em 11 colunas SEM cabeçalho (M a W) nas linhas
--       22-30. São uma cópia do pedido original do produto, na ordem:
--       extra_01 data_pedido, 02 item, 03 produto, 04 descrição, 05 ordem_compra,
--       06 qtde_pedida, 07 filial, 08 data_entrega, 09 qtde_entregue,
--       10 qtde_pendente, 11 preco_compra
SELECT linha_excel, pedido_id, produto_id, ordem_compra, qtde_pedida,
       extra_03 AS copia_produto, extra_05 AS copia_ordem, extra_06 AS copia_qtde_pedida,
       extra_09 AS copia_qtde_entregue, extra_10 AS copia_qtde_pendente
FROM stg.pedido_compra
WHERE extra_01 IS NOT NULL
ORDER BY linha_excel;

-- E02 - pedido_compra: a aba NÃO tem a coluna qtde_pendente (existe no DDL);
--       o valor foi calculado como qtde_pedida - qtde_entregue
SELECT 'qtde_pendente' AS coluna_esperada,
       EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'stg' AND table_name = 'pedido_compra'
                 AND column_name = 'qtde_pendente') AS existe_na_planilha;

-- E03 - produtos_filial: cabeçalho "idproduto" (nas outras abas é "produto_id")
--       (o importar.py registra a troca de nome no log da carga)
SELECT tabela, motivo FROM importacao_rejeicoes WHERE motivo LIKE 'AVISO: cabeçalho%';

-- E04 - Id do fornecedor em formatos diferentes: 'F1' (texto) em fornecedor e
--       produtos_filial; 1 (número) em pedido_compra. Convertido para número.
SELECT 'fornecedor' AS aba, idfornecedor AS valor_planilha FROM stg.fornecedor WHERE idfornecedor !~ '^\d+$'
UNION ALL
SELECT 'produtos_filial', idfornecedor FROM stg.produtos_filial WHERE idfornecedor !~ '^\d+$';

-- ---------- Pedidos de compra -----------------------------------------
-- E05 - Pedidos com ordem_compra = 0: impossível ligar à entrada de mercadoria
SELECT pedido_id, produto_id, data_pedido, qtde_pedida, ordem_compra
FROM pedido_compra WHERE ordem_compra = 0 ORDER BY pedido_id;

-- E06 - Pedidos 21-29 repetem produto, data do pedido, data de entrega, preço
--       e fornecedor de outro pedido (possível duplicidade ou desdobramento)
SELECT b.pedido_id AS pedido, a.pedido_id AS repete_o_pedido, b.produto_id,
       b.data_pedido, b.data_entrega, b.preco_compra, a.qtde_pedida AS qtde_original, b.qtde_pedida
FROM pedido_compra a
JOIN pedido_compra b
  ON b.produto_id = a.produto_id AND b.data_pedido = a.data_pedido
 AND b.data_entrega = a.data_entrega AND b.preco_compra = a.preco_compra
 AND b.pedido_id > a.pedido_id
ORDER BY b.pedido_id;

-- E07 - Conflito: pedido no banco x cópia do mesmo pedido nas colunas extras
--       (pedidos 19 e 20: ordem, quantidade e entregue diferentes)
--       O pedido "original" é o outro pedido do mesmo produto e data.
SELECT pc.pedido_id, pc.produto_id, s.linha_excel AS linha_da_copia,
       pc.ordem_compra,  s.extra_05 AS ordem_na_copia,
       pc.qtde_pedida,   s.extra_06 AS qtde_na_copia,
       pc.qtde_entregue, s.extra_09 AS entregue_na_copia
FROM stg.pedido_compra s
JOIN pedido_compra pc ON pc.produto_id = s.extra_03
                     AND pc.data_pedido = s.extra_01::date
                     AND pc.pedido_id <> s.pedido_id::bigint
WHERE s.extra_01 IS NOT NULL
  AND (pc.ordem_compra  <> s.extra_05::bigint
    OR pc.qtde_pedida   <> s.extra_06::numeric
    OR pc.qtde_entregue <> s.extra_09::numeric);

-- E08 - Data de entrega ANTERIOR à data do pedido
SELECT pedido_id, produto_id, data_pedido, data_entrega, data_pedido - data_entrega AS dias_antes
FROM pedido_compra WHERE data_entrega < data_pedido ORDER BY pedido_id;

-- E09 - qtde_entregue do pedido diferente do total recebido nas notas (pedidos com nota)
SELECT pc.pedido_id, pc.produto_id, pc.qtde_pedida, pc.qtde_entregue,
       SUM(e.qtde_recebida) AS recebido_nas_notas
FROM pedido_compra pc
JOIN entradas_mercadoria e ON e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id
GROUP BY pc.pedido_id, pc.produto_id, pc.qtde_pedida, pc.qtde_entregue
HAVING pc.qtde_entregue <> SUM(e.qtde_recebida)
ORDER BY pc.pedido_id;

-- E10 - Fornecedor do pedido diferente do fornecedor do produto no cadastro
SELECT pc.pedido_id, pc.produto_id, pc.fornecedor_id AS fornecedor_pedido, p.idfornecedor AS fornecedor_cadastro
FROM pedido_compra pc
JOIN produtos_filial p ON p.filial_id = pc.filial_id AND p.produto_id = pc.produto_id
WHERE pc.fornecedor_id IS DISTINCT FROM p.idfornecedor
ORDER BY pc.pedido_id;

-- ---------- Entradas de mercadoria ------------------------------------
-- E11 - Entradas sem pedido com a mesma ordem_compra e produto
SELECT e.nro_nfe, e.ordem_compra, e.produto_id, e.data_entrada, e.qtde_recebida
FROM entradas_mercadoria e
WHERE NOT EXISTS (SELECT 1 FROM pedido_compra pc
                  WHERE pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id);

-- E12 - Mercadoria recebida ANTES de ser pedida
SELECT e.nro_nfe, pc.pedido_id, e.produto_id, pc.data_pedido, e.data_entrada
FROM entradas_mercadoria e
JOIN pedido_compra pc ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
WHERE e.data_entrada < pc.data_pedido
ORDER BY pc.pedido_id;

-- E13 - Recebido MAIS do que o pedido
SELECT e.nro_nfe, pc.pedido_id, e.produto_id, pc.qtde_pedida, e.qtde_recebida
FROM entradas_mercadoria e
JOIN pedido_compra pc ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
WHERE e.qtde_recebida > pc.qtde_pedida
ORDER BY pc.pedido_id;

-- E14 - Custo da nota com diferença maior que 20% do preço do pedido
SELECT e.nro_nfe, pc.pedido_id, e.produto_id, pc.preco_compra, e.custo_unitario,
       ROUND(100 * (e.custo_unitario - pc.preco_compra) / pc.preco_compra, 1) AS dif_pct
FROM entradas_mercadoria e
JOIN pedido_compra pc ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
WHERE ABS(e.custo_unitario - pc.preco_compra) / pc.preco_compra > 0.20
ORDER BY pc.pedido_id;

-- ---------- Vendas ----------------------------------------------------
-- E15 - Vendas de produto SEM cadastro (P21 a P28)
SELECT v.venda_id, v.filial_id, v.produto_id, v.data_emissao, v.qtde_vendida, v.valor_unitario
FROM venda v
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.produto_id = v.produto_id)
ORDER BY v.venda_id;

-- E16 - Vendas em filial que não existe no cadastro (só há a filial 1)
SELECT v.venda_id, v.filial_id, v.produto_id, v.data_emissao
FROM venda v
WHERE v.filial_id NOT IN (SELECT DISTINCT filial_id FROM produtos_filial)
ORDER BY v.venda_id;

-- E17 - Quantidade fracionada vendida em UN (unidade não se vende "38,6")
SELECT venda_id, produto_id, qtde_vendida, unidade_medida
FROM venda
WHERE unidade_medida = 'UN' AND qtde_vendida <> TRUNC(qtde_vendida)
ORDER BY venda_id;

-- E18 - horariomov igual (08:00:00) em todas as vendas: hora fictícia/padrão.
--       Como faz parte da PK, vendas reais na mesma hora poderiam colidir.
SELECT horariomov, COUNT(*) AS vendas, ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM venda), 1) AS pct
FROM venda GROUP BY horariomov;

-- E19 - Linhas copiadas: venda com o MESMO valor unitário de uma venda anterior
--       na mesma data ou exatamente 1 mês antes. São justamente as vendas 21-33
--       (P21-P28): vendas 21-27 copiam 13-19 com o código +8, e 28-33 repetem
--       fevereiro em março.
SELECT b.venda_id, b.produto_id, b.data_emissao, b.qtde_vendida, b.valor_unitario,
       MIN(a.venda_id) AS provavel_origem
FROM venda b
JOIN venda a ON a.venda_id < b.venda_id
            AND a.valor_unitario = b.valor_unitario
            AND (a.data_emissao = b.data_emissao OR a.data_emissao + INTERVAL '1 month' = b.data_emissao)
GROUP BY b.venda_id, b.produto_id, b.data_emissao, b.qtde_vendida, b.valor_unitario
ORDER BY b.venda_id;

-- E20 - Valor unitário vendido com diferença maior que 20% do preço de venda do cadastro
SELECT v.venda_id, v.produto_id, v.valor_unitario, p.preco_venda,
       ROUND(100 * (v.valor_unitario - p.preco_venda) / p.preco_venda, 1) AS dif_pct
FROM venda v
JOIN produtos_filial p ON p.filial_id = v.filial_id AND p.produto_id = v.produto_id
WHERE ABS(v.valor_unitario - p.preco_venda) / p.preco_venda > 0.20
ORDER BY v.venda_id;

-- ---------- Produtos --------------------------------------------------
-- E21 - Preço de venda MENOR que o preço de compra (venda com prejuízo)
SELECT produto_id, preco_compra, preco_venda, preco_unitario
FROM produtos_filial WHERE preco_venda < preco_compra ORDER BY produto_id;

-- E22 - Fornecedores cadastrados sem nenhum produto (F14, F15, F16)
SELECT f.idfornecedor, f.razao_social
FROM fornecedor f
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.idfornecedor = f.idfornecedor)
ORDER BY f.idfornecedor;


-- #####################################################################
-- BLOCO R - Resumo (preenche a tabela de erros do docs/parte4_validacao.md)
-- #####################################################################
-- R01
SELECT * FROM (
  SELECT 'E01' AS consulta, 'pedido_compra' AS tabela, 'Valores em colunas sem cabeçalho (linhas)' AS problema,
         (SELECT COUNT(*) FROM stg.pedido_compra WHERE extra_01 IS NOT NULL) AS qtde
  UNION ALL SELECT 'E02', 'pedido_compra', 'Coluna qtde_pendente ausente na planilha',
         CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'stg'
              AND table_name = 'pedido_compra' AND column_name = 'qtde_pendente') THEN 0 ELSE 1 END
  UNION ALL SELECT 'E03', 'produtos_filial', 'Cabeçalho idproduto em vez de produto_id',
         (SELECT COUNT(*) FROM importacao_rejeicoes WHERE motivo LIKE 'AVISO: cabeçalho%')
  UNION ALL SELECT 'E04', 'fornecedor/produtos_filial', 'Id de fornecedor como texto (F1...)',
         (SELECT COUNT(*) FROM stg.fornecedor WHERE idfornecedor !~ '^\d+$')
       + (SELECT COUNT(*) FROM stg.produtos_filial WHERE idfornecedor !~ '^\d+$')
  UNION ALL SELECT 'E05', 'pedido_compra', 'ordem_compra = 0',
         (SELECT COUNT(*) FROM pedido_compra WHERE ordem_compra = 0)
  UNION ALL SELECT 'E06', 'pedido_compra', 'Pedido repete outro (produto, datas, preço)',
         (SELECT COUNT(*) FROM pedido_compra a JOIN pedido_compra b ON b.produto_id = a.produto_id
           AND b.data_pedido = a.data_pedido AND b.data_entrega = a.data_entrega
           AND b.preco_compra = a.preco_compra AND b.pedido_id > a.pedido_id)
  UNION ALL SELECT 'E07', 'pedido_compra', 'Pedido diverge da cópia nas colunas extras',
         (SELECT COUNT(*) FROM stg.pedido_compra s JOIN pedido_compra pc
           ON pc.produto_id = s.extra_03 AND pc.data_pedido = s.extra_01::date AND pc.pedido_id <> s.pedido_id::bigint
          WHERE s.extra_01 IS NOT NULL AND (pc.ordem_compra <> s.extra_05::bigint
             OR pc.qtde_pedida <> s.extra_06::numeric OR pc.qtde_entregue <> s.extra_09::numeric))
  UNION ALL SELECT 'E08', 'pedido_compra', 'Entrega antes do pedido',
         (SELECT COUNT(*) FROM pedido_compra WHERE data_entrega < data_pedido)
  UNION ALL SELECT 'E09', 'pedido_compra', 'qtde_entregue diferente das notas',
         (SELECT COUNT(*) FROM (SELECT 1 FROM pedido_compra pc JOIN entradas_mercadoria e
           ON e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id
          GROUP BY pc.pedido_id, pc.qtde_entregue HAVING pc.qtde_entregue <> SUM(e.qtde_recebida)) x)
  UNION ALL SELECT 'E10', 'pedido_compra', 'Fornecedor do pedido diferente do cadastro',
         (SELECT COUNT(*) FROM pedido_compra pc JOIN produtos_filial p
           ON p.filial_id = pc.filial_id AND p.produto_id = pc.produto_id
          WHERE pc.fornecedor_id IS DISTINCT FROM p.idfornecedor)
  UNION ALL SELECT 'E11', 'entradas_mercadoria', 'Entrada sem pedido (ordem/produto)',
         (SELECT COUNT(*) FROM entradas_mercadoria e WHERE NOT EXISTS (SELECT 1 FROM pedido_compra pc
           WHERE pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id))
  UNION ALL SELECT 'E12', 'entradas_mercadoria', 'Recebido antes de ser pedido',
         (SELECT COUNT(*) FROM entradas_mercadoria e JOIN pedido_compra pc
           ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id WHERE e.data_entrada < pc.data_pedido)
  UNION ALL SELECT 'E13', 'entradas_mercadoria', 'Recebido mais que o pedido',
         (SELECT COUNT(*) FROM entradas_mercadoria e JOIN pedido_compra pc
           ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id WHERE e.qtde_recebida > pc.qtde_pedida)
  UNION ALL SELECT 'E14', 'entradas_mercadoria', 'Custo da nota difere >20% do pedido',
         (SELECT COUNT(*) FROM entradas_mercadoria e JOIN pedido_compra pc
           ON pc.ordem_compra = e.ordem_compra AND pc.produto_id = e.produto_id
          WHERE ABS(e.custo_unitario - pc.preco_compra) / pc.preco_compra > 0.20)
  UNION ALL SELECT 'E15', 'venda', 'Venda de produto sem cadastro',
         (SELECT COUNT(*) FROM venda v WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.produto_id = v.produto_id))
  UNION ALL SELECT 'E16', 'venda', 'Venda em filial sem cadastro',
         (SELECT COUNT(*) FROM venda WHERE filial_id NOT IN (SELECT DISTINCT filial_id FROM produtos_filial))
  UNION ALL SELECT 'E17', 'venda', 'Quantidade fracionada em UN',
         (SELECT COUNT(*) FROM venda WHERE unidade_medida = 'UN' AND qtde_vendida <> TRUNC(qtde_vendida))
  UNION ALL SELECT 'E18', 'venda', 'horariomov igual em todas (08:00:00)',
         (SELECT COUNT(*) FROM venda WHERE horariomov = '08:00:00')
  UNION ALL SELECT 'E19', 'venda', 'Venda copiada de outra (mesmo valor, data ou +1 mês)',
         (SELECT COUNT(DISTINCT b.venda_id) FROM venda b JOIN venda a ON a.venda_id < b.venda_id
           AND a.valor_unitario = b.valor_unitario
           AND (a.data_emissao = b.data_emissao OR a.data_emissao + INTERVAL '1 month' = b.data_emissao))
  UNION ALL SELECT 'E20', 'venda', 'Valor vendido difere >20% do cadastro',
         (SELECT COUNT(*) FROM venda v JOIN produtos_filial p ON p.filial_id = v.filial_id AND p.produto_id = v.produto_id
          WHERE ABS(v.valor_unitario - p.preco_venda) / p.preco_venda > 0.20)
  UNION ALL SELECT 'E21', 'produtos_filial', 'Preço de venda < preço de compra',
         (SELECT COUNT(*) FROM produtos_filial WHERE preco_venda < preco_compra)
  UNION ALL SELECT 'E22', 'fornecedor', 'Fornecedor sem nenhum produto',
         (SELECT COUNT(*) FROM fornecedor f WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.idfornecedor = f.idfornecedor))
) r
ORDER BY consulta;
