-- DDL corrigido para PostgreSQL
-- Atividade de Integracao de Dados
-- Parte 1: Criacao das tabelas

-- Este arquivo utiliza a linguagem DDL para criar as cinco
-- tabelas que armazenam os dados da empresa comercial.
-- DDL significa Linguagem de Definicao de Dados.
-- Os registros vieram da planilha dados/base_teste.xlsx.
-- A importacao dos dados e realizada separadamente com Python.

-- 1. Tabela de vendas
-- Armazena as vendas realizadas pelas diferentes filiais.
-- Cada registro representa um item de uma venda.
-- CREATE TABLE cria uma tabela no banco de dados.
-- public indica o esquema em que a tabela sera criada.
CREATE TABLE public.venda (
    -- Numero que identifica a venda.
    -- int8 representa um numero inteiro de 64 bits.
    -- NOT NULL torna o preenchimento obrigatorio.
    venda_id int8 NOT NULL,

    -- Data em que a venda foi registrada.
    -- O tipo date armazena a data sem o horario.
    data_emissao date NOT NULL,

    -- Horario em que ocorreu a movimentacao.
    -- varchar(8) permite armazenar ate oito caracteres.
    -- DEFAULT define um valor padrao quando nao informado.
    horariomov varchar(8) DEFAULT '00:00:00' NOT NULL,

    -- Codigo do produto vendido, como P1 ou P2.
    -- O valor padrao e um texto vazio.
    produto_id varchar(25) DEFAULT '' NOT NULL,

    -- Quantidade do produto vendida.
    -- float8 permite numeros com casas decimais.
    -- NULL permite que o campo fique sem valor.
    qtde_vendida float8 NULL,

    -- Preco unitario registrado na venda.
    -- numeric(12,4) permite 12 digitos no total,
    -- sendo quatro deles destinados as casas decimais.
    valor_unitario numeric(12,4) DEFAULT 0 NOT NULL,

    -- Identificador da filial responsavel pela venda.
    -- Quando nao informado, utiliza o valor 1.
    filial_id int8 DEFAULT 1 NOT NULL,

    -- Numero que identifica o item dentro da venda.
    -- int4 representa um numero inteiro de 32 bits.
    item int4 DEFAULT 0 NOT NULL,

    -- Unidade de medida utilizada na venda.
    -- Exemplos: UN ou KG.
    unidade_medida varchar(3) NULL,

    -- CONSTRAINT define uma restricao da tabela.
    -- PRIMARY KEY representa a chave primaria.
    -- A combinacao das seis colunas identifica cada registro.
    -- Isso impede a repeticao da mesma combinacao de valores.
    CONSTRAINT pk_consumo PRIMARY KEY
        (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

-- 2. Tabela de pedidos de compra
-- Armazena os pedidos feitos pela empresa aos fornecedores.
-- Permite consultar os produtos solicitados, as quantidades,
-- as datas e as informacoes de entrega.
CREATE TABLE public.pedido_compra (
    -- Numero que identifica o pedido de compra.
    -- float8 permite armazenar valores numericos.
    pedido_id float8 DEFAULT 0 NOT NULL,

    -- Data em que o pedido foi realizado.
    data_pedido date NULL,

    -- Identifica o item dentro do pedido.
    -- Um pedido pode possuir diferentes itens.
    item float8 DEFAULT 0 NOT NULL,

    -- Codigo do produto solicitado pela empresa.
    produto_id varchar(25) DEFAULT '0' NOT NULL,

    -- Nome ou descricao do produto solicitado.
    descricao_produto varchar(255) NULL,

    -- Numero da ordem de compra.
    -- Permite relacionar pedidos e entradas de mercadorias.
    -- Na validacao, foram encontrados registros com valor zero.
    ordem_compra float8 DEFAULT 0 NOT NULL,

    -- Quantidade de unidades solicitadas no pedido.
    -- Foi comparada com a quantidade recebida na validacao.
    qtde_pedida float8 NULL,

    -- Identifica a filial que realizou o pedido.
    filial_id int4 NULL,

    -- Data de entrega informada no pedido.
    -- Permite verificar se a entrega aparece antes do pedido.
    data_entrega date NULL,

    -- Quantidade registrada como entregue no pedido.
    -- Pode ser comparada com os recebimentos de mercadorias.
    qtde_entregue float8 DEFAULT 0 NOT NULL,

    -- Quantidade que ainda falta ser entregue.
    -- Na importacao com Python, esse valor foi calculado
    -- subtraindo qtde_entregue de qtde_pedida.
    -- Esta coluna nao calcula o valor automaticamente no SQL.
    qtde_pendente float8 DEFAULT 0 NOT NULL,

    -- Preco de compra registrado para o produto.
    preco_compra float8 DEFAULT 0 NULL,

    -- Identificador do fornecedor relacionado ao pedido.
    fornecedor_id int4 DEFAULT 0 NULL,

    -- Chave primaria formada por pedido_id, produto_id e item.
    -- Impede repetir a mesma combinacao dessas tres colunas.
    CONSTRAINT pedido_compra_pkey PRIMARY KEY
        (pedido_id, produto_id, item)
);

-- 3. Tabela de entradas de mercadoria
-- Correcao: adicionada a coluna ordem_compra
-- Registra as mercadorias que chegaram a empresa.
-- A coluna ordem_compra foi adicionada porque aparecia
-- na chave primaria original, mas nao estava declarada.
-- Essa tabela e utilizada para conferir os recebimentos.
CREATE TABLE public.entradas_mercadoria (
    -- Data em que a mercadoria foi registrada como recebida.
    data_entrada date NULL,

    -- Numero da nota fiscal relacionada ao recebimento.
    nro_nfe varchar(255) NOT NULL,

    -- Identifica o item registrado na entrada.
    item float8 DEFAULT 0 NOT NULL,

    -- Codigo do produto recebido.
    produto_id varchar(25) DEFAULT '0' NOT NULL,

    -- Nome ou descricao do produto recebido.
    descricao_produto varchar(255) NULL,

    -- Numero da ordem de compra relacionada a entrada.
    -- Permite comparar os registros com pedido_compra.
    ordem_compra float8 DEFAULT 0 NOT NULL,

    -- Quantidade de unidades registradas como recebidas.
    -- Foi utilizada nas consultas para encontrar diferencas
    -- entre o que foi pedido e o que chegou a empresa.
    qtde_recebida float8 NULL,

    -- Identifica a filial que recebeu a mercadoria.
    filial_id int4 NULL,

    -- Custo unitario da mercadoria recebida.
    -- numeric(12,4) permite armazenar valores decimais.
    custo_unitario numeric(12,4) DEFAULT 0 NOT NULL,

    -- Chave primaria formada por quatro identificadores.
    -- Impede repetir a mesma combinacao de ordem de compra,
    -- item, produto e numero da nota fiscal.
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY
        (ordem_compra, item, produto_id, nro_nfe)
);

-- 4. Tabela de produtos por filial
-- Correcao: nomes das colunas, tipos e chave primaria
-- Armazena os produtos cadastrados em cada filial.
-- Contem informacoes sobre estoque, descricao, precos
-- e o fornecedor associado a cada produto.
CREATE TABLE public.produtos_filial (
    -- Identificador da filial em que o produto esta cadastrado.
    filial_id int4 NOT NULL,

    -- Codigo utilizado para identificar o produto.
    -- Um mesmo codigo pode existir em filiais diferentes.
    produto_id varchar(255) NOT NULL,

    -- Nome ou descricao do produto.
    descricao varchar(255) NOT NULL,

    -- Quantidade registrada no estoque da filial.
    estoque float8 DEFAULT 0 NOT NULL,

    -- Preco unitario cadastrado para o produto.
    preco_unitario float8 DEFAULT 0 NOT NULL,

    -- Valor pelo qual a empresa compra o produto.
    preco_compra float8 DEFAULT 0 NOT NULL,

    -- Valor pelo qual a empresa vende o produto.
    preco_venda float8 DEFAULT 0 NOT NULL,

    -- Codigo do fornecedor associado ao produto.
    -- Pode ficar sem valor quando ainda nao informado.
    -- A trigger definida em sql/03_transformacoes.sql
    -- pode gerar um identificador ao cadastrar o produto.
    idfornecedor varchar(25) NULL,

    -- Chave primaria formada por filial_id e produto_id.
    -- Impede cadastrar o mesmo codigo duas vezes
    -- dentro de uma mesma filial.
    CONSTRAINT produtos_filial_pkey PRIMARY KEY
        (filial_id, produto_id)
);

-- 5. Tabela de fornecedores
-- Correcao: nome do identificador e chave primaria
-- Armazena os fornecedores que abastecem a empresa.
-- Cada fornecedor possui um codigo e uma razao social.
CREATE TABLE public.fornecedor (
    -- Codigo unico utilizado para identificar o fornecedor.
    -- Exemplos de identificadores: F1, F2 e F3.
    idfornecedor varchar(25) NOT NULL,

    -- Razao social ou nome empresarial do fornecedor.
    razao_social varchar(255) NOT NULL,

    -- A chave primaria utiliza somente idfornecedor.
    -- Impede cadastrar dois fornecedores com o mesmo codigo.
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

-- As cinco tabelas acima armazenam os dados do projeto.
-- Os comandos CREATE TABLE criam apenas suas estruturas.
-- A importacao das 122 linhas foi feita com scripts/importar.py.
-- As consultas de validacao estao em sql/04_validacao.sql.
-- As chaves primarias identificam os registros de cada tabela.
-- Neste arquivo nao foram declaradas restricoes FOREIGN KEY.
