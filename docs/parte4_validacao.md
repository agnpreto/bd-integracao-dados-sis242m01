# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

## 1. Pontos a validar
1.Vendas: conferir se os produtos vendidos em fevereiro, as quantidades e os valores totais correspondem aos registros comerciais.
2.Pedidos de compra: verificar quais produtos foram pedidos, quais foram entregues e quais continuam pendentes.
3.Entradas de mercadorias: comparar as quantidades registradas nas notas fiscais com as quantidades dos pedidos de compra.
4.Fornecedores: confirmar se cada produto está associado ao fornecedor correto e se os identificadores numéricos estão funcionando.
5.Datas e cadastros: identificar datas inconsistentes, produtos sem cadastro correspondente e pedidos sem número de ordem válido.

## 2. Técnicas para garantir exatidão e precisão
Conferência de totais: comparar a quantidade de registros da planilha com a quantidade importada no PostgreSQL.
Conciliação de dados: comparar pedidos de compra, entradas de mercadorias e vendas.
Validação de integridade referencial: verificar se os relacionamentos entre produtos e fornecedores estão corretos.
Verificação de datas: identificar datas ausentes ou incompatíveis.
Amostragem: selecionar alguns registros e comparar os dados do banco com a planilha original.
Testes de automação: verificar se o trigger atualiza corretamente o identificador numérico do fornecedor.

## 3. Consultas preparadas para a reunião

(As consultas ficam em `sql/04_validacao.sql`. Explique aqui o que cada uma mostra.)
1. Conferência da quantidade de registros
O que faz: conta quantas linhas existem em cada tabela do banco de dados.
2. Conferência das vendas de fevereiro de 2025
O que faz: consulta as vendas realizadas entre 1º e 28 de fevereiro de 2025, agrupando os resultados por produto.
3. Conferência dos pedidos de compra pendentes
O que faz: identifica os pedidos em que a quantidade pedida é maior que a quantidade entregue.
4. Verificação de datas inconsistentes
O que faz: procura pedidos em que a data de entrega é anterior à data em que o pedido foi realizado.
5. Verificação de números de ordem de compra inválidos
O que faz: procura registros da tabela pedido_compra em que o número da ordem de compra está vazio (NULL) ou possui o valor zero.
6. Verificação de entradas sem pedido correspondente
O que faz: procura entradas de mercadorias que não possuem um pedido de compra correspondente.
7. Verificação de vendas sem produto cadastrado
O que faz: procura vendas cujos produtos não possuem um cadastro correspondente na tabela produtos_filial, considerando também a filial.
8. Verificação dos códigos numéricos dos fornecedores
O que faz: verifica se o código numérico do fornecedor registrado em produtos_filial corresponde ao código numérico existente na tabela fornecedor.
9. Resumo geral das vendas de fevereiro
O que faz: apresenta um resumo geral das vendas realizadas em fevereiro de 2025, considerando a quantidade de vendas, a quantidade de produtos vendidos e o valor total comercializado.

## Erros encontrados nos dados

| Tabela | Problema | Quantidade | Consulta que mostra |
| pedido_compra | Data de entrega anterior à data do pedido | 20 registros | Consulta 4: identifica pedidos com datas inconsistentes |
| pedido_compra | Número da ordem de compra igual a zero | 11 registros | Consulta 5: identifica pedidos sem número de ordem válido. |
| entradas_mercadoria | Entradas sem pedido de compra correspondente | 2 registros | Consulta 6: identifica entradas sem pedido relacionado. |
| venda / produtos_filial | Produtos vendidos sem correspondência no cadastro da filial | 6 códigos de produto | Consulta 7: identifica vendas de produtos não cadastrados na filial correspondente. |
| produtos_filial | Divergência no identificador numérico do fornecedor | 0 divergências | Consulta 8: verifica se o código numérico do fornecedor corresponde ao cadastro do fornecedor. |
