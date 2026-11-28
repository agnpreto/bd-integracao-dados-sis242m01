# Parte 1: Documentação do processo de importação

Autor: Franklin Mendonça | Disciplina: Banco de Dados (SIS242M01)

## Ferramenta utilizada

- **Banco:** PostgreSQL 16 (DDL em `sql/01_ddl_postgres.sql`). Há também a versão MySQL 8 em `sql/01_ddl_mysql.sql`, que **não foi executada em servidor MySQL**; só o PostgreSQL foi testado.
- **Importação:** script Python `scripts/importar.py` (pandas + psycopg2), corrigido a partir do script do estagiário. Foi preciso corrigir porque a versão original deixava `venda` e `pedido_compra` com **0 linhas** e ainda imprimia "Importação concluída com sucesso". (DBeaver continua sendo uma alternativa, mas os mesmos tratamentos abaixo teriam de ser feitos à mão.)
- **Como rodar:** `psql -f sql/01_ddl_postgres.sql`, depois definir `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` e rodar `python scripts/importar.py`. A senha vem de variável de ambiente, nunca do código.

## Estrutura da planilha

Arquivo `dados/base_teste.xlsx`, 5 abas.

| Aba | Coluna | Tipo (no banco) | Observação |
| --- | --- | --- | --- |
| venda (33 linhas) | venda_id | bigint | |
| | data_emissao | date | |
| | horariomov | varchar(8) | texto `08:00:00` |
| | produto_id | varchar(25) | P1 a P28 (P21 a P28 não existem no cadastro) |
| | qtde_vendida | double | 5 linhas fracionadas em unidade UN |
| | valor_unitario | numeric(12,4) | |
| | filial_id | bigint | 1, 2 ou 3 |
| | item | int | |
| | unidade_medida | varchar(3) | sempre UN |
| pedido_compra (29 linhas) | pedido_id, data_pedido, item, produto_id, descricao_produto, ordem_compra, qtde_pedida, filial_id, data_entrega, qtde_entregue, preco_compra, fornecedor_id | bigint, date, int, varchar(25), varchar(255), bigint, double, int, date, double, double, varchar(25) | 12 colunas com cabeçalho. **Não tem `qtde_pendente`** (existe no DDL). `fornecedor_id` vem como número (1 a 20). Há mais 11 colunas **sem cabeçalho** (M:W), preenchidas em 9 linhas |
| entradas_mercadoria (20 linhas) | data_entrada, nro_nfe, item, produto_id, descricao_produto, ordem_compra, qtde_recebida, filial_id, custo_unitario | date, varchar(255), int, varchar(25), varchar(255), bigint, double, int, numeric(12,4) | `ordem_compra` liga a entrada ao pedido |
| produtos_filial (20 linhas) | filial_id, **idproduto**, descricao, estoque, preco_unitario, preco_compra, preco_venda, idfornecedor | int, varchar(255), varchar(255), double, double, double, double, varchar(25) | a coluna se chama `idproduto` na planilha e `produto_id` no DDL; `idfornecedor` é texto (F1 a F20) |
| fornecedor (20 linhas) | idfornecedor, razao_social | varchar(25), varchar(255) | códigos F1 a F20 |

## Erros encontrados no DDL e como foram corrigidos

Rodei o `sql/01_ddl_enunciado.sql` no PostgreSQL 16. Resultado: só `venda` e `pedido_compra` foram criadas; as outras três falharam.

| Tabela | Erro | Correção |
| --- | --- | --- |
| entradas_mercadoria | `ordem_compra` está na PK mas não foi declarada (`column "ordem_compra" named in key does not exist`) | declarada `ordem_compra bigint NOT NULL DEFAULT 0` |
| produtos_filial | falta vírgula antes da CONSTRAINT (`syntax error at or near "("`) | vírgula adicionada |
| produtos_filial | PK usa `idproduto`, a coluna é `produto_id` | PK `(filial_id, produto_id)`, também `NOT NULL` em `filial_id` |
| fornecedor | PK usa `idproduto`, que não existe na tabela | PK apenas em `idfornecedor` |
| fornecedor | `idforncedor` escrito errado | `idfornecedor` |
| produtos_filial | `decricao` escrito errado | `descricao` |
| produtos_filial | `idfonecedor` escrito errado | `idfornecedor` |
| fornecedor / pedido_compra / produtos_filial | fornecedor é `varchar(25)` numa tabela e `int4` nas outras, mas a planilha tem códigos F1..F20 | `varchar(25)` nas três |
| pedido_compra, entradas_mercadoria | (melhoria minha, não é erro de sintaxe) `pedido_id`, `item` e `ordem_compra` eram `float8` e são chaves; igualdade em float é frágil e a junção por `ordem_compra` depende dela | `bigint`/`integer` |
| pedido_compra, produtos_filial | (melhoria) sem relacionamento declarado com fornecedor | chaves estrangeiras para `fornecedor` |

Não criei FK de `venda` para `produtos_filial` de propósito: a planilha tem vendas de produtos não cadastrados e a FK esconderia o problema em vez de mostrá-lo (ver `docs/parte4_validacao.md`).

## Erros encontrados no script de importação e como foram corrigidos

Rodei o `importar.py` original contra o DDL já corrigido (mudando só a porta e o banco para o meu ambiente de teste).

| Erro | Efeito | Correção |
| --- | --- | --- |
| `excel_para_data` faz `int(valor)`, mas o pandas já entrega `Timestamp`; o `except` engole o `TypeError` e devolve `None` | **todas as datas viraram NULL** (`entradas_mercadoria`: 0 de 20 com data). Em `venda`, `data_emissao` é NOT NULL, então as 33 vendas foram rejeitadas | `para_data` aceita Timestamp/datetime/date e serial do Excel; valor inválido gera erro em vez de NULL |
| `except` + `conn.rollback()` dentro do laço, com o `commit()` só depois | cada erro desfaz também as linhas boas anteriores da tabela | tudo numa única transação; erro aborta e faz rollback total |
| contagem impressa é `len(df)` (planilha), não o que entrou | o script dizia "N registros inseridos" com 0 no banco | contagem lida do banco com `COUNT(*)` e comparada com a planilha; diferença aborta |
| `ON CONFLICT DO NOTHING` | duplicidade de chave some sem aviso | removido, o erro aparece |
| `fornecedor_id` lido como `int` (1, 2...) | não casa com `fornecedor` (F1, F2...); com FK, **todos os 29 pedidos falharam** (`Key (fornecedor_id)=(1) is not present in table "fornecedor"`) | convertido para `F<n>` |
| `df.iloc[:, :12]` cortava as colunas extras em silêncio | as 11 colunas sem cabeçalho (M:W) eram descartadas sem aviso | continuo ignorando-as, mas agora o script avisa quantas linhas têm conteúdo ali |
| usava `decricao`/`idfonecedor` do DDL com erro e `row["idproduto"]` | quebrava com o DDL original | colunas padronizadas; `idproduto` renomeado para `produto_id` |
| senha `1234` escrita no código; comentário diz MySQL na porta "3006" (é 3306) | contraria a regra de não versionar senha | variáveis de ambiente `PG*` |
| rodar duas vezes duplicava ou falhava | não dava para reimportar | `TRUNCATE` das 5 tabelas no início da transação |

## Tratamentos aplicados aos dados

- **Datas:** `Timestamp` do pandas convertido para `date`.
- **Textos:** `strip()` em todos os campos de texto.
- **Tipos:** ids e `item` para inteiro; quantidades e preços para decimal. Campos nulos usam o default do DDL (0 ou `00:00:00`).
- **fornecedor_id** de `pedido_compra`: número vira código `F<n>`. Isso assume que o fornecedor 1 da planilha é o `F1`; **a confirmar com o cliente** (ver erro E03 na Parte 4).
- **qtde_pendente** (não existe na planilha): calculada como `qtde_pedida - qtde_entregue`.
- **Colunas M:W de `pedido_compra`:** ignoradas. Elas parecem uma cópia desalinhada dos pedidos 12 a 20 (com ordem_compra 12 a 20) colada nas linhas dos pedidos 21 a 29. Não tenho como saber qual versão o cliente considera certa, então não misturei as duas; fica como pergunta para a reunião.
- **Nada foi "corrigido" nos valores** (ordem_compra 0, datas incoerentes, produtos sem cadastro): são erros do cliente e foram carregados como vieram, para serem listados e validados na Parte 4.

## Conferência final

Rodei o script corrigido duas vezes (a segunda para provar que reimporta sem duplicar). Datas NULL: 0 nas 3 tabelas que têm data (pedido_compra, entradas_mercadoria, venda).

| Tabela | Linhas na planilha | Linhas no banco |
| --- | --- | --- |
| fornecedor | 20 | 20 |
| produtos_filial | 20 | 20 |
| pedido_compra | 29 | 29 |
| entradas_mercadoria | 20 | 20 |
| venda | 33 | 33 |

Para conferir no seu banco: `SELECT 'venda', COUNT(*) FROM public.venda UNION ALL ...` (consulta A1 de `sql/04_validacao.sql`).
