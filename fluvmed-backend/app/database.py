import os
import time
from sqlalchemy import text
from sqlmodel import SQLModel, create_engine, Session, select
from app.models import Medicamento, ProfissionalSaude, Paciente

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://fluvmed_user:fluvmed_password@localhost:5432/fluvmed_db"
)

engine = create_engine(DATABASE_URL, echo=True)

def migrar_estrutura_banco():
    with engine.connect() as conn:
        # 1. Garante que todas as colunas novas existam no PostgreSQL
        conn.execute(text("ALTER TABLE atendimento ADD COLUMN IF NOT EXISTS paciente_nome VARCHAR;"))
        conn.execute(text("ALTER TABLE atendimento ADD COLUMN IF NOT EXISTS profissional_nome VARCHAR;"))
        conn.execute(text("ALTER TABLE atendimento ADD COLUMN IF NOT EXISTS profissional_registro VARCHAR;"))
        conn.execute(text("ALTER TABLE atendimento ADD COLUMN IF NOT EXISTS classificacao_risco VARCHAR DEFAULT 'Verde';"))
        conn.execute(text("ALTER TABLE atendimento ADD COLUMN IF NOT EXISTS status_sincronizacao BOOLEAN DEFAULT TRUE;"))
        conn.execute(text("ALTER TABLE atendimento ALTER COLUMN data_hora TYPE VARCHAR USING data_hora::varchar;"))
        
        conn.execute(text("ALTER TABLE prescricaoitem ADD COLUMN IF NOT EXISTS medicamento_nome VARCHAR;"))
        conn.execute(text("ALTER TABLE prescricaoitem ADD COLUMN IF NOT EXISTS data_hora VARCHAR;"))
        
        conn.execute(text("ALTER TABLE paciente ADD COLUMN IF NOT EXISTS cpf VARCHAR;"))
        conn.execute(text("ALTER TABLE paciente ADD COLUMN IF NOT EXISTS data_nascimento VARCHAR;"))
        
        conn.execute(text("ALTER TABLE medicamento ADD COLUMN IF NOT EXISTS quantidade_estoque_geral INTEGER DEFAULT 0;"))
        conn.execute(text("ALTER TABLE medicamento ADD COLUMN IF NOT EXISTS capacidade_maxima INTEGER DEFAULT 200;"))

        # 2. Remove restrições que travam sincronização assíncrona gerada em offline
        conn.execute(text("ALTER TABLE atendimento DROP CONSTRAINT IF EXISTS atendimento_paciente_id_fkey;"))
        conn.execute(text("ALTER TABLE atendimento DROP CONSTRAINT IF EXISTS atendimento_profissional_id_fkey;"))
        conn.execute(text("ALTER TABLE prescricaoitem DROP CONSTRAINT IF EXISTS prescricaoitem_atendimento_id_fkey;"))
        conn.execute(text("ALTER TABLE prescricaoitem DROP CONSTRAINT IF EXISTS prescricaoitem_medicamento_id_fkey;"))
        
        conn.commit()
        print("Migrações de esquema e liberação de travas offline aplicadas com sucesso.")

def create_db_and_tables():
    conectado = False
    tentativas = 15
    while not conectado and tentativas > 0:
        try:
            SQLModel.metadata.create_all(engine)
            migrar_estrutura_banco()
            conectado = True
            print("Conexão validada com o PostgreSQL.")
        except Exception as e:
            tentativas -= 1
            print(f"Aguardando banco inicializar... Tentativas restantes: {tentativas}. Detalhe: {e}")
            time.sleep(2)

    if conectado:
        popular_dados_iniciais()

def popular_dados_iniciais():
    try:
        with Session(engine) as session:
            tem_meds = session.exec(select(Medicamento)).first()
            if not tem_meds:
                medicamentos = [
                    Medicamento(nome="Dipirona 500mg", especificacao="comprimidos", quantidade_estoque_geral=1000, capacidade_maxima=200),
                    Medicamento(nome="Amoxicilina 500mg", especificacao="cápsulas", quantidade_estoque_geral=800, capacidade_maxima=150),
                    Medicamento(nome="Soro de reidratação oral", especificacao="sachês", quantidade_estoque_geral=500, capacidade_maxima=100),
                    Medicamento(nome="Ivermectina 6mg", especificacao="comprimidos", quantidade_estoque_geral=400, capacidade_maxima=80),
                    Medicamento(nome="Losartana 50mg", especificacao="comprimidos", quantidade_estoque_geral=600, capacidade_maxima=120),
                ]
                session.add_all(medicamentos)
                session.commit()

            tem_prof = session.exec(select(ProfissionalSaude)).first()
            if not tem_prof:
                prof = ProfissionalSaude(
                    nome="Ana Paula Ribeiro",
                    registro_profissional="COREN-AM 102938",
                    cargo="Enfermeira de Campo",
                    usuario="enf.ana",
                    senha="123"
                )
                session.add(prof)
                session.commit()

            tem_pac = session.exec(select(Paciente)).first()
            if not tem_pac:
                pacs = [
                    Paciente(nome="Maria das Graças Souza", cpf="012.345.678-90", numero_sus="700 5012 3456 7890", data_nascimento="1970-05-12", comunidade="Comunidade Nossa Senhora do Livramento"),
                    Paciente(nome="Raimundo Nonato Lima", cpf="123.456.789-01", numero_sus="700 6023 4567 8901", data_nascimento="1957-08-20", comunidade="Vila do Careiro da Várzea")
                ]
                session.add_all(pacs)
                session.commit()
    except Exception as e:
        print(f"Erro ao injetar sementes iniciais: {e}")

def get_session():
    with Session(engine) as session:
        yield session