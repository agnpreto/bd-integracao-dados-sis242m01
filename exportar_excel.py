import pandas as pd
from sqlalchemy import create_engine

SENHA_POSTGRES = "22032007"
engine = create_engine(f"postgresql+psycopg2://postgres:{SENHA_POSTGRES}@localhost:5432/integracao_dados")

tabelas = ["fornecedor", "produtos_filial", "pedido_compra", "entradas_mercadoria", "venda"]

with pd.ExcelWriter("dados/exportado_postgres.xlsx", engine="openpyxl") as writer:
    for tabela in tabelas:
        df = pd.read_sql(f"SELECT * FROM public.{tabela}", con=engine)
        df.to_excel(writer, sheet_name=tabela, index=False)
        print(f"Tabela '{tabela}' exportada com {len(df)} linhas.")

print("Arquivo 'dados/exportado_postgres.xlsx' gerado com sucesso!")