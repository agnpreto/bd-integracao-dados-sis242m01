# Parte 1: Documentação do processo de importação

## Ferramenta utilizada

Utilizou-se o **DBeaver** para administração dos bancos de dados (PostgreSQL e MySQL) e execução dos scripts DDL, em conjunto com o script Python (`scripts/importar.py`) utilizando as bibliotecas `pandas`, `openpyxl` e `psycopg2` para leitura das 5 abas de `dados/base_teste.xlsx` e carga no PostgreSQL.

## Estrutura da planilha

| Aba | Coluna | Tipo | Observação |
| :--- | :--- | :--- | :--- |
| fornecedor | idfornecedor, razao_social | Texto (VARCHAR) | Cadastro de fornecedores (20 linhas) |
| produtos_filial | filial_id, idproduto, descricao, estoque, preco_unitario, preco_compra, preco_venda, idfornecedor | Inteiro, Texto e Decimal | Cadastro de produtos e estoque por filial (20 linhas) |
| pedido_compra | pedido_id, data_pedido, item, produto_id, descricao_produto, ordem_compra, qtde_pedida, filial_id, data_entrega, qtde_entregue, preco_compra, fornecedor_id | Numérico, Data e Texto | Pedidos de compra emitidos aos fornecedores (29 linhas) |
| entradas_mercadoria | data_entrada, nro_nfe, item, produto_id, descricao_produto, ordem_compra, qtde_recebida, filial_id, custo_unitario | Data, Texto e Numérico | Notas fiscais de entrada vinculadas por `ordem_compra` (20 linhas) |
| venda | venda_id, data_emissao, horariomov, produto_id, qtde_vendida, valor_unitario, filial_id, item, unidade_medida | Inteiro, Data, Hora, Texto e Numérico | Histórico de vendas realizadas pelas filiais (33 linhas) |

## Erros encontrados no DDL e como foram corrigidos

| Tabela | Erro | Correção |
| :--- | :--- | :--- |
| entradas_mercadoria | A chave primária referenciava a coluna `ordem_compra`, que não existia na definição da tabela. | Adicionada a coluna `ordem_compra float8 DEFAULT 0 NOT NULL` na tabela. |
| produtos_filial | Falta de vírgula após `idfornecedor int4 NULL`, coluna `filial_id` permitindo `NULL` sendo parte da PK, erro de digitação em `decricao` e PK citando `idproduto` em vez de `produto_id`. | Adicionada a vírgula, definido `filial_id NOT NULL`, corrigido o nome para `descricao`, ajustada a PK para `(filial_id, produto_id)` e alterado `idfornecedor` para `varchar(25)`. |
| fornecedor | Erro de digitação na coluna `idforncedor` e PK composta citando coluna inexistente `idproduto`. | Renomeada a coluna para `idfornecedor` e ajustada a PK para `PRIMARY KEY (idfornecedor)`. |

## Erros encontrados no script de importação e como foram corrigidos

| Erro | Efeito | Correção |
| :--- | :--- | :--- |
| Conversão restrita em `excel_para_data` | A função tentava converter qualquer valor via `int(valor)`, retornando `None` caso o `pandas` já lesse a célula como `datetime` ou string. | Atualizada a função para tratar objetos `datetime`/`Timestamp`, números seriais do Excel e strings de data. |
| Contagem incorreta de registros inseridos | O script exibia `len(df)` no final de cada tabela, mesmo quando linhas eram ignoradas por conflito de PK (`ON CONFLICT DO NOTHING`) ou erro. | Adicionado contador `inseridos += cur.rowcount` para exibir o total real inserido no banco. |

## Tratamentos aplicados aos dados

Foram aplicados `strip()` nos cabeçalhos e valores textuais para remover espaços em branco extras, conversão padronizada de datas via `excel_para_data()`, substituição de valores nulos (`NaN`) por `0` ou `None` conforme a coluna, e cálculo automático do campo `qtde_pendente = qtde_pedida - qtde_entregue` na tabela `pedido_compra`.

## Conferência final

| Tabela | Linhas na planilha | Linhas no banco |
| :--- | :--- | :--- |
| fornecedor | 20 | 20 |
| produtos_filial | 20 | 20 |
| pedido_compra | 29 | 29 |
| entradas_mercadoria | 20 | 20 |
| venda | 33 | 33 |