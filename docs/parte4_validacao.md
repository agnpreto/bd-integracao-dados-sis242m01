# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

## 1. Pontos a validar

Objetivo da reunião: o cliente confirmar que os números de fevereiro/2025 no banco são os do negócio dele e decidir o que fazer com cada inconsistência encontrada. Os pontos, na ordem em que eu conduziria:

1. **Fechamento do mês.** Em fevereiro/2025 o banco mostra 14 produtos vendidos, 14 vendas, 173,22 unidades e R$ 14.093,17. Esses números batem com o relatório do sistema do cliente? (consulta V2)
2. **Recorte do período.** A base tem vendas de janeiro (12) e de março (7) além das de fevereiro (14). Confirmar que fevereiro vai de 01/02 a 28/02 pela data de emissão. A venda de 28/02 entra no fechamento. (consulta E14)
3. **Cadastro de produtos e filiais.** Oito produtos foram vendidos sem cadastro (P21 a P28, 13 vendas) e 4 vendas ocorreram nas filiais 2 e 3, que não têm nenhum produto cadastrado. Faltou carregar o cadastro? As filiais 2 e 3 existem? (consultas E11 e E12)
4. **Quantidades.** Cinco vendas têm quantidade fracionada com unidade UN (por exemplo 38,6 unidades). A unidade está correta ou o item deveria ser vendido por peso? (consulta E13)
5. **Pedidos de compra.** Onze pedidos estão sem ordem de compra, 9 pares de pedidos parecem duplicados e 20 pedidos têm data de entrega anterior à data do pedido. Quais são válidos? (consultas E1, E4 e E3)
6. **Recebimentos.** Duas entradas não têm pedido, 9 aparecem antes do pedido, 7 receberam mais do que foi pedido, e a quantidade recebida e o custo não batem com o que o pedido registra. Qual campo é a fonte da verdade? (consultas E2, E5, E6, E7 e E8)
7. **Fornecedores.** Em 22 pedidos o fornecedor é diferente do cadastrado para o produto, e 3 fornecedores não têm nenhum produto. Vale o fornecedor do pedido ou o do cadastro? (consultas E9 e E10)
8. **Preços.** Quatro produtos têm preço de venda menor que o de compra. É erro de digitação ou prejuízo intencional? (consulta E15)
9. **Regras de negócio usadas nos relatórios.** "Requisitado e não recebido" é o pedido sem nenhuma entrada ligada pela ordem de compra. "Requisitado mais de 10 vezes" é a quantidade requisitada acima de 10 no período. O cliente concorda com essas leituras?

Para cada ponto, registrar a decisão (corrigir na origem, corrigir no banco ou aceitar como está) e o responsável.

## 2. Técnicas para garantir exatidão e precisão

- **Conciliação de totais.** Contagem de linhas por tabela, planilha contra banco (20, 20, 29, 20 e 33, consulta V1), e os totais de fevereiro (consulta V2) comparados com um cálculo independente feito direto na planilha. O resultado do SQL bateu com o cálculo.
- **Importação sem erro silencioso.** O script conta linhas inseridas, duplicadas e com erro por tabela e compara planilha e banco no final. Uma linha rejeitada aparece na tela e não some.
- **Tipos adequados à precisão.** Valores e quantidades em numeric (e não float), identificadores como inteiros e datas em tipo date. Isso evita erro de arredondamento e comparação imprecisa de chaves.
- **Integridade referencial.** Consultas de órfãos (E2, E10, E11 e E12) e chave estrangeira entre produtos e fornecedor.
- **Regras de consistência entre campos e tabelas.** Datas (E3 e E5), quantidades (E6 e E7) e preços (E8 e E15).
- **Detecção de duplicidade.** Consulta E4 e verificação das chaves primárias, que não tiveram duplicatas.
- **Amostragem com o cliente.** Escolher algumas vendas de fevereiro, por exemplo as de maior valor, e conferir uma a uma no sistema dele.
- **Nada é corrigido em silêncio.** Os tratamentos feitos na importação estão documentados na Parte 1. Erros de conteúdo não foram alterados, apenas listados, porque a decisão de correção é do cliente.
- **Registro e nova rodada.** Ata com decisões e pendências, e reexecução de V1 e V2 depois de qualquer correção.

## 3. Consultas preparadas para a reunião

(As consultas ficam em `sql/04_validacao.sql`. Explique aqui o que cada uma mostra.)

| Consulta | O que mostra | Esperado |
| --- | --- | --- |
| V1 | Linhas por tabela, para comparar com a planilha | 20, 20, 29, 20 e 33 |
| V2 | Fechamento de fevereiro/2025: produtos, vendas, unidades e valor | 14 produtos, 14 vendas, 173,22 unidades e R$ 14.093,17 |
| E1 | Pedidos sem ordem de compra (ordem_compra = 0) | 11 pedidos (19 a 29) |
| E2 | Entradas cuja ordem não existe em pedido_compra | 2 entradas (ordens 19 e 20) |
| E3 | Pedidos com entrega anterior à data do pedido | 20 pedidos |
| E4 | Pedidos possivelmente duplicados (mesmo produto, datas e preço) | 9 pares, de 12 e 21 até 20 e 29 |
| E5 | Entradas anteriores à data do pedido | 9 ordens |
| E6 | Quantidade recebida maior que a pedida | 7 ordens |
| E7 | Quantidade recebida diferente da entregue registrada no pedido | 18 ordens |
| E8 | Custo da entrada diferente do preço do pedido | 18 ordens |
| E9 | Fornecedor do pedido diferente do cadastrado para o produto | 22 pedidos |
| E10 | Fornecedores sem nenhum produto | 3 fornecedores (14, 15 e 16) |
| E11 | Produtos vendidos sem cadastro | 8 produtos (P21 a P28), 13 vendas |
| E12 | Vendas em filiais sem produtos cadastrados | 4 vendas (27, 28, 32 e 33) |
| E13 | Quantidade fracionada em unidade UN | 5 vendas (4, 8, 12, 16 e 26) |
| E14 | Vendas por mês, para mostrar o recorte de fevereiro | 12 em janeiro, 14 em fevereiro e 7 em março |
| E15 | Produtos com preço de venda menor que o de compra | 4 produtos (P1, P8, P15 e P18) |

## Erros encontrados nos dados

| Tabela | Problema | Quantidade | Consulta que mostra |
| --- | --- | --- | --- |
| pedido_compra | Pedidos sem ordem de compra (ordem_compra = 0), sem ligação com as entradas | 11 | E1 |
| entradas_mercadoria | Entradas cuja ordem de compra não existe em pedido_compra | 2 | E2 |
| pedido_compra | Data de entrega anterior à data do pedido | 20 | E3 |
| pedido_compra | Pedidos 21 a 29 repetem produto, datas e preço dos pedidos 12 a 20, com ordem 0 e quantidade menor | 9 pares | E4 |
| entradas_mercadoria e pedido_compra | Entrada anterior à data do pedido | 9 | E5 |
| entradas_mercadoria e pedido_compra | Quantidade recebida maior que a pedida | 7 | E6 |
| entradas_mercadoria e pedido_compra | Quantidade recebida diferente da entregue registrada no pedido | 18 | E7 |
| entradas_mercadoria e pedido_compra | Custo da entrada diferente do preço do pedido | 18 | E8 |
| pedido_compra e produtos_filial | Fornecedor do pedido diferente do fornecedor cadastrado para o produto | 22 | E9 |
| fornecedor | Fornecedores sem nenhum produto | 3 | E10 |
| venda e produtos_filial | Produtos vendidos sem cadastro (P21 a P28) | 8 produtos, 13 vendas | E11 |
| venda | Vendas nas filiais 2 e 3, que não têm produtos cadastrados | 4 | E12 |
| venda | Quantidade fracionada em unidade UN | 5 | E13 |
| venda | Vendas fora de fevereiro/2025 (12 em janeiro e 7 em março) | 19 | E14 |
| produtos_filial | Preço de venda menor que o preço de compra | 4 | E15 |
| pedido_compra (planilha) | Células soltas, sem cabeçalho, nas colunas M a W das linhas 22 a 30. Tratado na importação, que lê só as colunas A a L | 99 células | Não se aplica: está na planilha (ver Parte 1) |
| fornecedor e produtos_filial (planilha) | Código do fornecedor em texto (F1 a F20), enquanto pedido_compra usa número. Tratado removendo o F | 40 linhas | Não se aplica: tratado na importação (ver Parte 1) |
| produtos_filial (planilha) | Coluna chamada idproduto na planilha e produto_id no banco. Tratado com mapeamento na importação | 1 coluna | Não se aplica: tratado na importação (ver Parte 1) |
| pedido_compra (planilha) | A coluna qtde_pendente não existe na planilha. Calculada como pedida menos entregue | 29 linhas | Não se aplica: tratado na importação (ver Parte 1) |