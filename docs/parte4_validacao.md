# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

Autor: Franklin Mendonça | Consultas prontas em `sql/04_validacao.sql` (seções A, B e C).

Objetivo da reunião: o cliente sair sabendo (1) que os números do sistema batem com os dele, e (2) exatamente quais registros dele têm problema e precisam de uma decisão. Prefiro mostrar os erros do que escondê-los: um cliente que vê a lista, linha por linha, confia mais no resultado final.

## 1. Pontos a validar

1. **Volume carregado:** 20 fornecedores, 20 produtos, 29 pedidos, 20 entradas e 33 vendas, o mesmo que a planilha enviada (consulta A1).
2. **Totais de fevereiro/2025 que ele reconhece.** Vendas: 14 linhas, 14 produtos, 173,22 unidades e **R$ 14.093,17** (A2). Pedidos e entradas do mês (A3). Os valores de vendas também foram conferidos direto na planilha, fora do banco, e batem.
3. **Escopo do mês:** a base de teste tem 19 vendas fora de fevereiro (12 em janeiro, 7 em março, consulta A4/E16). Confirmar que foram enviadas de propósito e que o relatório de fevereiro deve ignorá-las.
4. **Regra de ligação pedido x entrada:** o vínculo é `ordem_compra`. Perguntar o que significa `ordem_compra = 0` (E01) e se os pedidos 19 e 20 já foram recebidos (as notas NFE19 e NFE20 existem, E06).
5. **Definições de negócio** que mudam o resultado: o que é "requisitado e não recebido" (nenhuma entrada ou entrada menor que o pedido?) e o que é "requisitado mais de 10 vezes" (número de pedidos ou quantidade?). Na Parte 3 usei quantidade somada; por número de pedidos a lista vem vazia.
6. **Cadastros:** produtos P21 a P28 vendidos mas ausentes do cadastro (E10); filiais 2 e 3 sem nenhum produto cadastrado (E11); fornecedor do pedido x fornecedor do cadastro do produto (E03); unidade UN com quantidade fracionada (E12).
7. **Conteúdo sem cabeçalho** nas colunas M:W de `pedido_compra` (9 linhas): qual das duas versões dos pedidos 21 a 29 vale.
8. **Preços e custos:** margem negativa em 4 produtos (E15), preço vendido diferente do cadastro (E13), custo da nota diferente do preço do pedido (E08).

## 2. Técnicas para garantir exatidão e precisão

- **Reconciliação de totais** (contagem, soma de quantidade, soma de R$) entre planilha e banco, com a conta feita por duas ferramentas diferentes (SQL e pandas). Divergência de um centavo já vale investigação.
- **Contagem por tabela antes e depois** da carga, dentro da própria transação de importação: se não bate, nada é gravado.
- **Carga sem ocultar erro:** sem `ON CONFLICT DO NOTHING`, sem `try/except` silencioso. Nenhum valor foi "consertado" na carga; o que está errado na origem aparece como erro.
- **Integridade referencial** (FKs para fornecedor) e chaves primárias, que impedem duplicidade.
- **Consultas de anomalia**, uma por regra de negócio (seção B/C do `04_validacao.sql`): datas incoerentes, quantidades acima do pedido, órfãos entre tabelas, duplicidades.
- **Amostragem manual:** o cliente escolhe 5 vendas e 5 pedidos de fevereiro e confere na tela do sistema dele contra o banco, linha a linha.
- **Precisão numérica:** `valor_unitario` e `custo_unitario` são `numeric(12,4)`; `preco_compra` segue `double` como no enunciado (risco de erro de ponto flutuante, por isso as comparações de preço usam `ROUND(...,2)`). Arredondamento só na exibição.
- **Reexecução:** a carga é repetível (testei duas vezes) e dá o mesmo resultado, então uma correção do cliente pode ser recarregada na hora.

## 3. Consultas preparadas para a reunião

Todas em `sql/04_validacao.sql`, testadas no PostgreSQL 16.

| Seção | O que mostra |
| --- | --- |
| A1 | linhas por tabela |
| A2 | vendas de fevereiro por filial: linhas, produtos, quantidade e R$ (com total geral) |
| A3 | pedidos e entradas de fevereiro: linhas, quantidade e valor |
| A4 | vendas por mês (mostra o que está fora de fevereiro) |
| A5 | chaves duplicadas (esperado: nenhuma) |
| B | **resumo**: uma linha por erro (E01 a E16) com a quantidade |
| C | detalhe linha a linha de cada erro, para o cliente corrigir |

## Erros encontrados nos dados

Contagens obtidas rodando a consulta B de `sql/04_validacao.sql` na base importada. Coluna "Consulta" = trecho da seção C com o detalhe.

| Cod | Tabela | Problema | Quantidade | Consulta |
| --- | --- | --- | --- | --- |
| E01 | pedido_compra | `ordem_compra = 0` (pedidos 19 a 29): impede ligar à entrada | 11 | C, E01 |
| E02 | pedido_compra | `data_entrega` anterior a `data_pedido` | 20 | C, E02 |
| E03 | pedido_compra | fornecedor do pedido diferente do fornecedor do produto (assumindo 1 = F1) | 22 | C, E03 |
| E04 | entradas_mercadoria | quantidade recebida maior que a pedida | 7 | C, E04 |
| E05 | entradas_mercadoria | `data_entrada` anterior ao pedido de compra | 9 | C, E05 |
| E06 | entradas_mercadoria | entrada sem pedido ligado por `ordem_compra` (NFE19, NFE20) | 2 | C, E06 |
| E07 | pedido x entrada | `qtde_entregue` do pedido diferente da `qtde_recebida` da nota | 18 | C, E07 |
| E08 | pedido x entrada | `custo_unitario` da nota diferente do `preco_compra` do pedido | 18 | C, E08 |
| E09 | pedido_compra | pedidos 21 a 29 repetem produto e data dos pedidos 12 a 20 | 9 | C, E09 |
| E10 | venda | produto vendido que não está no cadastro (P21 a P28) | 13 vendas, 8 produtos | C, E10 |
| E11 | venda | filiais 2 e 3 não têm nenhum produto cadastrado | 4 | C, E11 |
| E12 | venda | quantidade fracionada em unidade `UN` (ex.: 38,6) | 5 | C, E12 |
| E13 | venda | `valor_unitario` diferente do `preco_venda` do cadastro | 20 | C, E13 |
| E14 | venda | mesmo `valor_unitario` em produtos diferentes (P13/P21, P14/P22...) | 8 valores | C, E14 |
| E15 | produtos_filial | `preco_compra` maior que `preco_venda` (margem negativa) | 4 | C, E15 |
| E16 | venda | vendas fora de fevereiro/2025 (informativo, não é erro) | 19 | C, E16 |

Problemas de **estrutura/origem** (não aparecem em consulta SQL, estão descritos em `docs/parte1_importacao.md`):

| Onde | Problema |
| --- | --- |
| planilha `pedido_compra` | 11 colunas sem cabeçalho (M:W) preenchidas em 9 linhas |
| planilha `pedido_compra` | falta a coluna `qtde_pendente` que o DDL espera |
| planilha `pedido_compra` | `fornecedor_id` numérico (1 a 20) enquanto `fornecedor` usa F1 a F20 |
| planilha `produtos_filial` | coluna chama `idproduto`, no DDL é `produto_id` |
| DDL do enunciado | 8 erros (sintaxe, nomes, PKs e tipos), corrigidos na Parte 1 |

Observações sobre a leitura dos números: E03, E07, E08, E13 e E14 podem ter parte de causa em **dados fictícios gerados em série** na base de teste (os valores parecem aleatórios entre as tabelas), mas, para um cliente real, cada um seria uma pergunta legítima. E03 depende da hipótese de que fornecedor 1 = F1, que o cliente precisa confirmar.
