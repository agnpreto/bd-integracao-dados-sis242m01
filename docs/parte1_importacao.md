# Parte 1: Documentação do processo de importação

## Ferramenta utilizada
- **SGBD:** PostgreSQL (base `integracao_dados`, esquema `public`), gerido via **DBeaver 26.2.4**.
- **Script de importação:** Python (`scripts/importar.py`) com `pandas`, `openpyxl` e `psycopg2`.

## Estrutura da planilha

| Aba | Coluna | Tipo | Observação |
| --- | --- | --- | --- |
| fornecedor | idfornecedor | Texto (`object`) | Identificador do fornecedor (ex.: `F1`) |
| fornecedor | razao_social | Texto (`object`) | Razão social do fornecedor |
| produtos_filial | filial_id | Inteiro (`int64`) | Identificador da filial |
| produtos_filial | idproduto | Texto (`object`) | Identificador do produto (ex.: `P1`) |
| produtos_filial | descricao | Texto (`object`) | Descrição do produto |
| produtos_filial | estoque | Inteiro (`int64`) | Quantidade em estoque |
| produtos_filial | preco_unitario | Decimal (`float64`) | Preço unitário |
| produtos_filial | preco_compra | Decimal (`float64`) | Preço de compra |
| produtos_filial | preco_venda | Decimal (`float64`) | Preço de venda |
| produtos_filial | idfornecedor | Texto (`object`) | Código do fornecedor (ex.: `F8`) |
| pedido_compra | pedido_id | Inteiro (`int64`) | Identificador do pedido |
| pedido_compra | data_pedido | Data (`datetime64`) | Data do pedido |
| pedido_compra | item | Inteiro (`int64`) | Número do item no pedido |
| pedido_compra | produto_id | Texto (`object`) | Identificador do produto |
| pedido_compra | descricao_produto | Texto (`object`) | Descrição do produto |
| pedido_compra | ordem_compra | Inteiro (`int64`) | Ligação com `entradas_mercadoria` |
| pedido_compra | qtde_pedida | Inteiro (`int64`) | Quantidade solicitada |
| pedido_compra | filial_id | Inteiro (`int64`) | Identificador da filial |
| pedido_compra | data_entrega | Data (`datetime64`) | Data prevista/de entrega |
| pedido_compra | qtde_entregue | Inteiro (`int64`) | Quantidade entregue |
| pedido_compra | preco_compra | Decimal (`float64`) | Preço unitário de compra |
| pedido_compra | fornecedor_id | Inteiro (`int64`) | Identificador numérico do fornecedor |
| pedido_compra | Unnamed: 12 .. Unnamed: 22 | Vários (`datetime64`, `float64`, `object`) | Colunas extras/desalinhadas fora do cabeçalho principal (9 linhas preenchidas) |
| entradas_mercadoria | data_entrada | Data (`datetime64`) | Data de entrada da mercadoria |
| entradas_mercadoria | nro_nfe | Texto (`object`) | Número da nota fiscal (ex.: `NFE1`) |
| entradas_mercadoria | item | Inteiro (`int64`) | Número do item |
| entradas_mercadoria | produto_id | Texto (`object`) | Identificador do produto |
| entradas_mercadoria | descricao_produto | Texto (`object`) | Descrição do produto |
| entradas_mercadoria | ordem_compra | Inteiro (`int64`) | Chave de ligação ao pedido de compra |
| entradas_mercadoria | qtde_recebida | Inteiro (`int64`) | Quantidade recebida |
| entradas_mercadoria | filial_id | Inteiro (`int64`) | Identificador da filial |
| entradas_mercadoria | custo_unitario | Decimal (`float64`) | Custo unitário |
| venda | venda_id | Inteiro (`int64`) | Identificador da venda |
| venda | data_emissao | Data (`datetime64`) | Data de emissão da venda |
| venda | horariomov | Texto (`object`) | Horário do movimento (ex.: `08:00:00`) |
| venda | produto_id | Texto (`object`) | Identificador do produto |
| venda | qtde_vendida | Decimal (`float64`) | Quantidade vendida |
| venda | valor_unitario | Decimal (`float64`) | Valor unitário de venda |
| venda | filial_id | Inteiro (`int64`) | Identificador da filial |
| venda | item | Inteiro (`int64`) | Número do item na venda |
| venda | unidade_medida | Texto (`object`) | Unidade de medida (ex.: `UN`) |

## Erros encontrados no DDL e como foram corrigidos

| Tabela | Erro | Correção |
| --- | --- | --- |
| produtos_filial | Divergência no nome da coluna do produto (`idproduto` na planilha vs. `produto_id` no script) e tipo/chave do fornecedor (`VARCHAR` com códigos como `F8` na planilha). | Padronização do nome da coluna e do tipo de `idfornecedor` no DDL corrigido (`sql/01_ddl_postgres.sql` e `sql/01_ddl_mysql.sql`) para compatibilidade com os dados da planilha. |
| pedido_compra | Ausência da coluna `qtde_pendente` na origem e necessidade de chaves/tipos compatíveis com valores numéricos e datas. | Inclusão/manutenção de `qtde_pendente` com `DEFAULT 0` e ajuste dos tipos de colunas e chaves primárias no DDL. |

## Erros encontrados no script de importação e como foram corrigidos

| Erro | Efeito | Correção |
| --- | --- | --- |
| Nome do banco incorreto (`"database": "postgres"`) na configuração `DB` e erro `UnicodeDecodeError` (`0xe7`) ao conectar no Windows. | Falha de conexão ao tentar gravar na base `integracao_dados` e interrupção do script antes da importação. | Alteração de `database` para `"integracao_dados"` e ajuste de credenciais/codificação (`PGCLIENTENCODING=WIN1252` no ambiente Windows). |
| Colunas extras (`Unnamed: 12` a `Unnamed: 22`) na aba `pedido_compra`. | Sobrecarga de colunas inesperadas ao ler a aba com `pandas.read_excel`. | Recorte das 12 primeiras colunas (`df.iloc[:, :12]`) e renomeação explícita dos cabeçalhos antes do `INSERT`. |
| Nome de coluna `produto_id` em `produtos_filial` diferente do esquema (`idproduto`) e `excel_para_data` chamando `int(valor)` em objetos `Timestamp`. | Risco de erro de coluna inexistente ou perda de datas já convertidas pelo `pandas`. | Alinhamento do nome da coluna `idproduto` no `INSERT`/`ON CONFLICT` e tratamento de `datetime`/`pd.Timestamp` na função `excel_para_data`. |

## Tratamentos aplicados aos dados

- **Remoção de espaços:** aplicação de `.strip()` nos nomes de colunas e valores textuais (`idfornecedor`, `razao_social`, `idproduto`/`produto_id`, `nro_nfe`, `horariomov`, `unidade_medida`).
- **Conversão de tipos e datas:** conversão de datas para o tipo `DATE` (`excel_para_data` tratando `NaN`/`NaT`, `Timestamp`/`datetime` e seriais numéricos), numéricos para `int`/`float` e preenchimento de valores nulos com padrões (`0` ou `'00:00:00'`) onde aplicável.
- **Cálculo derivado e idempotência:** cálculo de `qtde_pendente` em `pedido_compra` (`qtde_pedida - qtde_entregue`) e uso de `ON CONFLICT ... DO NOTHING` com `conn.rollback()` por linha em caso de falha isolada.

## Conferência final

| Tabela | Linhas na planilha | Linhas no banco |
| --- | --- | --- |
| fornecedor | 20 | [PREENCHER COM SELECT COUNT(*)] |
| produtos_filial | 20 | [PREENCHER COM SELECT COUNT(*)] |
| pedido_compra | 29 | [PREENCHER COM SELECT COUNT(*)] |
| entradas_mercadoria | 20 | [PREENCHER COM SELECT COUNT(*)] |
| venda | 33 | [PREENCHER COM SELECT COUNT(*)] |
