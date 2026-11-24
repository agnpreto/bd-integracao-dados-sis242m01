# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

Banco de dados: PostgreSQL instalado localmente (`localhost:5432`, banco `postgres`), acessado pelo VS Code (extensão de PostgreSQL). O DDL do MySQL foi validado à parte, em um servidor MySQL local (`localhost:3306`).

Importação: script `scripts/importar.py` (Python 3.13) com as bibliotecas `pandas` e `openpyxl` (leitura do `.xlsx`) e `psycopg2` (conexão com o PostgreSQL).

Configuração da conexão: host, porta, banco, usuário e senha vêm de variáveis de ambiente (`PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`). Nenhuma senha fica no código.

Conferência: `SELECT COUNT(*)` em cada tabela, comparado com a quantidade de linhas de cada aba de `dados/base_teste.xlsx`.

Versionamento: Git e GitHub (fork da equipe, entrega por Pull Request).

## Estrutura da planilha

O arquivo `dados/base_teste.xlsx` (não alterado) tem uma aba por tabela:

| Aba                 | Linhas de dados |
| ------------------- | --------------- |
| fornecedor          | 20              |
| produtos_filial     | 20              |
| pedido_compra       | 29              |
| entradas_mercadoria | 20              |
| venda               | 33              |

Colunas de cada aba e tipo usado no banco:

| Aba                 | Coluna            | Tipo             | Observação                                                                                      |
| ------------------- | ----------------- | ---------------- | ----------------------------------------------------------------------------------------------- |
| fornecedor          | idfornecedor      | varchar(25)      | Chave primária. Código em texto (ex.: `F1`)                                                     |
| fornecedor          | razao_social      | varchar(255)     | Obrigatória                                                                                     |
| produtos_filial     | filial_id         | integer          | Parte da chave primária                                                                         |
| produtos_filial     | produto_id        | varchar(25)      | Parte da chave primária                                                                         |
| produtos_filial     | descricao         | varchar(255)     | Obrigatória                                                                                     |
| produtos_filial     | estoque           | double precision | Vazio vira 0                                                                                    |
| produtos_filial     | preco_unitario    | numeric(12,4)    | Vazio vira 0                                                                                    |
| produtos_filial     | preco_compra      | numeric(12,4)    | Vazio vira 0                                                                                    |
| produtos_filial     | preco_venda       | numeric(12,4)    | Vazio vira 0                                                                                    |
| produtos_filial     | idfornecedor      | varchar(25)      | Referencia `fornecedor`                                                                         |
| pedido_compra       | pedido_id         | bigint           | Parte da chave primária                                                                         |
| pedido_compra       | data_pedido       | date             | Data                                                                                            |
| pedido_compra       | item              | integer          | Parte da chave primária                                                                         |
| pedido_compra       | produto_id        | varchar(25)      | Parte da chave primária                                                                         |
| pedido_compra       | descricao_produto | varchar(255)     | Opcional                                                                                        |
| pedido_compra       | ordem_compra      | bigint           | Vazio vira 0                                                                                    |
| pedido_compra       | qtde_pedida       | double precision | Opcional                                                                                        |
| pedido_compra       | filial_id         | integer          | Opcional                                                                                        |
| pedido_compra       | data_entrega      | date             | Data                                                                                            |
| pedido_compra       | qtde_entregue     | double precision | Vazio vira 0                                                                                    |
| pedido_compra       | qtde_pendente     | double precision | Obrigatória no banco; calculada no script (`qtde_pedida - qtde_entregue`) quando a planilha não traz o valor |
| pedido_compra       | preco_compra      | numeric(12,4)    | Vazio vira 0                                                                                    |
| pedido_compra       | fornecedor_id     | varchar(25)      | Referencia `fornecedor`                                                                         |
| entradas_mercadoria | data_entrada      | date             | Data                                                                                            |
| entradas_mercadoria | nro_nfe           | varchar(255)     | Parte da chave primária                                                                         |
| entradas_mercadoria | item              | integer          | Parte da chave primária                                                                         |
| entradas_mercadoria | produto_id        | varchar(25)      | Parte da chave primária                                                                         |
| entradas_mercadoria | descricao_produto | varchar(255)     | Opcional                                                                                        |
| entradas_mercadoria | ordem_compra      | bigint           | Parte da chave primária (coluna ausente no DDL original)                                        |
| entradas_mercadoria | qtde_recebida     | double precision | Opcional                                                                                        |
| entradas_mercadoria | filial_id         | integer          | Opcional                                                                                        |
| entradas_mercadoria | custo_unitario    | numeric(12,4)    | Vazio vira 0                                                                                    |
| venda               | venda_id          | bigint           | Parte da chave primária                                                                         |
| venda               | data_emissao      | date             | Obrigatória; parte da chave primária                                                             |
| venda               | horariomov        | varchar(8)       | Formato `HH:MM:SS`; vazio vira `00:00:00`                                                       |
| venda               | produto_id        | varchar(25)      | Parte da chave primária                                                                         |
| venda               | qtde_vendida      | double precision | Opcional                                                                                        |
| venda               | valor_unitario    | numeric(12,4)    | Vazio vira 0                                                                                    |
| venda               | filial_id         | integer          | Vazio vira 1; parte da chave primária                                                             |
| venda               | item              | integer          | Vazio vira 0; parte da chave primária                                                             |
| venda               | unidade_medida    | varchar(3)       | Opcional                                                                                        |

## Erros encontrados no DDL e como foram corrigidos

O arquivo `sql/01_ddl_enunciado.sql` foi executado no PostgreSQL. Versões corrigidas: `sql/01_ddl_postgres.sql` e `sql/01_ddl_mysql.sql`.

| Tabela                                  | Erro                                                                                                               | Correção                                                                    |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| entradas_mercadoria                     | A chave primária usa `ordem_compra`, que não existe na tabela (`column "ordem_compra" named in key does not exist`) | Coluna `ordem_compra` adicionada                                            |
| produtos_filial                         | Falta vírgula antes do `CONSTRAINT` (`syntax error at or near "CONSTRAINT"`)                                        | Vírgula adicionada                                                          |
| produtos_filial                         | A chave primária usa `idproduto`, que não existe (a coluna é `produto_id`)                                          | Chave primária passou a `(filial_id, produto_id)`                           |
| fornecedor                              | A chave primária usa `idproduto`, que não existe na tabela                                                         | Chave primária passou a `(idfornecedor)`                                    |
| fornecedor / produtos_filial            | Nomes com erro de digitação: `idforncedor`, `idfonecedor`, `decricao`                                              | Renomeados para `idfornecedor` e `descricao`                                |
| fornecedor, produtos_filial, pedido_compra | Tipo do código do fornecedor inconsistente (`varchar(25)` em uma tabela e `int4` nas outras) e incompatível com os dados da planilha, que usam códigos em texto como `F1` | Tipo padronizado como texto (`varchar(25)`) nas três tabelas                |
| produtos_filial, pedido_compra          | Sem chave estrangeira para `fornecedor`                                                                            | FKs criadas; `fornecedor` passou a ser criada primeiro                      |
| pedido_compra, entradas_mercadoria     | `float8` em `pedido_id`, `item` e `ordem_compra`, que fazem parte de chaves primárias                               | Trocados por `bigint` e `integer`                                           |
| produtos_filial, pedido_compra          | `float8` em preços                                                                                                 | Trocado por `numeric(12,4)`                                                 |
| Várias                                  | `filial_id` com `int8` e `int4` conforme a tabela; `produto_id` com `varchar(255)` em `produtos_filial` e `varchar(25)` nas outras | Padronizados como `integer` e `varchar(25)`                                 |
| venda                                   | Chave primária chamada `pk_consumo`                                                                                | Renomeada para `pk_venda`                                                   |
| Todas (MySQL)                           | `public.`, `::character varying`, `int8` e `float8` não funcionam no MySQL                                          | Prefixo e cast removidos, `BIGINT`, `DOUBLE` e `DECIMAL` usados             |

## Erros encontrados no script de importação e como foram corrigidos

| Erro                                                                   | Efeito                                                                          | Correção                                                                        |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Senha escrita no código (`"1234"`)                                     | Exposição de credencial e descumprimento do enunciado                           | Credenciais lidas de variáveis de ambiente                                      |
| `rollback()` dentro do laço, com `commit` só no fim da tabela            | Uma linha com erro desfazia todas as anteriores da mesma tabela, sem aviso       | `commit` por linha; só a linha com erro é rejeitada                              |
| Código do fornecedor convertido para inteiro, mas a planilha traz texto (`F1`) | Nenhuma linha de `fornecedor` entrou (0 linhas no primeiro `COUNT`)             | Código tratado como texto                                                       |
| FK `fk_pedido_fornecedor` sem fornecedores carregados                  | Nenhuma linha de `pedido_compra` entrou, por violação de chave estrangeira     | `fornecedor` carregada antes e com o mesmo tipo de chave                        |
| Coluna `qtde_pendente` é `NOT NULL`, mas o script não preenchia o valor | Linhas de `pedido_compra` rejeitadas                                             | Valor da planilha, ou `qtde_pedida - qtde_entregue` quando ausente             |
| Mensagem "N registros inseridos" usava o total lido                     | Informava sucesso mesmo com linhas perdidas                                    | Contagem real por `rowcount`, separando inseridas, duplicadas e rejeitadas      |
| `ON CONFLICT DO NOTHING` sem contagem                                  | Linhas com chave repetida sumiam sem aviso                                      | Duplicadas contadas e exibidas no resumo                                        |
| Mensagem final "concluída com sucesso" sempre exibida                  | Mascarava erros                                                                 | Resumo por tabela e arquivo `rejeitadas.log` com a linha do Excel e o motivo    |
| `excel_para_data` com `except` genérico e `int(valor)`                 | Datas já em formato de data viravam `NULL`, quebrando `venda.data_emissao` (`NOT NULL`) | Função que aceita data, número serial do Excel e texto                         |
| Colunas lidas por nome fixo (`idproduto`) e por posição (`iloc[:, :12]`) | `KeyError` ou valores na coluna errada                                          | Nomes normalizados (minúsculas e apelidos) e leitura por nome                   |
| Ids e números enviados como `str()` ou `float()`                       | Valores como `12345.0`, e arredondamento silencioso ao ir para inteiro          | Conversores de texto, inteiro e número                                          |

## Tratamentos aplicados aos dados

Conversão de tipos: ids e chaves como texto limpo (sem `.0` quando o Excel entrega número); quantidades e preços como número; chaves inteiras como `int`.

Datas: `data_pedido`, `data_entrega`, `data_entrada` e `data_emissao` aceitam data nativa do Excel, número serial e texto `dd/mm/aaaa` ou `aaaa-mm-dd`. Data inválida rejeita a linha, em vez de virar `NULL` sem aviso.
- **Hora:** `horariomov` normalizada para `HH:MM:SS` (aceita hora nativa e fração de dia do Excel); vazio vira `00:00:00`.
- **Valores vazios:** quantidades e preços obrigatórios no banco recebem 0; `filial_id` de `venda` recebe 1; `item` recebe 0; campos opcionais ficam `NULL`.
- **Normalização de texto:** remoção de espaços no início e no fim; colunas da planilha normalizadas (minúsculas, sem espaços) e nomes errados mapeados para o nome do DDL.
- **Cálculo de `qtde_pendente`:** `qtde_pedida - qtde_entregue` quando a planilha não traz o valor.
- **Validações:** chaves primárias e estrangeiras verificadas pelo próprio banco; chaves repetidas ignoradas e contadas; linhas rejeitadas registradas com número da linha do Excel e motivo.
- **Ordem de carga:** `fornecedor`, `produtos_filial`, `pedido_compra`, `entradas_mercadoria`, `venda`, para respeitar as chaves estrangeiras.

## Conferência final

Contagem feita no PostgreSQL com `SELECT COUNT(*)` em cada tabela, comparada com as linhas de dados de cada aba de `dados/base_teste.xlsx`:

| Tabela              | Linhas na planilha | Linhas no banco |
| ------------------- | ------------------ | --------------- |
| fornecedor          | 20                 | 20 (Diff: +0)   |
| produtos_filial     | 20                 | 20 (Diff: +0)   |
| pedido_compra       | 29                 | 29 (Diff: +0)   |
| entradas_mercadoria | 20                 | 20 (Diff: +0)   |
| venda               | 33                 | 33 (Diff: +0)   |

Na primeira verificação, `fornecedor` e `pedido_compra` estavam com 0 linhas no banco, pelos motivos descritos na seção de erros do script (código `F1` convertido para inteiro, FK `fk_pedido_fornecedor` e campo `qtde_pendente` obrigatório). Depois das correções, todas as tabelas fecharam com diferença zero.