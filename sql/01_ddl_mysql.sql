-- DDL corrigido para MySQL
CREATE DATABASE IF NOT EXISTS integracao_dados CHARACTER SET utf8mb4;
USE integracao_dados;

DROP TABLE IF EXISTS entradas_mercadoria, pedido_compra, venda, produtos_filial, fornecedor;

CREATE TABLE fornecedor (
 idfornecedor INT NOT NULL,
 razao_social VARCHAR(255) NOT NULL,
 CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE produtos_filial (
 filial_id INT NOT NULL,
 produto_id VARCHAR(25) NOT NULL,
 descricao VARCHAR(255) NOT NULL,
 estoque DECIMAL(14,4) NOT NULL DEFAULT 0,
 preco_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
 preco_compra DECIMAL(12,4) NOT NULL DEFAULT 0,
 preco_venda DECIMAL(12,4) NOT NULL DEFAULT 0,
 idfornecedor INT NULL,
 CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE venda (
 venda_id BIGINT NOT NULL,
 data_emissao DATE NOT NULL,
 horariomov VARCHAR(8) NOT NULL DEFAULT '00:00:00',
 produto_id VARCHAR(25) NOT NULL,
 qtde_vendida DECIMAL(14,4) NULL,
 valor_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
 filial_id INT NOT NULL,
 item INT NOT NULL,
 unidade_medida VARCHAR(3) NULL,
 CONSTRAINT venda_pkey PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pedido_compra (
 pedido_id BIGINT NOT NULL,
 data_pedido DATE NULL,
 item INT NOT NULL,
 produto_id VARCHAR(25) NOT NULL,
 descricao_produto VARCHAR(255) NULL,
 ordem_compra BIGINT NOT NULL,
 qtde_pedida DECIMAL(14,4) NULL,
 filial_id INT NULL,
 data_entrega DATE NULL,
 qtde_entregue DECIMAL(14,4) NOT NULL DEFAULT 0,
 qtde_pendente DECIMAL(14,4) NOT NULL DEFAULT 0,
 preco_compra DECIMAL(12,4) NULL DEFAULT 0,
 fornecedor_id INT NULL,
 CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX idx_pedido_compra_ordem ON pedido_compra (ordem_compra);

CREATE TABLE entradas_mercadoria (
 data_entrada DATE NULL,
 nro_nfe VARCHAR(255) NOT NULL,
 ordem_compra BIGINT NOT NULL,
 item INT NOT NULL,
 produto_id VARCHAR(25) NOT NULL,
 descricao_produto VARCHAR(255) NULL,
 qtde_recebida DECIMAL(14,4) NULL,
 filial_id INT NULL,
 custo_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
 CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE INDEX idx_entradas_ordem ON entradas_mercadoria (ordem_compra);

-- CHAVES ESTRANGEIRAS: aplicar so DEPOIS da importacao e da validacao dos dados.
-- ALTER TABLE produtos_filial ADD CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor) REFERENCES fornecedor (idfornecedor);
-- ALTER TABLE pedido_compra ADD CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (fornecedor_id) REFERENCES fornecedor (idfornecedor);