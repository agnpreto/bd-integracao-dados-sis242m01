# Guia operacional — Integração de Dados

**Ambiente:** PostgreSQL · **Banco da demonstração:** `integracao_demo` · **Base:** 5 tabelas / 122 registros  
**Repositório:** https://github.com/RenisonJunior/bd-integracao-dados-sis242m01  
**Sequência:** obter arquivos → iniciar servidor → conectar → criar banco → restaurar → demonstrar → validar/ajustar  
**Arquivo de restauração:** `dados/banco_apresentacao.sql` (exportação do banco `integracao_teste`, já testada)

## 1. Obter o projeto

**GitHub → Code → Download ZIP → Downloads → Descompactar.**

No macOS: **Command + Espaço → Terminal**.

```bash
cd ~/Downloads/bd-integracao-dados-sis242m01-main
ls dados/banco_apresentacao.sql sql/02_consultas.sql sql/04_validacao.sql
```

> Se a pasta tiver outro nome, abrir a pasta extraída no Finder e arrastá-la para o Terminal após digitar `cd `.

## 2. Preparar o PostgreSQL no MacBook

### 2.1. Identificar o ambiente

**Terminal:**

```bash
psql --version
pg_isready -h localhost -p 5432
```

| Situação | Procedimento |
|---|---|
| `accepting connections` | Seguir para **3. Conexão e restauração**. |
| `no response` | PostgreSQL instalado, mas servidor possivelmente parado; iniciar conforme a instalação. |
| `command not found: psql` | Localizar o cliente PostgreSQL; se não existir, instalar servidor e ferramentas. |
| pgAdmin abre, mas não há servidor em **Servers** | Registrar a conexão conforme **2.4**. O pgAdmin sozinho não instala o servidor PostgreSQL. |

### 2.2. PostgreSQL instalado, mas parado

**Postgres.app:** abrir **Aplicativos → Postgres.app → Start**. Se for a primeira execução, clicar em **Initialize**.

**Homebrew (quando usado pelo professor):**

```bash
brew list --versions | grep postgresql
brew services list
# Exemplo, somente se esta versão estiver instalada:
brew services start postgresql@16
```

**Cliente `psql` não encontrado — Postgres.app instalado:**

```bash
export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
psql --version
```

**Cliente `psql` não encontrado — instalador PostgreSQL/EDB:** localizar a versão instalada em `/Library/PostgreSQL/` e ajustar o número, se necessário. Se o serviço EDB estiver parado, solicitar ao responsável pela instalação que o inicie; não modificar a configuração do MacBook sem autorização.

```bash
ls /Library/PostgreSQL/
export PATH="/Library/PostgreSQL/16/bin:$PATH"
psql --version
```

### 2.3. PostgreSQL não instalado

1. Acessar **https://postgresapp.com/** → **Download**.
2. Abrir o arquivo baixado → mover **Postgres.app** para **Aplicativos**.
3. Abrir **Postgres.app** → **Initialize** → iniciar o servidor (**Start**, se necessário).
4. No Terminal, disponibilizar `psql`:

```bash
export PATH="/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH"
psql --version
pg_isready -h localhost -p 5432
```

**Interface gráfica opcional:** instalar o pgAdmin 4 em https://www.pgadmin.org/download/pgadmin-4-macos/ (versão para Intel ou Apple Silicon). A restauração do arquivo `.sql` será feita pelo **Terminal/psql**.

### 2.4. pgAdmin: registrar ou conectar o servidor

**pgAdmin 4 → Servers → botão direito → Register → Server...**

| Aba | Campo | Valor |
|---|---|---|
| General | Name | `PostgreSQL local` |
| Connection | Host name/address | `localhost` |
| Connection | Port | `5432` (ou porta informada pelo professor) |
| Connection | Maintenance database | `postgres` |
| Connection | Username | Usuário PostgreSQL autorizado |
| Connection | Password | Informar quando solicitado; não inserir em arquivos do projeto |

Clicar em **Save**. Se já houver servidor registrado: **Servers → selecionar → Connect Server**.  
**Banco para a demonstração:** `Databases → integracao_demo` (criar na próxima seção).  
**Consultas SQL:** selecionar `integracao_demo` → **Tools → Query Tool → Execute (▶)**.

> Registrar um servidor no pgAdmin cria somente a conexão visual; o serviço PostgreSQL precisa estar instalado e iniciado.

## 3. Conectar e restaurar a base

### 3.1. Configurar a conexão no Terminal

**Substituir usuário e porta conforme a instalação do professor.** Em Postgres.app, o usuário inicial normalmente corresponde ao usuário do macOS; em outras instalações pode ser `postgres`.

```bash
export PGHOST=localhost
export PGPORT=5432
export PGUSER=USUARIO_POSTGRESQL
psql -d postgres -X -c "SELECT current_user, current_setting('server_version') AS versao;"
```

A senha será solicitada **somente se a autenticação do servidor exigir**. Não escrever senha no comando. As variáveis `PGHOST`, `PGPORT` e `PGUSER` permanecem disponíveis no **mesmo Terminal**; ao abrir outra sessão, configurar novamente.

**Permissão para criar banco:**

```bash
psql -d postgres -X -c "SELECT current_user, rolcreatedb, rolsuper FROM pg_roles WHERE rolname = current_user;"
```

### 3.2. Criar o banco separado

**Verificar se já existe:**

```bash
psql -d postgres -X -c "SELECT datname FROM pg_database WHERE datname = 'integracao_demo';"
```

**Se não existir e houver permissão:**

```bash
psql -d postgres -X -v ON_ERROR_STOP=1 -c "CREATE DATABASE integracao_demo;"
```

**No pgAdmin (alternativa):** `Databases → botão direito → Create → Database... → Database: integracao_demo → Save`.

Se a conta não tiver `CREATEDB`, o professor deverá autorizar a criação ou disponibilizar um banco vazio. **Não alterar permissões sem autorização.**

Se `integracao_demo` já existir e contiver tabelas, **não restaurar por cima**. Confirmar sua origem; se necessário, criar `integracao_demo_2` e trocar o nome do banco nos comandos seguintes.

### 3.3. Restaurar estrutura, registros, função e trigger

**No Terminal, dentro da pasta baixada:**

```bash
psql -d integracao_demo -X -v ON_ERROR_STOP=1 --single-transaction -f dados/banco_apresentacao.sql
```

**Saída esperada:** `CREATE FUNCTION`, cinco `CREATE TABLE`, `COPY 20`, `COPY 20`, `COPY 29`, `COPY 20`, `COPY 33`, chaves primárias e `CREATE TRIGGER`.

> O arquivo é um dump SQL em texto que contém `COPY`; restaurar com `psql`, não colando seu conteúdo no Query Tool do pgAdmin. Não executar `sql/01_ddl_postgres.sql` antes: a exportação já inclui as tabelas.

### 3.4. Verificar a restauração

**Terminal:**

```bash
psql -d integracao_demo -X -P pager=off
```

**A partir daqui, os blocos `sql` podem ser executados no `psql` conectado ou no Query Tool do pgAdmin.** Para sair do `psql`: `\q`.

```sql
SELECT current_database() AS banco, current_user AS usuario;

SELECT 'fornecedor' AS tabela, COUNT(*) AS registros FROM fornecedor
UNION ALL SELECT 'produtos_filial', COUNT(*) FROM produtos_filial
UNION ALL SELECT 'pedido_compra', COUNT(*) FROM pedido_compra
UNION ALL SELECT 'entradas_mercadoria', COUNT(*) FROM entradas_mercadoria
UNION ALL SELECT 'venda', COUNT(*) FROM venda;
```

| Tabela | Registros esperados |
|---|---:|
| `fornecedor` | 20 |
| `produtos_filial` | 20 |
| `pedido_compra` | 29 |
| `entradas_mercadoria` | 20 |
| `venda` | 33 |
| **Total** | **122** |

## 4. Demonstração do funcionamento

### 4.1. Estrutura das tabelas

**No `psql` conectado:**

```text
\dt public.*
\d public.pedido_compra
```

**No pgAdmin:** `Databases → integracao_demo → Schemas → public → Tables`.

### 4.2. Registros importados

```sql
SELECT * FROM public.venda ORDER BY venda_id LIMIT 5;
SELECT * FROM public.pedido_compra ORDER BY pedido_id LIMIT 5;
SELECT * FROM public.entradas_mercadoria ORDER BY ordem_compra LIMIT 5;
SELECT * FROM public.produtos_filial ORDER BY filial_id, produto_id LIMIT 5;
SELECT * FROM public.fornecedor ORDER BY idfornecedor LIMIT 5;
```

**Total consolidado:**

```sql
SELECT (SELECT COUNT(*) FROM venda)
     + (SELECT COUNT(*) FROM pedido_compra)
     + (SELECT COUNT(*) FROM entradas_mercadoria)
     + (SELECT COUNT(*) FROM produtos_filial)
     + (SELECT COUNT(*) FROM fornecedor) AS total_registros;
```

### 4.3. Consultas da Parte 2 e validações da Parte 4

**No Terminal, fora do `psql`, na pasta do projeto:**

```bash
psql -d integracao_demo -X -P pager=off -v ON_ERROR_STOP=1 -f sql/02_consultas.sql
psql -d integracao_demo -X -P pager=off -v ON_ERROR_STOP=1 -f sql/04_validacao.sql
```

| Consulta | Resultado esperado na base inicial |
|---|---:|
| Vendas por produto | 14 produtos |
| Pedidos com recebimento pendente | 21 pedidos |
| Validação 1 — recebido acima do pedido | 7 casos |
| Validação 2 — entregue diferente do recebido | 18 casos |
| Validação 3 — ordem de compra zero | 11 casos |
| Validação 4 — entrega anterior ao pedido | 20 casos |
| Validação 5 — produto sem cadastro na filial | 13 casos |
| Validação 6 — entrada sem pedido correspondente | 2 casos |

**Referências rápidas:** no arquivo `sql/02_consultas.sql`, P14 = R$ 5.633,90 em vendas; no `sql/04_validacao.sql`, pedido 2/P2 = 14 pedidos x 64 recebidos (excesso de 50).  
**Observação:** a situação `Nao recebido` pode indicar ausência de vínculo entre pedido e entrada, não necessariamente ausência física da mercadoria.

### 4.4. Transformações da Parte 3

**Transformação 1 — mais de dez registros de pedidos por produto:**

```sql
SELECT CONCAT(produto_id, ' - ', descricao_produto) AS produto,
       SUM(qtde_pedida) AS qtde_requisitada,
       TO_CHAR(MIN(data_pedido), 'DD/MM/YYYY') AS data_solicitacao
FROM pedido_compra
WHERE data_pedido >= '2025-02-01' AND data_pedido < '2025-03-01'
GROUP BY produto_id, descricao_produto
HAVING COUNT(*) > 10
ORDER BY qtde_requisitada DESC;
```

**Resultado inicial:** nenhuma linha.

**Transformação 2 — mais de dez unidades requisitadas por produto:**

```sql
SELECT CONCAT(produto_id, ' - ', descricao_produto) AS produto,
       SUM(qtde_pedida) AS qtde_requisitada,
       TO_CHAR(MIN(data_pedido), 'DD/MM/YYYY') AS data_solicitacao
FROM pedido_compra
WHERE data_pedido >= '2025-02-01' AND data_pedido < '2025-03-01'
GROUP BY produto_id, descricao_produto
HAVING SUM(qtde_pedida) > 10
ORDER BY qtde_requisitada DESC;
```

**Trigger instalada:**

```sql
SELECT tgname AS trigger, tgrelid::regclass AS tabela, tgenabled AS status
FROM pg_trigger
WHERE tgname = 'trg_idfornecedor_produto' AND NOT tgisinternal;

SELECT to_regprocedure('public.fn_idfornecedor_produto()') AS funcao;
```

**Testar geração de fornecedor (alterações descartadas no final):**

```sql
BEGIN;
SELECT set_config('app.nome_fornecedor', 'Fornecedor Demonstracao', true);
INSERT INTO public.produtos_filial
    (filial_id, produto_id, descricao, estoque,
     preco_unitario, preco_compra, preco_venda)
VALUES (1, 'P_DEMO', 'Produto Demonstracao', 0, 0, 0, 0)
RETURNING filial_id, produto_id, idfornecedor;
SELECT idfornecedor, razao_social FROM public.fornecedor
WHERE razao_social = 'Fornecedor Demonstracao';
ROLLBACK;
```

**Resultado:** `idfornecedor` gerado e fornecedor relacionado; `ROLLBACK` desfaz o teste. A função e a trigger já vieram no dump — não recriar para demonstrar.

### 4.5. Origem e implementação

| Etapa | Arquivo |
|---|---|
| Dados originais | `dados/base_teste.xlsx` |
| Estrutura PostgreSQL | `sql/01_ddl_postgres.sql` |
| Importação Python | `scripts/importar.py` |
| Consultas | `sql/02_consultas.sql` |
| Transformações/trigger | `sql/03_transformacoes.sql` |
| Validação | `sql/04_validacao.sql` |
| Base pronta para demonstração | `dados/banco_apresentacao.sql` |

**No MacBook, não é necessário importar novamente a planilha:** a restauração utiliza a exportação já validada.

## 5. Validação — localização e ajustes

**Banco de trabalho:** `integracao_demo`. **Consultas completas:** `sql/04_validacao.sql`.  
**Procedimento:** conferir registro → confirmar valor correto → executar ajuste dentro de `BEGIN`/`ROLLBACK` → repetir validação.  
Os exemplos abaixo são **simulações reversíveis**. Para registrar uma correção aprovada, substituir `ROLLBACK` por `COMMIT` **antes de executar o bloco**. Não assumir que uma divergência é erro sem confirmar a origem dos dados.

| Caso | Encontrados | Local principal |
|---|---:|---|
| 1. Recebimento maior que pedido | 7 | `pedido_compra.qtde_pedida` / `entradas_mercadoria.qtde_recebida` |
| 2. Entregue diferente do recebido | 18 | `pedido_compra.qtde_entregue` / `entradas_mercadoria` |
| 3. Ordem de compra zero | 11 | `pedido_compra.ordem_compra` |
| 4. Entrega anterior ao pedido | 20 | `pedido_compra.data_pedido` / `data_entrega` |
| 5. Produto sem cadastro na filial | 13 | `venda` / `produtos_filial` |
| 6. Entrada sem pedido associado | 2 | `pedido_compra.ordem_compra` / `entradas_mercadoria` |
| Extra. Campos adicionais na planilha | Pedido 21/P12 | `dados/base_teste.xlsx` → aba `pedido_compra` |

### 5.1. Recebimento maior que o pedido

**Exemplo:** pedido 2 / P2 — 14 solicitadas, 64 recebidas. **Verificar:**

```sql
SELECT pedido_id, produto_id, qtde_pedida, qtde_entregue, qtde_pendente
FROM pedido_compra WHERE pedido_id = 2 AND produto_id = 'P2';

SELECT ordem_compra, produto_id, item, nro_nfe, qtde_recebida
FROM entradas_mercadoria WHERE ordem_compra = 2 AND produto_id = 'P2';
```

**Se a quantidade solicitada correta for 64 — alterar `pedido_compra`:**

```sql
BEGIN;
UPDATE pedido_compra
SET qtde_pedida = 64, qtde_pendente = 64 - qtde_entregue
WHERE pedido_id = 2 AND produto_id = 'P2' AND qtde_pedida = 14
RETURNING pedido_id, produto_id, qtde_pedida, qtde_pendente;
ROLLBACK;
```

**Se o recebimento estiver incorreto — alterar `entradas_mercadoria`:** conferir a nota e o item na consulta anterior; substituir os três campos marcados antes de executar.

```sql
BEGIN;
UPDATE entradas_mercadoria
SET qtde_recebida = QUANTIDADE_CONFIRMADA
WHERE ordem_compra = 2 AND produto_id = 'P2'
  AND nro_nfe = 'NFE_CONFIRMADA' AND item = ITEM_CONFIRMADO
RETURNING ordem_compra, produto_id, item, nro_nfe, qtde_recebida;
ROLLBACK;
```

### 5.2. Quantidade entregue diferente do recebimento

**Exemplo:** pedido 1 / P1 — 10 entregues no pedido, 77 registradas na entrada. **Verificar:**

```sql
SELECT pedido_id, qtde_pedida, qtde_entregue, qtde_pendente
FROM pedido_compra WHERE pedido_id = 1 AND produto_id = 'P1';

SELECT ordem_compra, produto_id, item, nro_nfe, qtde_recebida
FROM entradas_mercadoria WHERE ordem_compra = 1 AND produto_id = 'P1';
```

**Se 77 for a quantidade entregue correta — alterar `pedido_compra`:**

```sql
BEGIN;
UPDATE pedido_compra
SET qtde_entregue = 77, qtde_pendente = qtde_pedida - 77
WHERE pedido_id = 1 AND produto_id = 'P1' AND qtde_entregue = 10
RETURNING pedido_id, qtde_entregue, qtde_pendente;
ROLLBACK;
```

### 5.3. Ordem de compra igual a zero

**Exemplo:** pedido 19 / P19. **Verificar:**

```sql
SELECT pedido_id, produto_id, ordem_compra, qtde_pedida
FROM pedido_compra WHERE ordem_compra = 0 ORDER BY pedido_id;
```

**Se a ordem correta for 19 — alterar `pedido_compra`:**

```sql
BEGIN;
UPDATE pedido_compra SET ordem_compra = 19
WHERE pedido_id = 19 AND produto_id = 'P19' AND ordem_compra = 0
RETURNING pedido_id, produto_id, ordem_compra;
ROLLBACK;
```

### 5.4. Data de entrega anterior à data do pedido

**Exemplo:** pedido 12/P12 — pedido 25/02/2025; entrega 20/02/2025. **Verificar:**

```sql
SELECT pedido_id, produto_id, data_pedido, data_entrega
FROM pedido_compra WHERE pedido_id = 12 AND produto_id = 'P12';
```

**Se as datas foram invertidas — alterar `pedido_compra`:**

```sql
BEGIN;
UPDATE pedido_compra
SET data_pedido = data_entrega, data_entrega = data_pedido
WHERE pedido_id = 12 AND produto_id = 'P12'
  AND data_pedido = DATE '2025-02-25'
  AND data_entrega = DATE '2025-02-20'
RETURNING pedido_id, data_pedido, data_entrega;
ROLLBACK;
```

### 5.5. Produto sem cadastro na filial

**Exemplo:** venda 21 / filial 1 / produto P21. **Verificar:**

```sql
SELECT venda_id, filial_id, produto_id FROM venda WHERE venda_id = 21;
SELECT filial_id, produto_id, descricao, idfornecedor
FROM produtos_filial WHERE filial_id = 1 AND produto_id = 'P21';
SELECT idfornecedor, razao_social FROM fornecedor ORDER BY idfornecedor;
```

**Se o código da venda estiver incorreto — alterar `venda.produto_id` (substituir `PRODUTO_CONFIRMADO`):**

```sql
BEGIN;
UPDATE venda SET produto_id = 'PRODUTO_CONFIRMADO'
WHERE venda_id = 21 AND filial_id = 1 AND produto_id = 'P21'
  AND EXISTS (
    SELECT 1 FROM produtos_filial
    WHERE filial_id = 1 AND produto_id = 'PRODUTO_CONFIRMADO'
  )
RETURNING venda_id, filial_id, produto_id;
ROLLBACK;
```

**Se o cadastro estiver ausente — inserir em `produtos_filial`:** utilizar descrição, preços e fornecedor confirmados. Um `idfornecedor` existente pode ser consultado em `fornecedor`; a trigger também permite gerar outro fornecedor quando o nome é informado previamente.

**Modelo de teste de cadastro com fornecedor existente (substituir dados confirmados):**

```sql
BEGIN;
INSERT INTO produtos_filial
  (filial_id, produto_id, descricao, estoque,
   preco_unitario, preco_compra, preco_venda, idfornecedor)
VALUES
  (1, 'P21', 'DESCRICAO_CONFIRMADA', 0, 0, 0, 0, 'FORNECEDOR_CONFIRMADO')
RETURNING filial_id, produto_id, idfornecedor;
ROLLBACK;
```

### 5.6. Entrada sem pedido correspondente

**Exemplos:** NFE19/P19/ordem 19 e NFE20/P20/ordem 20. **Verificar:**

```sql
SELECT ordem_compra, produto_id, qtde_recebida, nro_nfe
FROM entradas_mercadoria WHERE nro_nfe IN ('NFE19', 'NFE20');
SELECT pedido_id, produto_id, ordem_compra, qtde_pedida
FROM pedido_compra WHERE produto_id IN ('P19', 'P20') ORDER BY pedido_id;
```

**Se as entradas corresponderem aos pedidos 19 e 20 — ajustar `pedido_compra`:**

```sql
BEGIN;
UPDATE pedido_compra SET ordem_compra = 19
WHERE pedido_id = 19 AND produto_id = 'P19' AND ordem_compra = 0;
UPDATE pedido_compra SET ordem_compra = 20
WHERE pedido_id = 20 AND produto_id = 'P20' AND ordem_compra = 0;
SELECT pedido_id, produto_id, ordem_compra
FROM pedido_compra WHERE pedido_id IN (19, 20);
ROLLBACK;
```

**Se a ordem da entrada estiver incorreta — alterar `entradas_mercadoria`:** substituir `ORDEM_CONFIRMADA` e `ITEM_CONFIRMADO` após identificar o registro.

```sql
BEGIN;
UPDATE entradas_mercadoria
SET ordem_compra = ORDEM_CONFIRMADA
WHERE nro_nfe = 'NFE19' AND produto_id = 'P19'
  AND ordem_compra = 19 AND item = ITEM_CONFIRMADO
RETURNING ordem_compra, produto_id, item, nro_nfe;
ROLLBACK;
```

Ajustar somente o registro confirmado; o vínculo pode estar incorreto no pedido ou na entrada.

### 5.7. Colunas adicionais no Excel

**Origem:** `dados/base_teste.xlsx` → aba `pedido_compra` → pedido 21/P12. Os campos adicionais podem corresponder ao pedido 12; não sobrescrever automaticamente o registro 21.

```sql
SELECT pedido_id, produto_id, ordem_compra,
       qtde_pedida, qtde_entregue, qtde_pendente
FROM pedido_compra
WHERE (pedido_id = 21 AND produto_id = 'P12')
   OR (pedido_id = 12 AND produto_id = 'P12')
ORDER BY pedido_id;
```

**Antes de alterar:** identificar na planilha quais colunas e qual linha representam o pedido válido. A importação atual utiliza as colunas principais, sem aplicar automaticamente os campos adicionais.

**Se os campos adicionais forem confirmados como valores corretos do pedido 21 — simular o ajuste:**

```sql
BEGIN;
UPDATE pedido_compra
SET ordem_compra = 12, qtde_pedida = 91,
    qtde_entregue = 48, qtde_pendente = 43
WHERE pedido_id = 21 AND produto_id = 'P12' AND ordem_compra = 0
RETURNING pedido_id, produto_id, ordem_compra,
          qtde_pedida, qtde_entregue, qtde_pendente;
ROLLBACK;
```

**Conferir duplicidade:** a ordem 12/P12 já aparece no pedido 12. Não efetivar o ajuste sem validar se os registros 12 e 21 representam pedidos distintos.

### 5.8. Repetir as validações

**Terminal, fora do `psql`:**

```bash
psql -d integracao_demo -X -P pager=off -v ON_ERROR_STOP=1 -f sql/04_validacao.sql
```

**No Query Tool:** clicar em **Open File (ícone de pasta)**, abrir `sql/04_validacao.sql`, selecionar a consulta desejada e clicar em **Execute (▶)**.  
**`ROLLBACK`** desfaz a simulação · **`COMMIT`** grava somente a alteração autorizada.  
Mudanças em `integracao_demo` não alteram o Excel nem o banco original do Codespaces.

## 6. Solução rápida de problemas

| Situação | Verificação / ação |
|---|---|
| `psql: command not found` | Adicionar a pasta `bin` do PostgreSQL ao `PATH` (seção 2.2) ou instalar Postgres.app (2.3). |
| `connection refused` / `no response` | Iniciar serviço PostgreSQL e conferir host/porta (`pg_isready`). |
| `role ... does not exist` | Informar o usuário PostgreSQL correto em `PGUSER`; Postgres.app costuma usar o login do macOS. |
| `password authentication failed` | Confirmar usuário/senha com o professor; não registrar a senha no projeto. |
| `permission denied to create database` | Solicitar criação por conta autorizada ou banco vazio disponibilizado pelo professor. |
| `database ... already exists` | Não executar a restauração sobre tabelas existentes; escolher um banco novo. |
| `relation ... already exists` | O dump foi executado em banco não vazio; utilizar banco recém-criado. |
| `No such file or directory` | Confirmar pasta com `pwd` e arquivo com `ls dados/banco_apresentacao.sql`. |
| `COPY` / `syntax error at "\\"` no pgAdmin | Executar o arquivo pelo Terminal com `psql -f`, não colar o dump no Query Tool. |
| `port 5432 already in use` | Já existe um serviço local nessa porta; conectar ao existente ou usar a porta autorizada. Não desligar serviços do professor sem autorização. |
| Instalação bloqueada / sem permissão no Mac | Solicitar autorização ao professor ou administrador; não instalar nem alterar serviços sem autorização. |
| Consulta sem resultados após correção | Conferir banco conectado (`SELECT current_database();`) e repetir a validação pertinente. |

**Referências de instalação:** https://postgresapp.com/documentation/install.html · https://www.pgadmin.org/download/pgadmin-4-macos/
