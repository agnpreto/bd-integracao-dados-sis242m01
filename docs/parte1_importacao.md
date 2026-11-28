# Parte 1: Documentação do processo de importação

## 1. Ferramenta utilizada
- **Python 3 + pandas** (leitura do `.xlsx`) com **psycopg2** (PostgreSQL) e **pymysql** (MySQL), no script `scripts/importar.py` (corrigido).
- Testado em **PostgreSQL 16** e **MySQL 8.0**: `python scripts/importar.py` e `python scripts/importar.py --engine mysql`.
- Credenciais por variáveis de ambiente (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`). Nenhuma senha no código.
- Ordem de carga (respeita as chaves estrangeiras): `fornecedor`, `produtos_filial`, `pedido_compra`, `entradas_mercadoria`, `venda`.

## 2. Estrutura da planilha `base_teste.xlsx`

| Aba | Linhas | Colunas (tipo na planilha) |
|---|---|---|
| fornecedor | 20 | idfornecedor (texto `F1`..`F20`), razao_social |
| produtos_filial | 20 | filial_id, **idproduto** (texto), descricao, estoque, preco_unitario, preco_compra, preco_venda, idfornecedor (texto `F8`...) |
| pedido_compra | 29 | pedido_id, data_pedido, item, produto_id, descricao_produto, ordem_compra, qtde_pedida, filial_id, data_entrega, qtde_entregue, preco_compra, fornecedor_id (inteiro 1..20) + **colunas M:W soltas** (ver 4.7) |
| entradas_mercadoria | 20 | data_entrada, nro_nfe, item, produto_id, descricao_produto, ordem_compra, qtde_recebida, filial_id, custo_unitario |
| venda | 33 | venda_id, data_emissao, horariomov, produto_id, qtde_vendida (há decimais), valor_unitario, filial_id, item, unidade_medida |

A planilha **não tem** `qtde_pendente` (o DDL tem) e a coluna de produto em `produtos_filial` se chama `idproduto`, mas o DDL chama `produto_id`.

## 3. Resultado da carga (conferência `COUNT(*)` x planilha)

```
tabela                 planilha   banco  status
fornecedor                   20      20  OK
produtos_filial              20      20  OK
pedido_compra                29      29  OK
entradas_mercadoria          20      20  OK
venda                        33      33  OK
```
O script compara sozinho planilha x banco e termina com erro se algo divergir. A conferência de valores também foi feita: vendas de fevereiro = 14 linhas, quantidade 173,22, **R$ 14.093,17** (banco e pandas coincidem).

## 4. Erros encontrados e correções

### 4.1 DDL do enunciado (`sql/01_ddl_enunciado.sql`) rodado no PostgreSQL
Resultado: só `venda` e `pedido_compra` foram criadas; as outras 3 falharam.

| # | Erro | Mensagem / efeito | Correção |
|---|---|---|---|
| D1 | `entradas_mercadoria`: a PK cita `ordem_compra`, mas a coluna não existe | `column "ordem_compra" named in key does not exist` | coluna `ordem_compra INTEGER` criada (é o elo com o pedido) |
| D2 | `produtos_filial`: falta vírgula antes do `CONSTRAINT` | `syntax error at or near "("` | vírgula incluída |
| D3 | `produtos_filial`: PK usa `idproduto`, que não existe (a coluna é `produto_id`) | idem | PK `(filial_id, produto_id)` |
| D4 | typos `decricao` e `idfonecedor` (e `idforncedor` em fornecedor) | o script e a planilha usam `descricao`/`idfornecedor` | nomes corrigidos |
| D5 | `fornecedor`: PK `(idforncedor, idproduto)`, coluna inexistente e chave composta sem sentido | `column "idproduto" ... does not exist` | PK só em `idfornecedor` |
| D6 | `filial_id int4 NULL` dentro de PK em `produtos_filial` | PK exige NOT NULL | `NOT NULL` |
| D7 | `fornecedor.idforncedor` é **varchar**, mas `pedido_compra.fornecedor_id` e `produtos_filial.idfonecedor` são **int4**: impossível relacionar | | `idfornecedor INTEGER`; na carga `F8` vira `8` |
| D8 | `pedido_id`, `item`, `ordem_compra` como `float8` (ids e chaves em ponto flutuante) | risco de `1.0000001 <> 1` | `INTEGER` |
| D9 | quantidades `float8` | aceita imprecisão; há quantidades fracionadas (38,6) | `NUMERIC(14,3)`; preços `NUMERIC(12,4)` |
| D10 | `qtde_pendente` armazenada à mão (podia ficar inconsistente) | | coluna **gerada**: `qtde_pedida - qtde_entregue` |
| D11 | nenhuma chave estrangeira | | FKs de `produtos_filial`, `pedido_compra` e `entradas_mercadoria` (ver nota abaixo) |
| D12 | PK da `venda` chamada `pk_consumo` (nome de outro sistema); `DEFAULT ''` em `produto_id` aceita produto vazio | | `pk_venda`; default removido |
| D13 | sintaxe só de PostgreSQL (`::character varying`, `public.`) não roda no MySQL | `ERROR 1064` | versão `01_ddl_mysql.sql` |

*Nota sobre FKs:* `venda` **não** recebeu FK para `produtos_filial` de propósito: a planilha tem vendas de produtos e filiais inexistentes (E1/E2). Com FK essas linhas seriam rejeitadas e sumiriam do relatório; sem FK elas entram e ficam listadas em `sql/04_validacao.sql`.

### 4.2 Script do estagiário (`scripts/importar.py` original)
Rodado contra o DDL original, imprimiu "N registros inseridos" para tabelas que nem existiam.

| # | Erro | Consequência | Correção |
|---|---|---|---|
| S1 | `excel_para_data` trata a data como número serial do Excel, mas o pandas já entrega `Timestamp`; `int(Timestamp)` dá `TypeError` capturado por `except:` | **toda data vira NULL** (e `venda.data_emissao` é NOT NULL: nenhuma venda entraria) | `pd.Timestamp(v).date()` |
| S2 | `conn.rollback()` dentro do loop após cada erro | desfaz **todas** as linhas boas ainda não commitadas da tabela | carga tudo-ou-nada por tabela, com `commit`/`rollback` por tabela e saída com erro |
| S3 | imprime `len(df)` como "registros inseridos" | mostra sucesso mesmo com 0 linhas | conta com `SELECT COUNT(*)` e compara com a planilha |
| S4 | `ON CONFLICT ... DO NOTHING` em tudo | duplicidades e perdas ficam silenciosas | removido (erro explícito) |
| S5 | `except:` sem tipo e `print` de erro e `continue` | erros engolidos | exceções específicas e abort |
| S6 | `df.iloc[:, :12]` e renomear colunas na marra em `pedido_compra` | descarta sem aviso as colunas M:W com dados | aviso listando as colunas ignoradas |
| S7 | usa `row["descricao"]`/`idfornecedor` que não batiam com o DDL; `idfornecedor` texto `F8` em coluna int | `Erro ...` em toda linha | nomes alinhados; `F8` -> `8` |
| S8 | senha `1234` e banco `postgres` fixos no código; comentário diz MySQL na porta "3006" (é **3306**) | vazamento de credencial | variáveis de ambiente |
| S9 | só PostgreSQL (psycopg2) | o trabalho pede também MySQL | `--engine mysql` |

### 4.3 Erros nos dados (resumo; catálogo completo com consultas em `sql/04_validacao.sql`)
E1 a E17 (vendas de produtos e filiais inexistentes, pedidos sem `ordem_compra`, datas invertidas, recebido maior que o pedido, fornecedor do pedido diferente do cadastro, três custos diferentes, preço de venda abaixo do custo etc.). Os dados **não foram alterados**: ficam como o cliente enviou e os problemas são apontados, pois corrigir "no chute" falsearia os números do cliente.

### 4.4 Tratamentos aplicados na carga
- **Tipos:** datas para `DATE`; inteiros para `INTEGER`; decimais para `NUMERIC`; `NaN` para `NULL`.
- **Normalização:** `TRIM` nos textos; `F8` -> `8` em `fornecedor.idfornecedor` e `produtos_filial.idfornecedor` (necessário para o `idfornecedor` numérico da Parte 3).
- **Validação:** contagem planilha x banco por tabela; totais de fevereiro conferidos com pandas.
- **Colunas M:W de `pedido_compra`:** ignoradas com aviso. Parecem sobra de uma colagem: nas linhas dos pedidos 21 a 29 repetem os dados do pedido original (ex.: pedido 21 traz de novo o P12 com qtde 91 e entregue 48). Pergunta para o cliente.
