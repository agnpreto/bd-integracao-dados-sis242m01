-- =====================================================================
-- DDL corrigido (PostgreSQL). Original: sql/01_ddl_enunciado.sql
-- Todas as correções estão explicadas em docs/parte1_importacao.md
-- =====================================================================
DROP TABLE IF EXISTS public.entradas_mercadoria, public.pedido_compra,
                     public.venda, public.produtos_filial, public.fornecedor CASCADE;

-- fornecedor: PK somente em idfornecedor (o original citava "idproduto", que
-- não existe) e id numérico (o original era varchar e quebrava o vínculo com
-- pedido_compra.fornecedor_id, que é inteiro). Typo "idforncedor" corrigido.
CREATE TABLE public.fornecedor (
    idfornecedor INTEGER      NOT NULL,
    razao_social VARCHAR(255) NOT NULL,
    CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor)
);

-- produtos_filial: typos "decricao"/"idfonecedor" corrigidos, vírgula que
-- faltava antes do CONSTRAINT, PK sobre produto_id (o original usava
-- "idproduto"), filial_id NOT NULL (coluna de PK não pode ser nula).
CREATE TABLE public.produtos_filial (
    filial_id      INTEGER          NOT NULL,
    produto_id     VARCHAR(25)      NOT NULL,
    descricao      VARCHAR(255)     NOT NULL,
    estoque        DOUBLE PRECISION NOT NULL DEFAULT 0,
    preco_unitario NUMERIC(12,4)    NOT NULL DEFAULT 0,
    preco_compra   NUMERIC(12,4)    NOT NULL DEFAULT 0,
    preco_venda    NUMERIC(12,4)    NOT NULL DEFAULT 0,
    idfornecedor   INTEGER          NULL,
    CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id),
    CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor)
        REFERENCES public.fornecedor (idfornecedor)
);

-- venda: sem FK para produtos_filial DE PROPÓSITO: a planilha tem vendas de
-- produtos/filiais inexistentes (P21..P28, filiais 2 e 3). Em vez de perder
-- linhas na carga, elas entram e são apontadas em sql/04_validacao.sql.
-- Nome da PK "pk_consumo" (copiado de outro sistema) trocado por pk_venda.
CREATE TABLE public.venda (
    venda_id       BIGINT           NOT NULL,
    data_emissao   DATE             NOT NULL,
    horariomov     VARCHAR(8)       NOT NULL DEFAULT '00:00:00',
    produto_id     VARCHAR(25)      NOT NULL,
    qtde_vendida   NUMERIC(14,3)    NULL,
    valor_unitario NUMERIC(12,4)    NOT NULL DEFAULT 0,
    filial_id      INTEGER          NOT NULL DEFAULT 1,
    item           INTEGER          NOT NULL DEFAULT 0,
    unidade_medida VARCHAR(3)       NULL,
    CONSTRAINT pk_venda PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
);

-- pedido_compra: ids/itens float8 -> inteiros; quantidades float8 -> NUMERIC
-- (há quantidades fracionadas); qtde_pendente vira coluna GERADA (pedida -
-- entregue), eliminando o risco de ficar inconsistente; fornecedor_id passa a
-- ter FK. Datas de entrega anteriores ao pedido NÃO são barradas aqui (a
-- planilha as contém) e sim listadas na validação.
CREATE TABLE public.pedido_compra (
    pedido_id         INTEGER       NOT NULL,
    data_pedido       DATE          NULL,
    item              INTEGER       NOT NULL DEFAULT 0,
    produto_id        VARCHAR(25)   NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255)  NULL,
    ordem_compra      INTEGER       NOT NULL DEFAULT 0,
    qtde_pedida       NUMERIC(14,3) NULL,
    filial_id         INTEGER       NOT NULL,
    data_entrega      DATE          NULL,
    qtde_entregue     NUMERIC(14,3) NOT NULL DEFAULT 0,
    qtde_pendente     NUMERIC(14,3) GENERATED ALWAYS AS (qtde_pedida - qtde_entregue) STORED,
    preco_compra      NUMERIC(12,4) NULL DEFAULT 0,
    fornecedor_id     INTEGER       NULL,
    CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item),
    CONSTRAINT fk_pedido_produto    FOREIGN KEY (filial_id, produto_id)
        REFERENCES public.produtos_filial (filial_id, produto_id),
    CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (fornecedor_id)
        REFERENCES public.fornecedor (idfornecedor)
);

-- entradas_mercadoria: FALTAVA a coluna ordem_compra, citada na PK e que é o
-- elo com pedido_compra (observação do enunciado).
CREATE TABLE public.entradas_mercadoria (
    data_entrada      DATE          NULL,
    nro_nfe           VARCHAR(255)  NOT NULL,
    item              INTEGER       NOT NULL DEFAULT 0,
    produto_id        VARCHAR(25)   NOT NULL DEFAULT '0',
    descricao_produto VARCHAR(255)  NULL,
    ordem_compra      INTEGER       NOT NULL DEFAULT 0,
    qtde_recebida     NUMERIC(14,3) NULL,
    filial_id         INTEGER       NOT NULL,
    custo_unitario    NUMERIC(12,4) NOT NULL DEFAULT 0,
    CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe),
    CONSTRAINT fk_entrada_produto FOREIGN KEY (filial_id, produto_id)
        REFERENCES public.produtos_filial (filial_id, produto_id)
);

CREATE INDEX idx_venda_data     ON public.venda (data_emissao);
CREATE INDEX idx_pedido_ordem   ON public.pedido_compra (ordem_compra, produto_id);
CREATE INDEX idx_entrada_ordem  ON public.entradas_mercadoria (ordem_compra, produto_id);
