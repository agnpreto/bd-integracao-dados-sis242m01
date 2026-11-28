-- =====================================================================
-- 01_ddl_postgres.sql  |  DDL corrigido para PostgreSQL
-- Disciplina: Banco de Dados (SIS242M01)
-- Autor: Franklin Mendonça
--
-- Correções em relação a sql/01_ddl_enunciado.sql (detalhes em
-- docs/parte1_importacao.md):
--   01 entradas_mercadoria: coluna ordem_compra declarada (estava só na PK)
--   02 produtos_filial: vírgula faltando antes da CONSTRAINT
--   03 produtos_filial: PK usava "idproduto"; a coluna é produto_id
--   04 fornecedor: PK usava coluna inexistente "idproduto"
--   05 fornecedor: idforncedor -> idfornecedor
--   06 produtos_filial: decricao -> descricao
--   07 produtos_filial: idfonecedor -> idfornecedor
--   08 fornecedor_id / idfornecedor padronizados como varchar(25)
--      (a planilha usa códigos textuais: F1, F2, ... F20)
--   09 (melhoria) chaves que eram float8 (pedido_id, item, ordem_compra)
--      viraram inteiros: float não deve ser chave nem ser comparado por
--      igualdade (a junção por ordem_compra depende disso)
--   10 (melhoria) chaves estrangeiras para fornecedor
-- A ordem de criação respeita as dependências (fornecedor primeiro).
-- =====================================================================

DROP TABLE IF EXISTS public.venda CASCADE;
DROP TABLE IF EXISTS public.entradas_mercadoria CASCADE;
DROP TABLE IF EXISTS public.pedido_compra CASCADE;
DROP TABLE IF EXISTS public.produtos_filial CASCADE;
DROP TABLE IF EXISTS public.fornecedor CASCADE;

CREATE TABLE public.fornecedor (
    idfornecedor VARCHAR(25)  NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

CREATE TABLE public.produtos_filial (
    filial_id      INTEGER          NOT NULL,
    produto_id     VARCHAR(255)     NOT NULL,
    descricao      VARCHAR(255)     NOT NULL,
    estoque        DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_unitario DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_compra   DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_venda    DOUBLE PRECISION DEFAULT 0 NOT NULL,
    idfornecedor   VARCHAR(25)      NULL,
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_filial_fornecedor
        FOREIGN KEY (idfornecedor) REFERENCES public.fornecedor (idfornecedor)
);

CREATE TABLE public.pedido_compra (
    pedido_id         BIGINT           DEFAULT 0 NOT NULL,
    data_pedido       DATE             NULL,
    item              INTEGER          DEFAULT 0 NOT NULL,
    produto_id        VARCHAR(25)      DEFAULT '0' NOT NULL,
    descricao_produto VARCHAR(255)     NULL,
    ordem_compra      BIGINT           DEFAULT 0 NOT NULL,
    qtde_pedida       DOUBLE PRECISION NULL,
    filial_id         INTEGER          NULL,
    data_entrega      DATE             NULL,
    qtde_entregue     DOUBLE PRECISION DEFAULT 0 NOT NULL,
    qtde_pendente     DOUBLE PRECISION DEFAULT 0 NOT NULL,
    preco_compra      DOUBLE PRECISION DEFAULT 0 NULL,
    fornecedor_id     VARCHAR(25)      NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item),
    CONSTRAINT fk_pedido_compra_fornecedor
        FOREIGN KEY (fornecedor_id) REFERENCES public.fornecedor (idfornecedor)
);

CREATE TABLE public.entradas_mercadoria (
    data_entrada      DATE             NULL,
    nro_nfe           VARCHAR(255)     NOT NULL,
    item              INTEGER          DEFAULT 0 NOT NULL,
    produto_id        VARCHAR(25)      DEFAULT '0' NOT NULL,
    descricao_produto VARCHAR(255)     NULL,
    ordem_compra      BIGINT           DEFAULT 0 NOT NULL,
    qtde_recebida     DOUBLE PRECISION NULL,
    filial_id         INTEGER          NULL,
    custo_unitario    NUMERIC(12, 4)   DEFAULT 0 NOT NULL,
    CONSTRAINT entradas_mercadoria_pkey
        PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe)
);

CREATE TABLE public.venda (
    venda_id       BIGINT         NOT NULL,
    data_emissao   DATE           NOT NULL,
    horariomov     VARCHAR(8)     DEFAULT '00:00:00' NOT NULL,
    produto_id     VARCHAR(25)    DEFAULT '' NOT NULL,
    qtde_vendida   DOUBLE PRECISION NULL,
    valor_unitario NUMERIC(12, 4) DEFAULT 0 NOT NULL,
    filial_id      BIGINT         DEFAULT 1 NOT NULL,
    item           INTEGER        DEFAULT 0 NOT NULL,
    unidade_medida VARCHAR(3)     NULL,
    CONSTRAINT pk_consumo
        PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

-- Sem FK de venda -> produtos_filial de propósito: a planilha tem vendas de
-- produtos/filiais não cadastrados (ver sql/04_validacao.sql). Com a FK a
-- importação rejeitaria essas linhas e esconderia o problema do cliente.
