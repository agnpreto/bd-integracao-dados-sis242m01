
# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

O desenvolvimento foi realizado no GitHub Codespaces, utilizando Ubuntu 24.04.5 LTS.

Ferramentas utilizadas:

- PostgreSQL 16: criação das tabelas, importação e consultas de conferência.
- MySQL 8.4: teste do DDL corrigido utilizando Docker.
- Python 3.14.2: execução do script de importação.
- Pandas 3.1.1: leitura e tratamento dos dados do Excel.
- Openpyxl 3.1.5: leitura do arquivo XLSX.
- Psycopg2-binary 2.9.13: conexão entre Python e PostgreSQL.

O banco utilizado na importação foi `integracao_teste`, criado no PostgreSQL.

A planilha original `dados/base_teste.xlsx` foi mantida sem alterações.

## Estrutura da planilha

A planilha possui cinco abas, totalizando 122 linhas de dados.

Os tipos apresentados abaixo foram identificados pelo Pandas durante a leitura do Excel.

| Aba | Coluna | Tipo | Observação |
| --- | --- | --- | --- |
| fornecedor | idfornecedor | str | Identificador do fornecedor |
| fornecedor | razao_social | str | Nome do fornecedor |
| produtos_filial | filial_id | int64 | Identificador da filial |
| produtos_filial | idproduto | str | Identificador do produto |
| produtos_filial | descricao | str | Descrição do produto |
| produtos_filial | estoque | int64 | Quantidade em estoque |
| produtos_filial | preco_unitario | float64 | Preço unitário |
| produtos_filial | preco_compra | float64 | Preço de compra |
| produtos_filial | preco_venda | float64 | Preço de venda |
| produtos_filial | idfornecedor | str | Identificador do fornecedor |
| pedido_compra | pedido_id | int64 | Identificador do pedido |
| pedido_compra | data_pedido | datetime64[us] | Data do pedido |
| pedido_compra | item | int64 | Número do item |
| pedido_compra | produto_id | str | Identificador do produto |
| pedido_compra | descricao_produto | str | Descrição do produto |
| pedido_compra | ordem_compra | int64 | Número da ordem de compra |
| pedido_compra | qtde_pedida | int64 | Quantidade solicitada |
| pedido_compra | filial_id | int64 | Identificador da filial |
| pedido_compra | data_entrega | datetime64[us] | Data informada de entrega |
| pedido_compra | qtde_entregue | int64 | Quantidade entregue |
| pedido_compra | preco_compra | float64 | Preço de compra |
| pedido_compra | fornecedor_id | int64 | Identificador do fornecedor |
| entradas_mercadoria | data_entrada | datetime64[us] | Data da entrada |
| entradas_mercadoria | nro_nfe | str | Número da nota fiscal |
| entradas_mercadoria | item | int64 | Número do item |
| entradas_mercadoria | produto_id | str | Identificador do produto |
| entradas_mercadoria | descricao_produto | str | Descrição do produto |
| entradas_mercadoria | ordem_compra | int64 | Referência ao pedido de compra |
| entradas_mercadoria | qtde_recebida | int64 | Quantidade recebida |
| entradas_mercadoria | filial_id | int64 | Identificador da filial |
| entradas_mercadoria | custo_unitario | float64 | Custo unitário |
| venda | venda_id | int64 | Identificador da venda |
| venda | data_emissao | datetime64[us] | Data da venda |
| venda | horariomov | str | Horário da movimentação |
| venda | produto_id | str | Identificador do produto |
| venda | qtde_vendida | float64 | Quantidade vendida |
| venda | valor_unitario | float64 | Valor unitário |
| venda | filial_id | int64 | Identificador da filial |
| venda | item | int64 | Número do item |
| venda | unidade_medida | str | Unidade de medida |

### Colunas adicionais identificadas

A aba `pedido_compra` contém 11 colunas adicionais, identificadas pelo Pandas como `Unnamed: 12` até `Unnamed: 22`.

Essas colunas possuem valores preenchidos em nove linhas, correspondentes às linhas 22 a 30 da planilha.

Os valores incluem datas, identificadores, produtos, quantidades e preços.

Durante a importação inicial, foram utilizadas as 12 colunas principais da aba. As colunas adicionais permaneceram preservadas na planilha original.

Essas informações precisam de validação antes de serem incorporadas ou utilizadas para substituir os dados principais.

## Erros encontrados no DDL e como foram corrigidos

O arquivo `sql/01_ddl_enunciado.sql` foi executado no PostgreSQL.

Na primeira execução, duas tabelas foram criadas e três comandos apresentaram erros.

| Tabela | Erro | Correção |
| --- | --- | --- |
| entradas_mercadoria | A chave primária utilizava `ordem_compra`, mas a coluna não existia. | Adicionada a coluna `ordem_compra`, utilizando tipo compatível com `pedido_compra`. |
| produtos_filial | Faltava uma vírgula antes da declaração da chave primária. | Adicionada a vírgula necessária. |
| produtos_filial | A coluna `decricao` estava escrita incorretamente. | Corrigida para `descricao`. |
| produtos_filial | A coluna `idfonecedor` estava escrita incorretamente. | Corrigida para `idfornecedor`, com tipo VARCHAR. |
| produtos_filial | A chave primária utilizava `idproduto`, que não existia no DDL. | Corrigida para utilizar `produto_id`. |
| produtos_filial | A coluna `filial_id` estava declarada como NULL, apesar de fazer parte da chave primária. | Definida como NOT NULL. |
| fornecedor | O identificador estava escrito como `idforncedor`. | Corrigido para `idfornecedor`. |
| fornecedor | A chave primária utilizava `idproduto`, coluna inexistente nessa tabela. | Definida a chave primária apenas com `idfornecedor`. |

As versões corrigidas foram desenvolvidas nos arquivos:

- `sql/01_ddl_postgres.sql`
- `sql/01_ddl_mysql.sql`

Após as correções, os dois arquivos foram executados em seus respectivos SGBDs.

Os testes confirmaram a criação das cinco tabelas no PostgreSQL 16 e no MySQL 8.4.

## Erros encontrados no script de importação e como foram corrigidos

O arquivo `scripts/importar.py` foi analisado e ajustado para permitir a importação dos dados da planilha.

| Erro ou problema | Efeito | Correção |
| --- | --- | --- |
| Configuração original utilizava o banco `postgres` e a senha fixa `1234`. | A conexão não correspondia ao ambiente de testes. | Configuração adaptada para `integracao_teste`, com variáveis de ambiente e autenticação local. |
| Conversão de datas tratava os valores principalmente como números seriais do Excel. | Datas já interpretadas pelo Pandas poderiam gerar erros ou valores incorretos. | Função atualizada para tratar datas, timestamps e números seriais. |
| Uso de `conn.rollback()` em cada erro. | Poderia desfazer outras inserções ainda não confirmadas na mesma transação. | Utilizados SAVEPOINTs para recuperar apenas a inserção com erro. |
| Mensagens utilizavam o tamanho da planilha para informar registros inseridos. | A quantidade informada poderia não corresponder aos registros gravados. | Adicionados contadores de inserções, conflitos e erros, além de consultas COUNT(*). |
| Colunas adicionais sem cabeçalho em `pedido_compra`. | Informações extras não eram consideradas na importação principal. | Adicionado aviso sobre as colunas extras, mantendo sua análise pendente. |
| Durante os ajustes, a inserção em `entradas_mercadoria` ficou com dez parâmetros para nove colunas. | Ocorreram 20 erros `tuple index out of range`. | Corrigida a instrução INSERT para utilizar nove parâmetros. |

Após a última correção, o script executou sem erros de inserção.

## Tratamentos aplicados aos dados

Os seguintes tratamentos foram implementados no Python:

1. Remoção de espaços extras nos nomes das colunas e nos campos de texto.
2. Conversão de valores numéricos para os tipos necessários.
3. Conversão de datas do Excel para o formato aceito pelo PostgreSQL.
4. Tratamento de valores vazios, utilizando NULL ou valores padrão quando apropriado.
5. Cálculo de `qtde_pendente` pela diferença entre quantidade pedida e quantidade entregue.
6. Tratamento individual dos erros utilizando SAVEPOINT.
7. Uso de `ON CONFLICT DO NOTHING` para evitar inserções repetidas com a mesma chave primária.
8. Conferência das quantidades importadas por meio de consultas SQL.

A planilha original não foi modificada durante esses tratamentos.

## Conferência final

Após a execução do script corrigido, foi realizada uma consulta COUNT(*) diretamente no PostgreSQL para conferir a quantidade de registros.

| Tabela | Linhas na planilha | Linhas no banco |
| --- | ---: | ---: |
| fornecedor | 20 | 20 |
| produtos_filial | 20 | 20 |
| pedido_compra | 29 | 29 |
| entradas_mercadoria | 20 | 20 |
| venda | 33 | 33 |
| **Total** | **122** | **122** |

As quantidades das cinco tabelas correspondem às quantidades de linhas principais identificadas na planilha Excel.

Os 102 registros ignorados na segunda execução já existiam no banco e foram reconhecidos por suas chaves primárias. Os 20 registros restantes de `entradas_mercadoria` foram inseridos após a correção do script.

## Observações para validação

Embora as quantidades estejam corretas, a conferência de registros não garante que todos os valores estejam consistentes.

Na aba `pedido_compra`, foram encontradas 11 colunas adicionais com dados em nove linhas.

Por exemplo, para o pedido 21, produto P12:

- Dados principais: ordem de compra 0, quantidade pedida 12 e quantidade entregue 0.
- Dados adicionais: ordem de compra 12, quantidade pedida 91, quantidade entregue 48 e quantidade pendente 43.

Também foram observadas datas que precisam ser verificadas. Nesse exemplo, a data do pedido é 25/02/2025, enquanto a data informada de entrega é 20/02/2025.

Essas diferenças precisam ser esclarecidas na validação com o cliente, antes de decidir se os dados adicionais devem substituir ou complementar os registros principais.

A conferência de quantidades foi concluída, mas a validação integral da qualidade dos dados permanece pendente.
