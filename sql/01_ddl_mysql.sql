-- =====================================================================
-- DDL corrigido (MySQL 8). Mesmas correções do PostgreSQL, mais:
--  * removido "public." e os casts ::character varying (sintaxe do PG);
--  * fornecedor.idfornecedor AUTO_INCREMENT (usado pela trigger da Parte 3).
-- =====================================================================
DROP DATABASE IF EXISTS integracao;
CREATE DATABASE integracao CHARACTER SET utf8mb4;
USE integracao;

CREATE TABLE fornecedor (
    idfornecedor INT          NOT NULL AUTO_INCREMENT,
    razao_social VARCHAR(255) NOT NULL,
    PRIMARY KEY (idfornecedor)
);

CREATE TABLE produtos_filial (
    filial_id      INT          NOT NULL,
    produto_id     VARCHAR(25)  NOT NULL,
    descricao      VARCHAR(255) NOT NULL,
    estoque        DOUBLE       NOT NULL DEFAULT 0,
    preco_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
    preco_compra   DECIMAL(12,4) NOT NULL DEFAULT 0,
    preco_venda    DECIMAL(12,4) NOT NULL DEFAULT 0,
    idfornecedor   INT          NULL,
    PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor)
);

CREATE TABLE venda (
    venda_id       BIGINT        NOT NULL,
    data_emissao   DATE          NOT NULL,
    horariomov     VARCHAR(8)    NOT NULL DEFAULT '00:00:00',
    produto_id     VARCHAR(25)   NOT NULL,
    qtde_vendida   DECIMAL(14,3) NULL,
    valor_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
    filial_id      INT           NOT NULL DEFAULT 1,
    item           INT           NOT NULL DEFAULT 0,
    unidade_medida VARCHAR(3)    NULL,
    PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

CREATE TABLE pedido_compra (
    pedido_id         INT           NOT NULL,
    data_pedido       DATE          NULL,
    item              INT           NOT NULL DEFAULT 0,
    produto_id        VARCHAR(25)   NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255)  NULL,
    ordem_compra      INT           NOT NULL DEFAULT 0,
    qtde_pedida       DECIMAL(14,3) NULL,
    filial_id         INT           NOT NULL,
    data_entrega      DATE          NULL,
    qtde_entregue     DECIMAL(14,3) NOT NULL DEFAULT 0,
    qtde_pendente     DECIMAL(14,3) GENERATED ALWAYS AS (qtde_pedida - qtde_entregue) STORED,
    preco_compra      DECIMAL(12,4) NULL DEFAULT 0,
    fornecedor_id     INT           NULL,
    PRIMARY KEY (pedido_id, produto_id, item),
    CONSTRAINT fk_pedido_produto    FOREIGN KEY (filial_id, produto_id) REFERENCES produtos_filial (filial_id, produto_id),
    CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (fornecedor_id) REFERENCES fornecedor (idfornecedor)
);

-- (nro_nfe VARCHAR(255) na PK estouraria o limite de chave do MySQL com utf8mb4; 100 basta.)
CREATE TABLE entradas_mercadoria (
    data_entrada      DATE          NULL,
    nro_nfe           VARCHAR(100)  NOT NULL,
    item              INT           NOT NULL DEFAULT 0,
    produto_id        VARCHAR(25)   NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255)  NULL,
    ordem_compra      INT           NOT NULL DEFAULT 0,
    qtde_recebida     DECIMAL(14,3) NULL,
    filial_id         INT           NOT NULL,
    custo_unitario    DECIMAL(12,4) NOT NULL DEFAULT 0,
    PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe),
    CONSTRAINT fk_entrada_produto FOREIGN KEY (filial_id, produto_id) REFERENCES produtos_filial (filial_id, produto_id)
);

CREATE INDEX idx_venda_data    ON venda (data_emissao);
CREATE INDEX idx_pedido_ordem  ON pedido_compra (ordem_compra, produto_id);
CREATE INDEX idx_entrada_ordem ON entradas_mercadoria (ordem_compra, produto_id);
