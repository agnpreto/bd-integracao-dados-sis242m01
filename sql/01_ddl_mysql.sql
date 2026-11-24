-- DDL corrigido para MySQL
-- Atividade: Integracao de Dados

CREATE TABLE IF NOT EXISTS venda (
    venda_id BIGINT NOT NULL,
    data_emissao DATE NOT NULL,
    horariomov VARCHAR(8) NOT NULL DEFAULT '00:00:00',
    produto_id VARCHAR(25) NOT NULL DEFAULT '',
    qtde_vendida DOUBLE NULL,
    valor_unitario DECIMAL(12, 4) NOT NULL DEFAULT 0,
    filial_id BIGINT NOT NULL DEFAULT 1,
    item INT NOT NULL DEFAULT 0,
    unidade_medida VARCHAR(3) NULL,
    CONSTRAINT pk_consumo PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

CREATE TABLE IF NOT EXISTS pedido_compra (
    pedido_id DOUBLE NOT NULL DEFAULT 0,
    data_pedido DATE NULL,
    item DOUBLE NOT NULL DEFAULT 0,
    produto_id VARCHAR(25) NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255) NULL,
    ordem_compra DOUBLE NOT NULL DEFAULT 0,
    qtde_pedida DOUBLE NULL,
    filial_id INT NULL,
    data_entrega DATE NULL,
    qtde_entregue DOUBLE NOT NULL DEFAULT 0,
    qtde_pendente DOUBLE NOT NULL DEFAULT 0,
    preco_compra DOUBLE NOT NULL DEFAULT 0,
    fornecedor_id VARCHAR(25) NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item)
);

CREATE TABLE IF NOT EXISTS entradas_mercadoria (
    ordem_compra DOUBLE NOT NULL,
    data_entrada DATE NULL,
    nro_nfe VARCHAR(255) NOT NULL,
    item DOUBLE NOT NULL DEFAULT 0,
    produto_id VARCHAR(25) NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255) NULL,
    qtde_recebida DOUBLE NULL,
    filial_id INT NULL,
    custo_unitario DECIMAL(12, 4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

CREATE TABLE IF NOT EXISTS fornecedor (
    idfornecedor VARCHAR(25) NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

CREATE TABLE IF NOT EXISTS produtos_filial (
    filial_id INT NOT NULL,
    idproduto VARCHAR(255) NOT NULL,
    decricao VARCHAR(255) NOT NULL,
    estoque DOUBLE NOT NULL DEFAULT 0,
    preco_unitario DOUBLE NOT NULL DEFAULT 0,
    preco_compra DOUBLE NOT NULL DEFAULT 0,
    preco_venda DOUBLE NOT NULL DEFAULT 0,
    idfornecedor VARCHAR(25) NULL,
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, idproduto),
    CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor)
        REFERENCES fornecedor (idfornecedor)
);
