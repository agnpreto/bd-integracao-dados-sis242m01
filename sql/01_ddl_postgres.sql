-- DDL corrigido para PostgreSQL
-- Preserva os códigos de fornecedor (F1, F2...) como VARCHAR.
-- A coluna qtde_pendente é calculada na importação, pois não existe na planilha.

CREATE TABLE IF NOT EXISTS public.fornecedor (
    idfornecedor VARCHAR(25) PRIMARY KEY,
    razao_social VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.produtos_filial (
    filial_id INTEGER NOT NULL,
    produto_id VARCHAR(255) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    estoque NUMERIC(14,3) NOT NULL DEFAULT 0,
    preco_unitario NUMERIC(12,4) NOT NULL DEFAULT 0,
    preco_compra NUMERIC(12,4) NOT NULL DEFAULT 0,
    preco_venda NUMERIC(12,4) NOT NULL DEFAULT 0,
    idfornecedor VARCHAR(25),
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_fornecedor
        FOREIGN KEY (idfornecedor) REFERENCES public.fornecedor(idfornecedor)
);

CREATE TABLE IF NOT EXISTS public.pedido_compra (
    pedido_id BIGINT NOT NULL,
    data_pedido DATE,
    item INTEGER NOT NULL DEFAULT 0,
    produto_id VARCHAR(25) NOT NULL,
    descricao_produto VARCHAR(255),
    ordem_compra BIGINT NOT NULL DEFAULT 0,
    qtde_pedida NUMERIC(14,3),
    filial_id INTEGER,
    data_entrega DATE,
    qtde_entregue NUMERIC(14,3) NOT NULL DEFAULT 0,
    qtde_pendente NUMERIC(14,3) NOT NULL DEFAULT 0,
    preco_compra NUMERIC(12,4) DEFAULT 0,
    fornecedor_id VARCHAR(25),
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item),
    CONSTRAINT fk_pedido_fornecedor
        FOREIGN KEY (fornecedor_id) REFERENCES public.fornecedor(idfornecedor)
);

CREATE TABLE IF NOT EXISTS public.entradas_mercadoria (
    data_entrada DATE,
    nro_nfe VARCHAR(255) NOT NULL,
    item INTEGER NOT NULL DEFAULT 0,
    produto_id VARCHAR(25) NOT NULL,
    descricao_produto VARCHAR(255),
    ordem_compra BIGINT NOT NULL,
    qtde_recebida NUMERIC(14,3),
    filial_id INTEGER,
    custo_unitario NUMERIC(12,4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey
        PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

CREATE TABLE IF NOT EXISTS public.venda (
    venda_id BIGINT NOT NULL,
    data_emissao DATE NOT NULL,
    horariomov VARCHAR(8) NOT NULL DEFAULT '00:00:00',
    produto_id VARCHAR(25) NOT NULL DEFAULT '',
    qtde_vendida NUMERIC(14,3),
    valor_unitario NUMERIC(12,4) NOT NULL DEFAULT 0,
    filial_id BIGINT NOT NULL DEFAULT 1,
    item INTEGER NOT NULL DEFAULT 0,
    unidade_medida VARCHAR(3),
    CONSTRAINT pk_consumo
        PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

SELECT 'fornecedor' AS tabela, COUNT(*) AS total
FROM fornecedor
UNION ALL
SELECT 'produtos_filial', COUNT(*)
FROM produtos_filial
UNION ALL
SELECT 'pedido_compra', COUNT(*)
FROM pedido_compra
UNION ALL
SELECT 'entradas_mercadoria', COUNT(*)
FROM entradas_mercadoria
UNION ALL
SELECT 'venda', COUNT(*)
FROM venda;
