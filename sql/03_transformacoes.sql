
-- Parte 3: Transformacoes SQL
-- Nome: RENISON

-- Este arquivo contem duas consultas de produtos requisitados
-- e uma automacao para o cadastro de fornecedores.
--
-- As consultas utilizam os dados importados para o PostgreSQL.
-- A funcao e a trigger utilizam PL/pgSQL, linguagem do PostgreSQL.
--
-- As duas primeiras transformacoes apenas consultam os registros.
-- A terceira cria uma funcao e uma trigger que podem modificar
-- dados quando um produto e cadastrado ou atualizado.

-- Transformacao 1: Produtos requisitados mais de 10 vezes.
-- "mais de 10 vezes" significa que o produto
-- apareceu em mais de 10 registros de pedidos no periodo.
-- Nos dados de fevereiro de 2025, nenhum produto atende
-- a esse criterio, pois cada produto aparece no maximo 2 vezes.

-- Objetivo: identificar produtos que aparecem em mais
-- de dez registros de pedidos durante fevereiro de 2025.
--
-- Esta consulta utiliza a tabela pedido_compra.
-- O criterio considera a quantidade de registros,
-- e nao a soma das unidades solicitadas.

-- SELECT escolhe as informacoes apresentadas no resultado.
SELECT
    -- CONCAT junta o codigo e a descricao do produto.
    -- O separador ' - ' facilita a identificacao.
    -- AS produto define o nome da coluna apresentada.
    CONCAT(produto_id, ' - ', descricao_produto) AS produto,

    -- SUM soma as unidades solicitadas do mesmo produto.
    -- AS qtde_requisitada nomeia o total calculado.
    SUM(qtde_pedida) AS qtde_requisitada,

    -- MIN encontra a data mais antiga do grupo.
    -- TO_CHAR apresenta essa data no formato dia/mes/ano.
    TO_CHAR(MIN(data_pedido), 'DD/MM/YYYY') AS data_solicitacao

-- FROM identifica a tabela utilizada na consulta.
FROM pedido_compra

-- WHERE seleciona somente os pedidos de fevereiro de 2025.
-- A primeira condicao inclui os pedidos a partir de 01/02.
-- A segunda exclui os pedidos a partir de 01/03.
WHERE data_pedido >= '2025-02-01'
  AND data_pedido < '2025-03-01'

-- GROUP BY agrupa os pedidos do mesmo produto e descricao.
-- Isso permite calcular o total solicitado por produto.
GROUP BY produto_id, descricao_produto

-- HAVING filtra os grupos depois do agrupamento.
-- COUNT(*) conta quantos registros existem em cada grupo.
-- Somente produtos com mais de dez registros aparecem.
HAVING COUNT(*) > 10

-- ORDER BY organiza os resultados pela quantidade requisitada.
-- DESC significa ordem decrescente, do maior para o menor.
ORDER BY qtde_requisitada DESC;


-- Transformacao 2: Consulta complementar por quantidade.
-- Nessa alternativa, consideramos os produtos com mais
-- de 10 unidades requisitadas no periodo.
-- Essa interpretacao e diferente de "mais de 10 vezes".

-- Objetivo: encontrar produtos cuja soma das quantidades
-- solicitadas ultrapassa dez unidades em fevereiro de 2025.
--
-- Diferenca em relacao a Transformacao 1:
-- a primeira utiliza COUNT(*) para contar registros.
-- esta segunda utiliza SUM(qtde_pedida) para somar unidades.
--
-- Exemplo: um unico pedido com 20 unidades atende
-- a esta consulta, mas nao atende a Transformacao 1.

SELECT
    -- Junta o codigo e a descricao do produto.
    CONCAT(produto_id, ' - ', descricao_produto) AS produto,

    -- Soma as quantidades pedidas do mesmo produto.
    SUM(qtde_pedida) AS qtde_requisitada,

    -- Identifica a primeira data de pedido do grupo.
    -- Converte a data para o formato DD/MM/AAAA.
    TO_CHAR(MIN(data_pedido), 'DD/MM/YYYY') AS data_solicitacao

-- Consulta os registros armazenados em pedido_compra.
FROM pedido_compra

-- Considera somente os pedidos de fevereiro de 2025.
WHERE data_pedido >= '2025-02-01'
  AND data_pedido < '2025-03-01'

-- Agrupa os pedidos pelo codigo e descricao do produto.
GROUP BY produto_id, descricao_produto

-- Retorna somente os grupos cuja soma ultrapassa
-- dez unidades solicitadas.
HAVING SUM(qtde_pedida) > 10

-- Mostra primeiro os produtos com maior quantidade solicitada.
ORDER BY qtde_requisitada DESC;


-- Transformacao 3: Trigger para gerar um novo idfornecedor.
-- Quando um produto for cadastrado sem idfornecedor, a trigger
-- gera um codigo F seguido de numero, cadastra o fornecedor
-- e relaciona esse codigo ao produto.
-- O nome do novo fornecedor deve ser informado previamente.
-- Se um codigo existente for informado, verifica se ele e valido.

-- Objetivo: automatizar a identificacao de fornecedores
-- associados aos produtos cadastrados nas filiais.
--
-- Essa automacao utiliza duas tabelas:
-- produtos_filial: armazena os produtos e seus fornecedores.
-- fornecedor: armazena o codigo e a razao social do fornecedor.
--
-- A funcao define o procedimento que sera executado.
-- A trigger determina quando esse procedimento sera acionado.
--
-- Exemplo:
-- Ao cadastrar um produto sem idfornecedor, a funcao
-- pode gerar um codigo como F21 e cadastrar o fornecedor.
--
-- O numero gerado depende dos codigos existentes no banco.
-- O nome do novo fornecedor precisa estar informado
-- previamente na configuracao da sessao.

-- CREATE OR REPLACE FUNCTION cria a funcao ou substitui
-- sua definicao caso ela ja exista no banco.
-- public indica o esquema onde a funcao sera armazenada.
CREATE OR REPLACE FUNCTION public.fn_idfornecedor_produto()

-- RETURNS TRIGGER indica que esta funcao sera usada
-- por uma trigger, e nao como uma consulta comum.
RETURNS TRIGGER

-- LANGUAGE plpgsql identifica a linguagem utilizada.
-- PL/pgSQL permite trabalhar com variaveis e condicoes.
LANGUAGE plpgsql

-- AS $$ inicia o corpo da funcao.
-- Tudo entre os dois delimitadores $$ pertence a funcao.
AS $$

-- DECLARE e utilizado para declarar variaveis.
DECLARE
    -- Armazena temporariamente o nome do fornecedor.
    -- TEXT permite guardar informacoes textuais.
    v_nome TEXT;

    -- Armazena o proximo numero do codigo do fornecedor.
    -- BIGINT representa um numero inteiro de 64 bits.
    v_numero BIGINT;

-- BEGIN inicia os comandos executados pela funcao.
BEGIN
    -- NEW representa os dados do produto que esta
    -- sendo cadastrado ou atualizado.
    --
    -- BTRIM remove espacos do inicio e do fim do texto.
    -- NULLIF transforma texto vazio em NULL.
    --
    -- IF verifica se o identificador nao foi informado.
    IF NULLIF(BTRIM(NEW.idfornecedor), '') IS NULL THEN

        -- current_setting consulta a configuracao
        -- app.nome_fornecedor da sessao do PostgreSQL.
        --
        -- O parametro true permite retornar NULL
        -- quando a configuracao nao estiver disponivel.
        --
        -- BTRIM remove espacos extras.
        -- NULLIF transforma um texto vazio em NULL.
        --
        -- O resultado e guardado na variavel v_nome.
        v_nome := NULLIF(
            BTRIM(current_setting('app.nome_fornecedor', true)),
            ''
        );

        -- Verifica se o nome do fornecedor foi informado.
        IF v_nome IS NULL THEN

            -- RAISE EXCEPTION interrompe a operacao
            -- e apresenta uma mensagem de erro.
            --
            -- Isso impede cadastrar um fornecedor novo
            -- sem uma razao social informada.
            RAISE EXCEPTION
                'Informe o nome do novo fornecedor antes do cadastro';
        END IF;

        -- Evita que duas execucoes desta trigger gerem o mesmo ID.
        -- pg_advisory_xact_lock aplica um bloqueio
        -- durante a transacao atual.
        --
        -- O numero 35791 identifica esse bloqueio.
        -- Ele ajuda a evitar que duas execucoes simultaneas
        -- escolham o mesmo codigo para novos fornecedores.
        PERFORM pg_advisory_xact_lock(35791);

        -- Procura o maior codigo no formato F1, F2, F3...
        -- SELECT procura os identificadores existentes.
        -- SUBSTRING extrai a parte numerica depois do F.
        -- ::BIGINT converte essa parte para numero inteiro.
        --
        -- MAX encontra o maior numero ja cadastrado.
        -- COALESCE utiliza zero se nao houver nenhum.
        -- O + 1 calcula o numero do proximo fornecedor.
        --
        -- INTO armazena esse resultado em v_numero.
        SELECT COALESCE(
            MAX(SUBSTRING(idfornecedor FROM 2)::BIGINT), 0
        ) + 1
        INTO v_numero
        FROM public.fornecedor

        -- A expressao regular seleciona apenas codigos
        -- que comecam com F e continuam com numeros.
        -- Exemplos aceitos: F1, F20 e F150.
        WHERE idfornecedor ~ '^F[0-9]+$';

        -- Monta o novo codigo juntando F com v_numero.
        -- O operador || realiza a concatenacao de textos.
        --
        -- NEW.idfornecedor recebe o codigo gerado.
        -- Assim, o produto fica associado ao novo fornecedor.
        NEW.idfornecedor := 'F' || v_numero;

        -- INSERT INTO cadastra um novo registro.
        -- O codigo gerado vai para idfornecedor.
        -- O nome informado vai para razao_social.
        INSERT INTO public.fornecedor (idfornecedor, razao_social)
        VALUES (NEW.idfornecedor, v_nome);

    -- ELSIF representa uma segunda condicao.
    -- Ela e verificada quando o produto ja possui
    -- um codigo de fornecedor informado.
    --
    -- NOT EXISTS verifica se nao existe um fornecedor
    -- cadastrado com aquele mesmo identificador.
    ELSIF NOT EXISTS (
        SELECT 1
        FROM public.fornecedor
        WHERE idfornecedor = NEW.idfornecedor
    ) THEN

        -- Se o codigo informado nao existir na tabela
        -- fornecedor, a operacao sera interrompida.
        --
        -- O simbolo % sera substituido pelo codigo
        -- informado no registro do produto.
        RAISE EXCEPTION
            'Fornecedor % nao encontrado', NEW.idfornecedor;
    END IF;

    -- RETURN NEW devolve o registro do produto
    -- com os valores definidos pela funcao.
    -- Como a trigger e BEFORE, o PostgreSQL utiliza
    -- esse registro para continuar a operacao.
    RETURN NEW;

-- END finaliza o corpo da funcao.
END;

-- Encerra a definicao da funcao PL/pgSQL.
$$;

-- Permite executar este arquivo novamente sem duplicar a trigger.
-- DROP TRIGGER IF EXISTS remove a trigger anterior
-- somente se ela ja estiver cadastrada na tabela.
-- Isso evita erro ao criar novamente uma trigger
-- com o mesmo nome.
DROP TRIGGER IF EXISTS trg_idfornecedor_produto
ON public.produtos_filial;

-- CREATE TRIGGER registra a automacao na tabela.
CREATE TRIGGER trg_idfornecedor_produto

-- BEFORE determina que a funcao seja executada
-- antes da operacao que acionou a trigger.
--
-- INSERT aciona a trigger ao cadastrar um produto.
-- UPDATE OF idfornecedor aciona a trigger quando
-- essa coluna e mencionada em uma atualizacao.
BEFORE INSERT OR UPDATE OF idfornecedor

-- Define a tabela que possui a trigger.
ON public.produtos_filial

-- FOR EACH ROW executa a funcao para cada linha
-- afetada pela insercao ou atualizacao.
FOR EACH ROW

-- EXECUTE FUNCTION identifica qual funcao
-- sera chamada automaticamente pela trigger.
EXECUTE FUNCTION public.fn_idfornecedor_produto();
