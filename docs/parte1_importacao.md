# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

| Item | Ferramenta |
| --- | --- |
| Banco principal | PostgreSQL 16 (local) |
| Banco secundário | MySQL 8 (testado também em MariaDB 10.11) |
| IDE de banco | DBeaver Community (execução dos scripts SQL, conferência das tabelas e cópia dos dados para o MySQL) |
| Importação | `scripts/importar.py` corrigido: Python 3 + `pandas`/`openpyxl` (leitura do Excel) + `psycopg` 3 (gravação no PostgreSQL) |
| Carga no MySQL | DBeaver → *Export Data* → *Database* (das tabelas do PostgreSQL já carregadas para as do MySQL) |
| Editor | VS Code |

Fluxo: `01_ddl_postgres.sql` (cria as tabelas) → `importar.py` (lê a planilha, converte, grava e confere) → DBeaver (copia para o MySQL) → `SELECT COUNT(*)` nos dois bancos.

O script também guarda uma **cópia crua de cada aba** no schema `stg`, com todas as colunas como texto e o número da linha do Excel (`linha_excel`). Assim, qualquer dado do banco pode ser conferido contra a célula de origem, inclusive as colunas sem cabeçalho de `pedido_compra`. Avisos e linhas rejeitadas vão para a tabela `importacao_rejeicoes`.

## Estrutura da planilha

`dados/base_teste.xlsx`, 5 abas, cabeçalho na linha 1. "Tipo no Excel" é o tipo real das células, verificado com `openpyxl`.

| Aba | Coluna | Tipo no Excel → tipo no banco | Observação |
| --- | --- | --- | --- |
| fornecedor (20 linhas) | idfornecedor | texto (`F1`…`F20`) → `integer` | convertido `F8` → `8`; no DDL original era `idforncedor varchar(25)` |
| fornecedor | razao_social | texto → `varchar(255)` | |
| produtos_filial (20) | filial_id | inteiro → `integer` | só existe a filial 1 |
| produtos_filial | **idproduto** | texto (`P1`…`P20`) → `produto_id varchar(25)` | cabeçalho diferente das outras abas (`produto_id`) |
| produtos_filial | descricao | texto → `varchar(255)` | no DDL original estava `decricao` |
| produtos_filial | estoque | inteiro → `numeric(14,3)` | |
| produtos_filial | preco_unitario, preco_compra, preco_venda | decimal (1 célula inteira) → `numeric(12,4)` | |
| produtos_filial | idfornecedor | texto (`F8`…) → `integer` | no DDL original estava `idfonecedor` |
| pedido_compra (29) | pedido_id | inteiro → `bigint` | era `float8` |
| pedido_compra | data_pedido, data_entrega | data → `date` | |
| pedido_compra | item | inteiro → `integer` | era `float8` |
| pedido_compra | produto_id, descricao_produto | texto → `varchar` | |
| pedido_compra | ordem_compra | inteiro → `bigint` | **liga o pedido à entrada**; vale 0 em 11 pedidos |
| pedido_compra | qtde_pedida, qtde_entregue | inteiro → `numeric(14,3)` | |
| pedido_compra | preco_compra | decimal → `numeric(12,4)` | |
| pedido_compra | fornecedor_id | inteiro (1…20) → `integer` | aqui é número, nas outras abas `F1` |
| pedido_compra | *(ausente)* qtde_pendente | – → `numeric(14,3)` | **a aba não tem a coluna**; calculada = qtde_pedida − qtde_entregue |
| pedido_compra | *(colunas M a W, sem cabeçalho)* | 11 valores nas linhas 22 a 30 | cópia do pedido original do produto; não carregadas, guardadas em `stg.pedido_compra` (`extra_01`…`extra_11`) |
| entradas_mercadoria (20) | data_entrada | data → `date` | |
| entradas_mercadoria | nro_nfe | texto (`NFE1`…) → `varchar(255)` | |
| entradas_mercadoria | item | inteiro → `integer` | |
| entradas_mercadoria | produto_id, descricao_produto | texto → `varchar` | |
| entradas_mercadoria | ordem_compra | inteiro → `bigint` | **não existia no DDL original** (estava só na PK) |
| entradas_mercadoria | qtde_recebida | inteiro → `numeric(14,3)` | |
| entradas_mercadoria | filial_id | inteiro → `integer` | |
| entradas_mercadoria | custo_unitario | decimal → `numeric(12,4)` | |
| venda (33) | venda_id | inteiro → `bigint` | |
| venda | data_emissao | data → `date` | jan a mar/2025 |
| venda | horariomov | texto `08:00:00` → `time` | igual em todas as linhas |
| venda | produto_id | texto (`P1`…`P28`) → `varchar(25)` | P21 a P28 não existem em produtos_filial |
| venda | qtde_vendida | inteiro (28) e decimal (5) → `numeric(14,3)` | decimais com unidade `UN` |
| venda | valor_unitario | decimal → `numeric(12,4)` | |
| venda | filial_id | inteiro → `integer` | 1, 2 e 3 |
| venda | item | inteiro → `integer` | |
| venda | unidade_medida | texto → `varchar(3)` | sempre `UN` |

## Erros encontrados no DDL e como foram corrigidos

`sql/01_ddl_enunciado.sql` executado no PostgreSQL 16 e no MySQL (MariaDB 10.11). Mensagens obtidas:

```
PostgreSQL
  venda, pedido_compra ........ CREATE TABLE (criadas, mas com problemas de tipo)
  entradas_mercadoria ......... ERROR: column "ordem_compra" named in key does not exist
  produtos_filial ............. ERROR: syntax error at or near "("
  fornecedor .................. ERROR: column "idproduto" named in key does not exist
MySQL
  venda ....................... ERROR 1064 ... near '::character varying NOT NULL'
  pedido_compra ............... ERROR 1049 Unknown database 'public'
  entradas_mercadoria ......... ERROR 1072 Key column 'ordem_compra' doesn't exist in table
  produtos_filial ............. ERROR 1064 ... near 'PRIMARY KEY (filial_id, idproduto))'
  fornecedor .................. ERROR 1072 Key column 'idproduto' doesn't exist in table
```

| Tabela | Erro | Correção |
| --- | --- | --- |
| entradas_mercadoria | A PK usa `ordem_compra`, mas a coluna não existe. Sem ela também não há como ligar a entrada ao pedido | coluna `ordem_compra bigint NOT NULL` criada |
| produtos_filial | Falta a vírgula depois de `idfonecedor int4 NULL`, o que dá erro de sintaxe | vírgula incluída |
| produtos_filial | PK `(filial_id, idproduto)`: a coluna `idproduto` não existe | PK `(filial_id, produto_id)` |
| produtos_filial | Typos `decricao` e `idfonecedor` | `descricao`, `idfornecedor` |
| produtos_filial | `filial_id int4 NULL` faz parte da PK | `NOT NULL` |
| produtos_filial | `produto_id varchar(255)`; nas outras tabelas é `varchar(25)` | `varchar(25)` |
| produtos_filial | DEFAULT `'0'` (texto) em colunas numéricas | DEFAULT `0` em `numeric` |
| fornecedor | Typo `idforncedor` | `idfornecedor` |
| fornecedor | PK `(idforncedor, idproduto)`: `idproduto` não existe e o fornecedor não depende de produto | PK `(idfornecedor)` |
| fornecedor | id `varchar(25)`, mas produtos (`int4`) e pedidos (`fornecedor_id int4`) usam inteiro, então não daria para criar FK | `integer GENERATED BY DEFAULT AS IDENTITY` (MySQL: `AUTO_INCREMENT`) |
| todas | Sem relacionamento entre as tabelas | FKs `produtos_filial.idfornecedor` e `pedido_compra.fornecedor_id` → `fornecedor` |
| pedido_compra | `pedido_id`, `item` e `ordem_compra` em `float8` (float é aproximado e não serve para chave) | `bigint` / `integer` |
| pedido_compra | `fornecedor_id DEFAULT 0`: o fornecedor 0 não existe e quebraria a FK | sem DEFAULT |
| entradas_mercadoria | `item float8` | `integer` |
| todas | Quantidades e preços em `float8` (erro de arredondamento em somas) | `numeric(14,3)` para quantidades e `numeric(12,4)` para preços |
| venda | `horariomov varchar(8)` aceita qualquer texto | `time` |
| venda | PK chamada `pk_consumo` (nome de outra tabela) | `pk_venda` |
| venda | `filial_id int8`; nas outras tabelas é `int4` | `integer` |
| (MySQL) | `public.` (schema do PostgreSQL), `::character varying` (cast do PostgreSQL), `int8/int4/float8` | removidos/convertidos: `BIGINT/INT/DECIMAL`, `AUTO_INCREMENT`, `ENGINE=InnoDB`, `utf8mb4` |
| (ambos) | Script não pode ser executado de novo (tabelas já existem) | `DROP TABLE IF EXISTS` (PostgreSQL) / `DROP DATABASE IF EXISTS` (MySQL) |

Não foi criada FK de `entradas_mercadoria` para `pedido_compra`: `ordem_compra` não é única nos pedidos (11 pedidos têm `ordem_compra = 0`) e há entradas sem pedido (Parte 4, E05 e E11).

Resultado: `sql/01_ddl_postgres.sql` e `sql/01_ddl_mysql.sql` executam sem erro, e podem ser executados de novo.

## Erros encontrados no script de importação e como foram corrigidos

O script passou por três versões, todas no histórico do Git:

| Versão | Commit | Situação |
| --- | --- | --- |
| Original do estagiário | `3a59f2a` (modelo do professor) | Carrega quase nada e informa sucesso |
| 1ª correção (dupla) | `d00175e` | Carrega as 5 tabelas, mas ainda esconde erros |
| Versão final | este commit | Corrige o restante e confere a carga com o banco |

### Teste do script original (`3a59f2a`)

Executado sobre o DDL corrigido (o resultado é o mesmo no DDL da 1ª e da 2ª versão):

| Tabela | O script imprimiu | `SELECT COUNT(*)` no banco | Causa |
| --- | --- | --- | --- |
| fornecedor | 20 registros inseridos | **0** | `idfornecedor` vem como `'F1'` e a coluna é `integer`: `invalid input syntax for type integer: "F1"` nas 20 linhas |
| produtos_filial | 20 registros inseridos | **0** | mesmo erro com `'F8'`, `'F9'`... |
| pedido_compra | 0 registros inseridos | **0** | fornecedor vazio, então a FK falha nas 29 linhas (`violates foreign key constraint "fk_pedido_fornecedor"`) |
| entradas_mercadoria | 20 registros inseridos | 20, **com `data_entrada` NULL nas 20** | `excel_para_data` faz `int(valor)` num `Timestamp`, o `except:` engole o erro e devolve `None` |
| venda | 33 registros inseridos | **0** | mesma função de data: `data_emissao` NULL viola o NOT NULL nas 33 linhas |

No final, imprimiu `Importação concluída com sucesso!`. Das 122 linhas da planilha, entraram 20, e sem data.

### Erros do script original e onde cada um foi corrigido

| Erro no original | Efeito | Correção |
| --- | --- | --- |
| Senha no código (`"password": "1234"`) e banco `postgres` fixo | Credencial no GitHub; carga no banco errado | 1ª correção manteve o banco `postgres` fixo e trocou por outra senha fixa (`"1920"`), que ficou publicada no histórico do GitHub. **Versão final:** variáveis de ambiente (`PGHOST`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`) |
| `ARQUIVO = "dados/base_teste.xlsx"` (caminho relativo à pasta atual) | Falha se o script for rodado de dentro de `scripts/` | 1ª correção: caminho a partir do próprio arquivo (`Path(__file__)`) |
| `psycopg2` | Driver antigo | 1ª correção: `psycopg` 3 |
| `idfornecedor` gravado como texto `'F1'` em coluna `integer` | 0 fornecedores e 0 produtos; em cascata, 0 pedidos (FK) | 1ª correção: extrai os dígitos de qualquer texto (`AB1-2` viraria 12). **Versão final:** aceita só `F<número>` ou número; o resto é rejeitado |
| `excel_para_data` só trata número serial (`int(valor)`) e usa `except:` genérico | Todas as datas viram NULL: vendas rejeitadas, entradas sem data | 1ª correção: trata `datetime`/`Timestamp`. **Versão final:** também aceita texto `AAAA-MM-DD`, `DD/MM/AAAA`; data inválida é rejeitada com motivo |
| `print(f"{len(df)} registros inseridos")` | Informa o total da planilha, não o que entrou (disse 20 com 0 no banco) | 1ª correção: conta `cur.rowcount`. **Versão final:** confere com `SELECT COUNT(*)` no banco |
| `"Importação concluída com sucesso!"` incondicional | Sucesso com 102 linhas perdidas | **Versão final:** status `OK`/`DIVERGENTE` por tabela |
| `conn.rollback()` dentro do laço, `commit()` só no fim da tabela | Uma linha com erro desfaz **todas as anteriores** da tabela | **Continuava na 1ª correção.** Provado: com uma venda inválida na linha 30, ela imprimiu "32 inseridos" e o banco ficou com **4**. **Versão final:** `SAVEPOINT` por linha, só a linha ruim é desfeita |
| `except ... continue` / linhas puladas sem registro | Dados somem sem rastro | **Versão final:** tabela `importacao_rejeicoes` (aba, linha do Excel, motivo, dados) |
| Número da linha exibido = índice do pandas | Aponta a linha 28 quando no Excel é a 30 | **Versão final:** `linha_excel = idx + 2` |
| `ON CONFLICT DO NOTHING` sem aviso | Duplicadas somem em silêncio | **Versão final:** `RETURNING`; se nada entrou, registra "chave duplicada" |
| `df.iloc[:, :12]` + renomear colunas **por posição** (pedido_compra) | Descarta em silêncio as 11 colunas extras das linhas 22 a 30; se a ordem mudar, grava na coluna errada | **Continuava na 1ª correção.** **Versão final:** mapeamento pelo nome; colunas sem cabeçalho geram aviso e ficam em `stg.pedido_compra` |
| `float()` em `pedido_id`, `item`, `ordem_compra` | Chave tratada como número aproximado | 1ª correção: `int`. **Versão final:** inteiro validado (rejeita `1.5`) |
| Chave inválida vira 0 (`ordem_compra`, `pedido_id`, `produto_id` "0") | Grava pedido/ordem/produto 0 | **Versão final:** chave vazia ou inválida é rejeitada |
| `str(valor)` em campos vazios | Texto `"nan"` gravado no banco | 1ª correção: testa `pd.notna`. **Versão final:** função `texto()` única |
| `qtde_pendente` calculada sem documentação | Parece dado do cliente, mas a planilha não tem a coluna | Mantido o cálculo, documentado (Parte 4, E02) |
| Não limpa as tabelas antes | Rodar 2 vezes mantém dados antigos e mostra "0 inseridos" | **Versão final:** `TRUNCATE` no início, na mesma transação |
| IDENTITY de fornecedor não ajustada depois de gravar ids 1–20 | Testado: o próximo INSERT sem id dá `duplicate key`, e a trigger da Parte 3 quebraria | **Versão final:** `setval(pg_get_serial_sequence('fornecedor','idfornecedor'), max+1)` |
| Conexão sem `with`, sem tratamento de erro geral | Conexão fica aberta se o script quebrar | 1ª correção: `with psycopg.connect(...)`. **Versão final:** transação única (commit no fim, rollback em erro) |

## Tratamentos aplicados aos dados

- **Conversão de tipos:** inteiros (`pedido_id`, `item`, `ordem_compra`, `filial_id`), decimais (`numeric`), datas (`date`), hora (`time`). Código de produto e de nota tratado como texto, sem o `.0` que o Excel acrescenta.
- **Normalização de ids de fornecedor:** `F1`…`F20` → `1`…`20` (fornecedor e produtos_filial), para ficar igual a `pedido_compra.fornecedor_id`, que já é número.
- **Normalização de cabeçalhos:** minúsculas, sem acento. `idproduto` → `produto_id` (registrado como aviso).
- **Textos:** espaços extras removidos; `unidade_medida` em maiúsculas.
- **Coluna ausente:** `pedido_compra.qtde_pendente` = `qtde_pedida − qtde_entregue`.
- **Colunas sem cabeçalho** (pedido_compra, linhas 22 a 30, colunas M a W): não carregadas nas tabelas finais (não têm nome nem lugar no DDL). Ficam em `stg.pedido_compra.extra_01..extra_11` e foram levadas ao cliente (Parte 4, E01 e E07).
- **Validações:** chave obrigatória, chave duplicada, tipos e datas. Nada é descartado sem registro.
- **Carga transacional:** tudo ou nada; o script pode ser executado de novo.
- **IDENTITY** de fornecedor ajustada para 21 depois da carga.
- **Dados não corrigidos por conta própria:** `ordem_compra = 0`, entregas antes do pedido, vendas de produto sem cadastro etc. foram carregados **como vieram** e listados na Parte 4 para decisão do cliente. Alterar esses valores sem confirmação seria inventar dado.

## Conferência final

```sql
SELECT 'fornecedor' AS tabela, COUNT(*) FROM fornecedor UNION ALL
SELECT 'produtos_filial', COUNT(*) FROM produtos_filial UNION ALL
SELECT 'pedido_compra', COUNT(*) FROM pedido_compra UNION ALL
SELECT 'entradas_mercadoria', COUNT(*) FROM entradas_mercadoria UNION ALL
SELECT 'venda', COUNT(*) FROM venda;
```

| Tabela | Linhas na planilha | Script original (banco) | Versão final: PostgreSQL | Versão final: MySQL | Rejeitadas |
| --- | --- | --- | --- | --- | --- |
| fornecedor | 20 | 0 | 20 | 20 | 0 |
| produtos_filial | 20 | 0 | 20 | 20 | 0 |
| pedido_compra | 29 | 0 | 29 | 29 | 0 |
| entradas_mercadoria | 20 | 20 (sem data) | 20 | 20 | 0 |
| venda | 33 | 0 | 33 | 33 | 0 |

Avisos da carga (`SELECT * FROM importacao_rejeicoes`): 1 cabeçalho renomeado (`idproduto`) e 9 linhas de `pedido_compra` com dados em colunas sem cabeçalho.
