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
|fornecedor, produtos\_filial, pedido\_compra|Id do fornecedor com tipos incompatíveis: varchar(25) em fornecedor e int4 nas tabelas que o referenciam.|integer nas três tabelas (a trigger da Parte 3 exige id numérico).|
|fornecedor, produtos\_filial|Nomes com erro de digitação: idforncedor, idfonecedor e decricao.|idfornecedor nas duas tabelas e descricao em produtos\_filial.|
|pedido\_compra, entradas\_mercadoria|pedido\_id, ordem\_compra e item declarados como float8, tipo impreciso para chaves.|bigint para pedido\_id e ordem\_compra; integer para item.|
|produtos\_filial, pedido\_compra, entradas\_mercadoria, venda|Quantidades e preços em float8, enquanto valor\_unitario e custo\_unitario já eram numeric.|numeric(14,4) para quantidades e estoque; numeric(12,4) para preços.|
|venda, pedido\_compra, entradas\_mercadoria, produtos\_filial|filial\_id com tipos diferentes (int8 em venda, int4 nas outras) e NULL em coluna da PK de produtos\_filial.|integer em todas; NOT NULL em produtos\_filial.|
|produtos\_filial|produto\_id com varchar(255), enquanto nas outras tabelas é varchar(25).|varchar(25).|
|venda, pedido\_compra, entradas\_mercadoria|DEFAULTs sem sentido em colunas de chave (produto\_id vazio ou 0, ids 0, filial\_id 1): dado faltando entra sem dar erro.|DEFAULTs removidos; dado faltando passa a gerar erro.|
|produtos\_filial|DEFAULT '0' (texto) em colunas numéricas.|DEFAULT 0.|
|pedido\_compra|fornecedor\_id com DEFAULT 0, valor que não existe em fornecedor.|DEFAULT removido.|
|venda|Constraint da PK chamada pk\_consumo, nome que não tem relação com a tabela.|Renomeada para venda\_pkey.|
|pedido\_compra, entradas\_mercadoria|Sem índice em ordem\_compra, o campo que liga a entrada ao pedido.|Criados idx\_pedido\_compra\_ordem e idx\_entradas\_ordem.|
|pedido\_compra, produtos\_filial|Sem chave estrangeira para fornecedor.|FKs escritas no arquivo, comentadas: serão aplicadas depois da importação e da validação.|
|pedido\_compra|qtde\_pendente é derivável (qtde\_pedida menos qtde\_entregue) e pode ficar inconsistente.|Mantida; a conferência entra na Parte 4.|
|venda|horariomov é varchar(8) em vez de TIME.|Mantido para não rejeitar horários inválidos na importação; validação na Parte 4.|

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



