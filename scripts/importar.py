import os
import pandas as pd
import psycopg2
from datetime import datetime, timedelta

ARQUIVO = "dados/base_teste.xlsx"

DB = {
    "host": "localhost",
    "port": 5432,
    "database": "integracao_dados",
    "user": "postgres",
    "password": os.getenv("DB_PASSWORD", "12345")
}


def excel_para_data(valor):
    if pd.isna(valor):
        return None

    if isinstance(valor, (pd.Timestamp, datetime)):
        return valor.date()

    if hasattr(valor, "year") and hasattr(valor, "month") and hasattr(valor, "day"):
        return valor

    try:
        return (
            datetime(1899, 12, 30) +
            timedelta(days=float(valor))
        ).date()
    except (ValueError, TypeError, OverflowError):
        return None


def texto_seguro(valor):
    if pd.isna(valor):
        return None
    return str(valor).strip()


def numero_seguro(valor, padrao=None):
    if pd.isna(valor):
        return padrao
    return float(valor)


def inteiro_seguro(valor, padrao=None):
    if pd.isna(valor):
        return padrao
    return int(valor)


print("Conectando no PostgreSQL...")

conn = psycopg2.connect(**DB)
cur = conn.cursor()

print("Conectado!\n")


print("Importando fornecedor...")

df = pd.read_excel(ARQUIVO, sheet_name="fornecedor")
df.columns = df.columns.str.strip()

inseridos = 0

for indice, row in df.iterrows():
    try:
        cur.execute("""
            INSERT INTO public.fornecedor
                (idfornecedor, razao_social)
            VALUES (%s, %s)
            ON CONFLICT (idfornecedor) DO NOTHING
        """, (
            texto_seguro(row["idfornecedor"]),
            texto_seguro(row["razao_social"])
        ))

        if cur.rowcount > 0:
            inseridos += 1

    except Exception as e:
        print(f"Erro fornecedor linha {indice}: {e}")
        conn.rollback()
        continue

conn.commit()

print(f"{inseridos} registros inseridos em fornecedor.\n")


print("Importando produtos_filial...")

df = pd.read_excel(ARQUIVO, sheet_name="produtos_filial")
df.columns = df.columns.str.strip()

inseridos = 0

for indice, row in df.iterrows():
    try:
        cur.execute("""
            INSERT INTO public.produtos_filial
                (
                    filial_id,
                    produto_id,
                    descricao,
                    estoque,
                    preco_unitario,
                    preco_compra,
                    preco_venda,
                    idfornecedor
                )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (filial_id, produto_id) DO NOTHING
        """, (
            inteiro_seguro(row["filial_id"]),
            texto_seguro(row["idproduto"]),
            texto_seguro(row["descricao"]),
            numero_seguro(row["estoque"], 0),
            numero_seguro(row["preco_unitario"], 0),
            numero_seguro(row["preco_compra"], 0),
            numero_seguro(row["preco_venda"], 0),
            texto_seguro(row["idfornecedor"])
        ))

        if cur.rowcount > 0:
            inseridos += 1

    except Exception as e:
        print(f"Erro produtos_filial linha {indice}: {e}")
        conn.rollback()
        continue

conn.commit()

print(f"{inseridos} registros inseridos em produtos_filial.\n")


print("Importando pedido_compra...")

df = pd.read_excel(ARQUIVO, sheet_name="pedido_compra")
df.columns = df.columns.str.strip()

df = df.iloc[:, :12].copy()

df.columns = [
    "pedido_id",
    "data_pedido",
    "item",
    "produto_id",
    "descricao_produto",
    "ordem_compra",
    "qtde_pedida",
    "filial_id",
    "data_entrega",
    "qtde_entregue",
    "preco_compra",
    "fornecedor_id"
]

inseridos = 0

for indice, row in df.iterrows():
    try:
        qtde_pedida = numero_seguro(row["qtde_pedida"], 0)
        qtde_entregue = numero_seguro(row["qtde_entregue"], 0)

        qtde_pendente = qtde_pedida - qtde_entregue

        cur.execute("""
            INSERT INTO public.pedido_compra
                (
                    pedido_id,
                    data_pedido,
                    item,
                    produto_id,
                    descricao_produto,
                    ordem_compra,
                    qtde_pedida,
                    filial_id,
                    data_entrega,
                    qtde_entregue,
                    qtde_pendente,
                    preco_compra,
                    fornecedor_id
                )
            VALUES (%s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s)
            ON CONFLICT (pedido_id, produto_id, item) DO NOTHING
        """, (
            numero_seguro(row["pedido_id"]),
            excel_para_data(row["data_pedido"]),
            numero_seguro(row["item"]),
            texto_seguro(row["produto_id"]),
            texto_seguro(row["descricao_produto"]),
            numero_seguro(row["ordem_compra"]),
            qtde_pedida,
            inteiro_seguro(row["filial_id"]),
            excel_para_data(row["data_entrega"]),
            qtde_entregue,
            qtde_pendente,
            numero_seguro(row["preco_compra"], 0),
            inteiro_seguro(row["fornecedor_id"])
        ))

        if cur.rowcount > 0:
            inseridos += 1

    except Exception as e:
        print(f"Erro pedido_compra linha {indice}: {e}")
        conn.rollback()
        continue

conn.commit()

print(f"{inseridos} registros inseridos em pedido_compra.\n")


print("Importando entradas_mercadoria...")

df = pd.read_excel(ARQUIVO, sheet_name="entradas_mercadoria")
df.columns = df.columns.str.strip()

inseridos = 0

for indice, row in df.iterrows():
    try:
        cur.execute("""
            INSERT INTO public.entradas_mercadoria
                (
                    data_entrada,
                    nro_nfe,
                    item,
                    produto_id,
                    descricao_produto,
                    ordem_compra,
                    qtde_recebida,
                    filial_id,
                    custo_unitario
                )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT
                (ordem_compra, item, produto_id, nro_nfe)
            DO NOTHING
        """, (
            excel_para_data(row["data_entrada"]),
            texto_seguro(row["nro_nfe"]),
            numero_seguro(row["item"]),
            texto_seguro(row["produto_id"]),
            texto_seguro(row["descricao_produto"]),
            numero_seguro(row["ordem_compra"]),
            numero_seguro(row["qtde_recebida"]),
            inteiro_seguro(row["filial_id"]),
            numero_seguro(row["custo_unitario"], 0)
        ))

        if cur.rowcount > 0:
            inseridos += 1

    except Exception as e:
        print(f"Erro entradas_mercadoria linha {indice}: {e}")
        conn.rollback()
        continue

conn.commit()

print(f"{inseridos} registros inseridos em entradas_mercadoria.\n")


print("Importando venda...")

df = pd.read_excel(ARQUIVO, sheet_name="venda")
df.columns = df.columns.str.strip()

inseridos = 0

for indice, row in df.iterrows():
    try:
        cur.execute("""
            INSERT INTO public.venda
                (
                    venda_id,
                    data_emissao,
                    horariomov,
                    produto_id,
                    qtde_vendida,
                    valor_unitario,
                    filial_id,
                    item,
                    unidade_medida
                )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT
                (
                    filial_id,
                    venda_id,
                    data_emissao,
                    produto_id,
                    item,
                    horariomov
                )
            DO NOTHING
        """, (
            inteiro_seguro(row["venda_id"]),
            excel_para_data(row["data_emissao"]),
            texto_seguro(row["horariomov"]) or "00:00:00",
            texto_seguro(row["produto_id"]),
            numero_seguro(row["qtde_vendida"]),
            numero_seguro(row["valor_unitario"], 0),
            inteiro_seguro(row["filial_id"], 1),
            inteiro_seguro(row["item"], 0),
            texto_seguro(row["unidade_medida"])
        ))

        if cur.rowcount > 0:
            inseridos += 1

    except Exception as e:
        print(f"Erro venda linha {indice}: {e}")
        conn.rollback()
        continue

conn.commit()

print(f"{inseridos} registros inseridos em venda.\n")


cur.close()
conn.close()

print("=" * 45)
print("IMPORTAÇÃO FINALIZADA!")
print("=" * 45)
