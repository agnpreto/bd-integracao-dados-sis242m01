-- =====================================================================
-- 01_ddl_mysql.sql  |  DDL corrigido para MySQL 8
-- Disciplina: Banco de Dados (SIS242M01)
-- Autor: Franklin Mendonça
-- Mesmas correções do PostgreSQL (ver 01_ddl_postgres.sql e
-- docs/parte1_importacao.md). Diferenças de dialeto: sem schema "public",
-- DOUBLE/DECIMAL/BIGINT, ENGINE=InnoDB (necessário para FK).
-- Obs.: escrito para MySQL 8, mas NÃO foi executado em servidor MySQL; o teste foi no PostgreSQL.
-- =====================================================================

DROP TABLE IF EXISTS venda;
DROP TABLE IF EXISTS entradas_mercadoria;
DROP TABLE IF EXISTS pedido_compra;
DROP TABLE IF EXISTS produtos_filial;
DROP TABLE IF EXISTS fornecedor;

CREATE TABLE fornecedor (
    idfornecedor VARCHAR(25)  NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE produtos_filial (
    filial_id      INT          NOT NULL,
    produto_id     VARCHAR(255) NOT NULL,
    descricao      VARCHAR(255) NOT NULL,
    estoque        DOUBLE       NOT NULL DEFAULT 0,
    preco_unitario DOUBLE       NOT NULL DEFAULT 0,
    preco_compra   DOUBLE       NOT NULL DEFAULT 0,
    preco_venda    DOUBLE       NOT NULL DEFAULT 0,
    idfornecedor   VARCHAR(25)  NULL,
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_filial_fornecedor
        FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE pedido_compra (
    pedido_id         BIGINT       NOT NULL DEFAULT 0,
    data_pedido       DATE         NULL,
    item              INT          NOT NULL DEFAULT 0,
    produto_id        VARCHAR(25)  NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255) NULL,
    ordem_compra      BIGINT       NOT NULL DEFAULT 0,
    qtde_pedida       DOUBLE       NULL,
    filial_id         INT          NULL,
    data_entrega      DATE         NULL,
    qtde_entregue     DOUBLE       NOT NULL DEFAULT 0,
    qtde_pendente     DOUBLE       NOT NULL DEFAULT 0,
    preco_compra      DOUBLE       NULL DEFAULT 0,
    fornecedor_id     VARCHAR(25)  NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item),
    CONSTRAINT fk_pedido_compra_fornecedor
        FOREIGN KEY (fornecedor_id) REFERENCES fornecedor (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE entradas_mercadoria (
    data_entrada      DATE           NULL,
    nro_nfe           VARCHAR(255)   NOT NULL,
    item              INT            NOT NULL DEFAULT 0,
    produto_id        VARCHAR(25)    NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255)   NULL,
    ordem_compra      BIGINT         NOT NULL DEFAULT 0,
    qtde_recebida     DOUBLE         NULL,
    filial_id         INT            NULL,
    custo_unitario    DECIMAL(12, 4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey
        PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
) ENGINE=InnoDB;

CREATE TABLE venda (
    venda_id       BIGINT         NOT NULL,
    data_emissao   DATE           NOT NULL,
    horariomov     VARCHAR(8)     NOT NULL DEFAULT '00:00:00',
    produto_id     VARCHAR(25)    NOT NULL DEFAULT '',
    qtde_vendida   DOUBLE         NULL,
    valor_unitario DECIMAL(12, 4) NOT NULL DEFAULT 0,
    filial_id      BIGINT         NOT NULL DEFAULT 1,
    item           INT            NOT NULL DEFAULT 0,
    unidade_medida VARCHAR(3)     NULL,
    CONSTRAINT pk_consumo
        PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
) ENGINE=InnoDB;
