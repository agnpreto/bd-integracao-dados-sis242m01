-- =====================================================================
-- Parte 4 - Consultas de validação (fevereiro/2025) e catálogo de erros.
-- Roda em PostgreSQL e MySQL 8. Cada item E# tem o roteiro em
-- docs/parte4_validacao.md. Resultado vazio = tudo certo naquele teste.
-- =====================================================================

-- =====================================================================
-- BLOCO A. Painel de erros: quantas linhas falham em cada teste
-- =====================================================================
SELECT 'E1  Venda de produto sem cadastro em produtos_filial' AS teste, COUNT(*) AS linhas
  FROM venda v WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.produto_id = v.produto_id)
UNION ALL
SELECT 'E2  Venda em filial inexistente (2 e 3)', COUNT(*)
  FROM venda v WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.filial_id = v.filial_id)
UNION ALL
SELECT 'E3  Quantidade fracionada em unidade UN', COUNT(*)
  FROM venda WHERE unidade_medida = 'UN' AND qtde_vendida <> FLOOR(qtde_vendida)
UNION ALL
SELECT 'E4  Pedido sem ordem_compra (valor 0)', COUNT(*) FROM pedido_compra WHERE ordem_compra = 0
UNION ALL
SELECT 'E5  Entrada sem pedido correspondente (ordem+produto)', COUNT(*)
  FROM entradas_mercadoria e
 WHERE NOT EXISTS (SELECT 1 FROM pedido_compra p
                    WHERE p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id)
UNION ALL
SELECT 'E6  Data de entrega anterior à data do pedido', COUNT(*)
  FROM pedido_compra WHERE data_entrega < data_pedido
UNION ALL
SELECT 'E7  Entrada de mercadoria anterior à data do pedido', COUNT(*)
  FROM entradas_mercadoria e JOIN pedido_compra p
    ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
 WHERE e.data_entrada < p.data_pedido
UNION ALL
SELECT 'E8  Recebido MAIOR que o pedido', COUNT(*)
  FROM entradas_mercadoria e JOIN pedido_compra p
    ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
 WHERE e.qtde_recebida > p.qtde_pedida
UNION ALL
SELECT 'E9  qtde_entregue do pedido difere da qtde_recebida da entrada', COUNT(*)
  FROM entradas_mercadoria e JOIN pedido_compra p
    ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
 WHERE e.qtde_recebida <> p.qtde_entregue
UNION ALL
SELECT 'E10 Fornecedor do pedido difere do fornecedor do produto', COUNT(*)
  FROM pedido_compra pc JOIN produtos_filial pf
    ON pf.produto_id = pc.produto_id AND pf.filial_id = pc.filial_id
 WHERE pc.fornecedor_id <> pf.idfornecedor
UNION ALL
SELECT 'E11 Pedido repetido para o mesmo produto/data/fornecedor', COUNT(*)
  FROM pedido_compra a JOIN pedido_compra b
    ON a.produto_id = b.produto_id AND a.data_pedido = b.data_pedido
   AND a.fornecedor_id = b.fornecedor_id AND a.pedido_id < b.pedido_id
UNION ALL
SELECT 'E12 Custo do produto x custo do pedido x custo da entrada divergem', COUNT(*)
  FROM entradas_mercadoria e
  JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
  JOIN produtos_filial pf ON pf.produto_id = e.produto_id AND pf.filial_id = e.filial_id
 WHERE e.custo_unitario <> p.preco_compra OR e.custo_unitario <> pf.preco_compra
UNION ALL
SELECT 'E13 Produto com preco_venda menor que preco_compra (margem negativa)', COUNT(*)
  FROM produtos_filial WHERE preco_venda < preco_compra
UNION ALL
SELECT 'E14 Preco praticado na venda difere do preco_venda do cadastro', COUNT(*)
  FROM venda v JOIN produtos_filial p ON p.produto_id = v.produto_id AND p.filial_id = v.filial_id
 WHERE v.valor_unitario <> p.preco_venda
UNION ALL
SELECT 'E15 Mesmo valor_unitario em produtos diferentes (cópia de linhas?)', COUNT(*)
  FROM venda a JOIN venda b ON a.valor_unitario = b.valor_unitario
   AND a.produto_id <> b.produto_id AND a.venda_id < b.venda_id
UNION ALL
SELECT 'E16 Mais de um produto com o mesmo fornecedor / fornecedor sem produto', COUNT(*)
  FROM fornecedor f
 WHERE (SELECT COUNT(*) FROM produtos_filial p WHERE p.idfornecedor = f.idfornecedor) <> 1
UNION ALL
SELECT 'E17 Venda com horário fixo 08:00:00 e item 1 (placeholder?)', COUNT(*)
  FROM venda WHERE horariomov = '08:00:00' AND item = 1;

-- =====================================================================
-- BLOCO B. Uma consulta por erro, mostrando as linhas culpadas
-- =====================================================================
-- E1: vendas de produtos que não existem no cadastro (todas em P21..P28)
SELECT v.venda_id, v.data_emissao, v.produto_id, v.qtde_vendida, v.valor_unitario
  FROM venda v
 WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.produto_id = v.produto_id)
 ORDER BY v.venda_id;

-- E2: vendas em filiais 2 e 3, que não têm nenhum produto cadastrado
SELECT v.venda_id, v.filial_id, v.produto_id, v.data_emissao
  FROM venda v
 WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.filial_id = v.filial_id);

-- E3: quantidades quebradas (3.11 "UN" não existe; ou a unidade ou a qtde estão erradas)
SELECT venda_id, produto_id, qtde_vendida, unidade_medida
  FROM venda WHERE unidade_medida = 'UN' AND qtde_vendida <> FLOOR(qtde_vendida);

-- E4: pedidos 19 a 29 sem ordem de compra (não se ligam a nenhuma entrada)
SELECT pedido_id, produto_id, data_pedido, qtde_pedida, ordem_compra
  FROM pedido_compra WHERE ordem_compra = 0 ORDER BY pedido_id;

-- E5: entradas 19 e 20 apontam para ordens 19 e 20, que não existem em pedido_compra
SELECT e.nro_nfe, e.ordem_compra, e.produto_id, e.qtde_recebida, e.data_entrada
  FROM entradas_mercadoria e
 WHERE NOT EXISTS (SELECT 1 FROM pedido_compra p
                    WHERE p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id);

-- E6: a mercadoria "seria entregue" antes de ser pedida
SELECT pedido_id, produto_id, data_pedido, data_entrega
  FROM pedido_compra WHERE data_entrega < data_pedido ORDER BY pedido_id;

-- E7: nota fiscal de entrada com data anterior ao pedido
SELECT p.pedido_id, p.produto_id, p.data_pedido, e.nro_nfe, e.data_entrada
  FROM entradas_mercadoria e JOIN pedido_compra p
    ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
 WHERE e.data_entrada < p.data_pedido ORDER BY p.pedido_id;

-- E8: recebeu-se mais do que se pediu
SELECT p.pedido_id, p.produto_id, p.qtde_pedida, e.qtde_recebida
  FROM entradas_mercadoria e JOIN pedido_compra p
    ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
 WHERE e.qtde_recebida > p.qtde_pedida ORDER BY p.pedido_id;

-- E9: o pedido diz uma quantidade entregue e a nota fiscal outra
SELECT p.pedido_id, p.produto_id, p.qtde_entregue AS entregue_no_pedido,
       e.qtde_recebida AS recebido_na_nfe, e.nro_nfe
  FROM entradas_mercadoria e JOIN pedido_compra p
    ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
 WHERE e.qtde_recebida <> p.qtde_entregue ORDER BY p.pedido_id;

-- E10: o fornecedor do pedido não é o fornecedor cadastrado para o produto
SELECT pc.pedido_id, pc.produto_id, pc.fornecedor_id AS fornecedor_no_pedido,
       pf.idfornecedor AS fornecedor_no_cadastro
  FROM pedido_compra pc JOIN produtos_filial pf
    ON pf.produto_id = pc.produto_id AND pf.filial_id = pc.filial_id
 WHERE pc.fornecedor_id <> pf.idfornecedor ORDER BY pc.pedido_id;

-- E11: pedidos 21 a 29 repetem produto/data/fornecedor/preço de pedidos anteriores
SELECT a.pedido_id AS pedido_original, b.pedido_id AS pedido_repetido, a.produto_id,
       a.data_pedido, a.qtde_pedida AS qtde_original, b.qtde_pedida AS qtde_repetida
  FROM pedido_compra a JOIN pedido_compra b
    ON a.produto_id = b.produto_id AND a.data_pedido = b.data_pedido
   AND a.fornecedor_id = b.fornecedor_id AND a.pedido_id < b.pedido_id
 ORDER BY a.pedido_id;

-- E12: três custos diferentes para a mesma compra
SELECT e.produto_id, pf.preco_compra AS custo_cadastro, p.preco_compra AS custo_pedido,
       e.custo_unitario AS custo_nfe
  FROM entradas_mercadoria e
  JOIN pedido_compra p ON p.ordem_compra = e.ordem_compra AND p.produto_id = e.produto_id
  JOIN produtos_filial pf ON pf.produto_id = e.produto_id AND pf.filial_id = e.filial_id
 WHERE e.custo_unitario <> p.preco_compra OR e.custo_unitario <> pf.preco_compra
 ORDER BY e.produto_id;

-- E13: vende-se abaixo do custo (preço de venda < preço de compra do cadastro)
SELECT produto_id, preco_compra, preco_venda, (preco_venda - preco_compra) AS margem
  FROM produtos_filial WHERE preco_venda < preco_compra ORDER BY margem;

-- E14: o preço praticado na venda não é o preço do cadastro
SELECT v.venda_id, v.produto_id, v.valor_unitario AS preco_na_venda, p.preco_venda AS preco_cadastro
  FROM venda v JOIN produtos_filial p ON p.produto_id = v.produto_id AND p.filial_id = v.filial_id
 WHERE v.valor_unitario <> p.preco_venda ORDER BY v.venda_id;

-- E15: valores idênticos em produtos distintos (P13=P21=61.85, P14=P22 ...)
SELECT a.venda_id AS venda_a, a.produto_id AS produto_a, b.venda_id AS venda_b,
       b.produto_id AS produto_b, a.valor_unitario
  FROM venda a JOIN venda b ON a.valor_unitario = b.valor_unitario
   AND a.produto_id <> b.produto_id AND a.venda_id < b.venda_id
 ORDER BY a.venda_id;

-- E16: fornecedores com 0 ou 2+ produtos (F7, F18, F19 têm 2; F14, F15, F16 nenhum)
SELECT f.idfornecedor, f.razao_social,
       (SELECT COUNT(*) FROM produtos_filial p WHERE p.idfornecedor = f.idfornecedor) AS qtd_produtos
  FROM fornecedor f
 WHERE (SELECT COUNT(*) FROM produtos_filial p WHERE p.idfornecedor = f.idfornecedor) <> 1
 ORDER BY f.idfornecedor;

-- E17: todos os horários são 08:00:00 e todo item é 1
SELECT COUNT(*) AS vendas, COUNT(DISTINCT horariomov) AS horarios_distintos,
       COUNT(DISTINCT item) AS itens_distintos
  FROM venda;

-- =====================================================================
-- BLOCO C. Consultas para a reunião de validação de FEVEREIRO/2025
-- =====================================================================
-- C1. Volumetria: quantas linhas existem por tabela e o que cai em fevereiro
SELECT 'venda' AS tabela, COUNT(*) AS total,
       SUM(CASE WHEN data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01' THEN 1 ELSE 0 END) AS em_fevereiro FROM venda
UNION ALL SELECT 'pedido_compra', COUNT(*),
       SUM(CASE WHEN data_pedido >= '2025-02-01' AND data_pedido < '2025-03-01' THEN 1 ELSE 0 END) FROM pedido_compra
UNION ALL SELECT 'entradas_mercadoria', COUNT(*),
       SUM(CASE WHEN data_entrada >= '2025-02-01' AND data_entrada < '2025-03-01' THEN 1 ELSE 0 END) FROM entradas_mercadoria;

-- C2. Totais de fevereiro para o cliente conferir com o sistema dele
SELECT COUNT(*) AS qtd_vendas, COUNT(DISTINCT produto_id) AS produtos,
       SUM(qtde_vendida) AS total_quantidade,
       SUM(qtde_vendida * valor_unitario) AS total_valor_rs,
       MIN(data_emissao) AS primeira_venda, MAX(data_emissao) AS ultima_venda
  FROM venda WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01';

-- C3. Vendas por dia: dias sem movimento levantam a pergunta "a loja abriu?"
SELECT data_emissao, COUNT(*) AS vendas, SUM(qtde_vendida * valor_unitario) AS valor_rs
  FROM venda WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01'
 GROUP BY data_emissao ORDER BY data_emissao;

-- C4. Concentração: quanto o maior produto pesa no mês (outlier = pergunta ao cliente)
SELECT produto_id, SUM(qtde_vendida * valor_unitario) AS valor_rs,
       ROUND(100 * SUM(qtde_vendida * valor_unitario) /
             (SELECT SUM(qtde_vendida * valor_unitario) FROM venda
               WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01'), 1) AS pct_do_mes
  FROM venda WHERE data_emissao >= '2025-02-01' AND data_emissao < '2025-03-01'
 GROUP BY produto_id ORDER BY valor_rs DESC;

-- C5. Chaves duplicadas e nulos nas colunas críticas (esperado: vazio)
SELECT 'venda duplicada' AS teste, COUNT(*) AS linhas FROM
  (SELECT filial_id, venda_id, produto_id, item FROM venda
    GROUP BY filial_id, venda_id, produto_id, item HAVING COUNT(*) > 1) d
UNION ALL SELECT 'venda com qtde ou preco nulo/zero', COUNT(*) FROM venda
  WHERE qtde_vendida IS NULL OR qtde_vendida <= 0 OR valor_unitario <= 0
UNION ALL SELECT 'pedido sem data', COUNT(*) FROM pedido_compra WHERE data_pedido IS NULL OR data_entrega IS NULL
UNION ALL SELECT 'entrada sem data', COUNT(*) FROM entradas_mercadoria WHERE data_entrada IS NULL;

-- C6. Reconciliação carga x planilha: os números abaixo devem ser iguais aos da
-- planilha (confira com =CONT.VALORES / =SOMARPRODUTO no Excel)
SELECT (SELECT COUNT(*) FROM fornecedor)          AS fornecedor_20,
       (SELECT COUNT(*) FROM produtos_filial)     AS produtos_20,
       (SELECT COUNT(*) FROM pedido_compra)       AS pedidos_29,
       (SELECT COUNT(*) FROM entradas_mercadoria) AS entradas_20,
       (SELECT COUNT(*) FROM venda)               AS vendas_33,
       (SELECT SUM(qtde_vendida * valor_unitario) FROM venda) AS valor_total_vendas;

-- C7. Pedidos sem recebimento (mesma regra de 02_consultas.sql)
SELECT pc.pedido_id, pc.produto_id, pc.qtde_pedida
  FROM pedido_compra pc
 WHERE NOT EXISTS (SELECT 1 FROM entradas_mercadoria e
                    WHERE e.ordem_compra = pc.ordem_compra AND e.produto_id = pc.produto_id)
 ORDER BY pc.pedido_id;
