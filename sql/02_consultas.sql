-- Parte 2: Consultas SQL
-- Nome: RENISON

-- Este arquivo contem duas consultas SQL do projeto.
-- A primeira analisa as vendas realizadas em fevereiro de 2025.
-- A segunda identifica pedidos que ainda possuem quantidades pendentes.
--
-- As consultas utilizam os dados importados do Excel para o PostgreSQL.
-- O comando SELECT serve para consultar, sem modificar os registros.


-- Consulta 1: Total vendido por produto em fevereiro de 2025
-- Mostra a quantidade vendida e o valor total em reais.

-- Objetivo: descobrir quanto foi vendido de cada produto
-- durante fevereiro de 2025 e calcular o valor total das vendas.
--
-- A consulta utiliza a tabela venda.
-- Os produtos aparecem agrupados pelo codigo produto_id.
-- O resultado e organizado do maior valor vendido para o menor.

SELECT
    -- Identifica o produto vendido.
    -- Exemplos de codigos: P1, P2 e P3.
    produto_id,

    -- SUM soma as quantidades vendidas do mesmo produto.
    -- COALESCE substitui valores NULL por zero no calculo.
    -- AS define um nome para a coluna apresentada no resultado.
    SUM(COALESCE(qtde_vendida, 0)) AS quantidade_vendida,

    -- Multiplica a quantidade vendida pelo valor unitario.
    -- SUM soma os valores de todas as vendas do produto.
    -- ::numeric converte o resultado para o tipo numeric.
    -- ROUND arredonda o valor final para duas casas decimais.
    ROUND(
        SUM(COALESCE(qtde_vendida, 0) * valor_unitario)::numeric, 2
    ) AS total_vendido_reais

-- FROM indica a tabela de onde os registros serao consultados.
-- public e o esquema do banco onde a tabela venda foi criada.
FROM public.venda

-- WHERE filtra somente as vendas realizadas em fevereiro de 2025.
-- A primeira condicao inclui as datas a partir de 01/02/2025.
-- A segunda exclui as datas a partir de 01/03/2025.
WHERE data_emissao >= '2025-02-01'
  AND data_emissao < '2025-03-01'

-- GROUP BY agrupa as vendas que possuem o mesmo produto_id.
-- Assim, SUM calcula os totais de cada produto separadamente.
GROUP BY produto_id

-- ORDER BY organiza os resultados pelo valor total vendido.
-- DESC significa ordem decrescente: do maior para o menor.
ORDER BY total_vendido_reais DESC;


-- Consulta 2: Produtos pedidos e ainda não recebidos completamente.
-- Compara a quantidade solicitada com as entradas de mercadoria.

-- Objetivo: identificar os pedidos cuja quantidade solicitada
-- e maior que a quantidade registrada como recebida.
--
-- Esta consulta utiliza duas tabelas:
-- pedido_compra: informa o que foi solicitado pela empresa.
-- entradas_mercadoria: informa o que foi registrado como recebido.
--
-- A consulta possui duas etapas:
-- 1. Calcular o total recebido de cada produto por ordem de compra.
-- 2. Comparar esse total com a quantidade solicitada no pedido.
--
-- Diferentemente da Consulta 1, aqui nao existe filtro de data.
-- Portanto, a consulta considera todos os pedidos importados.

-- WITH cria uma CTE, que funciona como um resultado temporario
-- utilizado somente durante a execucao desta consulta.
-- O nome recebimentos identifica esse resultado.
WITH recebimentos AS (
    SELECT
        -- Numero da ordem de compra relacionada ao recebimento.
        ordem_compra,

        -- Identificador do produto recebido.
        produto_id,

        -- Soma as quantidades recebidas para cada combinacao
        -- de ordem de compra e produto.
        -- COALESCE considera zero quando qtde_recebida e NULL.
        SUM(COALESCE(qtde_recebida, 0)) AS total_recebido

    -- Busca as informacoes na tabela de entradas de mercadorias.
    FROM entradas_mercadoria

    -- Agrupa as entradas pela ordem de compra e pelo produto.
    -- Isso permite somar diferentes entradas da mesma operacao.
    GROUP BY ordem_compra, produto_id
)

-- A consulta principal compara os pedidos com os recebimentos.
SELECT
    -- Identificador do pedido de compra.
    p.pedido_id,

    -- Numero da ordem utilizado para relacionar os registros.
    p.ordem_compra,

    -- Codigo do produto solicitado.
    p.produto_id,

    -- Quantidade que a empresa solicitou ao fornecedor.
    p.qtde_pedida,

    -- Quantidade informada como entregue na tabela de pedidos.
    -- O AS muda apenas o nome apresentado no resultado.
    p.qtde_entregue AS entregue_no_pedido,

    -- Total de unidades encontradas nas entradas de mercadoria.
    -- Se nao houver entrada correspondente, COALESCE retorna zero.
    COALESCE(r.total_recebido, 0) AS recebido_nas_entradas,

    -- Calcula quanto ainda falta receber segundo as entradas.
    -- Subtrai o total recebido da quantidade solicitada.
    -- Exemplo: 96 pedidas - 77 recebidas = 19 pendentes.
    p.qtde_pedida - COALESCE(r.total_recebido, 0) AS quantidade_pendente,

    -- CASE permite apresentar uma situacao conforme uma condicao.
    -- WHEN verifica se o total recebido corresponde a zero.
    -- THEN apresenta uma mensagem quando a condicao e verdadeira.
    -- ELSE apresenta a outra mensagem quando nao e verdadeira.
    --
    -- Importante: "Nao recebido" significa que esta consulta
    -- nao encontrou quantidade recebida vinculada ao pedido.
    -- Isso nao comprova, sozinho, que a mercadoria nao chegou.
    CASE
        WHEN COALESCE(r.total_recebido, 0) = 0
            THEN 'Nao recebido'
        ELSE 'Recebimento parcial'
    END AS situacao

-- A letra p e um apelido para a tabela pedido_compra.
FROM pedido_compra p

-- LEFT JOIN relaciona os pedidos com o resultado recebimentos.
-- A letra r representa a CTE criada anteriormente.
--
-- LEFT JOIN mantem os pedidos mesmo quando nao encontra
-- uma entrada de mercadoria correspondente.
-- Nesses casos, os campos de r ficam com valor NULL.
LEFT JOIN recebimentos r

    -- Relaciona os registros pelo numero da ordem de compra.
    ON p.ordem_compra = r.ordem_compra

   -- Confere tambem se o codigo do produto e o mesmo.
   -- As duas condicoes precisam ser atendidas.
   AND p.produto_id = r.produto_id

-- Retorna somente pedidos cuja quantidade solicitada
-- e maior que a quantidade encontrada nos recebimentos.
-- Por isso, aparecem pedidos com quantidade pendente positiva.
WHERE p.qtde_pedida > COALESCE(r.total_recebido, 0)

-- Organiza primeiro os pedidos com maior quantidade pendente.
-- DESC ordena do maior para o menor.
-- Em caso de empate, utiliza o numero do pedido.
ORDER BY quantidade_pendente DESC, p.pedido_id;
