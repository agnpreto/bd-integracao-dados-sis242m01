DROP TABLE IF EXISTS public.entradas_mercadoria, public.pedido_compra, public.venda, public.produtos_filial, public.fornecedor;

CREATE TABLE public.fornecedor (
 idfornecedor integer NOT NULL,  -- era idforncedor varchar(25): nome errado e tipo diferente das tabelas que o referenciam
 razao_social varchar(255) NOT NULL,
 CONSTRAINT fornecedor_pkey PRIMARY KEY (idfornecedor));

CREATE TABLE public.produtos_filial (
 filial_id integer NOT NULL,  -- faz parte da PK, nao pode ser NULL; tipo igual ao das outras tabelas
 produto_id varchar(25) NOT NULL,  -- era varchar(255); nas outras tabelas e varchar(25)
 descricao varchar(255) NOT NULL,  -- era decricao
 estoque numeric(14,4) NOT NULL DEFAULT 0,
 preco_unitario numeric(12,4) NOT NULL DEFAULT 0,
 preco_compra numeric(12,4) NOT NULL DEFAULT 0,
 preco_venda numeric(12,4) NOT NULL DEFAULT 0,
 idfornecedor integer NULL,  -- era idfonecedor
 CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, produto_id));

CREATE TABLE public.venda (
 venda_id bigint NOT NULL,
 data_emissao date NOT NULL,
 horariomov varchar(8) NOT NULL DEFAULT '00:00:00',  -- mantido varchar(8) para nao rejeitar horarios ruins na importacao
 produto_id varchar(25) NOT NULL,  -- removido DEFAULT ''
 qtde_vendida numeric(14,4) NULL,
 valor_unitario numeric(12,4) NOT NULL DEFAULT 0,
 filial_id integer NOT NULL,  -- era int8 e DEFAULT 1
 item integer NOT NULL,  -- removido DEFAULT 0
 unidade_medida varchar(3) NULL,
 CONSTRAINT venda_pkey PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov));  -- era pk_consumo

CREATE TABLE public.pedido_compra (
 pedido_id bigint NOT NULL,  -- era float8
 data_pedido date NULL,
 item integer NOT NULL,  -- era float8
 produto_id varchar(25) NOT NULL,  -- removido DEFAULT '0'
 descricao_produto varchar(255) NULL,
 ordem_compra bigint NOT NULL,  -- era float8; liga a entrada ao pedido
 qtde_pedida numeric(14,4) NULL,
 filial_id integer NULL,
 data_entrega date NULL,
 qtde_entregue numeric(14,4) NOT NULL DEFAULT 0,
 qtde_pendente numeric(14,4) NOT NULL DEFAULT 0,  -- derivavel (pedida - entregue): conferir na Parte 4
 preco_compra numeric(12,4) NULL DEFAULT 0,
 fornecedor_id integer NULL,  -- removido DEFAULT 0 (fornecedor 0 nao existe)
 CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id, produto_id, item));
CREATE INDEX idx_pedido_compra_ordem ON public.pedido_compra (ordem_compra);

CREATE TABLE public.entradas_mercadoria (
 data_entrada date NULL,
 nro_nfe varchar(255) NOT NULL,
 ordem_compra bigint NOT NULL,  -- coluna que faltava; mesmo tipo de pedido_compra
 item integer NOT NULL,  -- era float8
 produto_id varchar(25) NOT NULL,  -- removido DEFAULT '0'
 descricao_produto varchar(255) NULL,
 qtde_recebida numeric(14,4) NULL,
 filial_id integer NULL,
 custo_unitario numeric(12,4) NOT NULL DEFAULT 0,
 CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe));
CREATE INDEX idx_entradas_ordem ON public.entradas_mercadoria (ordem_compra);

-- CHAVES ESTRANGEIRAS: aplicar so DEPOIS da importacao e da validacao dos dados.
-- ALTER TABLE public.produtos_filial ADD CONSTRAINT fk_produtos_fornecedor FOREIGN KEY (idfornecedor) REFERENCES public.fornecedor (idfornecedor);
-- ALTER TABLE public.pedido_compra ADD CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (fornecedor_id) REFERENCES public.fornecedor (idfornecedor);