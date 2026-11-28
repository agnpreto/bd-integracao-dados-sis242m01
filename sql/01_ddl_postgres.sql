-- DDL corrigido para PostgreSQL
-- Nome: Mikael Coelho Ramos e Kauã Monteiro Coelho

CREATE TABLE public.fornecedor (
    idfornecedor int4 NOT NULL,
    razao_social varchar(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

CREATE TABLE public.produtos_filial (
    filial_id int4 NOT NULL,
    produto_id varchar(25) NOT NULL,
    descricao varchar(255) NOT NULL,
    estoque float8 DEFAULT 0 NOT NULL,
    preco_unitario numeric(12,4) DEFAULT 0 NOT NULL,
    preco_compra numeric(12,4) DEFAULT 0 NOT NULL,
    preco_venda numeric(12,4) DEFAULT 0 NOT NULL,
    idfornecedor int4 NULL,
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT produtos_filial_fornecedor_fk FOREIGN KEY (idfornecedor) REFERENCES public.fornecedor (idfornecedor)
);

CREATE TABLE public.pedido_compra (
    pedido_id int8 NOT NULL,
    data_pedido date NULL,
    item int4 DEFAULT 0 NOT NULL,
    produto_id varchar(25) DEFAULT '0' NOT NULL,
    descricao_produto varchar(255) NULL,
    ordem_compra int8 DEFAULT 0 NOT NULL,
    qtde_pedida float8 NULL,
    filial_id int4 NULL,
    data_entrega date NULL,
    qtde_entregue float8 DEFAULT 0 NOT NULL,
    qtde_pendente float8 DEFAULT 0 NOT NULL,
    preco_compra numeric(12,4) DEFAULT 0 NULL,
    fornecedor_id int4 NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item),
    CONSTRAINT pedido_compra_fornecedor_fk FOREIGN KEY (fornecedor_id) REFERENCES public.fornecedor (idfornecedor)
);

CREATE TABLE public.entradas_mercadoria (
    data_entrada date NULL,
    nro_nfe varchar(255) NOT NULL,
    item int4 DEFAULT 0 NOT NULL,
    produto_id varchar(25) DEFAULT '0' NOT NULL,
    descricao_produto varchar(255) NULL,
    ordem_compra int8 DEFAULT 0 NOT NULL,  
    qtde_recebida float8 NULL,
    filial_id int4 NULL,
    custo_unitario numeric(12,4) DEFAULT 0 NOT NULL,
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

CREATE TABLE public.venda (
    venda_id int8 NOT NULL,
    data_emissao date NOT NULL,
    horariomov varchar(8) DEFAULT '00:00:00' NOT NULL,
    produto_id varchar(25) DEFAULT '' NOT NULL,
    qtde_vendida float8 NULL,
    valor_unitario numeric(12,4) DEFAULT 0 NOT NULL,
    filial_id int8 DEFAULT 1 NOT NULL,
    item int4 DEFAULT 0 NOT NULL,
    unidade_medida varchar(3) NULL,
    CONSTRAINT pk_venda PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);