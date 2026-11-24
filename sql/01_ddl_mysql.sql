-- DDL corrigido (MySQL 8 / MariaDB 10.6+)
-- Mesmas correções do PostgreSQL, adaptadas: sem prefixo public., sem cast ::,
-- AUTO_INCREMENT no lugar de IDENTITY, BIGINT/DECIMAL no lugar de int8/float8.
-- Revisão (2ª versão): mesmas mudanças do 01_ddl_postgres.sql (DECIMAL nas
-- quantidades, TIME em horariomov, índices), ENGINE=InnoDB explícito (FKs)
-- e a trigger da Parte 3 na versão MySQL.
-- ATENÇÃO: o DROP DATABASE abaixo apaga o banco estoque_vendas inteiro.

DROP DATABASE IF EXISTS estoque_vendas;

CREATE DATABASE estoque_vendas
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
USE estoque_vendas;

CREATE TABLE fornecedor (
  idfornecedor INT NOT NULL AUTO_INCREMENT,
  razao_social VARCHAR(255) NOT NULL,
  PRIMARY KEY (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE produtos_filial (
  filial_id      INT NOT NULL,
  produto_id     VARCHAR(25) NOT NULL,
  descricao      VARCHAR(255) NOT NULL,
  estoque        DECIMAL(14,3) NOT NULL DEFAULT 0,
  preco_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
  preco_compra   DECIMAL(12,4) NOT NULL DEFAULT 0,
  preco_venda    DECIMAL(12,4) NOT NULL DEFAULT 0,
  idfornecedor   INT NULL,
  PRIMARY KEY (filial_id, produto_id),
  CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor)
    REFERENCES fornecedor (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE venda (
  venda_id       BIGINT NOT NULL,
  data_emissao   DATE NOT NULL,
  horariomov     TIME NOT NULL DEFAULT '00:00:00',
  produto_id     VARCHAR(25) NOT NULL DEFAULT '',
  qtde_vendida   DECIMAL(14,3) NULL,
  valor_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
  filial_id      INT NOT NULL DEFAULT 1,
  item           INT NOT NULL DEFAULT 0,
  unidade_medida VARCHAR(3) NULL,
  PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov),
  KEY ix_venda_data (data_emissao)
) ENGINE=InnoDB;

CREATE TABLE pedido_compra (
  pedido_id         BIGINT NOT NULL DEFAULT 0,
  data_pedido       DATE NULL,
  item              INT NOT NULL DEFAULT 0,
  produto_id        VARCHAR(25) NOT NULL DEFAULT '0',
  descricao_produto VARCHAR(255) NULL,
  ordem_compra      BIGINT NOT NULL DEFAULT 0,
  qtde_pedida       DECIMAL(14,3) NULL,
  filial_id         INT NULL,
  data_entrega      DATE NULL,
  qtde_entregue     DECIMAL(14,3) NOT NULL DEFAULT 0,
  qtde_pendente     DECIMAL(14,3) NOT NULL DEFAULT 0,
  preco_compra      DECIMAL(12,4) NULL DEFAULT 0,
  fornecedor_id     INT NULL,
  PRIMARY KEY (pedido_id, produto_id, item),
  KEY ix_pedido_ordem (ordem_compra),
  KEY ix_pedido_data (data_pedido),
  CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (fornecedor_id)
    REFERENCES fornecedor (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE entradas_mercadoria (
  data_entrada      DATE NULL,
  nro_nfe           VARCHAR(255) NOT NULL,
  item              INT NOT NULL DEFAULT 0,
  produto_id        VARCHAR(25) NOT NULL DEFAULT '0',
  descricao_produto VARCHAR(255) NULL,
  ordem_compra      BIGINT NOT NULL DEFAULT 0,
  qtde_recebida     DECIMAL(14,3) NULL,
  filial_id         INT NULL,
  custo_unitario    DECIMAL(12,4) NOT NULL DEFAULT 0,
  PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe),
  KEY ix_entrada_ordem_prod (ordem_compra, produto_id)
) ENGINE=InnoDB;

-- Trigger da Parte 3 (versão MySQL). Produto inserido sem idfornecedor:
-- cria o fornecedor "A CADASTRAR" (AUTO_INCREMENT gera o número) e liga o produto
-- a ele. Com id informado mas inexistente: cria o fornecedor com esse id.
-- O DELIMITER é comando do cliente mysql/DBeaver: execute como script (Alt+X).
DELIMITER $$
CREATE TRIGGER trg_produtos_filial_fornecedor
BEFORE INSERT ON produtos_filial
FOR EACH ROW
BEGIN
  IF NEW.idfornecedor IS NULL THEN
    INSERT INTO fornecedor (razao_social)
    VALUES (CONCAT('FORNECEDOR A CADASTRAR - produto ', NEW.produto_id));
    SET NEW.idfornecedor = LAST_INSERT_ID();
  ELSEIF NOT EXISTS (SELECT 1 FROM fornecedor WHERE idfornecedor = NEW.idfornecedor) THEN
    INSERT INTO fornecedor (idfornecedor, razao_social)
    VALUES (NEW.idfornecedor, CONCAT('FORNECEDOR A CADASTRAR - id ', NEW.idfornecedor));
  END IF;
END$$
DELIMITER ;

SHOW TABLES;
