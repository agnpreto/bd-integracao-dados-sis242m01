# Integração de Dados: implantação, consultas e validação

**Disciplina:** Banco de Dados (SIS242M01)  
**Trabalho:** individual  
**Prazo:** dd/mm/aaaa

**Nome da dupla:** Mikael Coelho Ramos e Kauã Monteiro Coelho

| Nome | Matrícula | Usuário do GitHub |
| --- | --- | --- |
|  Mikael Coelho Ramos e Kauã Monteiro Coelho|  2388326 - 2533406|  mikaelrms e Kauaks|

## O cenário

Você foi contratado para implantar o banco de dados de uma rede de lojas. O cliente enviou:

- a planilha `dados/base_teste.xlsx`, com 5 abas: `venda`, `pedido_compra`, `entradas_mercadoria`, `produtos_filial` e `fornecedor`;
- o DDL das tabelas, em `sql/01_ddl_enunciado.sql`;
- um script de importação feito por um estagiário, em `scripts/importar.py`;
- o enunciado completo, em `docs/Atividade_Integracao_de_Dados.pdf`.

⚠️ **O material contém erros intencionais**, no DDL, nos dados e no script. Encontrar, explicar e corrigir esses erros faz parte da avaliação. Não confie em nada sem testar.

Uma entrada de mercadoria se liga ao seu pedido de compra pelo campo `ordem_compra`.

## Etapas

### Etapa 1: Implantação (Parte 1)

1. Rode o `sql/01_ddl_enunciado.sql` no PostgreSQL e anote cada erro.
2. Crie as versões corrigidas: `sql/01_ddl_postgres.sql` e `sql/01_ddl_mysql.sql`.
3. Rode o `scripts/importar.py` e **confira no banco** quantas linhas entraram em cada tabela (`SELECT COUNT(*) ...`). Compare com a planilha.
4. Corrija o script, ou importe por outra ferramenta, como o DBeaver, até os dados entrarem corretos.
5. Documente tudo em `docs/parte1_importacao.md`.

### Etapa 2: Consultas (Partes 2 e 3)

Use **somente SQL**:

- `sql/02_consultas.sql`
  - Total vendido em quantidade e em R$ por produto, em fevereiro de 2025.
  - Produtos requisitados e não recebidos.
- `sql/03_transformacoes.sql`
  - Concatenar `produto_id` e `descricao_produto` (onde houver), no formato `12345 - Detergente`.
  - Datas no formato DD/MM/YYYY.
  - Só os produtos requisitados mais de 10 vezes no período. Explique, em comentário, como você interpretou "mais de 10 vezes".
  - Trigger que gera automaticamente um novo `idfornecedor` na tabela de produtos, relacionado à tabela de fornecedor.

Exemplo de resultado esperado:

| Produto | Qtde Requisitada | Data Solicitação |
| --- | --- | --- |
| 12345 - Detergente | 15 | 01/01/2025 |

### Etapa 3: Validação com o cliente (Parte 4)

Em `docs/parte4_validacao.md`, monte o roteiro da reunião de validação dos dados de **fevereiro de 2025**:

1. Os pontos que você validaria com o cliente.
2. As técnicas para garantir a exatidão dos dados.
3. As consultas que você deixaria prontas, salvas em `sql/04_validacao.sql`.

Inclua uma lista de **todos os erros que você encontrou nos dados**, com a consulta que mostra cada um.

## Estrutura do repositório

```
dados/base_teste.xlsx               planilha do cliente (não alterar)
docs/Atividade_Integracao_de_Dados.pdf
docs/parte1_importacao.md           Etapa 1: documentação da importação
docs/parte4_validacao.md            Etapa 3: roteiro de validação
scripts/importar.py                 script do estagiário (corrija aqui)
sql/01_ddl_enunciado.sql            DDL original, com erros
sql/01_ddl_postgres.sql             seu DDL corrigido (PostgreSQL)
sql/01_ddl_mysql.sql                seu DDL corrigido (MySQL)
sql/02_consultas.sql                Parte 2
sql/03_transformacoes.sql           Parte 3 (inclui a trigger)
sql/04_validacao.sql                Parte 4
```

## Como entregar

1. Logado no GitHub, clique em **Fork** (canto superior direito) e depois em **Create fork**. O fork é a sua cópia individual.
2. No fork, preencha a tabela **Aluno** no topo deste README: clique em `README.md`, depois no lápis ✏️, e em **Commit changes**.
3. Clone o fork (`git clone <link-do-seu-fork>`) e faça o trabalho nele, com **pelo menos 5 commits** ao longo das etapas.
4. **Não coloque senha real** no `importar.py`: use variável de ambiente ou deixe um valor de exemplo.
5. Para entregar, no fork clique em **Contribute → Open pull request**, preencha o modelo e clique em **Create pull request**. Cada novo `git push` atualiza o mesmo Pull Request até o prazo.

⚠️ Não edite o repositório do professor, só o seu fork.


