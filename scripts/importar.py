"""
importar.py - importa dados/base_teste.xlsx para o PostgreSQL (versão corrigida)

Correções em relação ao script original (commit 3a59f2a) e à 1ª correção
(commit d00175e). Detalhes e testes em docs/parte1_importacao.md:
  1. Sem senha no código: a conexão vem de variáveis de ambiente.
  2. Uma transação só, com SAVEPOINT por linha. Antes, o conn.rollback()
     dentro do laço desfazia TODAS as linhas anteriores da tabela, e o contador
     continuava somando (teste: "32 inseridos" com 4 no banco).
  3. Nenhuma linha some em silêncio: rejeitadas e duplicadas vão para a tabela
     importacao_rejeicoes com o nº da linha do Excel e o motivo.
  4. Colunas mapeadas pelo NOME (não pela posição) e aviso de dados em colunas
     sem cabeçalho (pedido_compra tem 11 colunas extras em 9 linhas).
  5. Chave inválida é rejeitada; não vira 0 por padrão.
  6. IDs de fornecedor 'F8' -> 8, só no formato F<número>. O original gravava
     'F8' numa coluna integer e perdia todos os fornecedores e produtos.
  7. Datas do Excel (Timestamp) e em texto. O original transformava todas em
     NULL e perdia as 33 vendas.
  8. TRUNCATE no início: pode rodar de novo sem duplicar nem deixar lixo.
  9. Ajusta a sequência IDENTITY de fornecedor depois da carga. Sem isso, o
     próximo INSERT sem id (e a trigger da Parte 3) dá "duplicate key".
 10. A conferência final compara a planilha com SELECT COUNT(*) no banco,
     e não com um contador do próprio script.
 11. Cópia crua de cada aba no schema stg (tudo como texto) para auditoria
     por SQL (usada em sql/04_validacao.sql).

Uso:
  pip install -r requirements.txt
  export PGHOST=localhost PGPORT=5432 PGDATABASE=integracao PGUSER=postgres PGPASSWORD=...
  python scripts/importar.py
"""
import os
import re
import sys
import unicodedata
from datetime import datetime, date, time
from pathlib import Path

import pandas as pd
import psycopg

BASE_DIR = Path(__file__).resolve().parent.parent
ARQUIVO = BASE_DIR / "dados" / "base_teste.xlsx"

DB = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": int(os.getenv("PGPORT", "5432")),
    "dbname": os.getenv("PGDATABASE", "integracao"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD", ""),  # nunca coloque a senha real aqui
}

# Ordem respeita as FKs: fornecedor primeiro
ABAS = ["fornecedor", "produtos_filial", "pedido_compra", "entradas_mercadoria", "venda"]

# Nome na planilha -> nome no banco (a aba produtos_filial usa "idproduto")
APELIDOS = {"idproduto": "produto_id", "decricao": "descricao",
            "idfonecedor": "idfornecedor", "idforncedor": "idfornecedor"}


class LinhaInvalida(Exception):
    """Linha que não pode ser gravada; o texto da exceção é o motivo."""


# ---------------------------------------------------------------- conversões
def vazio(v):
    return v is None or (not isinstance(v, str) and pd.isna(v)) or (isinstance(v, str) and not v.strip())


def texto(v):
    return None if vazio(v) else " ".join(str(v).split())


def codigo(v):
    """Código (produto, NF-e): texto sem espaços e sem o '.0' que o Excel põe em números."""
    t = texto(v)
    return re.sub(r"\.0+$", "", t) if t else None


def numero(v, campo):
    if vazio(v):
        return None
    if isinstance(v, (int, float)):
        return v
    s = str(v).strip().replace("R$", "").replace(" ", "")
    if re.fullmatch(r"-?\d{1,3}(\.\d{3})+(,\d+)?", s):   # 1.234,56
        s = s.replace(".", "").replace(",", ".")
    elif re.fullmatch(r"-?\d+,\d+", s):                  # 1234,56
        s = s.replace(",", ".")
    try:
        return float(s)
    except ValueError:
        raise LinhaInvalida(f"{campo} não numérico: {v!r}")


def inteiro(v, campo):
    n = numero(v, campo)
    if n is None:
        return None
    if float(n) != int(float(n)):
        raise LinhaInvalida(f"{campo} deveria ser inteiro: {v!r}")
    return int(float(n))


def id_fornecedor(v, campo):
    """Aceita 8, '8' ou 'F8' (formato da planilha). Qualquer outra coisa é erro."""
    if vazio(v):
        return None
    if isinstance(v, (int, float)):
        return inteiro(v, campo)
    m = re.fullmatch(r"[Ff]?\s*(\d+)", str(v).strip())
    if not m:
        raise LinhaInvalida(f"{campo} em formato desconhecido: {v!r}")
    return int(m.group(1))


def data(v, campo):
    if vazio(v):
        return None
    if isinstance(v, (datetime, pd.Timestamp)):
        return v.date()
    if isinstance(v, date):
        return v
    s = str(v).strip()
    for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y"):
        try:
            return datetime.strptime(s[:10], fmt).date()
        except ValueError:
            pass
    raise LinhaInvalida(f"{campo} não é uma data válida: {v!r}")


def hora(v, campo):
    if vazio(v):
        return None
    if isinstance(v, time):
        return v
    if isinstance(v, datetime):
        return v.time()
    try:
        return time.fromisoformat(str(v).strip())
    except ValueError:
        raise LinhaInvalida(f"{campo} não é uma hora válida: {v!r}")


def obrigatorio(valor, campo):
    if valor is None:
        raise LinhaInvalida(f"{campo} vazio")
    return valor


# ---------------------------------------------------------------- conversão linha -> registro
def reg_fornecedor(r):
    return {"idfornecedor": obrigatorio(id_fornecedor(r.get("idfornecedor"), "idfornecedor"), "idfornecedor"),
            "razao_social": obrigatorio(texto(r.get("razao_social")), "razao_social")}


def reg_produtos_filial(r):
    return {"filial_id": obrigatorio(inteiro(r.get("filial_id"), "filial_id"), "filial_id"),
            "produto_id": obrigatorio(codigo(r.get("produto_id")), "produto_id"),
            "descricao": obrigatorio(texto(r.get("descricao")), "descricao"),
            "estoque": numero(r.get("estoque"), "estoque") or 0,
            "preco_unitario": numero(r.get("preco_unitario"), "preco_unitario") or 0,
            "preco_compra": numero(r.get("preco_compra"), "preco_compra") or 0,
            "preco_venda": numero(r.get("preco_venda"), "preco_venda") or 0,
            "idfornecedor": id_fornecedor(r.get("idfornecedor"), "idfornecedor")}


def reg_pedido_compra(r):
    pedida = numero(r.get("qtde_pedida"), "qtde_pedida")
    entregue = numero(r.get("qtde_entregue"), "qtde_entregue") or 0
    pendente = numero(r.get("qtde_pendente"), "qtde_pendente")
    if pendente is None:            # a aba não tem a coluna qtde_pendente: calcula
        pendente = (pedida or 0) - entregue
    return {"pedido_id": obrigatorio(inteiro(r.get("pedido_id"), "pedido_id"), "pedido_id"),
            "data_pedido": data(r.get("data_pedido"), "data_pedido"),
            "item": inteiro(r.get("item"), "item") or 0,
            "produto_id": obrigatorio(codigo(r.get("produto_id")), "produto_id"),
            "descricao_produto": texto(r.get("descricao_produto")),
            "ordem_compra": obrigatorio(inteiro(r.get("ordem_compra"), "ordem_compra"), "ordem_compra"),
            "qtde_pedida": pedida,
            "filial_id": inteiro(r.get("filial_id"), "filial_id"),
            "data_entrega": data(r.get("data_entrega"), "data_entrega"),
            "qtde_entregue": entregue,
            "qtde_pendente": pendente,
            "preco_compra": numero(r.get("preco_compra"), "preco_compra"),
            "fornecedor_id": id_fornecedor(r.get("fornecedor_id"), "fornecedor_id")}


def reg_entradas_mercadoria(r):
    return {"data_entrada": data(r.get("data_entrada"), "data_entrada"),
            "nro_nfe": obrigatorio(codigo(r.get("nro_nfe")), "nro_nfe"),
            "item": inteiro(r.get("item"), "item") or 0,
            "produto_id": obrigatorio(codigo(r.get("produto_id")), "produto_id"),
            "descricao_produto": texto(r.get("descricao_produto")),
            "ordem_compra": obrigatorio(inteiro(r.get("ordem_compra"), "ordem_compra"), "ordem_compra"),
            "qtde_recebida": numero(r.get("qtde_recebida"), "qtde_recebida"),
            "filial_id": inteiro(r.get("filial_id"), "filial_id"),
            "custo_unitario": numero(r.get("custo_unitario"), "custo_unitario") or 0}


def reg_venda(r):
    un = texto(r.get("unidade_medida"))
    return {"venda_id": obrigatorio(inteiro(r.get("venda_id"), "venda_id"), "venda_id"),
            "data_emissao": obrigatorio(data(r.get("data_emissao"), "data_emissao"), "data_emissao"),
            "horariomov": hora(r.get("horariomov"), "horariomov") or time(0, 0),
            "produto_id": codigo(r.get("produto_id")) or "",
            "qtde_vendida": numero(r.get("qtde_vendida"), "qtde_vendida"),
            "valor_unitario": numero(r.get("valor_unitario"), "valor_unitario") or 0,
            "filial_id": inteiro(r.get("filial_id"), "filial_id") or 1,
            "item": inteiro(r.get("item"), "item") or 0,
            "unidade_medida": un.upper() if un else None}


CONVERSORES = {"fornecedor": reg_fornecedor, "produtos_filial": reg_produtos_filial,
               "pedido_compra": reg_pedido_compra, "entradas_mercadoria": reg_entradas_mercadoria,
               "venda": reg_venda}
CHAVES = {"fornecedor": "idfornecedor", "produtos_filial": "filial_id, produto_id",
          "pedido_compra": "pedido_id, produto_id, item",
          "entradas_mercadoria": "ordem_compra, item, produto_id, nro_nfe",
          "venda": "filial_id, venda_id, data_emissao, produto_id, item, horariomov"}


# ---------------------------------------------------------------- leitura
def normaliza(nome):
    s = unicodedata.normalize("NFKD", str(nome)).encode("ascii", "ignore").decode()
    s = "_".join(s.strip().lower().split())
    return APELIDOS.get(s, s)


def ler_aba(aba):
    df = pd.read_excel(ARQUIVO, sheet_name=aba, dtype=object)
    originais = [str(c).strip() for c in df.columns]
    df.columns = [normaliza(c) for c in df.columns]
    renomeadas = [(o, n) for o, n in zip(originais, df.columns)
                  if o != n and not n.startswith("unnamed")]
    df = df.dropna(how="all")                       # linhas 100% vazias não são dados
    sem_nome = [c for c in df.columns if c.startswith("unnamed")]
    return df, sem_nome, renomeadas


def como_texto(v):
    """Valor da célula como texto legível (datas em ISO, 12.0 -> '12')."""
    if vazio(v):
        return None
    if isinstance(v, (datetime, pd.Timestamp)):
        return v.strftime("%Y-%m-%d")
    if isinstance(v, float) and v.is_integer():
        return str(int(v))
    return str(v)


def gravar_staging(cur, aba, df):
    """Cópia crua (texto) da aba em stg.<aba>, com o nº da linha do Excel."""
    # colunas sem cabeçalho viram extra_01, extra_02...
    extras = iter(range(1, len(df.columns) + 1))
    cols = [f"extra_{next(extras):02d}" if c.startswith("unnamed") else c for c in df.columns]
    cur.execute(f'CREATE TABLE stg."{aba}" (linha_excel int, '
                + ", ".join(f'"{c}" text' for c in cols) + ")")
    sql = (f'INSERT INTO stg."{aba}" VALUES (%s' + ", %s" * len(cols) + ")")
    for idx, row in df.iterrows():
        cur.execute(sql, [idx + 2] + [como_texto(v) for v in row.tolist()])


# ---------------------------------------------------------------- principal
def main():
    if not ARQUIVO.exists():
        sys.exit(f"Planilha não encontrada: {ARQUIVO}")

    print(f"Conectando em {DB['user']}@{DB['host']}:{DB['port']}/{DB['dbname']}...")
    with psycopg.connect(**DB) as conn:            # commit no final; rollback se der exceção
        with conn.cursor() as cur:
            cur.execute("TRUNCATE venda, entradas_mercadoria, pedido_compra, produtos_filial, fornecedor")
            cur.execute("DROP SCHEMA IF EXISTS stg CASCADE; CREATE SCHEMA stg")
            cur.execute("DROP TABLE IF EXISTS importacao_rejeicoes")
            cur.execute("CREATE TABLE importacao_rejeicoes (tabela text, linha_excel int, motivo text, dados text)")

            linhas_planilha = {}
            for aba in ABAS:
                print(f"Importando {aba}...")
                df, sem_nome, renomeadas = ler_aba(aba)
                linhas_planilha[aba] = len(df)
                for original, novo in renomeadas:
                    cur.execute("INSERT INTO importacao_rejeicoes VALUES (%s, %s, %s, %s)",
                                (aba, 1, f"AVISO: cabeçalho '{original}' lido como '{novo}'", None))
                    print(f"  AVISO: cabeçalho '{original}' lido como '{novo}'")
                gravar_staging(cur, aba, df)

                if sem_nome:
                    com_dados = df[df[sem_nome].notna().any(axis=1)]
                    for idx in com_dados.index:
                        cur.execute("INSERT INTO importacao_rejeicoes VALUES (%s, %s, %s, %s)",
                                    (aba, idx + 2, "AVISO: valores em colunas sem cabeçalho (ignorados; ver stg)",
                                     " | ".join(como_texto(v) for v in df.loc[idx, sem_nome].tolist() if not vazio(v))))
                    if len(com_dados):
                        print(f"  AVISO: {len(com_dados)} linha(s) com dados em colunas sem cabeçalho "
                              f"(linhas Excel {[i + 2 for i in com_dados.index]}). Ignorados na carga, mantidos em stg.{aba}")
                    df = df.drop(columns=sem_nome)

                for idx, row in df.iterrows():
                    linha_excel = idx + 2               # linha 1 = cabeçalho
                    try:
                        reg = CONVERSORES[aba](row.to_dict())
                        cols = ", ".join(reg)
                        params = ", ".join(["%s"] * len(reg))
                        cur.execute("SAVEPOINT linha")
                        cur.execute(f"INSERT INTO {aba} ({cols}) VALUES ({params}) "
                                    f"ON CONFLICT ({CHAVES[aba]}) DO NOTHING RETURNING 1", list(reg.values()))
                        if cur.fetchone() is None:
                            raise LinhaInvalida("chave primária duplicada (mantida a 1ª ocorrência)")
                        cur.execute("RELEASE SAVEPOINT linha")
                    except (LinhaInvalida, psycopg.Error) as e:
                        if isinstance(e, psycopg.Error):
                            cur.execute("ROLLBACK TO SAVEPOINT linha")   # desfaz só esta linha
                        motivo = str(e).splitlines()[0]
                        cur.execute("INSERT INTO importacao_rejeicoes VALUES (%s, %s, %s, %s)",
                                    (aba, linha_excel, motivo,
                                     " | ".join(f"{k}={como_texto(v)}" for k, v in row.items())))
                        print(f"  REJEITADA {aba} linha Excel {linha_excel}: {motivo}")

            # IDENTITY continua depois do maior id carregado (evita duplicate key depois)
            cur.execute("SELECT setval(pg_get_serial_sequence('fornecedor', 'idfornecedor'), "
                        "COALESCE((SELECT max(idfornecedor) FROM fornecedor), 0) + 1, false)")

            # ---------------- conferência final
            print("\nConferência final")
            print(f"{'tabela':<22}{'planilha':>9}{'banco':>8}{'rejeitadas':>12}  status")
            tudo_ok = True
            for aba in ABAS:
                cur.execute(f"SELECT count(*) FROM {aba}")
                banco = cur.fetchone()[0]
                cur.execute("SELECT count(*) FROM importacao_rejeicoes "
                            "WHERE tabela = %s AND motivo NOT LIKE 'AVISO%%'", (aba,))
                rej = cur.fetchone()[0]
                ok = linhas_planilha[aba] == banco + rej
                tudo_ok &= ok
                print(f"{aba:<22}{linhas_planilha[aba]:>9}{banco:>8}{rej:>12}  {'OK' if ok else 'DIVERGENTE'}")
            cur.execute("SELECT count(*) FROM importacao_rejeicoes WHERE motivo LIKE 'AVISO%'")
            avisos = cur.fetchone()[0]
            if avisos:
                print(f"\n{avisos} aviso(s) registrados em importacao_rejeicoes (SELECT * FROM importacao_rejeicoes).")

    print("\nImportação concluída." if tudo_ok else "\nImportação concluída COM DIVERGÊNCIA de contagem!")


if __name__ == "__main__":
    main()
