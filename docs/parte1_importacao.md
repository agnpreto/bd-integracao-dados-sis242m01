# Parte 1: Documentação do processo de importação

## Ferramenta utilizada
DBeaver, PostgreSql, MySQL, Python.

## Estrutura da planilha

| Aba | Coluna | Tipo | Observação |
| fornecedor | idfornecedor | razão_social | texto |
| produtos_filial | idproduto | descricao | texto |

## Erros encontrados no DDL e como foram corrigidos

| Tabela | Erro | Correção |
| entradas_mercadoria | A chave primária utilizava ordem_compra, mas a coluna não estava declarada. | Inclusão da coluna ordem_compra na estrutura da tabela. |
| produtos_filial | Nome da coluna escrito incorretamente como decricao. | Correção para descricao. |
| produtos_filial | Nome da coluna idfonecedor escrito incorretamente. | Correção para idfornecedor. |
| produtos_filial | Chave primária fazia referência à coluna inexistente idproduto. | Ajuste para utilizar produto_id, juntamente com filial_id. |
| produtos_filial | Ausência de vírgula antes da declaração da restrição. | nclusão da vírgula para corrigir a sintaxe SQL. |
| fornecedor | Nome da coluna escrito como idforncedor. | Padronização para idfornecedor. |
| fornecedor | Chave primária fazia referência a uma coluna inexistente (idproduto). | Correção da chave primária para utilizar idfornecedor. |
| pedido_compra | Necessidade de armazenar o identificador do fornecedor de forma compatível com a tabela de fornecedores. | Padronização do campo fornecedor_id para texto, permitindo relacioná-lo ao código do fornecedor. |

## Erros encontrados no script de importação e como foram corrigidos

| Erro | Efeito | Correção |
| Caminho incorreto do arquivo Excel. | O Python não encontrava a planilha para realizar a importação. | Ajuste do caminho para localizar base_teste.xlsx dentro da pasta dados. |
| Identificadores de fornecedores em formatos diferentes. | Os códigos numéricos da planilha não correspondiam diretamente aos códigos de texto do banco. | Criação de uma normalização para converter, por exemplo, 1 em F1. |
| Colunas completamente vazias na planilha de pedidos. | Poderiam gerar informações desnecessárias durante a leitura dos dados. | Remoção automática das colunas totalmente vazias utilizando dropna(axis=1, how="all"). |
| Diferenças entre os tipos de dados do Excel e do PostgreSQL. | Poderiam ocorrer incompatibilidades durante a inserção dos registros. | Conversão dos valores para os tipos esperados pelo banco antes da inserção. |

## Tratamentos aplicados aos dados

Durante o processo de importação, foram realizados os seguintes tratamentos:
- Conversão de datas: os campos de data foram convertidos para o formato de data aceito pelo PostgreSQL.
- Conversão numérica: quantidades, preços e valores foram convertidos para tipos numéricos.
- Normalização de fornecedores: os identificadores numéricos foram padronizados para o formato de texto, como F1, F2 e assim sucessivamente.
- Tratamento de valores nulos: valores vazios foram identificados e tratados para evitar problemas durante a inserção.
- Padronização textual: espaços desnecessários foram removidos dos valores de texto.
- Remoção de colunas vazias: colunas sem conteúdo foram descartadas durante a leitura da planilha.
- Controle de duplicidade: foram utilizadas operações de inserção com tratamento de conflitos para evitar duplicações de registros.
- Validação da importação: após a execução do script, foram realizadas consultas SQL com COUNT(*) para conferir a quantidade de registros armazenados em cada tabela.

## Conferência final

| Tabela | Linhas na planilha | Linhas no banco |
| --- | --- | --- |
| fornecedor | 20 | 20 |
| produtos_filial | 20 | 20 |
| pedido_compra | 29 | 29 |
| entradas_mercadoria | 20 | 20 |
| venda | 33 | 33 |
| Total: 122|
