import argparse
import os
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

import pandas as pd

RAIZ = Path(__file__).resolve().parent.parent
ARQUIVO_PADRAO = RAIZ / "dados" / "base_teste.xlsx"

# ── Converte serial do Excel para data ─────────────────────
def _vazio(v):
    return v is None or (not isinstance(v, str) and pd.isna(v)) or (isinstance(v, str) and v.strip() == "")

def txt(v):
    return None if _vazio(v) else str(v).strip()

def inteiro(v):
    if _vazio(v):
        return None
    f = float(v)
    if f != int(f):
        raise ValueError(f"esperava inteiro, veio {v!r}")
    return int(f)

def decimal(v):
    if _vazio(v):
        return None
    if isinstance(v, str):
        texto = v.strip().replace(" ", "")
        if "," in texto:
            texto = texto.replace(".", "").replace(",", ".")
        return float(texto)
    return float(v)

def id_fornecedor(v):
    if _vazio(v):
        return None
    s = str(v).strip().upper().removeprefix("F")
    if not s.isdigit():
        raise ValueError(f"idfornecedor inválido: {v!r}")
    return int(s)

def data(v):
    if _vazio(v):
        return None
    if isinstance(v, (pd.Timestamp, datetime)):
        return v.date()
    if isinstance(v, date):
        return v
    if isinstance(v, (int, float)):  # data gravada como número serial do Excel
        return (datetime(1899, 12, 30) + timedelta(days=float(v))).date()
    if isinstance(v, str):
        for formato in ("%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y"):
            try:
                return datetime.strptime(v.strip(), formato).date()
            except ValueError:
                pass
    raise ValueError(f"data inválida: {v!r}")

# ----------------------------------------------------------------------------------------------
# Mapa aba da planilha -> tabela do banco: (coluna na planilha, coluna no banco, conversor).
# A ordem das tabelas respeita as chaves estrangeiras.
# ----------------------------------------------------------------------------------------------
TABELAS = [
    ("fornecedor", "fornecedor", [
        ("idfornecedor", "idfornecedor", id_fornecedor),
        ("razao_social", "razao_social", txt),
    ]),
    ("produtos_filial", "produtos_filial", [
        ("filial_id", "filial_id", inteiro),
        ("idproduto", "produto_id", txt),  # na planilha a coluna se chama idproduto
        ("descricao", "descricao", txt),
        ("estoque", "estoque", decimal),
        ("preco_unitario", "preco_unitario", decimal),
        ("preco_compra", "preco_compra", decimal),
        ("preco_venda", "preco_venda", decimal),
        ("idfornecedor", "idfornecedor", id_fornecedor),
    ]),
    ("pedido_compra", "pedido_compra", [
        ("pedido_id", "pedido_id", inteiro),
        ("data_pedido", "data_pedido", data),
        ("item", "item", inteiro),
        ("produto_id", "produto_id", txt),
        ("descricao_produto", "descricao_produto", txt),
        ("ordem_compra", "ordem_compra", inteiro),
        ("qtde_pedida", "qtde_pedida", decimal),
        ("filial_id", "filial_id", inteiro),
        ("data_entrega", "data_entrega", data),
        ("qtde_entregue", "qtde_entregue", decimal),
        # qtde_pendente NÃO existe na planilha: é calculada abaixo (qtde_pedida - qtde_entregue)
        ("preco_compra", "preco_compra", decimal),
        ("fornecedor_id", "fornecedor_id", inteiro),
    ]),
    ("entradas_mercadoria", "entradas_mercadoria", [
        ("data_entrada", "data_entrada", data),
        ("nro_nfe", "nro_nfe", txt),
        ("item", "item", inteiro),
        ("produto_id", "produto_id", txt),
        ("descricao_produto", "descricao_produto", txt),
        ("ordem_compra", "ordem_compra", inteiro),
        ("qtde_recebida", "qtde_recebida", decimal),
        ("filial_id", "filial_id", inteiro),
        ("custo_unitario", "custo_unitario", decimal),
    ]),
    ("venda", "venda", [
        ("venda_id", "venda_id", inteiro),
        ("data_emissao", "data_emissao", data),
        ("horariomov", "horariomov", txt),
        ("produto_id", "produto_id", txt),
        ("qtde_vendida", "qtde_vendida", decimal),
        ("valor_unitario", "valor_unitario", decimal),
        ("filial_id", "filial_id", inteiro),
        ("item", "item", inteiro),
        ("unidade_medida", "unidade_medida", txt),
    ]),
]

def conectar():
    engine = os.getenv("DB_ENGINE", "postgres").lower()
    senha = os.getenv("DB_PASSWORD")
    if senha is None:
        sys.exit("Defina a variável de ambiente DB_PASSWORD (a senha não fica escrita no código).\n"
                 "  Windows (cmd):        set DB_PASSWORD=sua_senha\n"
                 "  Windows (PowerShell): $env:DB_PASSWORD=\"sua_senha\"\n"
                 "  Linux/macOS:          export DB_PASSWORD=sua_senha")
    nome = os.getenv("DB_NAME", "teste")
    host = os.getenv("DB_HOST", "localhost")
    try:
        porta = int(os.getenv("DB_PORT", "5432" if engine == "postgres" else "3306"))
    except ValueError:
        sys.exit("DB_PORT deve ser um número inteiro.")
    if not 1 <= porta <= 65535:
        sys.exit("DB_PORT deve estar entre 1 e 65535.")
    if engine == "postgres":
        import psycopg2
        conn = psycopg2.connect(host=host, port=porta, dbname=nome,
                                user=os.getenv("DB_USER", "postgres"), password=senha)
    elif engine == "mysql":
        import pymysql
        conn = pymysql.connect(host=host, port=porta, database=nome,
                               user=os.getenv("DB_USER", "root"), password=senha, charset="utf8mb4",
                               autocommit=False)
    else:
        sys.exit(f"DB_ENGINE inválido: {engine!r} (use postgres ou mysql)")
    return engine, conn


def ler_aba(arquivo, aba, colunas):
    """Lê só as colunas do cabeçalho. Avisa (em vez de descartar em silêncio) se houver dados fora dele."""
    df = pd.read_excel(arquivo, sheet_name=aba)
    df.columns = [str(c).strip() for c in df.columns]
    faltando = [c for c, _, _ in colunas if c not in df.columns]
    if faltando:
        sys.exit(f"Aba '{aba}': faltam as colunas {faltando}. Colunas encontradas: {list(df.columns)}")
    extras = [c for c in df.columns if c not in {n for n, _, _ in colunas}]
    com_dados = [c for c in extras if df[c].notna().any()]
    if com_dados:
        linhas = df.index[df[com_dados].notna().any(axis=1)] + 2  # +2: cabeçalho e base 1 do Excel
        celulas = int(df[com_dados].notna().sum().sum())
        print(f"  ATENCAO: a aba '{aba}' tem {celulas} células preenchidas em colunas SEM cabeçalho "
              f"({com_dados[0]} ... {com_dados[-1]}), nas linhas Excel {linhas.min()} a {linhas.max()}. "
              f"Esses dados NÃO foram importados (validar com o cliente).")
    return df


def importar_aba(cur, engine, arquivo, aba, tabela, colunas):
    df = ler_aba(arquivo, aba, colunas)
    nomes_banco = [b for _, b, _ in colunas]
    calcula_pendente = tabela == "pedido_compra"
    if calcula_pendente:
        nomes_banco.append("qtde_pendente")
    sql = f"INSERT INTO {tabela} ({', '.join(nomes_banco)}) VALUES ({', '.join(['%s'] * len(nomes_banco))})"

    inseridas, rejeitadas = 0, []
    if engine == "postgres":
        import psycopg2
        erros_banco = psycopg2.Error
    else:
        import pymysql
        erros_banco = pymysql.MySQLError
    tipos_erro = (ValueError, TypeError, OverflowError, erros_banco)

    for i, linha in df.iterrows():
        linha_excel = i + 2
        ponto_criado = False
        try:
            cur.execute("SAVEPOINT linha")
            ponto_criado = True
            valores = [conv(linha[origem]) for origem, _, conv in colunas]
            if calcula_pendente:
                pedida = valores[nomes_banco.index("qtde_pedida")]
                entregue = valores[nomes_banco.index("qtde_entregue")]
                valores.append(pedida - entregue)
            cur.execute(sql, valores)
            cur.execute("RELEASE SAVEPOINT linha")
            inseridas += 1
        except tipos_erro as erro:
            if ponto_criado:
                cur.execute("ROLLBACK TO SAVEPOINT linha")
            rejeitadas.append((linha_excel, str(erro).strip().splitlines()[0]))
    return len(df), inseridas, rejeitadas


def main():
    ap = argparse.ArgumentParser(description="Importa dados/base_teste.xlsx para o banco.")
    ap.add_argument("--arquivo", default=str(ARQUIVO_PADRAO), help="caminho do .xlsx")
    ap.add_argument("--limpar", action="store_true", help="apaga as linhas das 5 tabelas antes de importar")
    args = ap.parse_args()

    engine, conn = conectar()
    cur = conn.cursor()
    print(f"Conectado ao {engine} (banco '{os.getenv('DB_NAME', 'teste')}'). Arquivo: {args.arquivo}\n")

    if args.limpar:
        resposta = input("ATENCAO: --limpar apagará os dados das 5 tabelas. Digite SIM para continuar: ").strip()
        if resposta.upper() != "SIM":
            cur.close()
            conn.close()
            sys.exit("Operação cancelada.")
        for _, tabela, _ in reversed(TABELAS):  # ordem inversa por causa das chaves estrangeiras
            cur.execute(f"DELETE FROM {tabela}")
        conn.commit()
        print("Tabelas limpas.\n")

    resumo = []
    for aba, tabela, colunas in TABELAS:
        print(f"Importando {aba} ...")
        lidas, inseridas, rejeitadas = importar_aba(cur, engine, args.arquivo, aba, tabela, colunas)
        conn.commit()  # commit por tabela, DEPOIS de tratar as linhas ruins
        resumo.append((tabela, lidas, inseridas, rejeitadas))
        print(f"  {inseridas} de {lidas} linhas inseridas, {len(rejeitadas)} rejeitadas.")
        for linha_excel, motivo in rejeitadas:
            print(f"    linha Excel {linha_excel}: {motivo}")

    # Confere no banco (o script original imprimia len(df), não o que realmente entrou).
    print("\nCONFERENCIA FINAL (planilha x banco)")
    print(f"{'tabela':<22}{'planilha':>9}{'inseridas':>11}{'rejeitadas':>12}{'no banco':>10}  situação")
    tudo_certo = True
    for tabela, lidas, inseridas, rejeitadas in resumo:
        cur.execute(f"SELECT COUNT(*) FROM {tabela}")
        resultado = cur.fetchone()
        no_banco = resultado[0] if resultado else 0
        ok = no_banco == lidas and not rejeitadas
        tudo_certo = tudo_certo and ok
        print(f"{tabela:<22}{lidas:>9}{inseridas:>11}{len(rejeitadas):>12}{no_banco:>10}  {'OK' if ok else 'DIFERENTE'}")
    cur.close()
    conn.close()

    print("\n" + ("Importação concluída: todas as linhas da planilha estão no banco." if tudo_certo else
                  "ATENÇÃO: há diferenças entre a planilha e o banco (veja as linhas rejeitadas acima)."))
    sys.exit(0 if tudo_certo else 1)


if __name__ == "__main__":
    main()