"""
Importação da planilha base_teste.xlsx para PostgreSQL.
Execute a partir da raiz do projeto:
    python scripts/importar.py

Dependências:
    pip install pandas openpyxl psycopg2-binary
"""
from pathlib import Path
from datetime import date, datetime
import pandas as pd
import psycopg2

RAIZ = Path(__file__).resolve().parents[1]
ARQUIVO = Path(__file__).resolve().parents[1] / "base_teste.xlsx"

DB = {
    "host": "localhost",
    "port": 5432,
    "database": "postgres",   # altere para o banco criado para a atividade
    "user": "postgres",
    "password": "SUASENHA",       # substitua pela senha do seu PostgreSQL
}

def valor_nulo(valor):
    return pd.isna(valor)

def texto(valor):
    if valor_nulo(valor):
        return None
    return str(valor).strip()

def numero(valor, padrao=None):
    if valor_nulo(valor):
        return padrao
    return float(valor)

def inteiro(valor, padrao=None):
    if valor_nulo(valor):
        return padrao
    return int(float(valor))

def data_sql(valor):
    """Aceita Timestamp, datetime, date e datas reconhecidas pelo pandas."""
    if valor_nulo(valor):
        return None
    return pd.to_datetime(valor, errors="raise").date()

def codigo_fornecedor(valor):
    """Padroniza 1 -> F1 e preserva F1 -> F1."""
    if valor_nulo(valor):
        return None
    s = str(valor).strip()
    if s.endswith(".0"):
        s = s[:-2]
    return s if s.upper().startswith("F") else f"F{int(float(s))}"

def hora_texto(valor):
    if valor_nulo(valor):
        return "00:00:00"
    if hasattr(valor, "strftime"):
        return valor.strftime("%H:%M:%S")
    s = str(valor).strip()
    # Excel pode entregar fração de dia ou texto.
    if s.replace(".", "", 1).isdigit() and 0 <= float(s) < 1:
        segundos = round(float(s) * 86400)
        h, resto = divmod(segundos, 3600)
        m, sec = divmod(resto, 60)
        return f"{h:02d}:{m:02d}:{sec:02d}"
    return s[:8]

def importar_aba(cur, nome_aba, sql, transformar):
    df = pd.read_excel(ARQUIVO, sheet_name=nome_aba)
    df.columns = df.columns.astype(str).str.strip()
    # Remove colunas totalmente vazias, como Unnamed: 12 ... Unnamed: 22.
    df = df.dropna(axis=1, how="all")
    inseridos = 0
    ignorados = 0
    erros = []

    for indice, (_, row) in enumerate(df.iterrows(), start=2):
        cur.execute("SAVEPOINT linha_importacao")
        try:
            valores = transformar(row)
            cur.execute(sql, valores)
            if cur.rowcount == 1:
                inseridos += 1
            else:
                ignorados += 1
            cur.execute("RELEASE SAVEPOINT linha_importacao")
        except Exception as exc:
            cur.execute("ROLLBACK TO SAVEPOINT linha_importacao")
            cur.execute("RELEASE SAVEPOINT linha_importacao")
            erros.append((indice, str(exc)))
    cur.connection.commit()
    print(f"{nome_aba}: {inseridos} inseridos; {ignorados} já existentes/duplicados; {len(erros)} erros.")
    for linha, erro in erros:
        print(f"  Linha Excel {linha}: {erro}")
    return len(df), inseridos, ignorados, erros

def main():
    if not ARQUIVO.exists():
        raise FileNotFoundError(f"Planilha não encontrada: {ARQUIVO}")

    conn = psycopg2.connect(**DB)
    try:
        cur = conn.cursor()

        # 1. Fornecedores (tabela-pai primeiro).
        importar_aba(cur, "fornecedor", """
            INSERT INTO public.fornecedor (idfornecedor, razao_social)
            VALUES (%s, %s)
            ON CONFLICT (idfornecedor) DO NOTHING
        """, lambda r: (texto(r["idfornecedor"]), texto(r["razao_social"])))

        # 2. Produtos por filial.
        importar_aba(cur, "produtos_filial", """
            INSERT INTO public.produtos_filial
              (filial_id, produto_id, descricao, estoque, preco_unitario,
               preco_compra, preco_venda, idfornecedor)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (filial_id, produto_id) DO NOTHING
        """, lambda r: (
            inteiro(r["filial_id"]), texto(r["idproduto"]), texto(r["descricao"]),
            numero(r["estoque"], 0), numero(r["preco_unitario"], 0),
            numero(r["preco_compra"], 0), numero(r["preco_venda"], 0),
            codigo_fornecedor(r["idfornecedor"])
        ))

        # 3. Pedidos. A planilha não possui qtde_pendente: calculamos a diferença.
        def pedido(r):
            pedida = numero(r["qtde_pedida"])
            entregue = numero(r["qtde_entregue"], 0)
            pendente = (pedida - entregue) if pedida is not None else 0
            return (
                inteiro(r["pedido_id"]), data_sql(r["data_pedido"]), inteiro(r["item"], 0),
                texto(r["produto_id"]), texto(r["descricao_produto"]),
                inteiro(r["ordem_compra"], 0), pedida, inteiro(r["filial_id"]),
                data_sql(r["data_entrega"]), entregue, pendente,
                numero(r["preco_compra"], 0), codigo_fornecedor(r["fornecedor_id"])
            )

        importar_aba(cur, "pedido_compra", """
            INSERT INTO public.pedido_compra
              (pedido_id, data_pedido, item, produto_id, descricao_produto,
               ordem_compra, qtde_pedida, filial_id, data_entrega,
               qtde_entregue, qtde_pendente, preco_compra, fornecedor_id)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (pedido_id, produto_id, item) DO NOTHING
        """, pedido)

        # 4. Entradas de mercadoria.
        importar_aba(cur, "entradas_mercadoria", """
            INSERT INTO public.entradas_mercadoria
              (data_entrada, nro_nfe, item, produto_id, descricao_produto,
               ordem_compra, qtde_recebida, filial_id, custo_unitario)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (ordem_compra, item, produto_id, nro_nfe) DO NOTHING
        """, lambda r: (
            data_sql(r["data_entrada"]), texto(r["nro_nfe"]), inteiro(r["item"], 0),
            texto(r["produto_id"]), texto(r["descricao_produto"]),
            inteiro(r["ordem_compra"]), numero(r["qtde_recebida"]),
            inteiro(r["filial_id"]), numero(r["custo_unitario"], 0)
        ))

        # 5. Vendas.
        importar_aba(cur, "venda", """
            INSERT INTO public.venda
              (venda_id, data_emissao, horariomov, produto_id, qtde_vendida,
               valor_unitario, filial_id, item, unidade_medida)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            ON CONFLICT (filial_id, venda_id, data_emissao, produto_id, item, horariomov)
            DO NOTHING
        """, lambda r: (
            inteiro(r["venda_id"]), data_sql(r["data_emissao"]), hora_texto(r["horariomov"]),
            texto(r["produto_id"]), numero(r["qtde_vendida"]),
            numero(r["valor_unitario"], 0), inteiro(r["filial_id"], 1),
            inteiro(r["item"], 0), texto(r["unidade_medida"])
        ))

        cur.close()
    finally:
        conn.close()

    print("\\nImportação finalizada. Confira os totais com SELECT COUNT(*) no PostgreSQL.")

if __name__ == "__main__":
    main()
