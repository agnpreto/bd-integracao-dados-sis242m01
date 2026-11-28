# Parte 1: Documentação do processo de importação

## Ferramentas utilizadas

DBeaver
PostgreSQL
MySQL
Python

## Estrutura da planilha

A planilha `base_teste.xlsx` contém cinco abas correspondentes nas tabelas do banco de dados.

| Aba | Coluna | Tipo | Observação |
|---|---|---|---|
| venda | A preencher | A verificar | Dados de vendas |
| pedido_compra | A preencher | A verificar | Dados dos pedidos de compra |
| entradas_mercadoria | A preencher | A verificar | Dados das entradas de mercadorias |
| produtos_filial | A preencher | A verificar | Dados dos produtos por filial |
| fornecedor | A preencher | A verificar | Dados dos fornecedores |

## Erros encontrados no DDL e como foram corrigidos

| Tabela | Erro | Correção |
|---|---|---|
| entradas_mercadoria | Coluna `ordem_compra` utilizada na chave primária sem declaração na tabela. | Inclusão da coluna `ordem_compra`. |
| produtos_filial | Nome incorreto da coluna `decricao`. | Correção para `descricao`. |
| produtos_filial | Nome incorreto da coluna `idfonecedor`. | Correção para `idfornecedor`. |
| produtos_filial | Ausência de vírgula antes da declaração da chave primária. | Inclusão da vírgula. |
| produtos_filial | Chave primária utiliza `idproduto`, coluna não declarada. | Padronização para `produto_id`. |
| fornecedor | Nome incorreto da coluna `idforncedor`. | Correção para `idfornecedor`. |
| fornecedor | Chave primária utiliza `idproduto`, coluna inexistente. | Correção para utilizar `idfornecedor`. |

Também foi identificado o erro SQL 42P07, referente à existência prévia da tabela `venda`. Esse problema ocorreu porque a tabela já havia sido criada em uma execução anterior.

## Erros encontrados no script de importação e como foram corrigidos

| Erro | Efeito | Correção |
|---|---|---|
| A verificar após análise do arquivo `scripts/importar.py`. | A preencher. | A preencher. |

## Tratamentos aplicados aos dados

Durante o processo de importação, serão verificadas as conversões dos tipos de dados, incluindo datas, números inteiros, valores decimais e campos de texto.

Também serão verificadas a presença de valores nulos, a compatibilidade entre as colunas da planilha e as tabelas do banco de dados e a padronização dos nomes dos campos.

Os tratamentos efetivamente realizados serão registrados após a execução e validação do script de importação.

## Conferência final

A conferência será realizada comparando a quantidade de linhas de cada aba da planilha com a quantidade de registros inseridos nas respectivas tabelas do PostgreSQL e do MySQL.

| Tabela | Linhas na planilha | Linhas no banco |
|---|---:|---:|
| fornecedor | A verificar | A verificar |
| produtos_filial | A verificar | A verificar |
| pedido_compra | A verificar | A verificar |
| entradas_mercadoria | A verificar | A verificar |
| venda | A verificar | A verificar |
