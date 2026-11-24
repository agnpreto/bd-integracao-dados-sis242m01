import pandas as pd
from sqlalchemy import create_engine, text

SENHA_POSTGRES = "senha"
ARQUIVO_EXCEL = "dados/base_teste.xlsx"

engine = create_engine(f"postgresql+psycopg2://postgres:{SENHA_POSTGRES}@localhost:5432/integracao_dados")

excel = pd.ExcelFile(ARQUIVO_EXCEL)

ordem_tabelas = [
    "fornecedor",
    "produtos_filial",
    "pedido_compra",
    "entradas_mercadoria",
    "venda"
]

with engine.connect() as conn:
    for tabela in ordem_tabelas:
        # Verifica se a tabela já tem dados (para não duplicar fornecedor e produtos_filial)
        qtd_atual = conn.execute(text(f"SELECT COUNT(*) FROM public.{tabela}")).scalar()
        if qtd_atual > 0:
            print(f"Pulando '{tabela}' (já possui {qtd_atual} linhas).")
            continue

        aba_encontrada = next((aba for aba in excel.sheet_names if aba.strip().lower() == tabela), None)
        
        if aba_encontrada:
            print(f"A importar aba '{aba_encontrada}' -> tabela '{tabela}'...")
            df = pd.read_excel(ARQUIVO_EXCEL, sheet_name=aba_encontrada)
            
            # Padroniza nomes e remove colunas sem cabeçalho ("unnamed: ...") e linhas totalmente vazias
            df.columns = [str(c).strip().lower() for c in df.columns]
            df = df.loc[:, ~df.columns.str.startswith("unnamed")]
            df = df.dropna(how="all")
            
            df.to_sql(tabela, con=engine, schema="public", if_exists="append", index=False)
            print(f"Sucesso! {len(df)} linhas inseridas em '{tabela}'.")
        else:
            print(f"AVISO: Nenhuma aba chamada '{tabela}' foi encontrada.")