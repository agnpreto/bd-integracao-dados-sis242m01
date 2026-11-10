# Integração de Dados: implantação, consultas e validação

**Disciplina:** Banco de Dados (SIS242M01)  
**Trabalho:** individual ou em dupla (à escolha do aluno)  
**Prazo de entrega:** 24/11/2026

## Equipe

**Nome da dupla:** ____________________ (deixe em branco se for individual)

| Nome | Matrícula | Usuário do GitHub |
| --- | --- | --- |
| Carlos Alencar | 2400784 | xandealencar-S |
| Carlos Vasconcelos | 2385765 | Carlos-VasconceloS |


## O cenário

Você (ou sua dupla) foi contratado para implantar o banco de dados de uma rede de lojas. O cliente enviou:

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

1. Logado no GitHub, clique em **Fork** (canto superior direito) e depois em **Create fork**. **Individual:** você faz o seu fork. **Dupla:** só um dos dois faz o fork; o outro **não** faz.
2. **Só para dupla:** no fork, vá em **Settings → Collaborators → Add people** e adicione o colega pelo usuário do GitHub. O colega aceita o convite que chega por e-mail.
3. **Logo no início**, preencha no fork a tabela **Equipe** no topo deste README (uma linha se for individual, duas se for dupla, e o **nome da dupla** se for o caso): clique em `README.md`, depois no lápis ✏️, e em **Commit changes**. Não apague a linha `| --- | --- | --- |` da tabela. É por ela que a lista de equipes (`EQUIPES.md`) é montada.
4. Clone o fork (`git clone <link-do-fork>`) e trabalhe nele. **Individual:** pelo menos 5 commits. **Dupla:** cada integrante com pelo menos 3 commits.
5. **Não coloque senha real** no `importar.py`: use variável de ambiente ou deixe um valor de exemplo.
6. Para entregar, abra o fork, clique em **Contribute → Open pull request**, preencha o modelo e clique em **Create pull request**. Cada novo `git push` atualiza o mesmo Pull Request até o prazo, **24/11/2026**.

⚠️ Não edite o repositório do professor, só o fork. Um Pull Request por aluno individual ou por dupla.
