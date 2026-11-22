import os
import pandas as pd
import psycopg2
from datetime import datetime, timedelta

# ── Configurações ──────────────────────────────────────────
# O caminho é calculado a partir da pasta do script: funciona de qualquer pasta.
ARQUIVO = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "dados", "base_teste.xlsx")
DB = {
    "host": "localhost",
    "port": 5432,                 # PostgreSQL: 5432 (MySQL: 3306)
    "database": "integracao_dados",
    "user": "postgres",
    "password": os.environ.get("PGPASSWORD", "sua_senha_aqui")  # nunca coloque a senha real aqui
}


# ── Funções de conversão ───────────────────────────────────
def excel_para_data(valor):
    if pd.isna(valor):
        return None
    if isinstance(valor, (int, float)):  # serial do Excel
        return (datetime(1899, 12, 30) + timedelta(days=int(valor))).date()
    return pd.to_datetime(valor).date()  # o pandas já entrega data


def codigo_fornecedor(valor):
    # 'F8' vira 8: a coluna no banco é numérica
    if pd.isna(valor):
        return None
    return int(str(valor).strip().lstrip("Ff"))


def numero(valor, padrao=None):
    return float(valor) if pd.notna(valor) else padrao


def inteiro(valor):
    return int(valor) if pd.notna(valor) else None


def texto(valor):
    return str(valor).strip() if pd.notna(valor) else None


# ── Conecta no banco ───────────────────────────────────────
print("Conectando no PostgreSQL...")
try:
    conn = psycopg2.connect(**DB)
except UnicodeDecodeError:
    # No Windows em português o servidor responde em Windows-1252 e o psycopg2 quebra ao ler o erro.
    raise SystemExit("Falha ao conectar: confira a senha (variável PGPASSWORD), o usuário e o banco.")
conn.autocommit = True  # cada linha é gravada sozinha: um erro não desfaz as outras
cur = conn.cursor()
print("Conectado!\n")


def importar(nome, df, sql, montar):
    """Insere linha a linha e conta inseridas, duplicadas e com erro."""
    inseridas = duplicadas = erros = 0
    for i, row in df.iterrows():
        try:
            cur.execute(sql, montar(row))
            if cur.rowcount == 1:
                inseridas += 1
            else:
                duplicadas += 1
        except Exception as e:
            erros += 1
            print(f"  Erro {nome}, linha {i + 2} da planilha: {e}")
    print(f"  {nome}: {inseridas} inseridas, {duplicadas} duplicadas ignoradas, {erros} com erro\n")
    return erros


total_erros = 0

# 1. FORNECEDOR
print("Importando fornecedor...")
df = pd.read_excel(ARQUIVO, sheet_name="fornecedor")
df.columns = df.columns.str.strip()
total_erros += importar("fornecedor", df, """
    INSERT INTO public.fornecedor (idfornecedor, razao_social)
    VALUES (%s, %s)
    ON CONFLICT (idfornecedor) DO NOTHING
""", lambda r: (
    codigo_fornecedor(r["idfornecedor"]),
    texto(r["razao_social"]),
))

# 2. PRODUTOS_FILIAL
print("Importando produtos_filial...")
df = pd.read_excel(ARQUIVO, sheet_name="produtos_filial")
df.columns = df.columns.str.strip()
total_erros += importar("produtos_filial", df, """
    INSERT INTO public.produtos_filial
        (filial_id, produto_id, descricao, estoque,
         preco_unitario, preco_compra, preco_venda, idfornecedor)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (filial_id, produto_id) DO NOTHING
""", lambda r: (
    int(r["filial_id"]),
    texto(r["idproduto"]),            # na planilha a coluna se chama idproduto
    texto(r["descricao"]),
    numero(r["estoque"], 0),
    numero(r["preco_unitario"], 0),
    numero(r["preco_compra"], 0),
    numero(r["preco_venda"], 0),
    codigo_fornecedor(r["idfornecedor"]),
))

# 3. PEDIDO_COMPRA
print("Importando pedido_compra...")
df = pd.read_excel(ARQUIVO, sheet_name="pedido_compra")
df = df.iloc[:, :12]  # ignora as colunas M:W soltas, sem cabeçalho
df.columns = ["pedido_id", "data_pedido", "item", "produto_id", "descricao_produto",
              "ordem_compra", "qtde_pedida", "filial_id", "data_entrega",
              "qtde_entregue", "preco_compra", "fornecedor_id"]


def qtde_pendente(r):
    # a planilha não tem essa coluna: pendente = pedida - entregue
    if pd.notna(r["qtde_pedida"]) and pd.notna(r["qtde_entregue"]):
        return float(r["qtde_pedida"]) - float(r["qtde_entregue"])
    return 0


total_erros += importar("pedido_compra", df, """
    INSERT INTO public.pedido_compra
        (pedido_id, data_pedido, item, produto_id, descricao_produto,
         ordem_compra, qtde_pedida, filial_id, data_entrega,
         qtde_entregue, qtde_pendente, preco_compra, fornecedor_id)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (pedido_id, produto_id, item) DO NOTHING
""", lambda r: (
    int(r["pedido_id"]),
    excel_para_data(r["data_pedido"]),
    int(r["item"]),
    texto(r["produto_id"]),
    texto(r["descricao_produto"]),
    int(r["ordem_compra"]),
    numero(r["qtde_pedida"]),
    inteiro(r["filial_id"]),
    excel_para_data(r["data_entrega"]),
    numero(r["qtde_entregue"], 0),
    qtde_pendente(r),
    numero(r["preco_compra"], 0),
    inteiro(r["fornecedor_id"]),
))

# 4. ENTRADAS_MERCADORIA
print("Importando entradas_mercadoria...")
df = pd.read_excel(ARQUIVO, sheet_name="entradas_mercadoria")
df.columns = df.columns.str.strip()
total_erros += importar("entradas_mercadoria", df, """
    INSERT INTO public.entradas_mercadoria
        (data_entrada, nro_nfe, item, produto_id, descricao_produto,
         ordem_compra, qtde_recebida, filial_id, custo_unitario)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (ordem_compra, item, produto_id, nro_nfe) DO NOTHING
""", lambda r: (
    excel_para_data(r["data_entrada"]),
    texto(r["nro_nfe"]),
    int(r["item"]),
    texto(r["produto_id"]),
    texto(r["descricao_produto"]),
    int(r["ordem_compra"]),
    numero(r["qtde_recebida"]),
    inteiro(r["filial_id"]),
    numero(r["custo_unitario"], 0),
))

# 5. VENDA
print("Importando venda...")
df = pd.read_excel(ARQUIVO, sheet_name="venda")
df.columns = df.columns.str.strip()
total_erros += importar("venda", df, """
    INSERT INTO public.venda
        (venda_id, data_emissao, horariomov, produto_id,
         qtde_vendida, valor_unitario, filial_id, item, unidade_medida)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    ON CONFLICT (filial_id, venda_id, data_emissao, produto_id, item, horariomov) DO NOTHING
""", lambda r: (
    int(r["venda_id"]),
    excel_para_data(r["data_emissao"]),
    texto(r["horariomov"]) or "00:00:00",
    texto(r["produto_id"]),
    numero(r["qtde_vendida"]),
    numero(r["valor_unitario"], 0),
    int(r["filial_id"]),
    int(r["item"]),
    texto(r["unidade_medida"]),
))

# ── Conferência final: linhas na planilha x linhas no banco ──
print("Conferência final (planilha x banco):")
diferencas = 0
for aba in ["fornecedor", "produtos_filial", "pedido_compra", "entradas_mercadoria", "venda"]:
    na_planilha = len(pd.read_excel(ARQUIVO, sheet_name=aba))
    cur.execute(f"SELECT COUNT(*) FROM public.{aba}")
    no_banco = cur.fetchone()[0]
    aviso = "" if na_planilha == no_banco else "   <-- DIFERENTE"
    diferencas += 0 if na_planilha == no_banco else 1
    print(f"  {aba}: planilha={na_planilha} | banco={no_banco}{aviso}")

cur.close()
conn.close()
print("=" * 40)
if total_erros == 0 and diferencas == 0:
    print("Importação concluída: todas as linhas conferem.")
else:
    print(f"Importação terminou COM PROBLEMAS: {total_erros} erro(s) de linha, {diferencas} tabela(s) com contagem diferente.")
print("=" * 40)