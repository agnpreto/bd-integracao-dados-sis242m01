# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

- **Importação:** script Python `scripts/importar.py`, a versão corrigida do script do estagiário. Usa `pandas` e `openpyxl` para ler a planilha `dados/base_teste.xlsx`, `psycopg2` para gravar no PostgreSQL e `pymysql` para gravar no MySQL.
- **Bancos:** PostgreSQL local (versão 18.x) como banco principal, que é onde o README manda rodar o DDL. O DDL do MySQL (`sql/01_ddl_mysql.sql`) também foi escrito e usa só sintaxe comum ao MySQL 8 e ao MariaDB 10.11, onde foi executado sem erros.
- **VS Code** (extensão PostgreSQL): para rodar o DDL e as consultas e para conferir as contagens com `SELECT COUNT(*)`.
- **Claude Code:** refatoração, revisão e ambiente para executar os aquivos MySQL.
- **Copilot CLI:** debug.
- **Por que um script e não um assistente visual de importação:** a planilha tem problemas que um assistente visual não trata sozinho (ids de fornecedor com prefixo `F`, colunas sem cabeçalho, coluna `qtde_pendente` que não existe na planilha). O script faz esses tratamentos sempre do mesmo jeito, relata cada linha rejeitada e confere o resultado no banco, o que deixa o processo repetível e auditável.

Para reproduzir (a partir da raiz do repositório; a senha nunca fica no código):

```
pip install pandas openpyxl psycopg2-binary pymysql
set DB_PASSWORD=sua_senha            (PowerShell: $env:DB_PASSWORD="sua_senha")
set DB_NAME=teste
python scripts/importar.py --limpar
```

## Estrutura da planilha

A planilha tem 5 abas. Os tipos abaixo são os que a planilha realmente traz; a coluna Observação diz o que foi verificado e o tipo usado no banco.

| Aba | Coluna | Tipo | Observação |
| --- | --- | --- | --- |
| venda | venda_id | inteiro | 1 a 33, sem repetição. Faz parte da PK. |
| venda | data_emissao | data | Data real do Excel (não é texto). De 03/01/2025 a 28/03/2025; 14 vendas em fevereiro. |
| venda | horariomov | texto | Todas as 33 linhas têm `08:00:00`. |
| venda | produto_id | texto | P1 a P28. Os produtos P21 a P28 não existem em `produtos_filial`. |
| venda | qtde_vendida | decimal | 1 a 90. Cinco valores fracionados com unidade UN (ex.: 38,6). |
| venda | valor_unitario | decimal | 14,41 a 197,61. Vai para `numeric(12,4)`. |
| venda | filial_id | inteiro | 1, 2 e 3. Só a filial 1 tem produtos cadastrados. |
| venda | item | inteiro | Sempre 1. |
| venda | unidade_medida | texto | Sempre `UN`. |
| pedido_compra | pedido_id | inteiro | 1 a 29, sem repetição. |
| pedido_compra | data_pedido | data | De 02/01/2025 a 01/03/2025. |
| pedido_compra | item | inteiro | Sempre 1. |
| pedido_compra | produto_id | texto | P1 a P20. |
| pedido_compra | descricao_produto | texto | "Produto 1" a "Produto 20". |
| pedido_compra | ordem_compra | inteiro | 1 a 18 nos pedidos 1 a 18 e **0 nos pedidos 19 a 29**. É o vínculo com `entradas_mercadoria`. |
| pedido_compra | qtde_pedida | inteiro | 2 a 99. |
| pedido_compra | filial_id | inteiro | Sempre 1. |
| pedido_compra | data_entrega | data | De 01/01/2025 a 28/02/2025. |
| pedido_compra | qtde_entregue | inteiro | 0 a 91. |
| pedido_compra | preco_compra | decimal | 6,92 a 85,04. Vai para `numeric(12,4)`. |
| pedido_compra | fornecedor_id | inteiro | 1 a 20 (número, sem o prefixo `F`). |
| pedido_compra | (colunas M a W, sem cabeçalho) | misto | **99 células preenchidas nas linhas Excel 22 a 30**, 11 valores por linha. Parecem uma cópia dos pedidos de P12 a P20 com `qtde_pendente`. **Não foram importadas** (ver Tratamentos). |
| pedido_compra | qtde_pendente | não existe | Está no DDL (NOT NULL), mas não na planilha. É calculada: `qtde_pedida - qtde_entregue`. |
| entradas_mercadoria | data_entrada | data | De 01/01/2025 a 01/03/2025. |
| entradas_mercadoria | nro_nfe | texto | `NFE1` a `NFE20`. Faz parte da PK. |
| entradas_mercadoria | item | inteiro | Sempre 1. |
| entradas_mercadoria | produto_id | texto | P1 a P20. |
| entradas_mercadoria | descricao_produto | texto | "Produto 1" a "Produto 20". |
| entradas_mercadoria | ordem_compra | inteiro | 1 a 20. Liga a entrada ao pedido. Coluna que faltava no DDL do enunciado. |
| entradas_mercadoria | qtde_recebida | inteiro | 4 a 95. |
| entradas_mercadoria | filial_id | inteiro | Sempre 1. |
| entradas_mercadoria | custo_unitario | decimal | 10,32 a 98,99. |
| produtos_filial | filial_id | inteiro | Sempre 1. |
| produtos_filial | idproduto | texto | P1 a P20. No banco a coluna se chama `produto_id` (como no DDL). |
| produtos_filial | descricao | texto | "Produto 1" a "Produto 20". |
| produtos_filial | estoque | inteiro | 2 a 198. |
| produtos_filial | preco_unitario | decimal | 24,64 a 199,56. Vai para `numeric(12,4)`. |
| produtos_filial | preco_compra | decimal | 7,75 a 149,50. Vai para `numeric(12,4)`. |
| produtos_filial | preco_venda | decimal | 29,24 a 278,88. Vai para `numeric(12,4)`. |
| produtos_filial | idfornecedor | texto | `F1` a `F20` (17 distintos). **Texto com prefixo F**; no banco vira inteiro. |
| fornecedor | idfornecedor | texto | `F1` a `F20`. **Texto com prefixo F**; no banco vira inteiro. |
| fornecedor | razao_social | texto | "Fornecedor 1 LTDA" a "Fornecedor 20 LTDA". |

Nenhuma aba tem chave duplicada, valores negativos, espaços sobrando nas pontas ou células vazias (nas colunas com cabeçalho).

## Erros encontrados no DDL e como foram corrigidos

O DDL original foi executado no PostgreSQL e criou só 2 das 5 tabelas (venda e pedido_compra). Os três primeiros erros abaixo são os que o PostgreSQL acusou; os demais foram encontrados lendo o DDL contra a planilha e o enunciado.

| Tabela | Erro | Correção |
| --- | --- | --- |
| entradas_mercadoria | A PK usa `ordem_compra`, que não existe na tabela (`column "ordem_compra" named in key does not exist`). É justamente o campo que liga a entrada ao pedido. | Criada a coluna `ordem_compra` (`int8`, NOT NULL, padrão 0). |
| produtos_filial | Falta a vírgula depois de `idfonecedor int4 NULL` (`syntax error at or near "("`). | Vírgula incluída. |
| fornecedor | A PK usa `idproduto`, que não existe nessa tabela e não faz sentido para um fornecedor (`column "idproduto" named in key does not exist`). | PK passou a ser só `idfornecedor`. |
| produtos_filial | A PK usa `idproduto`, mas a coluna se chama `produto_id`. | PK `(filial_id, produto_id)`. |
| produtos_filial | `filial_id` é NULL, mas faz parte da PK. | `NOT NULL`. |
| produtos_filial | Erros de digitação: `decricao` e `idfonecedor`. | Renomeadas para `descricao` e `idfornecedor`. |
| fornecedor | Erro de digitação: `idforncedor`. | Renomeada para `idfornecedor`. |
| fornecedor, produtos_filial, pedido_compra | O mesmo conceito tem tipos incompatíveis: `varchar(25)` em `fornecedor`, `int4` em `produtos_filial` e `pedido_compra`. Não dá para relacionar as tabelas, e o PDF (Parte 3, item 4) pede um `idfornecedor` numérico. | `int4` nas três tabelas, com chaves estrangeiras para `fornecedor`. A planilha traz `F8`, então o importador remove o prefixo `F`. |
| pedido_compra | `fornecedor_id` tem `DEFAULT 0`, mas não existe fornecedor 0 (quebraria a chave estrangeira). | Padrão removido (a coluna aceita NULL). |
| pedido_compra, entradas_mercadoria | `pedido_id`, `item` e `ordem_compra` são `float8`, mas são identificadores. Comparar chaves em ponto flutuante é impreciso. | `int8` (`pedido_id`, `ordem_compra`) e `int4` (`item`). |
| pedido_compra, produtos_filial | Preços em `float8`, enquanto `venda.valor_unitario` e `entradas_mercadoria.custo_unitario` usam `numeric(12,4)` para o mesmo conceito. Float não representa centavos com exatidão. | `numeric(12,4)` em `preco_compra`, `preco_unitario` e `preco_venda`. |
| produtos_filial, venda, pedido_compra | `produto_id` é `varchar(255)` em uma tabela e `varchar(25)` nas outras. | Padronizado em `varchar(25)`. |
| venda | A constraint se chama `pk_consumo`, nome de outra coisa. | Renomeada para `pk_venda`. |
| todas | O enunciado não define nenhuma chave estrangeira. | Criadas as de `fornecedor` (de `produtos_filial` e `pedido_compra`). **Não** foram criadas para `venda` e `entradas_mercadoria`, porque os dados as violam (13 vendas de produtos sem cadastro e 2 entradas sem pedido); esses casos ficam documentados na Parte 4. |
| todas | O DDL usa sintaxe só do PostgreSQL (`::character varying`, `public.`), mas o PDF pede PostgreSQL **e** MySQL. | Criado `sql/01_ddl_mysql.sql` (BIGINT, INT, DOUBLE, DECIMAL; sem `public.` e sem os casts). |
| (texto do enunciado) | O texto fala em `vendas`, `pedidos_compra` e `produtos`, mas o DDL e a planilha usam `venda`, `pedido_compra` e `produtos_filial`. | Mantidos os nomes do DDL e da planilha, que são os mesmos usados no README. |

## Erros encontrados no script de importação e como foram corrigidos

O script original foi executado contra o DDL já corrigido (só a conexão foi trocada) e o resultado foi conferido com SELECT COUNT(*).

| Erro | Efeito | Correção |
| --- | --- | --- |
| `excel_para_data` faz `int(valor)`, mas o pandas já entrega a data como `Timestamp`; o `except:` genérico esconde o erro e devolve `None`. | **Todas as datas viram NULL**: `pedido_compra` (29 de 29) e `entradas_mercadoria` (20 de 20). Em `venda`, a data é NOT NULL, então as 33 linhas falham e a tabela fica com **0 linhas**. | Função `data()` aceita `Timestamp`, número serial do Excel e texto (`AAAA-MM-DD`, `DD/MM/AAAA`) e **levanta erro** se a data for inválida, em vez de engolir. |
| `conn.rollback()` dentro do loop, com `commit()` só no fim da tabela. | Um erro numa linha desfaz **todas as linhas boas anteriores** da tabela. Em teste: das linhas 1, 2, 4 e 5 (a 3 era inválida), ficaram só a 4 e a 5. | Um `SAVEPOINT` por linha: só a linha ruim é desfeita, e as boas são mantidas. |
| O contador imprime `len(df)` e a mensagem final é fixa ("concluída com sucesso"). | Imprime "33 registros inseridos em venda" com 0 linhas no banco. | Conta as inseridas e as rejeitadas, consulta `COUNT(*)` no banco, compara com a planilha e termina com código 1 se houver diferença. |
| `ON CONFLICT ... DO NOTHING` em todas as tabelas. | Linhas duplicadas são descartadas em silêncio. | Removido: uma linha duplicada é rejeitada e relatada com o número da linha do Excel. |
| `df.iloc[:, :12]` em `pedido_compra`. | Descarta sem avisar as 99 células das colunas M a W. | O script detecta colunas sem cabeçalho com dados e avisa (colunas e linhas Excel); não importa esses dados, e isso fica documentado. |
| O script usa nomes de coluna do DDL com erro (`idfornecedor`, `descricao`, `ordem_compra`). | Falha com "column does not exist" no DDL original. | Passa a ser coerente com o DDL corrigido. |
| `idfornecedor` é enviado como texto (`F8`) para uma coluna `int4`. | `invalid input syntax for type integer: "F8"` em todas as linhas. | Função `id_fornecedor()` remove o prefixo `F` e converte para inteiro. |
| Valores ausentes viram `0` (`else 0`). | Altera o dado em silêncio. | Valor ausente fica NULL e o banco decide (rejeita se a coluna for NOT NULL). |
| Senha escrita no código (`"1234"`). | O README proíbe senha no `importar.py`. | Lida da variável de ambiente `DB_PASSWORD`; o script avisa se ela não existir. |
| Só funciona com PostgreSQL; o comentário diz que a porta do MySQL é "3006". | Não serve para o MySQL que o PDF também pede. A porta correta é 3306. | `DB_ENGINE=postgres` ou `mysql`, com porta padrão correta para cada um. |
| O caminho `dados/base_teste.xlsx` só funciona se o script for chamado da raiz do repositório. | Falha ao rodar de outra pasta. | O caminho é relativo ao próprio script; também há a opção `--arquivo`. |

## Tratamentos aplicados aos dados

- **Leitura só do que tem cabeçalho.** As colunas M a W de pedido_compra (sem cabeçalho) são detectadas e **não importadas**, com aviso. Sete das nove linhas coincidem exatamente com os pedidos 12 a 18; as outras duas (P19 e P20) trazem ordem_compra 19 e 20, onde os pedidos normais têm 0. Só o cliente pode dizer qual é o dado correto (Parte 4).
- **Conversão de tipos.** Datas para DATE; identificadores para inteiro (o script recusa um "3,5" onde se espera um inteiro); quantidades para DOUBLE/float8; valores monetários para numeric(12,4); textos com espaços das pontas removidos.
- **Normalização do fornecedor.** F8 vira 8 em fornecedor e em produtos_filial, para ser numérico e poder se relacionar com pedido_compra.fornecedor_id. A coluna idproduto da planilha vira produto_id no banco.
- **Coluna calculada.** qtde_pendente não existe na planilha; é calculada como qtde_pedida - qtde_entregue.
- **Nada de preencher valor ausente com 0.** Valor ausente fica NULL e o banco aplica as regras (NOT NULL, PK, chaves estrangeiras). Cada linha rejeitada é relatada com o número da linha do Excel e o motivo.
- **Ordem de carga.** fornecedor, produtos_filial, pedido_compra, entradas_mercadoria, venda, para respeitar as chaves estrangeiras.
- **O que NÃO foi alterado.** Os problemas de negócio dos dados (venda de produto sem cadastro, ordem_compra = 0, quantidades e preços que não batem entre as abas) foram **mantidos como vieram** e documentados na Parte 4. Apagar ou "consertar" esses valores sem o cliente seria inventar dado. É também por isso que venda não tem chave estrangeira para produtos_filial.

## Conferência final

| Tabela | Linhas na planilha | Linhas no banco |
| --- | --- | --- |
| fornecedor | 20 | 20 |
| produtos_filial | 20 | 20 |
| pedido_compra | 29 | 29 |
| entradas_mercadoria | 20 | 20 |
| venda | 33 | 33 |

Além da contagem, o conteúdo foi comparado valor a valor com a planilha (1.025 células nas 5 tabelas, 0 diferenças). Saída final do `importar.py`:

```
CONFERENCIA FINAL (planilha x banco)
tabela                 planilha  inseridas  rejeitadas  no banco  situação
fornecedor                   20         20           0        20  OK
produtos_filial              20         20           0        20  OK
pedido_compra                29         29           0        29  OK
entradas_mercadoria          20         20           0        20  OK
venda                        33         33           0        33  OK

Importação concluída: todas as linhas da planilha estão no banco.
```

O aviso sobre as 99 células sem cabeçalho aparece antes dessa tabela, durante a importação de pedido_compra.
