
-- DDL corrigido para PostgreSQL
-- Atividade: Integracao de Dados

CREATE TABLE IF NOT EXISTS public.venda (
    venda_id BIGINT NOT NULL,
    data_emissao DATE NOT NULL,
    horariomov VARCHAR(8) DEFAULT '00:00:00' NOT NULL,
    produto_id VARCHAR(25) DEFAULT '' NOT NULL,
    qtde_vendida DOUBLE PRECISION,
    valor_unitario NUMERIC(12,4) DEFAULT 0 NOT NULL,
    filial_id BIGINT DEFAULT 1 NOT NULL,
    item INTEGER DEFAULT 0 NOT NULL,
    unidade_medida VARCHAR(3),
    CONSTRAINT pk_consumo PRIMARY KEY
    (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

CREATE TABLE IF NOT EXISTS public.pedido_compra (
    pedido_id DOUBLE PRECISION DEFAULT 0 NOT NULL,
    data_pedido DATE,
    item DOUBLE PRECISION DEFAULT 0 NOT NULL,
    produto_id VARCHAR(25) DEFAULT '0' NOT NULL,
    descricao_produto VARCHAR(255),
    ordem_compra DOUBLE PRECISION DEFAULT 0 NOT NULL,
    qtde_pedida DOUBLE PRECISION,
    filial_id INTEGER,
    data_entrega DATE,
    qtde_entregue DOUBLE PRECISION DEFAULT 0 NOT NULL,
    qtde_pendente DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_compra DOUBLE PRECISION DEFAULT 0,
    fornecedor_id INTEGER DEFAULT 0,
    CONSTRAINT pedido_compra_pkey
    PRIMARY KEY (pedido_id, produto_id, item)
);

CREATE TABLE IF NOT EXISTS public.entradas_mercadoria (
    ordem_compra DOUBLE PRECISION NOT NULL,
    data_entrada DATE,
    nro_nfe VARCHAR(255) NOT NULL,
    item DOUBLE PRECISION DEFAULT 0 NOT NULL,
    produto_id VARCHAR(25) DEFAULT '0' NOT NULL,
    descricao_produto VARCHAR(255),
    qtde_recebida DOUBLE PRECISION,
    filial_id INTEGER,
    custo_unitario NUMERIC(12,4) DEFAULT 0 NOT NULL,
    CONSTRAINT entradas_mercadoria_pkey
    PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

CREATE TABLE IF NOT EXISTS public.fornecedor (
    idfornecedor VARCHAR(25) NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

CREATE TABLE IF NOT EXISTS public.produtos_filial (
    filial_id INTEGER NOT NULL,
    idproduto VARCHAR(255) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    estoque DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_unitario DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_compra DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_venda DOUBLE PRECISION DEFAULT 0 NOT NULL,
    idfornecedor VARCHAR(25),
    CONSTRAINT produtos_filial_pkey
    PRIMARY KEY (filial_id, idproduto),
    CONSTRAINT fk_produtos_fornecedor
    FOREIGN KEY (idfornecedor)
    REFERENCES public.fornecedor (idfornecedor)
);
