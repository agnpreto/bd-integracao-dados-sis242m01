-- Active: 1795404488346@@127.0.0.1@3306
-- DDL corrigido (MySQL)
-- Mesmas correções do PostgreSQL, adaptadas: sem prefixo public., sem cast ::,
-- AUTO_INCREMENT no lugar de IDENTITY, DOUBLE/BIGINT/DECIMAL.


 DROP DATABASE IF EXISTS estoque_vendas;

CREATE DATABASE estoque_vendas
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
 USE estoque_vendas;

CREATE TABLE fornecedor (
  idfornecedor INT NOT NULL AUTO_INCREMENT,
  razao_social VARCHAR(255) NOT NULL,
  PRIMARY KEY (idfornecedor)
);

CREATE TABLE produtos_filial (
  filial_id      INT NOT NULL,
  produto_id     VARCHAR(25) NOT NULL,
  descricao      VARCHAR(255) NOT NULL,
  estoque        DOUBLE NOT NULL DEFAULT 0,
  preco_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
  preco_compra   DECIMAL(12,4) NOT NULL DEFAULT 0,
  preco_venda    DECIMAL(12,4) NOT NULL DEFAULT 0,
  idfornecedor   INT NULL,
  PRIMARY KEY (filial_id, produto_id),
  CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor)
    REFERENCES fornecedor (idfornecedor)
);

CREATE TABLE venda (
  venda_id       BIGINT NOT NULL,
  data_emissao   DATE NOT NULL,
  horariomov     VARCHAR(8) NOT NULL DEFAULT '00:00:00',
  produto_id     VARCHAR(25) NOT NULL DEFAULT '',
  qtde_vendida   DOUBLE NULL,
  valor_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
  filial_id      INT NOT NULL DEFAULT 1,
  item           INT NOT NULL DEFAULT 0,
  unidade_medida VARCHAR(3) NULL,
  PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

CREATE TABLE pedido_compra (
  pedido_id         BIGINT NOT NULL DEFAULT 0,
  data_pedido       DATE NULL,
  item              INT NOT NULL DEFAULT 0,
  produto_id        VARCHAR(25) NOT NULL DEFAULT '0',
  descricao_produto VARCHAR(255) NULL,
  ordem_compra      BIGINT NOT NULL DEFAULT 0,
  qtde_pedida       DOUBLE NULL,
  filial_id         INT NULL,
  data_entrega      DATE NULL,
  qtde_entregue     DOUBLE NOT NULL DEFAULT 0,
  qtde_pendente     DOUBLE NOT NULL DEFAULT 0,
  preco_compra      DECIMAL(12,4) NULL DEFAULT 0,
  fornecedor_id     INT NULL,
  PRIMARY KEY (pedido_id, produto_id, item),
  CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (fornecedor_id)
    REFERENCES fornecedor (idfornecedor)
);

CREATE TABLE entradas_mercadoria (
  data_entrada      DATE NULL,
  nro_nfe           VARCHAR(255) NOT NULL,
  item              INT NOT NULL DEFAULT 0,
  produto_id        VARCHAR(25) NOT NULL DEFAULT '0',
  descricao_produto VARCHAR(255) NULL,
  ordem_compra      BIGINT NOT NULL DEFAULT 0,
  qtde_recebida     DOUBLE NULL,
  filial_id         INT NULL,
  custo_unitario    DECIMAL(12,4) NOT NULL DEFAULT 0,
  PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

 SHOW TABLES;