from pathlib import Path
from datetime import datetime, timedelta
import pandas as pd
import psycopg

BASE_DIR = Path(__file__).resolve().parent.parent
ARQUIVO = BASE_DIR / "dados" / "base_teste.xlsx"

DB = {
    "host": "127.0.0.1",
    "port": 5432,
    "dbname": "postgres",
    "user": "postgres",
    "password": "1920",
}


def excel_para_data(valor):
    if pd.isna(valor):
        return None
    if isinstance(valor, (datetime, pd.Timestamp)):
        return valor.date()
    try:
        return (datetime(1899, 12, 30) + timedelta(days=int(float(valor)))).date()
    except Exception:
        return None


def para_int(valor, padrao=None):
    if pd.isna(valor):
        return padrao
    try:
        return int(float(valor))
    except Exception:
        return padrao


def para_id_int(valor, padrao=None):
    if pd.isna(valor):
        return padrao
    try:
        return int(float(valor))
    except Exception:
        digitos = "".join(ch for ch in str(valor) if ch.isdigit())
        return int(digitos) if digitos else padrao


def para_float(valor, padrao=None):
    if pd.isna(valor):
        return padrao
    try:
        return float(valor)
    except Exception:
        return padrao


print("Conectando no PostgreSQL...")
with psycopg.connect(**DB) as conn:
    with conn.cursor() as cur:
        print("Conectado!\n")

        # 1. FORNECEDOR
        print("Importando fornecedor...")
        df = pd.read_excel(ARQUIVO, sheet_name="fornecedor")
        df.columns = df.columns.str.strip()
        inseridos = 0

        for idx, row in df.iterrows():
            try:
                id_forn = para_id_int(row.get("idfornecedor"))
                razao = str(row["razao_social"]).strip() if pd.notna(row.get("razao_social")) else None
                if id_forn is None or not razao:
                    continue
                cur.execute(
                    """
                    INSERT INTO public.fornecedor (idfornecedor, razao_social)
                    VALUES (%s, %s)
                    ON CONFLICT (idfornecedor) DO NOTHING
                    """,
                    (id_forn, razao),
                )
                inseridos += cur.rowcount
            except Exception as e:
                print(f"  Erro fornecedor linha {idx}: {e}")
                conn.rollback()

        conn.commit()
        print(f"  {inseridos} registros inseridos em fornecedor (total no Excel: {len(df)})\n")

        # 2. PRODUTOS_FILIAL
        print("Importando produtos_filial...")
        df = pd.read_excel(ARQUIVO, sheet_name="produtos_filial")
        df.columns = df.columns.str.strip()
        inseridos = 0

        for idx, row in df.iterrows():
            try:
                filial_id = para_int(row.get("filial_id"))
                col_prod = "produto_id" if "produto_id" in df.columns else "idproduto"
                produto_id = str(row[col_prod]).strip() if pd.notna(row.get(col_prod)) else ""
                descricao = str(row["descricao"]).strip() if pd.notna(row.get("descricao")) else ""
                if filial_id is None or not produto_id:
                    continue

                cur.execute(
                    """
                    INSERT INTO public.produtos_filial
                        (filial_id, produto_id, descricao, estoque,
                         preco_unitario, preco_compra, preco_venda, idfornecedor)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (filial_id, produto_id) DO NOTHING
                    """,
                    (
                        filial_id,
                        produto_id,
                        descricao,
                        para_float(row.get("estoque"), 0.0),
                        para_float(row.get("preco_unitario"), 0.0),
                        para_float(row.get("preco_compra"), 0.0),
                        para_float(row.get("preco_venda"), 0.0),
                        para_id_int(row.get("idfornecedor")),
                    ),
                )
                inseridos += cur.rowcount
            except Exception as e:
                print(f"  Erro produtos_filial linha {idx}: {e}")
                conn.rollback()

        conn.commit()
        print(f"  {inseridos} registros inseridos em produtos_filial (total no Excel: {len(df)})\n")

        # 3. PEDIDO_COMPRA
        print("Importando pedido_compra...")
        df = pd.read_excel(ARQUIVO, sheet_name="pedido_compra")
        df.columns = df.columns.str.strip()
        df = df.iloc[:, :12]
        df.columns = [
            "pedido_id", "data_pedido", "item", "produto_id", "descricao_produto",
            "ordem_compra", "qtde_pedida", "filial_id", "data_entrega",
            "qtde_entregue", "preco_compra", "fornecedor_id",
        ]
        inseridos = 0

        for idx, row in df.iterrows():
            try:
                pedido_id = para_int(row.get("pedido_id"), 0)
                item = para_int(row.get("item"), 0)
                produto_id = str(row["produto_id"]).strip() if pd.notna(row.get("produto_id")) else "0"
                qtde_pedida = para_float(row.get("qtde_pedida"))
                qtde_entregue = para_float(row.get("qtde_entregue"), 0.0)
                qtde_pendente = (
                    (qtde_pedida - qtde_entregue)
                    if qtde_pedida is not None and qtde_entregue is not None
                    else 0.0
                )

                cur.execute(
                    """
                    INSERT INTO public.pedido_compra
                        (pedido_id, data_pedido, item, produto_id, descricao_produto,
                         ordem_compra, qtde_pedida, filial_id, data_entrega,
                         qtde_entregue, qtde_pendente, preco_compra, fornecedor_id)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (pedido_id, produto_id, item) DO NOTHING
                    """,
                    (
                        pedido_id,
                        excel_para_data(row.get("data_pedido")),
                        item,
                        produto_id,
                        str(row["descricao_produto"]).strip() if pd.notna(row.get("descricao_produto")) else None,
                        para_int(row.get("ordem_compra"), 0),
                        qtde_pedida,
                        para_int(row.get("filial_id")),
                        excel_para_data(row.get("data_entrega")),
                        qtde_entregue,
                        qtde_pendente,
                        para_float(row.get("preco_compra"), 0.0),
                        para_id_int(row.get("fornecedor_id")),
                    ),
                )
                inseridos += cur.rowcount
            except Exception as e:
                print(f"  Erro pedido_compra linha {idx}: {e}")
                conn.rollback()

        conn.commit()
        print(f"  {inseridos} registros inseridos em pedido_compra (total no Excel: {len(df)})\n")

        # 4. ENTRADAS_MERCADORIA
        print("Importando entradas_mercadoria...")
        df = pd.read_excel(ARQUIVO, sheet_name="entradas_mercadoria")
        df.columns = df.columns.str.strip()
        inseridos = 0

        for idx, row in df.iterrows():
            try:
                nro_nfe = str(row["nro_nfe"]).strip() if pd.notna(row.get("nro_nfe")) else ""
                produto_id = str(row["produto_id"]).strip() if pd.notna(row.get("produto_id")) else "0"
                if not nro_nfe:
                    continue

                cur.execute(
                    """
                    INSERT INTO public.entradas_mercadoria
                        (data_entrada, nro_nfe, item, produto_id, descricao_produto,
                         ordem_compra, qtde_recebida, filial_id, custo_unitario)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (ordem_compra, item, produto_id, nro_nfe) DO NOTHING
                    """,
                    (
                        excel_para_data(row.get("data_entrada")),
                        nro_nfe,
                        para_int(row.get("item"), 0),
                        produto_id,
                        str(row["descricao_produto"]).strip() if pd.notna(row.get("descricao_produto")) else None,
                        para_int(row.get("ordem_compra"), 0),
                        para_float(row.get("qtde_recebida")),
                        para_int(row.get("filial_id")),
                        para_float(row.get("custo_unitario"), 0.0),
                    ),
                )
                inseridos += cur.rowcount
            except Exception as e:
                print(f"  Erro entradas_mercadoria linha {idx}: {e}")
                conn.rollback()

        conn.commit()
        print(f"  {inseridos} registros inseridos em entradas_mercadoria (total no Excel: {len(df)})\n")

        # 5. VENDA
        print("Importando venda...")
        df = pd.read_excel(ARQUIVO, sheet_name="venda")
        df.columns = df.columns.str.strip()
        inseridos = 0

        for idx, row in df.iterrows():
            try:
                venda_id = para_int(row.get("venda_id"))
                data_emissao = excel_para_data(row.get("data_emissao"))
                if venda_id is None or data_emissao is None:
                    continue

                cur.execute(
                    """
                    INSERT INTO public.venda
                        (venda_id, data_emissao, horariomov, produto_id,
                         qtde_vendida, valor_unitario, filial_id, item, unidade_medida)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON CONFLICT (filial_id, venda_id, data_emissao, produto_id, item, horariomov) DO NOTHING
                    """,
                    (
                        venda_id,
                        data_emissao,
                        str(row["horariomov"]).strip() if pd.notna(row.get("horariomov")) else "00:00:00",
                        str(row["produto_id"]).strip() if pd.notna(row.get("produto_id")) else "",
                        para_float(row.get("qtde_vendida")),
                        para_float(row.get("valor_unitario"), 0.0),
                        para_int(row.get("filial_id"), 1),
                        para_int(row.get("item"), 0),
                        str(row["unidade_medida"]).strip() if pd.notna(row.get("unidade_medida")) else None,
                    ),
                )
                inseridos += cur.rowcount
            except Exception as e:
                print(f"  Erro venda linha {idx}: {e}")
                conn.rollback()

        conn.commit()
        print(f"  {inseridos} registros inseridos em venda (total no Excel: {len(df)})\n")

print("=" * 40)
print("Importação concluída com sucesso!")
print("=" * 40)