-- DDL corrigido para MySQL


-- Atividade de Integracao de Dados

-- ============================================================
-- PARTE 1: CRIACAO DAS TABELAS NO MYSQL
-- Atividade de Integracao de Dados
-- ============================================================

-- Este arquivo cria a estrutura do banco de dados no MySQL.
-- As tabelas armazenam informacoes sobre vendas, pedidos,
-- recebimentos de mercadorias, produtos e fornecedores.
--
-- Os dados originais estao em dados/base_teste.xlsx.
-- Este arquivo cria apenas as tabelas; ele nao importa o Excel.
--
-- O DDL foi adaptado para MySQL, corrigindo problemas
-- encontrados na estrutura originalmente fornecida.


-- ============================================================
-- 1. TABELA DE VENDAS
-- ============================================================

-- Armazena as vendas realizadas pelas filiais da empresa.
-- Cada registro representa um item de uma venda.

CREATE TABLE venda (
    -- Identifica o numero da venda.
    venda_id BIGINT NOT NULL,

    -- Armazena a data em que a venda foi registrada.
    data_emissao DATE NOT NULL,

    -- Guarda o horario da movimentacao como texto.
    -- Se nao for informado, utiliza 00:00:00.
    horariomov VARCHAR(8) NOT NULL DEFAULT '00:00:00',

    -- Identifica o produto vendido.
    produto_id VARCHAR(25) NOT NULL DEFAULT '',

    -- Armazena a quantidade vendida.
    -- DOUBLE permite valores numericos com casas decimais.
    -- NULL permite que a informacao fique vazia.
    qtde_vendida DOUBLE NULL,

    -- Armazena o valor unitario utilizado na venda.
    -- DECIMAL(12,4) permite ate 12 digitos, sendo
    -- quatro depois da virgula.
    valor_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,

    -- Identifica a filial responsavel pela venda.
    -- Caso nao seja informada, utiliza a filial 1.
    filial_id BIGINT NOT NULL DEFAULT 1,

    -- Identifica o item dentro da venda.
    item INT NOT NULL DEFAULT 0,

    -- Informa a unidade de medida do produto.
    -- Exemplo: UN ou KG.
    unidade_medida VARCHAR(3) NULL,

    -- Define a chave primaria da tabela.
    -- A combinacao dessas seis colunas identifica
    -- cada registro e impede duplicidades dessa combinacao.
    CONSTRAINT pk_consumo PRIMARY KEY
        (filial_id, venda_id, data_emissao, produto_id, item, horariomov)

-- InnoDB e o mecanismo de armazenamento utilizado.
-- utf8mb4 permite armazenar caracteres especiais e acentos.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- 2. TABELA DE PEDIDOS DE COMPRA
-- ============================================================

-- Armazena os pedidos feitos pela empresa aos fornecedores.
-- Permite conferir o que foi solicitado e o que foi entregue.

CREATE TABLE pedido_compra (
    -- Identifica o pedido de compra.
    pedido_id DOUBLE NOT NULL DEFAULT 0,

    -- Data em que o pedido foi realizado.
    data_pedido DATE NULL,

    -- Numero do item dentro do pedido.
    item DOUBLE NOT NULL DEFAULT 0,

    -- Codigo do produto solicitado.
    produto_id VARCHAR(25) NOT NULL DEFAULT '0',

    -- Descricao do produto solicitado.
    descricao_produto VARCHAR(255) NULL,

    -- Numero da ordem de compra.
    -- Esse numero ajuda a relacionar o pedido
    -- com os registros de entrada de mercadorias.
    ordem_compra DOUBLE NOT NULL DEFAULT 0,

    -- Quantidade de unidades solicitadas pela empresa.
    qtde_pedida DOUBLE NULL,

    -- Identifica a filial que realizou o pedido.
    filial_id INT NULL,

    -- Data de entrega informada no pedido.
    -- Pode ser utilizada para verificar datas suspeitas.
    data_entrega DATE NULL,

    -- Quantidade registrada como entregue no pedido.
    qtde_entregue DOUBLE NOT NULL DEFAULT 0,

    -- Quantidade que ainda falta receber.
    -- Na importacao Python, esse valor foi calculado
    -- subtraindo qtde_entregue de qtde_pedida.
    qtde_pendente DOUBLE NOT NULL DEFAULT 0,

    -- Valor de compra do produto.
    preco_compra DOUBLE NULL DEFAULT 0,

    -- Identifica o fornecedor relacionado ao pedido.
    fornecedor_id INT NULL DEFAULT 0,

    -- A chave primaria combina pedido, produto e item.
    -- Isso permite que um pedido tenha diferentes itens,
    -- sem repetir a mesma combinacao de identificadores.
    CONSTRAINT pedido_compra_pkey PRIMARY KEY
        (pedido_id, produto_id, item)

-- Define o mecanismo de armazenamento e a codificacao.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- 3. TABELA DE ENTRADAS DE MERCADORIAS
-- ============================================================

-- Armazena as mercadorias registradas como recebidas.
-- Permite comparar os recebimentos com os pedidos de compra.
--
-- Correcao realizada no DDL original:
-- foi adicionada a coluna ordem_compra, que era utilizada
-- pela chave primaria, mas nao estava declarada.

CREATE TABLE entradas_mercadoria (
    -- Data em que a mercadoria entrou na empresa.
    data_entrada DATE NULL,

    -- Numero da nota fiscal da entrada.
    nro_nfe VARCHAR(255) NOT NULL,

    -- Identifica o item da nota ou da entrada.
    item DOUBLE NOT NULL DEFAULT 0,

    -- Codigo do produto recebido.
    produto_id VARCHAR(25) NOT NULL DEFAULT '0',

    -- Descricao do produto recebido.
    descricao_produto VARCHAR(255) NULL,

    -- Numero da ordem de compra relacionada a entrada.
    -- Tambem e utilizado para comparar com pedido_compra.
    ordem_compra DOUBLE NOT NULL DEFAULT 0,

    -- Quantidade de mercadorias registradas como recebidas.
    qtde_recebida DOUBLE NULL,

    -- Filial que recebeu a mercadoria.
    filial_id INT NULL,

    -- Custo unitario registrado na entrada.
    custo_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,

    -- Chave primaria formada por quatro colunas.
    -- Impede a repeticao da mesma combinacao de
    -- ordem de compra, item, produto e nota fiscal.
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY
        (ordem_compra, item, produto_id, nro_nfe)

-- Define o mecanismo de armazenamento e a codificacao.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- 4. TABELA DE PRODUTOS POR FILIAL
-- ============================================================

-- Armazena os produtos cadastrados em cada filial.
-- Contem informacoes como estoque, descricao e precos.
--
-- Correcoes realizadas no DDL original:
-- foram corrigidos nomes de colunas, a chave primaria
-- e a obrigatoriedade do identificador da filial.

CREATE TABLE produtos_filial (
    -- Identifica a filial em que o produto esta cadastrado.
    filial_id INT NOT NULL,

    -- Codigo utilizado para identificar o produto.
    produto_id VARCHAR(255) NOT NULL,

    -- Nome ou descricao do produto.
    descricao VARCHAR(255) NOT NULL,

    -- Quantidade registrada em estoque.
    estoque DOUBLE NOT NULL DEFAULT 0,

    -- Preco unitario cadastrado para o produto.
    preco_unitario DOUBLE NOT NULL DEFAULT 0,

    -- Preco pelo qual a empresa compra o produto.
    preco_compra DOUBLE NOT NULL DEFAULT 0,

    -- Preco pelo qual a empresa vende o produto.
    preco_venda DOUBLE NOT NULL DEFAULT 0,

    -- Codigo do fornecedor associado ao produto.
    -- Pode ficar vazio quando ainda nao informado.
    idfornecedor VARCHAR(25) NULL,

    -- A chave primaria combina filial e produto.
    -- Assim, um mesmo produto pode aparecer em
    -- filiais diferentes, mas nao pode ser repetido
    -- com o mesmo codigo dentro da mesma filial.
    CONSTRAINT produtos_filial_pkey PRIMARY KEY
        (filial_id, produto_id)

-- Define o mecanismo de armazenamento e a codificacao.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- 5. TABELA DE FORNECEDORES
-- ============================================================

-- Armazena as empresas que fornecem mercadorias.
-- Cada fornecedor possui um codigo e uma razao social.
--
-- Correcoes realizadas no DDL original:
-- o nome do identificador foi corrigido e a chave primaria
-- passou a utilizar apenas a coluna idfornecedor.

CREATE TABLE fornecedor (
    -- Codigo unico que identifica o fornecedor.
    -- Exemplo de formato utilizado no projeto: F1, F2, F3.
    idfornecedor VARCHAR(25) NOT NULL,

    -- Nome empresarial ou razao social do fornecedor.
    razao_social VARCHAR(255) NOT NULL,

    -- Impede o cadastro de dois fornecedores
    -- utilizando o mesmo identificador.
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)

-- Define o mecanismo de armazenamento e a codificacao.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- FIM DA PARTE 1: CRIACAO DAS TABELAS
-- ============================================================

-- Foram definidas cinco tabelas:
-- 1. venda
-- 2. pedido_compra
-- 3. entradas_mercadoria
-- 4. produtos_filial
-- 5. fornecedor
--
-- Os comandos CREATE TABLE definem a estrutura do banco.
-- A importacao dos registros foi realizada separadamente,
-- usando Python e PostgreSQL no ambiente principal.
--
-- Neste DDL, as chaves primarias identificam os registros.
-- Nao foram declaradas restricoes FOREIGN KEY.
--
-- Na apresentacao, a estrutura MySQL demonstra
-- a adaptacao do DDL para outro SGBD.
-- As consultas e a validacao principal foram
-- executadas no PostgreSQL.
