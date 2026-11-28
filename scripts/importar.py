"""Importa dados/base_teste.xlsx para o PostgreSQL (versão corrigida).

Uso:
    export PGHOST=localhost PGPORT=5432 PGDATABASE=postgres PGUSER=postgres
    export PGPASSWORD='sua-senha'      # nunca versionar a senha
    psql -f sql/01_ddl_postgres.sql    # cria as tabelas (antes de importar)
    python scripts/importar.py

O que mudou em relação ao script do estagiário está em
docs/parte1_importacao.md. Resumo: datas deixam de virar NULL, tudo roda em
uma única transação (qualquer erro desfaz tudo, sem "sucesso" falso), as
contagens impressas são as do banco, fornecedor_id numérico vira 'F<n>', as
colunas soltas fora do cabeçalho de pedido_compra são ignoradas e a senha vem
de variável de ambiente.
"""
import os
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

import pandas as pd
import psycopg2

ARQUIVO = Path(__file__).resolve().parent.parent / "dados" / "base_teste.xlsx"

DB = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": int(os.getenv("PGPORT", "5432")),
    "dbname": os.getenv("PGDATABASE", "postgres"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", ""),
}


# ── Funções de conversão ───────────────────────────────────
def nulo(v):
    return v is None or pd.isna(v)


def para_data(v):
    """Aceita Timestamp/datetime/date (o pandas já converte as datas do Excel)
    e, por segurança, o número serial do Excel. Devolve None só se for vazio;
    valor inválido gera erro em vez de virar NULL em silêncio."""
    if nulo(v):
        return None
    if isinstance(v, pd.Timestamp):
        return v.date()
    if isinstance(v, datetime):
        return v.date()
    if isinstance(v, date):
        return v
    if isinstance(v, (int, float)):
        return (datetime(1899, 12, 30) + timedelta(days=float(v))).date()
    return pd.to_datetime(v, dayfirst=True).date()


def texto(v, padrao=None):
    return padrao if nulo(v) else str(v).strip()


def inteiro(v, padrao=None):
    return padrao if nulo(v) else int(v)


def decimal(v, padrao=None):
    return padrao if nulo(v) else float(v)


def codigo_fornecedor(v):
    """pedido_compra traz o fornecedor como número (1, 2...), enquanto a tabela
    fornecedor usa códigos textuais (F1, F2...). Padroniza para 'F<n>'."""
    if nulo(v):
        return None
    s = str(v).strip()
    if s.upper().startswith("F"):
        return s.upper()
    return f"F{int(float(s))}"


# ── Leitura das abas ───────────────────────────────────────
def ler(aba):
    df = pd.read_excel(ARQUIVO, sheet_name=aba)
    df.columns = df.columns.astype(str).str.strip()
    return df


COLUNAS_PEDIDO = [
    "pedido_id", "data_pedido", "item", "produto_id", "descricao_produto",
    "ordem_compra", "qtde_pedida", "filial_id", "data_entrega",
    "qtde_entregue", "preco_compra", "fornecedor_id",
]


def carregar_planilha():
    dados = {}
    dados["fornecedor"] = ler("fornecedor")

    prod = ler("produtos_filial")
    # a planilha chama a coluna de "idproduto"; no banco é produto_id
    dados["produtos_filial"] = prod.rename(columns={"idproduto": "produto_id"})

    ped = ler("pedido_compra")
    extras = ped.iloc[:, len(COLUNAS_PEDIDO):]
    linhas_extras = int(extras.notna().any(axis=1).sum())
    if linhas_extras:
        print(f"  AVISO: pedido_compra tem {extras.shape[1]} colunas sem cabeçalho "
              f"(M:W) preenchidas em {linhas_extras} linhas; ignoradas "
              "(ver docs/parte1_importacao.md).")
    ped = ped.iloc[:, :len(COLUNAS_PEDIDO)]
    if list(ped.columns) != COLUNAS_PEDIDO:
        sys.exit(f"Cabeçalho inesperado em pedido_compra: {list(ped.columns)}")
    dados["pedido_compra"] = ped

    dados["entradas_mercadoria"] = ler("entradas_mercadoria")
    dados["venda"] = ler("venda")
    return dados


# ── Linhas de cada tabela ──────────────────────────────────
def linhas_fornecedor(df):
    return [(texto(r.idfornecedor), texto(r.razao_social)) for r in df.itertuples()]


def linhas_produtos(df):
    return [(
        inteiro(r.filial_id), texto(r.produto_id), texto(r.descricao),
        decimal(r.estoque, 0), decimal(r.preco_unitario, 0),
        decimal(r.preco_compra, 0), decimal(r.preco_venda, 0),
        texto(r.idfornecedor),
    ) for r in df.itertuples()]


def linhas_pedido(df):
    out = []
    for r in df.itertuples():
        pedida = decimal(r.qtde_pedida)
        entregue = decimal(r.qtde_entregue, 0)
        pendente = (pedida - entregue) if pedida is not None else 0
        out.append((
            inteiro(r.pedido_id), para_data(r.data_pedido), inteiro(r.item),
            texto(r.produto_id), texto(r.descricao_produto),
            inteiro(r.ordem_compra, 0), pedida, inteiro(r.filial_id),
            para_data(r.data_entrega), entregue, pendente,
            decimal(r.preco_compra, 0), codigo_fornecedor(r.fornecedor_id),
        ))
    return out


def linhas_entradas(df):
    return [(
        para_data(r.data_entrada), texto(r.nro_nfe), inteiro(r.item),
        texto(r.produto_id), texto(r.descricao_produto),
        inteiro(r.ordem_compra, 0), decimal(r.qtde_recebida),
        inteiro(r.filial_id), decimal(r.custo_unitario, 0),
    ) for r in df.itertuples()]


def linhas_venda(df):
    return [(
        inteiro(r.venda_id), para_data(r.data_emissao),
        texto(r.horariomov, "00:00:00"), texto(r.produto_id),
        decimal(r.qtde_vendida), decimal(r.valor_unitario, 0),
        inteiro(r.filial_id, 1), inteiro(r.item, 0), texto(r.unidade_medida),
    ) for r in df.itertuples()]


# (tabela, colunas, função que monta as linhas) na ordem das dependências
TABELAS = [
    ("fornecedor",
     ["idfornecedor", "razao_social"], linhas_fornecedor),
    ("produtos_filial",
     ["filial_id", "produto_id", "descricao", "estoque", "preco_unitario",
      "preco_compra", "preco_venda", "idfornecedor"], linhas_produtos),
    ("pedido_compra",
     ["pedido_id", "data_pedido", "item", "produto_id", "descricao_produto",
      "ordem_compra", "qtde_pedida", "filial_id", "data_entrega",
      "qtde_entregue", "qtde_pendente", "preco_compra", "fornecedor_id"],
     linhas_pedido),
    ("entradas_mercadoria",
     ["data_entrada", "nro_nfe", "item", "produto_id", "descricao_produto",
      "ordem_compra", "qtde_recebida", "filial_id", "custo_unitario"],
     linhas_entradas),
    ("venda",
     ["venda_id", "data_emissao", "horariomov", "produto_id", "qtde_vendida",
      "valor_unitario", "filial_id", "item", "unidade_medida"], linhas_venda),
]


def main():
    print(f"Lendo {ARQUIVO.name}...")
    planilha = carregar_planilha()

    print(f"Conectando em {DB['host']}:{DB['port']}/{DB['dbname']}...")
    conn = psycopg2.connect(**DB)
    esperado, no_banco = {}, {}
    try:
        with conn, conn.cursor() as cur:  # uma transação: erro => rollback total
            cur.execute("TRUNCATE venda, entradas_mercadoria, pedido_compra, "
                        "produtos_filial, fornecedor")  # permite reimportar
            for tabela, colunas, montar in TABELAS:
                linhas = montar(planilha[tabela])
                sql = (f"INSERT INTO public.{tabela} ({', '.join(colunas)}) "
                       f"VALUES ({', '.join(['%s'] * len(colunas))})")
                cur.executemany(sql, linhas)  # sem ON CONFLICT: erro aparece
                esperado[tabela] = len(planilha[tabela])
            for tabela, _, _ in TABELAS:
                cur.execute(f"SELECT COUNT(*) FROM public.{tabela}")
                no_banco[tabela] = cur.fetchone()[0]
            if any(no_banco[t] != esperado[t] for t in esperado):
                raise RuntimeError("contagem do banco difere da planilha")
    except Exception as e:
        print(f"\nERRO: {e}\nNada foi gravado (rollback).")
        sys.exit(1)
    finally:
        conn.close()

    print("\nConferência (planilha x banco):")
    for tabela, _, _ in TABELAS:
        print(f"  {tabela:<20} {esperado[tabela]:>3} x {no_banco[tabela]:>3}")
    print("Importação concluída: contagens conferem.")


if __name__ == "__main__":
    main()
