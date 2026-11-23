-- DDL exatamente como veio no enunciado do cliente.
-- Rode, veja os erros e crie as suas versões corrigidas:
--   sql/01_ddl_postgres.sql e sql/01_ddl_mysql.sql

CREATE TABLE public.venda (
 venda_id int8 NOT NULL,
 data_emissao date NOT NULL,
 horariomov varchar(8) DEFAULT '00:00:00'::character varying NOT NULL,
 produto_id varchar(25) DEFAULT ''::character varying NOT NULL,
 qtde_vendida float8 NULL,
 valor_unitario numeric(12, 4) DEFAULT 0 NOT NULL,
 filial_id int8 DEFAULT 1 NOT NULL,
 item int4 DEFAULT 0 NOT NULL,
 unidade_medida varchar(3) NULL,
 CONSTRAINT pk_consumo PRIMARY KEY (filial_id, venda_id, data_emissao, produto_id, item, horariomov));
CREATE TABLE public.pedido_compra (
 pedido_id float8 DEFAULT 0 NOT NULL, data_pedido date NULL, item float8 DEFAULT 0 NOT NULL,
 produto_id varchar(25) DEFAULT '0' NOT NULL, descricao_produto varchar(255) NULL,
 ordem_compra float8 DEFAULT 0 NOT NULL, qtde_pedida float8 NULL, filial_id int4 NULL,
 data_entrega date NULL, qtde_entregue float8 DEFAULT 0 NOT NULL, qtde_pendente float8 DEFAULT 0 NOT NULL,
 preco_compra float8 DEFAULT 0 NULL, fornecedor_id int4 DEFAULT 0 NULL,
 CONSTRAINT pedido_compra_pkey PRIMARY KEY (pedido_id , produto_id, item));
CREATE TABLE public.entradas_mercadoria (
 data_entrada date NULL, nro_nfe varchar(255) NOT NULL, item float8 DEFAULT 0 NOT NULL,
 produto_id varchar(25) DEFAULT '0' NOT NULL, descricao_produto varchar(255) NULL,
 qtde_recebida float8 NULL, filial_id int4 NULL, custo_unitario numeric(12, 4) DEFAULT 0 NOT NULL,
 CONSTRAINT entradas_mercadoria_pkey PRIMARY KEY (ordem_compra, item, produto_id, nro_nfe));
CREATE TABLE public.produtos_filial (
 filial_id int4 NULL, produto_id varchar(255) NOT NULL, decricao varchar(255) NOT NULL,
 estoque float8 DEFAULT 0 NOT NULL, preco_unitario float8 DEFAULT '0' NOT NULL,
 preco_compra float8 DEFAULT '0' NOT NULL, preco_venda float8 DEFAULT '0' NOT NULL,
 idfonecedor int4 NULL
 CONSTRAINT produtos_filial_pkey PRIMARY KEY (filial_id, idproduto));
CREATE TABLE public.fornecedor (
 idforncedor varchar(25) NOT NULL, razao_social varchar(255) NOT NULL,
 CONSTRAINT fornecedor_pkey PRIMARY KEY (idforncedor, idproduto));

Erros identificados no DDL
Erro 01 – Tabela entradas_mercadoria

A coluna ordem_compra está sendo utilizada na definição da chave primária, porém não foi declarada entre as colunas da tabela. Isso provoca um erro porque o PostgreSQL não consegue identificar a coluna informada. Para corrigir, é necessário declarar ordem_compra na estrutura da tabela ou removê-la da chave primária, conforme a planilha de origem.

Erro 02 – Tabela produtos_filial

Foi identificada a ausência de uma vírgula após a declaração da coluna idfonecedor int4 NULL, antes da definição da chave primária. Essa falha provoca um erro de sintaxe durante a execução do comando CREATE TABLE. A correção consiste em adicionar a vírgula antes da CONSTRAINT.

Erro 03 – Tabela produtos_filial

A chave primária utiliza a coluna idproduto, mas essa coluna não foi declarada na tabela. O nome utilizado na estrutura é produto_id. Essa divergência provoca um erro de referência a uma coluna inexistente. É necessário padronizar o nome utilizado na declaração da coluna e na chave primária.

Erro 04 – Tabela fornecedor

A chave primária foi definida utilizando as colunas idforncedor e idproduto, porém idproduto não existe nessa tabela. Como a tabela representa o cadastro de fornecedores, a chave primária deve utilizar o identificador do fornecedor, corrigindo também sua nomenclatura.

Erro 05 – Tabela fornecedor

Foi identificada uma inconsistência na escrita do nome da coluna idforncedor. O nome correto é idfornecedor. Embora essa divergência não provoque um erro de sintaxe, pode gerar dificuldades na utilização e no relacionamento dos dados entre as tabelas.

Erro 06 – Tabela produtos_filial

A coluna responsável pela descrição do produto foi declarada como decricao, apresentando um erro de escrita. O nome correto é descricao. Essa correção é necessária para manter a padronização dos campos e facilitar a utilização da coluna nas consultas SQL.

Erro 07 – Tabela produtos_filial

A coluna idfonecedor apresenta um erro de escrita em seu nome. O correto é idfornecedor. Essa inconsistência pode dificultar a identificação do fornecedor relacionado a cada produto e comprometer a padronização dos relacionamentos.

Erro 08 – Relacionamento entre as tabelas

Foi identificada uma divergência nos tipos de dados utilizados para identificar os fornecedores. Na tabela fornecedor, o identificador está definido como varchar(25), enquanto nas tabelas pedido_compra e produtos_filial os campos correspondentes utilizam int4. Entretanto, a planilha de origem apresenta códigos textuais, como F1, F2 e F20. Para preservar esses identificadores durante a importação e permitir os relacionamentos, é necessário padronizar os tipos de dados, utilizando varchar(25) nos campos correspondentes.
