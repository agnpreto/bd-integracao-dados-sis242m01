# Parte 4: Roteiro da reunião de validação (fevereiro/2025)

Todas as consultas estão prontas em `sql/04_validacao.sql` (blocos A, B e C).

## Abertura (2 minutos)
"Vamos conferir os números de fevereiro item por item. Onde houver dúvida eu mostro a linha de origem. O que não tiver explicação fica registrado para você confirmar."

## 1. O que validar com o cliente

| Ponto | Pergunta ao cliente | Consulta |
|---|---|---|
| Volume | "O arquivo tinha 33 vendas, 29 pedidos e 20 entradas; fevereiro tem 14 vendas. Isso confere com o sistema de vocês?" | C1, C6 |
| Total do mês | "Fevereiro: 14 vendas, 173,22 unidades, **R$ 14.093,17**. Bate com o fechamento?" | C2 |
| Dias e produtos | "Existem dias sem venda? A loja abriu?" | C3 |
| Concentração | "Um produto (P14) pesa 40% do mês. É normal?" | C4 |
| Produtos | "Há vendas dos produtos P21 a P28, que não estão no cadastro. São produtos novos ou erro de código? E as filiais 2 e 3?" | E1, E2 |
| Quantidades | "Cinco vendas têm quantidade quebrada em unidade UN (ex.: 38,6). Qual é a unidade correta?" | E3 |
| Compras | "Os pedidos 19 a 29 não têm ordem de compra; os 21 a 29 repetem pedidos anteriores. São pedidos novos, reedições ou duplicidade?" | E4, E11, C7 |
| Recebimento | "Recebeu-se mais do que se pediu em 7 pedidos, e as datas de entrega/entrada vêm antes do pedido. Qual data vale?" | E6 a E9 |
| Fornecedor | "O fornecedor do pedido não é o do cadastro em 22 casos. Qual é o correto?" | E10, E16 |
| Preços | "Há três custos por produto (cadastro, pedido, nota) e quatro produtos com preço de venda abaixo do custo." | E12 a E14 |

## 2. Técnicas para garantir exatidão e precisão
1. **Reconciliação:** contagem e soma carregadas x planilha original (feito: 20/20/29/20/33 e R$ 14.093,17 em dois meios independentes, SQL e pandas).
2. **Chaves e duplicidade:** teste de PK, de venda repetida e de nulos nas colunas críticas (C5).
3. **Integridade referencial:** todo produto, filial e fornecedor citado existe no cadastro (E1, E2, E10).
4. **Regras de negócio:** datas coerentes (entrega >= pedido), recebido <= pedido, preço de venda >= custo (E6 a E8, E13).
5. **Tipos numéricos exatos:** `NUMERIC` em quantidade e dinheiro (sem `float`), valor calculado linha a linha e depois somado.
6. **Dupla checagem independente:** o mesmo total calculado por duas ferramentas (SQL e pandas).
7. **Amostragem com o cliente:** 5 vendas escolhidas por ele, conferidas à vista contra o sistema dele.
8. **Dados originais preservados:** nada foi "arrumado" por conta própria; toda correção só entra depois da confirmação do cliente, registrada em ata.

## 3. Consultas deixadas prontas
Ver `sql/04_validacao.sql`. Para a reunião, a ordem sugerida é C1, C2, C3, C4, C5, C6 e depois o painel de erros (bloco A) com o detalhe (bloco B) só dos itens que o cliente perguntar.

## 4. Lista de todos os erros encontrados nos dados

| ID | Erro | Linhas | Consulta |
|---|---|---|---|
| E1 | Venda de produto sem cadastro (P21 a P28) | 13 | B / E1 |
| E2 | Venda em filial inexistente (2 e 3) | 4 | E2 |
| E3 | Quantidade fracionada em unidade `UN` (vendas 4, 8, 12, 16, 26) | 5 | E3 |
| E4 | Pedidos 19 a 29 com `ordem_compra = 0` | 11 | E4 |
| E5 | Entradas NFE19 e NFE20 apontam para ordens 19 e 20, que não existem em `pedido_compra` | 2 | E5 |
| E6 | Data de entrega anterior à data do pedido | 20 | E6 |
| E7 | Nota de entrada com data anterior ao pedido | 9 | E7 |
| E8 | Quantidade recebida maior que a pedida | 7 | E8 |
| E9 | `qtde_entregue` do pedido diferente de `qtde_recebida` da nota | 18 | E9 |
| E10 | Fornecedor do pedido diferente do fornecedor do produto | 22 | E10 |
| E11 | Pedidos 21 a 29 repetem produto, data, fornecedor e preço de pedidos anteriores | 9 | E11 |
| E12 | Custo diferente no cadastro, no pedido e na nota | 18 | E12 |
| E13 | Preço de venda menor que o preço de compra no cadastro | 4 | E13 |
| E14 | Preço praticado na venda diferente do preço de venda do cadastro | 20 | E14 |
| E15 | Mesmo `valor_unitario` em produtos diferentes (P13=P21, P14=P22 ...; vendas 21 a 28 parecem cópia das 13 a 20) | 13 pares | E15 |
| E16 | Fornecedores com 2 produtos (7, 18, 19) ou nenhum (14, 15, 16) | 6 | E16 |
| E17 | Todas as vendas com horário `08:00:00` e item 1 (placeholder) | 33 | E17 |
| E18 | Colunas M:W soltas na aba `pedido_compra` (sobras de colagem) | 9 linhas | aviso do `importar.py` |
| E19 | Nome de coluna diferente do DDL: `idproduto` (planilha) x `produto_id` (DDL) | 1 | estrutura |

Observação: algumas linhas contam em mais de um erro.
> Revisão final da etapa de validação concluída para entrega individual.