# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

A importação foi feita pelo script `scripts/importar.py` (Python 3 com `pandas`, `openpyxl` e `psycopg2`). Ele lê as 5 abas de `dados/base_teste.xlsx` e grava no PostgreSQL local, no banco `integracao_dados`. O DBeaver foi usado para criar o banco, executar os DDLs corrigidos (`sql/01_ddl_postgres.sql` e `sql/01_ddl_mysql.sql`) e conferir os dados com consultas SQL.

## Estrutura da planilha

| Aba | Coluna | Tipo | Observação |
| --- | --- | --- | --- |
| venda | venda_id | inteiro | bigint |
| venda | data_emissao | data | date; 14 das 33 vendas são de fevereiro/2025 |
| venda | horariomov | texto | varchar(8), formato HH:MM:SS (mantido como texto) |
| venda | produto_id | texto | varchar(25) |
| venda | qtde_vendida | inteiro (28) e decimal (5) | numeric(14,4); 5 valores fracionados em unidade UN |
| venda | valor_unitario | decimal | numeric(12,4) |
| venda | filial_id | inteiro | integer; filiais 1, 2 e 3 |
| venda | item | inteiro | integer |
| venda | unidade_medida | texto | varchar(3); todas "UN" |
| pedido_compra | pedido_id | inteiro | bigint |
| pedido_compra | data_pedido | data | date; de 02/01/2025 a 01/03/2025 |
| pedido_compra | item | inteiro | integer |
| pedido_compra | produto_id | texto | varchar(25) |
| pedido_compra | descricao_produto | texto | varchar(255) |
| pedido_compra | ordem_compra | inteiro | bigint; 11 pedidos com valor 0 |
| pedido_compra | qtde_pedida | inteiro | numeric(14,4) |
| pedido_compra | filial_id | inteiro | integer; todos na filial 1 |
| pedido_compra | data_entrega | data | date; 20 anteriores à data do pedido |
| pedido_compra | qtde_entregue | inteiro | numeric(14,4) |
| pedido_compra | preco_compra | decimal | numeric(12,4) |
| pedido_compra | fornecedor_id | inteiro | integer; valores de 1 a 20 |
| pedido_compra | qtde_pendente | não existe na planilha | numeric(14,4); calculada na importação como qtde_pedida menos qtde_entregue |
| pedido_compra | colunas M a W, sem cabeçalho | 99 células soltas | ignoradas: a importação lê só as colunas A a L |
| entradas_mercadoria | data_entrada | data | date |
| entradas_mercadoria | nro_nfe | texto | varchar(255) |
| entradas_mercadoria | item | inteiro | integer |
| entradas_mercadoria | produto_id | texto | varchar(25) |
| entradas_mercadoria | descricao_produto | texto | varchar(255) |
| entradas_mercadoria | ordem_compra | inteiro | bigint; liga a entrada ao pedido (coluna que faltava no DDL do enunciado); as ordens 19 e 20 não existem em pedido_compra |
| entradas_mercadoria | qtde_recebida | inteiro | numeric(14,4) |
| entradas_mercadoria | filial_id | inteiro | integer |
| entradas_mercadoria | custo_unitario | decimal | numeric(12,4) |
| produtos_filial | filial_id | inteiro | integer; todos na filial 1 |
| produtos_filial | idproduto | texto | produto_id varchar(25); a coluna tem outro nome no banco, mapeada na importação |
| produtos_filial | descricao | texto | varchar(255) |
| produtos_filial | estoque | inteiro | numeric(14,4) |
| produtos_filial | preco_unitario | decimal | numeric(12,4) |
| produtos_filial | preco_compra | decimal (19) e inteiro (1) | numeric(12,4) |
| produtos_filial | preco_venda | decimal | numeric(12,4) |
| produtos_filial | idfornecedor | texto (F1 a F20) | integer; prefixo "F" removido na importação (F8 vira 8) |
| fornecedor | idfornecedor | texto (F1 a F20) | integer; prefixo "F" removido na importação |
| fornecedor | razao_social | texto | varchar(255) |

## Erros encontrados no DDL e como foram corrigidos

| Tabela | Erro | Correção |
| --- | --- | --- |
| entradas_mercadoria | coluna "ordem_compra" indicada na chave não existe. A PK usa ordem_compra, mas essa coluna não foi declarada na tabela. | Adicionei a coluna ordem_compra float8 DEFAULT 0 NOT NULL na lista de colunas (mesmo tipo de pedido_compra), para a PK passar a funcionar. |
| fornecedor | coluna "idproduto" indicada na chave não existe. A PK cita idproduto, mas essa coluna não existe em fornecedor (as colunas dessa tabela são idforncedor e razao_social). | Troquei a PK para PRIMARY KEY (idforncedor), removendo idproduto, que não existe nessa tabela. |
| produtos_filial | erro de sintaxe em ou próximo a "(". Falta uma vírgula no fim da linha do idfonecedor; sem ela o PostgreSQL leu o CONSTRAINT como parte da própria coluna e estranhou o "(". | Adicionei a vírgula no fim da linha idfonecedor int4 NULL, |
| produtos_filial | coluna "idproduto" indicada na chave não existe. A PK cita idproduto, mas a coluna se chama produto_id. | Troquei idproduto por produto_id na PK: PRIMARY KEY (filial_id, produto_id). |
| fornecedor, produtos_filial, pedido_compra | Id do fornecedor com tipos incompatíveis: varchar(25) em fornecedor e int4 nas tabelas que o referenciam. | integer nas três tabelas (a trigger da Parte 3 exige id numérico). |
| fornecedor, produtos_filial | Nomes com erro de digitação: idforncedor, idfonecedor e decricao. | idfornecedor nas duas tabelas e descricao em produtos_filial. |
| pedido_compra, entradas_mercadoria | pedido_id, ordem_compra e item declarados como float8, tipo impreciso para chaves. | bigint para pedido_id e ordem_compra; integer para item. |
| produtos_filial, pedido_compra, entradas_mercadoria, venda | Quantidades e preços em float8, enquanto valor_unitario e custo_unitario já eram numeric. | numeric(14,4) para quantidades e estoque; numeric(12,4) para preços. |
| venda, pedido_compra, entradas_mercadoria, produtos_filial | filial_id com tipos diferentes (int8 em venda, int4 nas outras) e NULL em coluna da PK de produtos_filial. | integer em todas; NOT NULL em produtos_filial. |
| produtos_filial | produto_id com varchar(255), enquanto nas outras tabelas é varchar(25). | varchar(25). |
| venda, pedido_compra, entradas_mercadoria | DEFAULTs sem sentido em colunas de chave (produto_id vazio ou 0, ids 0, filial_id 1): dado faltando entra sem dar erro. | DEFAULTs removidos; dado faltando passa a gerar erro. |
| produtos_filial | DEFAULT '0' (texto) em colunas numéricas. | DEFAULT 0. |
| pedido_compra | fornecedor_id com DEFAULT 0, valor que não existe em fornecedor. | DEFAULT removido. |
| venda | Constraint da PK chamada pk_consumo, nome que não tem relação com a tabela. | Renomeada para venda_pkey. |
| pedido_compra, entradas_mercadoria | Sem índice em ordem_compra, o campo que liga a entrada ao pedido. | Criados idx_pedido_compra_ordem e idx_entradas_ordem. |
| pedido_compra, produtos_filial | Sem chave estrangeira para fornecedor. | FKs escritas nos arquivos de DDL, comentadas, para aplicar depois da importação e da validação. A de produtos_filial foi aplicada em sql/03_transformacoes.sql, junto da trigger; a de pedido_compra continua só escrita. |
| pedido_compra | qtde_pendente é derivável (qtde_pedida menos qtde_entregue) e pode ficar inconsistente. | Mantida; a conferência entra na Parte 4. |
| venda | horariomov é varchar(8) em vez de TIME. | Mantido para não rejeitar horários inválidos na importação; validação na Parte 4. |
| venda (MySQL) | ERROR 1064: erro de sintaxe perto de '::character varying'. O cast ::character varying nos DEFAULTs só existe no PostgreSQL. | Removi o cast: DEFAULT '00:00:00'. |
| pedido_compra, entradas_mercadoria, fornecedor (MySQL) | ERROR 1049: Unknown database 'public'. No MySQL o prefixo public. é lido como nome de banco, não de esquema. | Removi o prefixo public. e escolhi o banco com USE integracao_dados. |
| produtos_filial (MySQL) | ERROR 1064 perto de 'PRIMARY KEY (filial_id, idproduto))': mesma causa da vírgula que falta; o PostgreSQL apontava para o "(", o MySQL aponta para o PRIMARY KEY. | Vírgula adicionada, como no PostgreSQL. |
| produtos_filial (MySQL) | filial_id declarado NULL mas usado na PK: o MySQL rejeita com ERROR 1171 (todas as partes de uma PRIMARY KEY devem ser NOT NULL), enquanto o PostgreSQL aceita e força NOT NULL em silêncio. | filial_id NOT NULL. |

## Erros encontrados no script de importação e como foram corrigidos

| Erro | Efeito | Correção |
| --- | --- | --- |
| `database` apontava para `postgres` | As tabelas estão em `integracao_dados`, então todo INSERT falharia com "relation does not exist" | Banco trocado para `integracao_dados` |
| Senha `1234` escrita no código | Expõe a senha. Com a senha real diferente, o script não conecta, e no Windows em português o erro aparece como UnicodeDecodeError, que esconde a mensagem de autenticação | Senha lida da variável de ambiente `PGPASSWORD` (valor de exemplo no arquivo) e aviso claro quando a conexão falha |
| `excel_para_data` fazia `int()` em um Timestamp, com `except:` vazio | O pandas já entrega data. Testado com a planilha: 33 de 33 datas de venda viravam NULL, e `venda.data_emissao` é NOT NULL, então nenhuma venda entraria | Função trata data e serial do Excel, sem `except` vazio |
| Código de fornecedor em texto (`F1`) enviado a coluna integer | `fornecedor` e `produtos_filial` rejeitariam todas as linhas | Função `codigo_fornecedor()` remove o "F" |
| `conn.rollback()` dentro do loop, com commit só no fim | Um erro desfaz todas as linhas já inseridas da mesma tabela | `autocommit` ligado: cada linha é gravada sozinha |
| Mensagens "N registros inseridos" usavam `len(df)` e a mensagem final era fixa | Dizia sucesso mesmo com 0 linhas inseridas | Contagem real de inseridas, duplicadas e com erro, conferência final planilha x banco e mensagem final condicional |
| Valores ausentes viravam valores falsos em silêncio (`else 1` e `else 0` em filial_id, item e ordem_compra) | Dado ausente entraria como filial 1, item 0 ou ordem 0 sem aviso | Valores padrão removidos das colunas de chave: dado ausente gera erro visível |
| Identificadores convertidos com `float()` | Resquício dos float8 do DDL antigo; chave imprecisa | `int()` nos identificadores |
| Caminho relativo `dados/base_teste.xlsx` | Só funcionava com o terminal na raiz do repositório | Caminho calculado a partir da pasta do script |

## Tratamentos aplicados aos dados

- **Conversão de tipos:** datas do Excel para `date`; identificadores para inteiro; quantidades e preços para `numeric`; textos sem espaços nas pontas.
- **Código do fornecedor:** prefixo "F" removido em `fornecedor` e `produtos_filial` (F8 vira 8), para casar com `pedido_compra.fornecedor_id` e com o tipo inteiro do DDL.
- **Mapeamento de coluna:** `idproduto` da planilha gravado em `produto_id`.
- **Colunas ignoradas:** as 99 células soltas das colunas M a W de `pedido_compra`. Só as colunas A a L são lidas.
- **Coluna calculada:** `qtde_pendente` não existe na planilha e é calculada como `qtde_pedida` menos `qtde_entregue`.
- **Valores ausentes:** estoque e preços ausentes virariam 0, como no DDL. A planilha não tem nenhuma célula vazia nas colunas lidas.
- **Validações:** inserção com `ON CONFLICT DO NOTHING` pelas chaves primárias (nenhuma linha duplicada foi ignorada) e contagem planilha x banco no fim do script.
- **Dados mantidos como vieram:** erros de conteúdo (datas invertidas, ordem de compra 0, quantidades divergentes) não foram alterados. Estão listados na Parte 4, porque a correção depende do cliente.

## Conferência final

| Tabela | Linhas na planilha | Linhas no banco |
| --- | --- | --- |
| fornecedor | 20 | 20 |
| produtos_filial | 20 | 20 |
| pedido_compra | 29 | 29 |
| entradas_mercadoria | 20 | 20 |
| venda | 33 | 33 |

Conferência feita no PostgreSQL, pelo próprio script ao final da importação.