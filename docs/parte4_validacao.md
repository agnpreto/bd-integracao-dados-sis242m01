# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

**Objetivo:** o cliente sair da reunião seguro de que os números de fevereiro/2025 no banco são os mesmos do sistema dele, sabendo o que foi tratado e o que depende de decisão dele.

**Participantes:** responsável por vendas, comprador/estoque, financeiro e TI do cliente. **Duração:** cerca de 60 min.

**Levar pronto:** `sql/04_validacao.sql` aberto no DBeaver; resultados exportados para Excel (no resultado: botão direito → *Export data* → XLSX); e pedir antes ao cliente o fechamento de fevereiro do sistema dele (caixa, compras, notas de entrada).

| Tempo | Assunto | Consultas |
| --- | --- | --- |
| 5 min | Como os dados foram carregados; nada se perdeu | A01 |
| 15 min | Vendas de fevereiro | A02, A03, A04, 2.1 |
| 15 min | Compras e recebimentos de fevereiro | A05, A06, 2.2 |
| 20 min | Erros encontrados: decisão do cliente para cada um | E01 a E22, R01 |
| 5 min | Pendências, responsáveis e aceite | ata |

## 1. Pontos a validar

**Números de fevereiro/2025 (resultado das consultas):**

| Indicador | Valor no banco | Consulta |
| --- | --- | --- |
| Vendas (linhas) | 14 | A02 |
| Quantidade vendida | 173,22 | A02 |
| Faturamento | **R$ 14.093,17** | A02 |
| Faturamento de produtos **sem cadastro** (P22 a P27) | R$ 3.241,24 (6 vendas, 23% do mês) | A04 |
| Faturamento da filial 2 (não existe no cadastro) | R$ 547,53 | A03 |
| Pedidos de compra emitidos | 17 pedidos, 619 unidades, R$ 28.396,93 | A05 |
| Recebido desses pedidos (pelas notas) | 375 unidades | A05 |
| Notas de entrada no mês | 10 notas, 468 unidades, R$ 36.722,92 | A06 |

**Perguntas para o cliente:**

1. **Faturamento:** R$ 14.093,17 em 14 vendas bate com o fechamento do caixa? Os dias com venda (7, 17, 18, 20, 22 e 28/02) estão corretos? (A02, A03)
2. **Produtos P21 a P28:** existem? Faltam no cadastro, ou são lançamentos indevidos? As 13 vendas desses produtos repetem o valor e a data de outras vendas (E15, E19). Se forem indevidas, o faturamento de fevereiro cai para R$ 10.851,94.
3. **Filiais 2 e 3:** existem? O cadastro de produtos só tem a filial 1. (E16)
4. **Unidade de medida:** vendas de 38,6 / 20,04 / 2,86 / 37,11 / 3,11 com unidade `UN`. O produto é vendido a granel (KG) ou a quantidade está errada? (E17)
5. **Horário:** todas as vendas estão às 08:00:00. O sistema não exporta a hora real? (E18)
6. **Preço:** o valor vendido difere mais de 20% do preço de cadastro em 18 vendas, e 4 produtos têm preço de venda menor que o de compra. Qual preço vale? E o que é `preco_unitario` no cadastro, diferente de compra e de venda? (E20, E21)
7. **Pedidos com `ordem_compra = 0`** (pedidos 19 a 29): qual é a ordem correta? Sem ela não dá para ligar o pedido à nota. As notas NFE19 e NFE20 (ordens 19 e 20) provavelmente são dos pedidos 19 e 20. (E05, E11)
8. **Pedidos 21 a 29:** são um segundo pedido (complemento) dos produtos P12 a P20, ou linhas duplicadas? Eles repetem data, entrega, preço e fornecedor dos pedidos 12 a 20. (E06)
9. **Colunas extras na planilha** (linhas 22 a 30): trazem uma cópia dos pedidos originais com `qtde_pendente`. Para os pedidos 19 e 20, essa cópia diverge (ordem 19/20 em vez de 0; quantidade 40 e 86 em vez de 20 e 25; entregue 78 em vez de 0). Qual versão vale? (E01, E07)
10. **Fonte da verdade do recebido:** `qtde_entregue` do pedido não bate com as notas em 18 de 18 pedidos. Nossa proposta é usar as notas (entradas). (E09)
11. **Datas:** 20 pedidos com entrega antes do pedido e 9 notas antes do pedido. Datas trocadas na digitação? (E08, E12)
12. **Recebimento acima do pedido** (7 notas) e **custo da nota** muito diferente do preço do pedido (16 notas): aceitos? (E13, E14)
13. **Fornecedores:** o fornecedor do pedido é diferente do fornecedor do produto em 22 pedidos. Qual cadastro está certo? F14, F15 e F16 não têm produto. (E10, E22)
14. **Requisitados e não recebidos:** validar a lista da consulta 2.2 com o comprador. São 21 itens: 11 sem nota (todos com `ordem_compra = 0`) e 10 recebidos em parte.

## 2. Técnicas para garantir exatidão e precisão

| Técnica | Como foi aplicada |
| --- | --- |
| Cópia fiel da origem | A planilha fica no schema `stg`, como texto, com o número da linha do Excel. Qualquer número do banco é rastreável até a célula |
| Reconciliação de contagem | Planilha × banco por tabela: 20/20/29/20/33, sem perda (A01) |
| Totais de controle | Quantidade, faturamento e nº de vendas comparados com o fechamento do sistema do cliente (A02, A05, A06) |
| Reconciliação em níveis | Total do mês → por filial → por dia → por produto (A03, 2.1) |
| Amostragem | O cliente escolhe algumas vendas/pedidos no sistema dele e conferimos campo a campo no banco |
| Integridade referencial | PK em todas as tabelas, FK com fornecedor, consultas de órfãos (E11, E15, E16) |
| Tipos corretos | `numeric` em vez de `float` (sem erro de centavos), `date` e `time` em vez de texto, `bigint` nas chaves |
| Regras cruzadas | Entregue × notas (E09), datas pedido × entrega × nota (E08, E12), recebido × pedido (E13), preço × custo (E14, E20, E21) |
| Detecção de cópia/duplicidade | Pedidos repetidos (E06), vendas copiadas (E19) |
| Filtro de período correto | `data >= '2025-02-01' AND data < '2025-03-01'`: inclui o dia 28 inteiro e usa o índice |
| Log de carga | `importacao_rejeicoes`: nenhuma linha descartada sem motivo |
| Reprodutibilidade | DDL → `importar.py` → consultas rodam de novo do zero. A carga é transacional |
| Dois bancos | Mesmas contagens no PostgreSQL e no MySQL |
| Não "corrigir" sem o cliente | Valores suspeitos foram carregados como vieram e são apresentados para decisão |

## 3. Consultas preparadas para a reunião

Todas estão em `sql/04_validacao.sql` (e as da Parte 2 em `sql/02_consultas.sql`).

| ID | O que mostra |
| --- | --- |
| A01 | Linhas na planilha × no banco, por tabela |
| A02 | Fevereiro: nº de vendas, produtos, quantidade, faturamento, 1ª e última data |
| A03 | Fevereiro: vendas e faturamento por filial e por dia, com subtotais (ROLLUP) |
| A04 | Fevereiro: faturamento de produtos com e sem cadastro |
| A05 | Fevereiro: pedidos emitidos, quantidade pedida × recebida, valor |
| A06 | Fevereiro: notas de entrada, quantidade e valor |
| 2.1 | Total vendido (qtde e R$) por produto em fevereiro |
| 2.2 | Itens requisitados e não recebidos (sem nota ou recebidos em parte) |
| E01–E22 | Uma consulta por erro, listando as linhas afetadas (tabela abaixo) |
| R01 | Resumo com a quantidade de cada erro (gerou a coluna "Quantidade" abaixo) |

## Erros encontrados nos dados

| # | Tabela | Problema | Quantidade | Consulta que mostra |
| --- | --- | --- | --- | --- |
| 1 | pedido_compra | Valores em 11 colunas **sem cabeçalho** (M a W) nas linhas 22 a 30: cópia do pedido original com `qtde_pendente` | 9 linhas | E01 |
| 2 | pedido_compra | A aba **não tem a coluna `qtde_pendente`** (existe no DDL); foi calculada | 1 coluna | E02 |
| 3 | produtos_filial | Cabeçalho `idproduto` em vez de `produto_id` (padrão das outras abas) | 1 | E03 |
| 4 | fornecedor / produtos_filial | Id do fornecedor como texto (`F1`); em pedido_compra é número (`1`) | 40 células | E04 |
| 5 | pedido_compra | `ordem_compra = 0`: pedido sem vínculo com a nota | 11 pedidos (19 a 29) | E05 |
| 6 | pedido_compra | Pedidos 21 a 29 repetem produto, datas, preço e fornecedor dos pedidos 12 a 20 | 9 | E06 |
| 7 | pedido_compra | Pedidos 19 e 20 divergem da cópia nas colunas extras (ordem, qtde pedida, qtde entregue) | 2 | E07 |
| 8 | pedido_compra | Data de entrega anterior à data do pedido (até 48 dias antes) | 20 | E08 |
| 9 | pedido_compra | `qtde_entregue` diferente do total recebido nas notas | 18 (de 18 com nota) | E09 |
| 10 | pedido_compra | Fornecedor do pedido diferente do fornecedor do produto no cadastro | 22 | E10 |
| 11 | entradas_mercadoria | Nota sem pedido com a mesma ordem/produto (NFE19, NFE20) | 2 | E11 |
| 12 | entradas_mercadoria | Mercadoria recebida antes de ser pedida | 9 | E12 |
| 13 | entradas_mercadoria | Recebido mais que o pedido (ex.: pedido 3: pediu 12, recebeu 88) | 7 | E13 |
| 14 | entradas_mercadoria | Custo da nota difere mais de 20% do preço do pedido (até +520%) | 16 | E14 |
| 15 | venda | Venda de produto sem cadastro (P21 a P28) | 13 vendas / 8 produtos | E15 |
| 16 | venda | Venda em filial sem cadastro (filiais 2 e 3) | 4 | E16 |
| 17 | venda | Quantidade fracionada com unidade `UN` | 5 | E17 |
| 18 | venda | `horariomov` = 08:00:00 em 100% das vendas (hora fictícia, e faz parte da PK) | 33 | E18 |
| 19 | venda | Venda copiada de outra (mesmo valor unitário, mesma data ou +1 mês): vendas 21 a 33 | 13 | E19 |
| 20 | venda | Valor vendido difere mais de 20% do preço de venda do cadastro | 18 | E20 |
| 21 | produtos_filial | Preço de venda menor que o preço de compra (P1, P8, P15, P18) | 4 | E21 |
| 22 | fornecedor | Fornecedor sem nenhum produto (F14, F15, F16) | 3 | E22 |

Os erros de estrutura (DDL e script de importação) estão em `docs/parte1_importacao.md`.

### Encerramento

- Ata com os números de fevereiro validados (vendas, compras, entradas).
- Para cada erro: decisão do cliente (corrigir na origem, aceitar ou excluir), responsável e prazo.
- Depois das correções: rodar `importar.py` de novo, depois A01, A02 e R01. Os números têm que bater com a ata.
