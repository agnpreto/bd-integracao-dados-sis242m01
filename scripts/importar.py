
import os
import pandas as pd
import psycopg2
from pathlib import Path
from datetime import datetime, date, timedelta

# Configuracoes
# Caminho da planilha original, que nao sera alterada
ARQUIVO = Path(__file__).resolve().parent.parent / "dados" / "base_teste.xlsx"

# Conexao local com o PostgreSQL do Codespaces
# As configuracoes podem ser alteradas por variaveis de ambiente
DB = {
    "host": os.getenv("PGHOST", "/var/run/postgresql"),
    "port": int(os.getenv("PGPORT", "5432")),
    "database": os.getenv("PGDATABASE", "integracao_teste"),
    "user": os.getenv("PGUSER", "codespace")
}

# A senha so sera utilizada se estiver configurada no ambiente
if os.getenv("PGPASSWORD"):
    DB["password"] = os.getenv("PGPASSWORD")


# Converte os diferentes formatos de data encontrados no Excel
def excel_para_data(valor):
    if pd.isna(valor):
        return None

    if isinstance(valor, (datetime, pd.Timestamp)):
        return valor.date()

    if isinstance(valor, date):
        return valor

    # Algumas planilhas armazenam datas como numeros
    if isinstance(valor, (int, float)):
        return (datetime(1899, 12, 30) + timedelta(days=float(valor))).date()

    return pd.to_datetime(valor, dayfirst=True, errors="raise").date()


# Trata campos de texto e valores vazios
def texto(valor):
    if pd.isna(valor):
        return None
    return str(valor).strip()


# Converte valores numericos sem inventar dados ausentes
def numero(valor, padrao=None):
    if pd.isna(valor):
        return padrao
    return float(valor)


# Converte identificadores e outros campos inteiros
def inteiro(valor, padrao=None):
    if pd.isna(valor):
        return padrao

    valor_numerico = float(valor)

    if not valor_numerico.is_integer():
        raise ValueError(f"Valor inteiro invalido: {valor}")

    return int(valor_numerico)


# Prepara os dados dos fornecedores
def dados_fornecedor(row):
    return (
        texto(row["idfornecedor"]),
        texto(row["razao_social"])
    )


# Prepara os dados dos produtos por filial
def dados_produtos_filial(row):
    return (
        inteiro(row["filial_id"]),
        texto(row["idproduto"]),
        texto(row["descricao"]),
        numero(row["estoque"], 0),
        numero(row["preco_unitario"], 0),
        numero(row["preco_compra"], 0),
        numero(row["preco_venda"], 0),
        texto(row["idfornecedor"])
    )


# Prepara os dados dos pedidos de compra
def dados_pedido_compra(row):
    pedida = numero(row["qtde_pedida"])
    entregue = numero(row["qtde_entregue"], 0)

    # Calcula a quantidade pendente
    pendente = pedida - entregue if pedida is not None else 0

    return (
        numero(row["pedido_id"]),
        excel_para_data(row["data_pedido"]),
        numero(row["item"]),
        texto(row["produto_id"]),
        texto(row["descricao_produto"]),
        numero(row["ordem_compra"], 0),
        pedida,
        inteiro(row["filial_id"]),
        excel_para_data(row["data_entrega"]),
        entregue,
        pendente,
        numero(row["preco_compra"], 0),
        inteiro(row["fornecedor_id"])
    )


# Prepara os dados das entradas de mercadoria
def dados_entradas_mercadoria(row):
    return (
        excel_para_data(row["data_entrada"]),
        texto(row["nro_nfe"]),
        numero(row["item"]),
        texto(row["produto_id"]),
        texto(row["descricao_produto"]),
        numero(row["ordem_compra"], 0),
        numero(row["qtde_recebida"]),
        inteiro(row["filial_id"]),
        numero(row["custo_unitario"], 0)
    )


# Prepara os dados das vendas
def dados_venda(row):
    return (
        inteiro(row["venda_id"]),
        excel_para_data(row["data_emissao"]),
        texto(row["horariomov"]) or "00:00:00",
        texto(row["produto_id"]),
        numero(row["qtde_vendida"]),
        numero(row["valor_unitario"], 0),
        inteiro(row["filial_id"], 1),
        inteiro(row["item"], 0),
        texto(row["unidade_medida"])
    )


# Comandos de insercao nas cinco tabelas
# ON CONFLICT evita inserir novamente uma chave primaria existente
COMANDOS = {
    "fornecedor": """
        INSERT INTO public.fornecedor (idfornecedor, razao_social)
        VALUES (%s, %s)
        ON CONFLICT (idfornecedor) DO NOTHING
    """,

    "produtos_filial": """
        INSERT INTO public.produtos_filial
            (filial_id, produto_id, descricao, estoque,
             preco_unitario, preco_compra, preco_venda, idfornecedor)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (filial_id, produto_id) DO NOTHING
    """,

    "pedido_compra": """
        INSERT INTO public.pedido_compra
            (pedido_id, data_pedido, item, produto_id, descricao_produto,
             ordem_compra, qtde_pedida, filial_id, data_entrega,
             qtde_entregue, qtde_pendente, preco_compra, fornecedor_id)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (pedido_id, produto_id, item) DO NOTHING
    """,

    "entradas_mercadoria": """
        INSERT INTO public.entradas_mercadoria
            (data_entrada, nro_nfe, item, produto_id, descricao_produto,
             ordem_compra, qtde_recebida, filial_id, custo_unitario)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (ordem_compra, item, produto_id, nro_nfe) DO NOTHING
    """,

    "venda": """
        INSERT INTO public.venda
            (venda_id, data_emissao, horariomov, produto_id,
             qtde_vendida, valor_unitario, filial_id, item, unidade_medida)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
        DO NOTHING
    """
}


# Associa cada tabela a sua funcao de conversao
CONVERSORES = {
    "fornecedor": dados_fornecedor,
    "produtos_filial": dados_produtos_filial,
    "pedido_compra": dados_pedido_compra,
    "entradas_mercadoria": dados_entradas_mercadoria,
    "venda": dados_venda
}


# Faz a importacao de uma aba e confere os registros
def importar_tabela(conn, cur, tabela):
    print(f"\nImportando {tabela}...")

    df = pd.read_excel(ARQUIVO, sheet_name=tabela)
    df.columns = df.columns.str.strip()

    # A aba pedido_compra possui colunas extras sem cabecalho.
    # Por enquanto, usamos as 12 colunas principais.
    # As colunas extras serao analisadas na validacao.
    if tabela == "pedido_compra":
        colunas_principais = [
            "pedido_id", "data_pedido", "item", "produto_id",
            "descricao_produto", "ordem_compra", "qtde_pedida",
            "filial_id", "data_entrega", "qtde_entregue",
            "preco_compra", "fornecedor_id"
        ]

        extras = [c for c in df.columns if c not in colunas_principais]

        if extras:
            linhas_extras = df[extras].notna().any(axis=1).sum()
            print(f"  ATENCAO: {len(extras)} colunas adicionais encontradas.")
            print(f"  Linhas com informacoes extras: {linhas_extras}")
            print("  Os dados extras nao serao descartados do Excel.")
            print("  Sera necessario avaliar essas informacoes na validacao.")

        df = df[colunas_principais].copy()

    inseridos = 0
    ignorados = 0
    erros = 0

    for indice, row in df.iterrows():
        # Um SAVEPOINT permite desfazer apenas a linha com erro
        cur.execute("SAVEPOINT antes_linha")

        try:
            valores = CONVERSORES[tabela](row)
            cur.execute(COMANDOS[tabela], valores)

            if cur.rowcount == 1:
                inseridos += 1
            else:
                ignorados += 1

            cur.execute("RELEASE SAVEPOINT antes_linha")

        except Exception as erro:
            # Mantem os registros anteriores mesmo se esta linha falhar
            cur.execute("ROLLBACK TO SAVEPOINT antes_linha")
            cur.execute("RELEASE SAVEPOINT antes_linha")

            erros += 1
            print(f"  Erro na linha {indice + 2} do Excel: {erro}")

    # Confirma os registros validos desta tabela
    conn.commit()

    # Confere a quantidade real de registros no banco
    cur.execute(f"SELECT COUNT(*) FROM public.{tabela}")
    total_banco = cur.fetchone()[0]

    print(f"  Linhas na planilha: {len(df)}")
    print(f"  Registros inseridos nesta execucao: {inseridos}")
    print(f"  Registros ignorados por chave existente: {ignorados}")
    print(f"  Registros com erro: {erros}")
    print(f"  Total atual no banco: {total_banco}")

    if erros > 0 or ignorados > 0:
        print("  ATENCAO: existem diferencas que precisam ser verificadas.")

    return erros


# Execucao principal da importacao
def main():
    print("=" * 45)
    print("INTEGRACAO DE DADOS - EXCEL E POSTGRESQL")
    print("=" * 45)

    print("\nConectando ao PostgreSQL...")

    conn = psycopg2.connect(**DB)

    total_erros = 0

    try:
        with conn.cursor() as cur:
            print("Conexao realizada com sucesso!")

            # Importa as cinco abas na ordem definida
            tabelas = [
                "fornecedor",
                "produtos_filial",
                "pedido_compra",
                "entradas_mercadoria",
                "venda"
            ]

            for tabela in tabelas:
                total_erros += importar_tabela(conn, cur, tabela)

    finally:
        conn.close()

    print("\n" + "=" * 45)

    if total_erros == 0:
        print("Execucao da importacao finalizada.")
        print("Confira as quantidades e valide os dados.")
    else:
        print(f"Importacao finalizada com {total_erros} erros.")
        print("Os registros com erro precisam ser analisados.")

    print("=" * 45)


if __name__ == "__main__":
    main()
