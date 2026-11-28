# Parte 4: Roteiro de validação com o cliente (fevereiro/2025)

## 1. Pontos a validar

Durante a reunião com o cliente, o objetivo será verificar se os dados de fevereiro de 2025 foram importados corretamente e se as informações apresentadas pelo sistema correspondem aos registros originais.

Os principais pontos que serão validados são:

-Quantidade de registros: conferir se todas as vendas do período foram importadas, sem perda de informações.
-Valores das vendas: verificar se as quantidades vendidas e os valores unitários estão corretos e se os totais calculados correspondem aos valores esperados.
-Produtos cadastrados: confirmar se os produtos presentes nas vendas existem no cadastro da respectiva filial.
-Datas: verificar se os registros pertencem ao mês de fevereiro de 2025.
-Integridade: identificar campos obrigatórios vazios, valores negativos ou registros duplicados.
-Consistência: comparar os resultados obtidos no banco de dados com a planilha original e verificar se PostgreSQL e MySQL apresentam resultados equivalentes.

## 2. Técnicas para garantir exatidão e precisão

Para garantir a confiabilidade dos dados, serão utilizadas as seguintes técnicas:

-Conferência de registros: comparar a quantidade de linhas da planilha original com a quantidade de registros importados.
-Validação de valores: recalcular os valores das vendas utilizando a quantidade vendida multiplicada pelo valor unitário.
-Verificação de dados ausentes: utilizar consultas SQL para localizar campos obrigatórios sem preenchimento.
-Identificação de duplicidades: agrupar registros com informações iguais para investigar possíveis repetições.
-Validação de relacionamentos: verificar se os produtos vendidos possuem cadastro correspondente na tabela de produtos da filial.
-Comparação entre bancos: executar as mesmas consultas no PostgreSQL e no MySQL e comparar os resultados.
-Análise de inconsistências: investigar os registros que apresentarem divergências, consultando a planilha original antes de realizar qualquer correção.

Essas técnicas permitem verificar se os dados representam corretamente as operações realizadas e se apresentam consistência suficiente para serem utilizados na aplicação e na tomada de decisões.

## 3. Consultas preparadas para a reunião

As consultas preparadas no arquivo `sql/04_validacao.sql` serão utilizadas para apresentar e conferir os dados de fevereiro de 2025.

-Resumo geral das vendas: apresenta a quantidade de registros, a quantidade total vendida e o valor total das vendas.
-Vendas por produto: demonstra a quantidade e o valor vendido de cada produto, permitindo identificar os produtos com maior movimentação.
-Vendas por dia: apresenta os resultados diários para facilitar a identificação de movimentações fora do esperado.
-Campos obrigatórios vazios: identifica registros que possuem informações essenciais não preenchidas.
-Valores inconsistentes: localiza quantidades zeradas ou negativas e valores unitários negativos.
-Produtos sem cadastro: verifica se existem vendas de produtos que não estão cadastrados na respectiva filial.
-Possíveis duplicidades: identifica registros com informações repetidas que precisam ser investigadas.

Os resultados serão comparados com a planilha original e com as regras de negócio apresentadas pelo cliente. Caso sejam encontradas divergências, elas serão registradas e investigadas antes da aprovação final.

## Erros encontrados nos dados

A tabela abaixo será preenchida após a execução das consultas de validação, registrando os problemas efetivamente encontrados e suas respectivas quantidades.

| Tabela | Problema | Quantidade | Consulta que mostra |
| --- | --- | --- | --- |
| A preencher | A verificar | A verificar | A verificar |

Conclusão: a reunião de validação permitirá demonstrar ao cliente que os dados foram analisados por meio de consultas e técnicas de conferência. A aprovação final dependerá da confirmação de que as informações estão corretas, consistentes e de acordo com os registros de origem.