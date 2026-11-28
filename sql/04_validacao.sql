-- 04_validacao  
-- Nome: Mikael Coelho Ramos e Kauã Monteiro Coelho
 
-- V00- quantas ocorrências de cada problema existem. 
SELECT * FROM (
    SELECT 'V05' AS codigo, 'venda: produto sem cadastro em produtos_filial' AS verificacao,
     COUNT(*) AS qtd
    FROM venda v
    WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.produto_id = v.produto_id)
  UNION ALL
    SELECT 'V05f', '   (dessas, vendas de fevereiro/2025)',
     COUNT(*)
    FROM venda v
    WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.produto_id = v.produto_id)
      AND v.data_emissao >= DATE '2025-02-01' AND v.data_emissao < DATE '2025-03-01'
  UNION ALL
    SELECT 'V06', 'venda: filial sem nenhum produto cadastrado (só a filial 1 tem)', COUNT(*)
    FROM venda v
    WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.filial_id = v.filial_id)
  UNION ALL
    SELECT 'V06f', '   (dessas, vendas de fevereiro/2025)', COUNT(*)
    FROM venda v
    WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.filial_id = v.filial_id)
      AND v.data_emissao >= DATE '2025-02-01' AND v.data_emissao < DATE '2025-03-01'
  UNION ALL
    SELECT 'V07', 'pedido_compra: ordem_compra = 0 (sem vínculo com entradas)', COUNT(*)
    FROM pedido_compra WHERE ordem_compra = 0
  UNION ALL
    SELECT 'V08', 'entradas_mercadoria: ordem_compra sem pedido correspondente', COUNT(*)
    FROM entradas_mercadoria e
    WHERE NOT EXISTS (SELECT 1 FROM pedido_compra p WHERE p.ordem_compra = e.ordem_compra)
  UNION ALL
    SELECT 'V09', 'pedido_compra: pares de pedidos repetidos (mesmo produto, datas, preço e fornecedor)', COUNT(*)
    FROM pedido_compra a JOIN pedido_compra b
      ON a.pedido_id < b.pedido_id AND a.produto_id = b.produto_id AND a.data_pedido = b.data_pedido
     AND a.data_entrega = b.data_entrega AND a.preco_compra = b.preco_compra AND a.fornecedor_id = b.fornecedor_id
  UNION ALL
    SELECT 'V10', 'fornecedor do produto diferente do fornecedor do pedido', COUNT(*)
    FROM pedido_compra p JOIN produtos_filial pf ON pf.produto_id = p.produto_id
    WHERE pf.idfornecedor <> p.fornecedor_id
  UNION ALL
    SELECT 'V11', 'fornecedores sem nenhum produto (informativo)', COUNT(*)
    FROM fornecedor f
    WHERE NOT EXISTS (SELECT 1 FROM produtos_filial pf WHERE pf.idfornecedor = f.idfornecedor)
  UNION ALL
    SELECT 'V12', 'qtde_entregue do pedido diferente da qtde_recebida das entradas', COUNT(*)
    FROM pedido_compra p JOIN entradas_mercadoria e
      ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
    WHERE e.qtde_recebida <> p.qtde_entregue
  UNION ALL
    SELECT 'V13', 'entrada com qtde_recebida MAIOR que a qtde_pedida', COUNT(*)
    FROM pedido_compra p JOIN entradas_mercadoria e
      ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
    WHERE e.qtde_recebida > p.qtde_pedida
  UNION ALL
    SELECT 'V14', 'pedido_compra: data_entrega anterior à data_pedido', COUNT(*)
    FROM pedido_compra WHERE data_entrega < data_pedido
  UNION ALL
    SELECT 'V15', 'entrada com data_entrada anterior à data_pedido', COUNT(*)
    FROM pedido_compra p JOIN entradas_mercadoria e
      ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
    WHERE e.data_entrada < p.data_pedido
  UNION ALL
    SELECT 'V16', 'custo_unitario da entrada diferente do preco_compra do pedido', COUNT(*)
    FROM pedido_compra p JOIN entradas_mercadoria e
      ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
    WHERE ABS(e.custo_unitario - p.preco_compra) > 0.005
  UNION ALL
    SELECT 'V17', 'valor_unitario da venda diferente do preco_venda do cadastro', COUNT(*)
    FROM venda v JOIN produtos_filial pf ON pf.produto_id = v.produto_id AND pf.filial_id = v.filial_id
    WHERE ABS(v.valor_unitario - pf.preco_venda) > 0.005
  UNION ALL
    SELECT 'V18', 'produto com preço de venda MENOR que o de compra (venda abaixo do custo)', COUNT(*)
    FROM produtos_filial WHERE preco_venda < preco_compra
  UNION ALL
    SELECT 'V19', 'venda com quantidade fracionada em unidade UN', COUNT(*)
    FROM venda WHERE unidade_medida = 'UN' AND qtde_vendida <> FLOOR(qtde_vendida)
) painel
ORDER BY codigo;

-- BLOCO A - OS NÚMEROS FECHAM?

-- V01 - Linhas por tabela. Comparar com a planilha: fornecedor 20, produtos_filial 20, pedido_compra 29,
--       entradas_mercadoria 20, venda 33.
SELECT 'fornecedor' AS tabela, COUNT(*) AS linhas FROM fornecedor
UNION ALL SELECT 'produtos_filial',     COUNT(*) FROM produtos_filial
UNION ALL SELECT 'pedido_compra',       COUNT(*) FROM pedido_compra
UNION ALL SELECT 'entradas_mercadoria', COUNT(*) FROM entradas_mercadoria
UNION ALL SELECT 'venda',               COUNT(*) FROM venda;

-- V02 - Totais de controle das vendas de fevereiro/2025. O cliente compara estes números com o relatório
--       que ele tem no sistema de origem: se as linhas, a quantidade e o valor baterem, a importação está íntegra.
--       Esperado: 14 linhas | 14 produtos | 2 filiais | 173,22 un | R$ 14.093,17 | 07/02 a 28/02/2025.
SELECT COUNT(*)                                                    AS linhas_de_venda,
       COUNT(DISTINCT produto_id)                                  AS produtos,
       COUNT(DISTINCT filial_id)                                   AS filiais,
       SUM(qtde_vendida)                                           AS qtde_total,
       CAST(SUM(qtde_vendida * valor_unitario) AS DECIMAL(14,2))   AS valor_total_rs,
       MIN(data_emissao)                                           AS primeira_data,
       MAX(data_emissao)                                           AS ultima_data
FROM venda
WHERE data_emissao >= DATE '2025-02-01' AND data_emissao < DATE '2025-03-01';

-- V03 - Vendas de fevereiro/2025 por filial (o cliente confirma se as filiais 2 e 3 realmente existem).
SELECT filial_id,
       COUNT(*)                                                  AS linhas_de_venda,
       SUM(qtde_vendida)                                         AS qtde_total,
       CAST(SUM(qtde_vendida * valor_unitario) AS DECIMAL(14,2)) AS valor_total_rs
FROM venda
WHERE data_emissao >= DATE '2025-02-01' AND data_emissao < DATE '2025-03-01'
GROUP BY filial_id
ORDER BY filial_id;

-- V04 - Movimento de compras em fevereiro/2025: pedidos feitos e mercadoria recebida no mês.
SELECT 'pedido_compra (data_pedido)' AS origem, COUNT(*) AS linhas, SUM(qtde_pedida) AS quantidade
FROM pedido_compra
WHERE data_pedido >= DATE '2025-02-01' AND data_pedido < DATE '2025-03-01'
UNION ALL
SELECT 'entradas_mercadoria (data_entrada)', COUNT(*), SUM(qtde_recebida)
FROM entradas_mercadoria
WHERE data_entrada >= DATE '2025-02-01' AND data_entrada < DATE '2025-03-01';



-- BLOCO B - OS VÍNCULOS ENTRE AS TABELAS ESTÃO CORRETOS? (cada consulta lista as linhas para mostrar ao cliente)

-- V05 - Vendas de produtos que NÃO existem em produtos_filial (a coluna em_fevereiro marca as que entram no
--       recorte da reunião). Pergunta ao cliente: são produtos novos que faltou cadastrar, ou códigos errados?
SELECT v.venda_id, v.produto_id, v.filial_id, v.data_emissao, v.qtde_vendida, v.valor_unitario,
       CASE WHEN v.data_emissao >= DATE '2025-02-01' AND v.data_emissao < DATE '2025-03-01' THEN 'SIM' ELSE 'não' END AS em_fevereiro
FROM venda v
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.produto_id = v.produto_id)
ORDER BY v.data_emissao, v.venda_id;

-- V06 - Vendas em filiais que não têm nenhum produto cadastrado (só a filial 1 tem).
SELECT v.venda_id, v.filial_id, v.produto_id, v.data_emissao, v.qtde_vendida
FROM venda v
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial p WHERE p.filial_id = v.filial_id)
ORDER BY v.venda_id;

-- V07 - Pedidos com ordem_compra = 0: ainda são requisições (ou faltou preencher a ordem?). É por causa deles que
--       a Parte 2, consulta 2 retorna 11 linhas.
SELECT pedido_id, item, produto_id, data_pedido, ordem_compra, qtde_pedida, qtde_entregue, qtde_pendente
FROM pedido_compra
WHERE ordem_compra = 0
ORDER BY pedido_id;

-- V08 - Entradas cuja ordem_compra não existe em nenhum pedido. As ordens 19 e 20 têm entrada, mas os pedidos de
--       P19 e P20 estão com ordem 0. Pergunta: a entrada pertence a esses pedidos?
SELECT e.nro_nfe, e.ordem_compra, e.produto_id, e.data_entrada, e.qtde_recebida
FROM entradas_mercadoria e
WHERE NOT EXISTS (SELECT 1 FROM pedido_compra p WHERE p.ordem_compra = e.ordem_compra)
ORDER BY e.ordem_compra;

-- V09 - Pedidos que repetem produto, datas, preço e fornecedor de outro pedido, com pedido_id e quantidades
--       diferentes (os pedidos 21 a 29 repetem os 12 a 20). Pergunta: são lançamentos duplicados?
SELECT a.pedido_id AS pedido_original, b.pedido_id AS pedido_repetido, a.produto_id, a.data_pedido,
       a.qtde_pedida AS qtde_original, b.qtde_pedida AS qtde_repetido, a.ordem_compra AS ordem_original, b.ordem_compra AS ordem_repetido
FROM pedido_compra a JOIN pedido_compra b
  ON a.pedido_id < b.pedido_id AND a.produto_id = b.produto_id AND a.data_pedido = b.data_pedido
 AND a.data_entrega = b.data_entrega AND a.preco_compra = b.preco_compra AND a.fornecedor_id = b.fornecedor_id
ORDER BY a.pedido_id;

-- V10 - O fornecedor cadastrado no produto não é o fornecedor do pedido 
--       Pergunta: qual dos dois cadastros vale?
SELECT p.pedido_id, p.produto_id, p.fornecedor_id AS fornecedor_no_pedido, pf.idfornecedor AS fornecedor_no_cadastro
FROM pedido_compra p JOIN produtos_filial pf ON pf.produto_id = p.produto_id
WHERE pf.idfornecedor <> p.fornecedor_id
ORDER BY p.pedido_id;

-- V11 - Fornecedores cadastrados que não fornecem nenhum produto (informativo: F14, F15 e F16).
SELECT f.idfornecedor, f.razao_social
FROM fornecedor f
WHERE NOT EXISTS (SELECT 1 FROM produtos_filial pf WHERE pf.idfornecedor = f.idfornecedor)
ORDER BY f.idfornecedor;


-- =====================================================================================================
-- BLOCO C - OS VALORES E AS DATAS FAZEM SENTIDO?
-- =====================================================================================================

-- V12 - A quantidade entregue no pedido não é a quantidade recebida nas entradas (nas 18 ordens comparáveis).
SELECT p.pedido_id, p.produto_id, p.ordem_compra, p.qtde_pedida, p.qtde_entregue AS entregue_no_pedido, e.qtde_recebida AS recebido_na_entrada
FROM pedido_compra p JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
WHERE e.qtde_recebida <> p.qtde_entregue
ORDER BY p.pedido_id;

-- V13 - Entradas com MAIS mercadoria do que foi pedido (ordens 2, 3, 5, 7, 11, 15 e 16).
SELECT p.pedido_id, p.produto_id, p.ordem_compra, p.qtde_pedida, e.qtde_recebida, e.qtde_recebida - p.qtde_pedida AS excesso
FROM pedido_compra p JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
WHERE e.qtde_recebida > p.qtde_pedida
ORDER BY p.pedido_id;

-- V14 - Pedidos com data de entrega ANTERIOR à data do pedido (entrega prevista ou realizada antes de pedir?).
SELECT pedido_id, produto_id, data_pedido, data_entrega
FROM pedido_compra
WHERE data_entrega < data_pedido
ORDER BY pedido_id;

-- V15 - Mercadoria que entrou ANTES de o pedido existir (ordens 6, 7, 11, 12, 13, 14, 15, 16 e 18).
SELECT p.pedido_id, p.ordem_compra, p.produto_id, p.data_pedido, e.data_entrada, e.nro_nfe
FROM pedido_compra p JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
WHERE e.data_entrada < p.data_pedido
ORDER BY p.pedido_id;

-- V16 - O custo na nota fiscal (entrada) é diferente do preço combinado no pedido, em todas as ordens comparáveis.
SELECT p.pedido_id, p.produto_id, p.preco_compra AS preco_no_pedido, e.custo_unitario AS custo_na_entrada,
       CAST(e.custo_unitario - p.preco_compra AS DECIMAL(12,2)) AS diferenca
FROM pedido_compra p JOIN entradas_mercadoria e
  ON e.ordem_compra = p.ordem_compra AND e.produto_id = p.produto_id AND e.item = p.item
WHERE ABS(e.custo_unitario - p.preco_compra) > 0.005
ORDER BY p.pedido_id;

-- V17 - O preço praticado na venda não é o preço de venda do cadastro (todas as 20 vendas comparáveis).
SELECT v.venda_id, v.produto_id, v.valor_unitario AS preco_na_venda, pf.preco_venda AS preco_no_cadastro
FROM venda v JOIN produtos_filial pf ON pf.produto_id = v.produto_id AND pf.filial_id = v.filial_id
WHERE ABS(v.valor_unitario - pf.preco_venda) > 0.005
ORDER BY v.venda_id;

-- V18 - Produtos cadastrados com preço de venda menor que o preço de compra (P1, P8, P15 e P18).
SELECT produto_id, descricao, preco_compra, preco_venda, preco_venda - preco_compra AS margem
FROM produtos_filial
WHERE preco_venda < preco_compra
ORDER BY margem;

-- V19 - Quantidade fracionada em unidade UN (não existe 38,6 "unidade"). Falta a unidade correta (kg?) ou é erro.
SELECT venda_id, produto_id, data_emissao, qtde_vendida, unidade_medida
FROM venda
WHERE unidade_medida = 'UN' AND qtde_vendida <> FLOOR(qtde_vendida)
ORDER BY venda_id;

-- V20 -  Procura nulos, zeros, negativos e extremos.

SELECT * FROM (
    SELECT 'venda' AS tabela, 'qtde_vendida' AS coluna, COUNT(*) AS linhas,
           SUM(CASE WHEN qtde_vendida IS NULL THEN 1 ELSE 0 END) AS nulos,
           SUM(CASE WHEN qtde_vendida <= 0 THEN 1 ELSE 0 END) AS zeros_ou_negativos,
           MIN(qtde_vendida) AS minimo, MAX(qtde_vendida) AS maximo FROM venda
  UNION ALL
    SELECT 'venda', 'valor_unitario', COUNT(*), SUM(CASE WHEN valor_unitario IS NULL THEN 1 ELSE 0 END),
           SUM(CASE WHEN valor_unitario <= 0 THEN 1 ELSE 0 END), MIN(valor_unitario), MAX(valor_unitario) FROM venda
  UNION ALL
    SELECT 'pedido_compra', 'qtde_pedida', COUNT(*), SUM(CASE WHEN qtde_pedida IS NULL THEN 1 ELSE 0 END),
           SUM(CASE WHEN qtde_pedida <= 0 THEN 1 ELSE 0 END), MIN(qtde_pedida), MAX(qtde_pedida) FROM pedido_compra
  UNION ALL
    SELECT 'pedido_compra', 'preco_compra', COUNT(*), SUM(CASE WHEN preco_compra IS NULL THEN 1 ELSE 0 END),
           SUM(CASE WHEN preco_compra <= 0 THEN 1 ELSE 0 END), MIN(preco_compra), MAX(preco_compra) FROM pedido_compra
  UNION ALL
    SELECT 'entradas_mercadoria', 'qtde_recebida', COUNT(*), SUM(CASE WHEN qtde_recebida IS NULL THEN 1 ELSE 0 END),
           SUM(CASE WHEN qtde_recebida <= 0 THEN 1 ELSE 0 END), MIN(qtde_recebida), MAX(qtde_recebida) FROM entradas_mercadoria
  UNION ALL
    SELECT 'entradas_mercadoria', 'custo_unitario', COUNT(*), SUM(CASE WHEN custo_unitario IS NULL THEN 1 ELSE 0 END),
           SUM(CASE WHEN custo_unitario <= 0 THEN 1 ELSE 0 END), MIN(custo_unitario), MAX(custo_unitario) FROM entradas_mercadoria
  UNION ALL
    SELECT 'produtos_filial', 'estoque', COUNT(*), SUM(CASE WHEN estoque IS NULL THEN 1 ELSE 0 END),
           SUM(CASE WHEN estoque <= 0 THEN 1 ELSE 0 END), MIN(estoque), MAX(estoque) FROM produtos_filial
  UNION ALL
    SELECT 'produtos_filial', 'preco_venda', COUNT(*), SUM(CASE WHEN preco_venda IS NULL THEN 1 ELSE 0 END),
           SUM(CASE WHEN preco_venda <= 0 THEN 1 ELSE 0 END), MIN(preco_venda), MAX(preco_venda) FROM produtos_filial
) perfil
ORDER BY tabela, coluna;
