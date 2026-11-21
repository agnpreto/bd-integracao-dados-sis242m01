# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

## Estrutura da planilha

|Aba|Coluna|Tipo|Observação|
|-|-|-|-|
|||||

## Erros encontrados no DDL e como foram corrigidos

|Tabela|Erro|Correção|
|-|-|-|
|entradas\_mercadoria|coluna "ordem\_compra" indicada na chave não existe. A PK usa ordem\_compra, mas essa coluna não foi declarada na tabela.|Adicionei a coluna ordem\_compra float8 DEFAULT 0 NOT NULL na lista de colunas (mesmo tipo de pedido\_compra), para a PK passar a funcionar.|
|fornecedor|coluna "idproduto" indicada na chave não existe. A PK cita idproduto, mas essa coluna não existe em fornecedor (as colunas dessa tabela são idforncedor e razao\_social).|Troquei a PK para PRIMARY KEY (idforncedor), removendo idproduto, que não existe nessa tabela.|
|produtos\_filial|erro de sintaxe em ou próximo a "(". Falta uma vírgula no fim da linha do idfonecedor; sem ela o PostgreSQL leu o CONSTRAINT como parte da própria coluna e estranhou o "(".|Adicionei a vírgula no fim da linha idfonecedor int4 NULL,|
|produtos\_filial|coluna "idproduto" indicada na chave não existe. A PK cita idproduto, mas a coluna se chama produto\_id.|Troquei idproduto por produto\_id na PK: PRIMARY KEY (filial\_id, produto\_id).|

## Erros encontrados no script de importação e como foram corrigidos

|Erro|Efeito|Correção|
|-|-|-|
||||

## Tratamentos aplicados aos dados

(conversão de tipos, validações, normalizações)

## Conferência final

|Tabela|Linhas na planilha|Linhas no banco|
|-|-|-|
|fornecedor|||
|produtos\_filial|||
|pedido\_compra|||
|entradas\_mercadoria|||
|venda|||



