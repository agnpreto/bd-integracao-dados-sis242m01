
-- Parte 4: Validacao dos dados
-- Nome: RENISON
-- Periodo de referencia: fevereiro de 2025
-- Consultas somente de leitura: nao alteram os dados.

-- Este arquivo verifica possiveis inconsistencias nos dados
-- que foram importados da planilha Excel para o PostgreSQL.
--
-- As consultas comparam informacoes de compras, recebimentos,
-- vendas e produtos cadastrados nas filiais.
--
-- O objetivo e encontrar situacoes que precisam ser
-- confirmadas com a empresa antes de realizar correcoes.
--
-- Embora fevereiro de 2025 seja o periodo de referencia
-- da atividade, estas seis consultas nao possuem filtro
-- de data e analisam todos os registros importados.
--
-- Todas utilizam SELECT e nao modificam o banco de dados.


-- Validacao 1: Recebimentos maiores que os pedidos.
-- Exemplo investigado: produto P2.

-- Objetivo: encontrar pedidos cuja quantidade recebida
-- foi maior do que a quantidade solicitada.
--
-- A consulta relaciona duas tabelas:
-- pedido_compra: quantidade solicitada pela empresa.
-- entradas_mercadoria: quantidade registrada como recebida.
--
-- Exemplo real do projeto:
-- Produto P2: 14 unidades pedidas e 64 recebidas.
-- A diferenca encontrada foi de 50 unidades a mais.
--
-- A diferenca nao confirma automaticamente um erro.
-- Precisamos verificar o pedido e a nota fiscal com o cliente.

-- WITH cria um resultado temporario chamado recebimentos.
-- Esse resultado fica disponivel durante esta consulta.
WITH recebimentos AS (
    -- Seleciona a ordem de compra e o codigo do produto.
    -- SUM soma as quantidades recebidas do mesmo grupo.
    -- AS define o nome da coluna calculada.
    SELECT ordem_compra, produto_id,
           SUM(qtde_recebida) AS total_recebido

    -- Busca os registros na tabela de entradas de mercadoria.
    FROM entradas_mercadoria

    -- GROUP BY agrupa os recebimentos que possuem
    -- a mesma ordem de compra e o mesmo produto.
    GROUP BY ordem_compra, produto_id
)

-- A consulta principal compara os pedidos com os recebimentos.
SELECT
    -- Numero que identifica o pedido de compra.
    p.pedido_id,

    -- Numero da ordem de compra associada ao pedido.
    p.ordem_compra,

    -- Codigo do produto solicitado.
    p.produto_id,

    -- Quantidade solicitada pela empresa.
    p.qtde_pedida,

    -- Total de unidades recebidas, calculado anteriormente.
    r.total_recebido,

    -- Subtrai a quantidade pedida da quantidade recebida.
    -- O resultado representa quantas unidades excederam
    -- a quantidade solicitada.
    r.total_recebido - p.qtde_pedida AS quantidade_excedente

-- A letra p e um apelido para a tabela pedido_compra.
FROM pedido_compra p

-- JOIN relaciona os pedidos com os recebimentos.
-- Nesse caso, somente registros correspondentes
-- nas duas fontes participam do resultado.
JOIN recebimentos r

    -- A ordem de compra precisa ser a mesma.
    ON p.ordem_compra = r.ordem_compra

   -- O codigo do produto tambem precisa ser o mesmo.
   AND p.produto_id = r.produto_id

-- WHERE filtra somente os casos em que a quantidade
-- recebida ultrapassa a quantidade solicitada.
WHERE r.total_recebido > p.qtde_pedida

-- Organiza os resultados pelo maior excesso primeiro.
-- DESC significa ordem decrescente.
ORDER BY quantidade_excedente DESC;


-- Validacao 2: Divergencia entre a quantidade entregue
-- informada no pedido e o recebimento registrado.

-- Objetivo: identificar diferencas entre a quantidade
-- registrada como entregue no pedido e a quantidade
-- encontrada na tabela de entradas de mercadorias.
--
-- As informacoes comparadas sao:
-- pedido_compra.qtde_entregue
-- entradas_mercadoria.qtde_recebida
--
-- Exemplo real do projeto:
-- Produto P1: 10 unidades informadas como entregues
-- no pedido e 77 registradas como recebidas na entrada.
--
-- Esses campos podem representar etapas diferentes.
-- Por isso, a divergencia precisa ser esclarecida.

-- Cria um resultado temporario com os totais recebidos.
WITH recebimentos AS (
    -- Seleciona a ordem, o produto e a soma recebida.
    SELECT ordem_compra, produto_id,
           SUM(qtde_recebida) AS total_recebido

    -- Consulta a tabela que registra as entradas.
    FROM entradas_mercadoria

    -- Agrupa os registros pela ordem e pelo produto.
    GROUP BY ordem_compra, produto_id
)

-- Seleciona as informacoes que serao comparadas.
SELECT
    -- Identificador do pedido.
    p.pedido_id,

    -- Codigo do produto.
    p.produto_id,

    -- Numero da ordem de compra.
    p.ordem_compra,

    -- Quantidade entregue informada no pedido.
    -- O AS altera apenas o titulo mostrado no resultado.
    p.qtde_entregue AS entregue_no_pedido,

    -- Quantidade total recebida nas entradas.
    r.total_recebido AS recebido_na_entrada

-- A letra p representa a tabela de pedidos.
FROM pedido_compra p

-- JOIN relaciona o pedido ao recebimento correspondente.
JOIN recebimentos r

    -- Compara os numeros das ordens de compra.
    ON p.ordem_compra = r.ordem_compra

   -- Confirma que o codigo do produto e o mesmo.
   AND p.produto_id = r.produto_id

-- IS DISTINCT FROM verifica se os dois valores diferem.
-- Diferentemente de <>, tambem considera valores NULL
-- de maneira definida na comparacao.
--
-- Assim, aparecem os registros cujas quantidades
-- entregues e recebidas nao correspondem.
WHERE p.qtde_entregue IS DISTINCT FROM r.total_recebido

-- Organiza os resultados pelo identificador do pedido.
ORDER BY p.pedido_id;


-- Validacao 3: Pedidos com ordem de compra igual a zero.
-- Precisam ser conferidos com os dados originais.

-- Objetivo: localizar pedidos que possuem o campo
-- ordem_compra preenchido com zero.
--
-- A ordem de compra e utilizada para relacionar
-- pedidos com entradas de mercadorias.
--
-- Quando esse campo vale zero, precisamos confirmar
-- se representa uma informacao ausente ou uma regra
-- utilizada pela propria empresa.
--
-- Na conferencia anterior, foram encontrados 11 pedidos.

-- SELECT escolhe quais colunas serao apresentadas.
SELECT
    -- Numero identificador do pedido.
    pedido_id,

    -- Codigo do produto solicitado.
    produto_id,

    -- Numero da ordem de compra que sera verificado.
    ordem_compra,

    -- Quantidade solicitada no pedido.
    qtde_pedida,

    -- Quantidade registrada como entregue.
    qtde_entregue

-- Consulta os registros da tabela de pedidos de compra.
FROM pedido_compra

-- Retorna somente os pedidos com ordem_compra igual a zero.
WHERE ordem_compra = 0

-- Organiza os resultados pelo numero do pedido.
ORDER BY pedido_id;


-- Validacao 4: Data de entrega anterior a data do pedido.

-- Objetivo: identificar pedidos cuja data de entrega
-- aparece antes da data em que a compra foi solicitada.
--
-- Exemplo real:
-- Pedido 12, produto P12.
-- Data do pedido: 25/02/2025.
-- Data informada de entrega: 20/02/2025.
--
-- Essa situacao precisa ser conferida com a empresa
-- antes de considerar que alguma data foi registrada errada.

-- Seleciona os identificadores e as datas do pedido.
SELECT
    -- Numero identificador do pedido.
    pedido_id,

    -- Codigo do produto relacionado ao pedido.
    produto_id,

    -- TO_CHAR converte a data para o formato DD/MM/AAAA.
    -- AS define o titulo apresentado na consulta.
    TO_CHAR(data_pedido, 'DD/MM/YYYY') AS data_pedido,

    -- Apresenta a data de entrega no mesmo formato.
    TO_CHAR(data_entrega, 'DD/MM/YYYY') AS data_entrega

-- Busca os registros na tabela pedido_compra.
FROM pedido_compra

-- Seleciona somente os registros em que a data
-- de entrega e anterior a data do pedido.
WHERE data_entrega < data_pedido

-- Organiza os resultados pelo numero do pedido.
ORDER BY pedido_id;


-- Validacao 5: Produtos referenciados sem cadastro
-- correspondente na mesma filial.

-- Objetivo: localizar pedidos e vendas cujos produtos
-- nao possuem cadastro correspondente em produtos_filial.
--
-- A consulta considera dois identificadores:
-- filial_id: identifica a filial.
-- produto_id: identifica o produto.
--
-- Um produto pode estar cadastrado em uma filial,
-- mas nao estar cadastrado em outra.
--
-- Por isso, as duas informacoes precisam coincidir.
--
-- A consulta verifica separadamente:
-- 1. Produtos mencionados nos pedidos de compra.
-- 2. Produtos mencionados nas vendas.
--
-- Depois, UNION ALL reune os dois resultados.
--
-- Na execucao anterior, foram encontrados 13 registros,
-- todos provenientes da tabela venda.

-- PRIMEIRA PARTE: CONFERENCIA DOS PEDIDOS DE COMPRA.

SELECT
    -- Identifica de qual tabela veio o registro.
    -- O texto pedido_compra aparece na coluna tabela_origem.
    'pedido_compra' AS tabela_origem,

    -- ::TEXT converte o identificador do pedido para texto.
    -- Isso permite unir o resultado com a segunda consulta,
    -- que tambem apresenta o identificador como texto.
    p.pedido_id::TEXT AS registro_id,

    -- Identificador da filial do pedido.
    p.filial_id,

    -- Codigo do produto mencionado no pedido.
    p.produto_id

-- A letra p representa a tabela pedido_compra.
FROM pedido_compra p

-- NOT EXISTS verifica se nao existe um cadastro correspondente.
-- Quando a subconsulta nao encontra nenhuma linha,
-- o registro do pedido aparece no resultado.
WHERE NOT EXISTS (
    -- SELECT 1 e utilizado para verificar a existencia
    -- de registros, sem precisar retornar suas colunas.
    SELECT 1

    -- A letra pf representa a tabela produtos_filial.
    FROM produtos_filial pf

    -- A filial do cadastro precisa ser a mesma do pedido.
    WHERE pf.filial_id = p.filial_id

      -- O codigo do produto tambem precisa corresponder.
      AND pf.produto_id = p.produto_id
)

-- UNION ALL junta os resultados das duas verificacoes.
-- Diferentemente de UNION, nao elimina linhas repetidas.
UNION ALL

-- SEGUNDA PARTE: CONFERENCIA DAS VENDAS.

SELECT
    -- Identifica que o registro encontrado veio de venda.
    'venda' AS tabela_origem,

    -- Converte o identificador da venda para texto.
    v.venda_id::TEXT AS registro_id,

    -- Identificador da filial onde ocorreu a venda.
    v.filial_id,

    -- Codigo do produto vendido.
    v.produto_id

-- A letra v representa a tabela venda.
FROM venda v

-- Procura vendas sem produto cadastrado na mesma filial.
WHERE NOT EXISTS (
    -- Verifica se existe um cadastro correspondente.
    SELECT 1

    -- Consulta os produtos cadastrados por filial.
    FROM produtos_filial pf

    -- Verifica se a filial e a mesma da venda.
    WHERE pf.filial_id = v.filial_id

      -- Verifica se o produto e o mesmo da venda.
      AND pf.produto_id = v.produto_id
)

-- Organiza primeiro pela tabela de origem.
-- Depois, organiza pelo identificador do registro.
ORDER BY tabela_origem, registro_id;


-- Validacao 6: Entradas sem pedido correspondente.
-- Relacionamento pela ordem de compra e produto.

-- Objetivo: encontrar registros de entrada de mercadorias
-- que nao possuem um pedido correspondente no banco.
--
-- A correspondencia utiliza:
-- ordem_compra: numero da ordem de compra.
-- produto_id: codigo do produto.
--
-- Exemplo real do projeto:
-- Ordem 19, produto P19, nota fiscal NFE19.
-- Ordem 20, produto P20, nota fiscal NFE20.
--
-- Essas entradas precisam ser conferidas para descobrir
-- se o pedido esta ausente ou possui identificacao incorreta.
--
-- A ausencia de correspondencia nao significa
-- necessariamente que a mercadoria chegou sem pedido.

-- Seleciona as informacoes da entrada de mercadoria.
SELECT
    -- Numero da ordem de compra registrado na entrada.
    e.ordem_compra,

    -- Codigo do produto recebido.
    e.produto_id,

    -- Quantidade registrada como recebida.
    e.qtde_recebida,

    -- Numero da nota fiscal relacionada a entrada.
    e.nro_nfe

-- A letra e representa a tabela entradas_mercadoria.
FROM entradas_mercadoria e

-- NOT EXISTS verifica se nao existe um pedido
-- com a mesma ordem de compra e o mesmo produto.
--
-- A entrada aparece no resultado quando a subconsulta
-- nao encontra um pedido correspondente.
WHERE NOT EXISTS (
    -- SELECT 1 verifica apenas a existencia do registro.
    SELECT 1

    -- A letra p representa a tabela pedido_compra.
    FROM pedido_compra p

    -- Confere se o numero da ordem de compra corresponde.
    WHERE p.ordem_compra = e.ordem_compra

      -- Confere tambem o codigo do produto.
      AND p.produto_id = e.produto_id
)

-- Organiza os resultados pela ordem de compra
-- e depois pelo codigo do produto.
ORDER BY e.ordem_compra, e.produto_id;
