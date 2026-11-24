"""
Importação de dados/base_teste.xlsx para PostgreSQL ou MySQL (versão corrigida).

Uso:
    python scripts/importar.py                 # PostgreSQL (padrão)
    python scripts/importar.py --engine mysql  # MySQL

Credenciais por variável de ambiente (nenhuma senha real fica no código):
    DB_HOST (localhost)  DB_PORT (5432 / 3306)  DB_NAME (postgres / integracao)
    DB_USER (postgres / root)  DB_PASSWORD (vazio)  DB_SOCKET (opcional, MySQL)
Pré-requisito: rodar antes sql/01_ddl_postgres.sql ou sql/01_ddl_mysql.sql.
"""
import argparse
import os
import sys

import pandas as pd

ARQUIVO = os.environ.get("ARQUIVO_XLSX", "dados/base_teste.xlsx")

ap = argparse.ArgumentParser()
ap.add_argument("--engine", choices=["postgres", "mysql"], default="postgres")
ENGINE = ap.parse_args().engine


def conectar():
    host = os.environ.get("DB_HOST", "localhost")
    if ENGINE == "postgres":
        import psycopg2
        return psycopg2.connect(
            host=host, port=int(os.environ.get("DB_PORT", 5432)),
            dbname=os.environ.get("DB_NAME", "postgres"),
            user=os.environ.get("DB_USER", "postgres"),
            password=os.environ.get("DB_PASSWORD", ""))
    import pymysql
    return pymysql.connect(
        host=host, port=int(os.environ.get("DB_PORT", 3306)),
        database=os.environ.get("DB_NAME", "integracao"),
        user=os.environ.get("DB_USER", "root"),
        password=os.environ.get("DB_PASSWORD", ""), charset="utf8mb4",
        unix_socket=os.environ.get("DB_SOCKET") or None)


def ler(aba):
    """Lê a aba, tira espaços dos nomes de coluna e descarta colunas 100% vazias."""
    df = pd.read_excel(ARQUIVO, sheet_name=aba)
    df.columns = df.columns.astype(str).str.strip()
    return df.dropna(axis=1, how="all")


def n(v):
    """NaN/NaT -> None (NULL)."""
    return None if pd.isna(v) else v


def data(v):
    """O pandas já entrega Timestamp; o script antigo tratava como serial do
    Excel (int(Timestamp) dá TypeError) e gravava NULL em todas as datas."""
    return None if pd.isna(v) else pd.Timestamp(v).date()


def cod_fornecedor(v):
    """'F8' -> 8 (o id passa a ser numérico, como pede a Parte 3)."""
    if pd.isna(v):
        return None
    return int(str(v).strip().upper().lstrip("F"))


def txt(v):
    return None if pd.isna(v) else str(v).strip()


def num(v):
    return None if pd.isna(v) else float(v)


def inteiro(v, padrao=None):
    return padrao if pd.isna(v) else int(v)


def linhas_fornecedor(df):
    for r in df.itertuples():
        yield (cod_fornecedor(r.idfornecedor), txt(r.razao_social))


def linhas_produtos(df):
    for r in df.itertuples():
        yield (inteiro(r.filial_id), txt(r.idproduto), txt(r.descricao), num(r.estoque) or 0,
               num(r.preco_unitario) or 0, num(r.preco_compra) or 0, num(r.preco_venda) or 0,
               cod_fornecedor(r.idfornecedor))


def linhas_pedido(df):
    for r in df.itertuples():
        yield (inteiro(r.pedido_id), data(r.data_pedido), inteiro(r.item), txt(r.produto_id),
               txt(r.descricao_produto), inteiro(r.ordem_compra, 0), num(r.qtde_pedida),
               inteiro(r.filial_id), data(r.data_entrega), num(r.qtde_entregue) or 0,
               num(r.preco_compra), inteiro(r.fornecedor_id))


def linhas_entradas(df):
    for r in df.itertuples():
        yield (data(r.data_entrada), txt(r.nro_nfe), inteiro(r.item), txt(r.produto_id),
               txt(r.descricao_produto), inteiro(r.ordem_compra, 0), num(r.qtde_recebida),
               inteiro(r.filial_id), num(r.custo_unitario) or 0)


def linhas_venda(df):
    for r in df.itertuples():
        yield (inteiro(r.venda_id), data(r.data_emissao), txt(r.horariomov) or "00:00:00",
               txt(r.produto_id), num(r.qtde_vendida), num(r.valor_unitario) or 0,
               inteiro(r.filial_id, 1), inteiro(r.item, 0), txt(r.unidade_medida))


# (aba, tabela, colunas, gerador). A ordem respeita as chaves estrangeiras.
CARGAS = [
    ("fornecedor", "fornecedor", ["idfornecedor", "razao_social"], linhas_fornecedor),
    ("produtos_filial", "produtos_filial",
     ["filial_id", "produto_id", "descricao", "estoque", "preco_unitario",
      "preco_compra", "preco_venda", "idfornecedor"], linhas_produtos),
    ("pedido_compra", "pedido_compra",
     ["pedido_id", "data_pedido", "item", "produto_id", "descricao_produto", "ordem_compra",
      "qtde_pedida", "filial_id", "data_entrega", "qtde_entregue", "preco_compra",
      "fornecedor_id"], linhas_pedido),
    ("entradas_mercadoria", "entradas_mercadoria",
     ["data_entrada", "nro_nfe", "item", "produto_id", "descricao_produto", "ordem_compra",
      "qtde_recebida", "filial_id", "custo_unitario"], linhas_entradas),
    ("venda", "venda",
     ["venda_id", "data_emissao", "horariomov", "produto_id", "qtde_vendida",
      "valor_unitario", "filial_id", "item", "unidade_medida"], linhas_venda),
]

# colunas válidas por aba: tudo que vier além disso (ex.: colunas M:W soltas
# na aba pedido_compra) é avisado e ignorado, nunca descartado em silêncio.
ESPERADAS = {c[0]: set(c[2]) | {"idproduto"} for c in CARGAS}


def main():
    conn = conectar()
    cur = conn.cursor()
    resumo, ok = [], True
    for aba, tabela, colunas, gerador in CARGAS:
        df = ler(aba)
        extras = [c for c in df.columns if c not in ESPERADAS[aba]]
        if extras:
            sobra = df[extras].dropna(how="all")
            print(f"AVISO [{aba}]: {len(extras)} coluna(s) fora do layout ignoradas "
                  f"({extras[0]} ... {extras[-1]}), com dados em {len(sobra)} linha(s).")
            df = df.drop(columns=extras)
        marcadores = ", ".join(["%s"] * len(colunas))
        sql = f"INSERT INTO {tabela} ({', '.join(colunas)}) VALUES ({marcadores})"
        try:  # tudo-ou-nada por tabela: nada de rollback que apaga linhas boas
            cur.executemany(sql, list(gerador(df)))
            conn.commit()
        except Exception as e:
            conn.rollback()
            print(f"ERRO [{tabela}]: {e}")
            sys.exit(1)
        cur.execute(f"SELECT COUNT(*) FROM {tabela}")
        no_banco = cur.fetchone()[0]
        bate = no_banco == len(df)
        ok &= bate
        resumo.append((tabela, len(df), no_banco, "OK" if bate else "DIVERGE"))

    print(f"\n{'tabela':22}{'planilha':>9}{'banco':>8}  status")
    for t, p, b, s in resumo:
        print(f"{t:22}{p:>9}{b:>8}  {s}")
    cur.close()
    conn.close()
    sys.exit(0 if ok else 2)


if __name__ == "__main__":
    main()
