-- DDL corrigido para MySQL
-- Preserva os códigos de fornecedor (F1, F2...) como VARCHAR.

CREATE TABLE IF NOT EXISTS fornecedor (
    idfornecedor VARCHAR(25) NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    PRIMARY KEY (idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS produtos_filial (
    filial_id INT NOT NULL,
    produto_id VARCHAR(255) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    estoque DECIMAL(14,3) NOT NULL DEFAULT 0,
    preco_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
    preco_compra DECIMAL(12,4) NOT NULL DEFAULT 0,
    preco_venda DECIMAL(12,4) NOT NULL DEFAULT 0,
    idfornecedor VARCHAR(25),
    PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_fornecedor
        FOREIGN KEY (idfornecedor) REFERENCES fornecedor(idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pedido_compra (
    pedido_id BIGINT NOT NULL,
    data_pedido DATE,
    item INT NOT NULL DEFAULT 0,
    produto_id VARCHAR(25) NOT NULL,
    descricao_produto VARCHAR(255),
    ordem_compra BIGINT NOT NULL DEFAULT 0,
    qtde_pedida DECIMAL(14,3),
    filial_id INT,
    data_entrega DATE,
    qtde_entregue DECIMAL(14,3) NOT NULL DEFAULT 0,
    qtde_pendente DECIMAL(14,3) NOT NULL DEFAULT 0,
    preco_compra DECIMAL(12,4) DEFAULT 0,
    fornecedor_id VARCHAR(25),
    PRIMARY KEY (pedido_id, produto_id, item),
    CONSTRAINT fk_pedido_fornecedor
        FOREIGN KEY (fornecedor_id) REFERENCES fornecedor(idfornecedor)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS entradas_mercadoria (
    data_entrada DATE,
    nro_nfe VARCHAR(255) NOT NULL,
    item INT NOT NULL DEFAULT 0,
    produto_id VARCHAR(25) NOT NULL,
    descricao_produto VARCHAR(255),
    ordem_compra BIGINT NOT NULL,
    qtde_recebida DECIMAL(14,3),
    filial_id INT,
    custo_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
    PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS venda (
    venda_id BIGINT NOT NULL,
    data_emissao DATE NOT NULL,
    horariomov VARCHAR(8) NOT NULL DEFAULT '00:00:00',
    produto_id VARCHAR(25) NOT NULL DEFAULT '',
    qtde_vendida DECIMAL(14,3),
    valor_unitario DECIMAL(12,4) NOT NULL DEFAULT 0,
    filial_id BIGINT NOT NULL DEFAULT 1,
    item INT NOT NULL DEFAULT 0,
    unidade_medida VARCHAR(3),
    PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
) ENGINE=InnoDB;
