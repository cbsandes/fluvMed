from contextlib import asynccontextmanager
from typing import List
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, select
from app.database import create_db_and_tables, get_session
from app.models import (
    ProfissionalSaude, ProfissionalSaudeCreate, ProfissionalSaudeRead,
    Paciente, PacienteCreate, PacienteRead,
    Medicamento, MedicamentoCreate, MedicamentoRead,
    EstoqueLocal, EstoqueLocalCreate, EstoqueLocalRead,
    Atendimento, AtendimentoCreate, AtendimentoRead,
    PrescricaoItem, PrescricaoItemCreate, PrescricaoItemRead,
    SyncBatchPayload
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield

app = FastAPI(
    title="FluvMed API",
    description="API de sincronização e apoio à saúde fluvial ribeirinha (Offline-First)",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------- PROFISSIONAIS DE SAÚDE ----------------
@app.post("/profissionais/", response_model=ProfissionalSaudeRead, status_code=status.HTTP_201_CREATED)
def criar_profissional(profissional: ProfissionalSaudeCreate, session: Session = Depends(get_session)):
    db_item = ProfissionalSaude.model_validate(profissional)
    session.add(db_item)
    session.commit()
    session.refresh(db_item)
    return db_item

@app.get("/profissionais/", response_model=List[ProfissionalSaudeRead])
def listar_profissionais(session: Session = Depends(get_session)):
    return session.exec(select(ProfissionalSaude)).all()

# ---------------- PACIENTES ----------------
@app.post("/pacientes/", response_model=PacienteRead, status_code=status.HTTP_201_CREATED)
def criar_paciente(paciente: PacienteCreate, session: Session = Depends(get_session)):
    db_item = Paciente.model_validate(paciente)
    session.add(db_item)
    session.commit()
    session.refresh(db_item)
    return db_item

@app.get("/pacientes/", response_model=List[PacienteRead])
def listar_pacientes(session: Session = Depends(get_session)):
    return session.exec(select(Paciente)).all()

@app.put("/pacientes/{id}", response_model=PacienteRead)
def atualizar_paciente(id: int, dados: PacienteCreate, session: Session = Depends(get_session)):
    item = session.get(Paciente, id)
    if not item:
        raise HTTPException(status_code=404, detail="Paciente não encontrado")
    dados_dict = dados.model_dump(exclude_unset=True)
    for key, value in dados_dict.items():
        setattr(item, key, value)
    session.add(item)
    session.commit()
    session.refresh(item)
    return item

# ---------------- MEDICAMENTOS ----------------
@app.post("/medicamentos/", response_model=MedicamentoRead, status_code=status.HTTP_201_CREATED)
def criar_medicamento(medicamento: MedicamentoCreate, session: Session = Depends(get_session)):
    db_item = Medicamento.model_validate(medicamento)
    session.add(db_item)
    session.commit()
    session.refresh(db_item)
    return db_item

@app.get("/medicamentos/", response_model=List[MedicamentoRead])
def listar_medicamentos(session: Session = Depends(get_session)):
    return session.exec(select(Medicamento)).all()

# ---------------- ATENDIMENTOS ----------------
@app.get("/atendimentos/", response_model=List[AtendimentoRead])
def listar_atendimentos(session: Session = Depends(get_session)):
    return session.exec(select(Atendimento)).all()

# ---------------- SINCRONIZAÇÃO EM DUAS VIAS (PUSH & PULL) ----------------
@app.get("/sync/pull")
def puxar_dados_consolidados(session: Session = Depends(get_session)):
    meds = [m.model_dump() for m in session.exec(select(Medicamento)).all()]
    pacs = [p.model_dump() for p in session.exec(select(Paciente)).all()]
    profs = [pr.model_dump() for pr in session.exec(select(ProfissionalSaude)).all()]
    atends = [a.model_dump() for a in session.exec(select(Atendimento)).all()]
    prescs = [ps.model_dump() for ps in session.exec(select(PrescricaoItem)).all()]
    return {
        "medicamentos": meds,
        "pacientes": pacs,
        "profissionais": profs,
        "atendimentos": atends,
        "prescricoes": prescs
    }

@app.post("/sync/lote", status_code=status.HTTP_200_OK)
def sincronizar_em_lote(payload: SyncBatchPayload, session: Session = Depends(get_session)):
    try:
        novos_profissionais = 0
        novos_pacientes = 0
        novos_atendimentos = 0
        novas_prescricoes = 0
        estoques_atualizados = 0

        # 1. Profissionais pendentes
        for prof in payload.profissionais:
            db_prof = session.exec(
                select(ProfissionalSaude).where(ProfissionalSaude.usuario == prof.usuario)
            ).first()
            if not db_prof:
                session.add(ProfissionalSaude.model_validate(prof))
                novos_profissionais += 1

        # 2. Pacientes pendentes
        for pac in payload.pacientes:
            db_pac = None
            if pac.cpf:
                db_pac = session.exec(select(Paciente).where(Paciente.cpf == pac.cpf)).first()
            if not db_pac and pac.numero_sus:
                db_pac = session.exec(select(Paciente).where(Paciente.numero_sus == pac.numero_sus)).first()

            if db_pac:
                db_pac.nome = pac.nome
                db_pac.comunidade = pac.comunidade
                db_pac.data_nascimento = pac.data_nascimento
                session.add(db_pac)
            else:
                session.add(Paciente.model_validate(pac))
                novos_pacientes += 1

        session.commit()

        # 3. Atendimentos pendentes
        for atend in payload.atendimentos:
            db_atend = Atendimento.model_validate(atend)
            db_atend.status_sincronizacao = True
            session.add(db_atend)
            novos_atendimentos += 1

        session.commit()

        # 4. Prescrições pendentes
        for presc in payload.prescricoes:
            session.add(PrescricaoItem.model_validate(presc))
            db_med = session.get(Medicamento, presc.medicamento_id)
            if db_med:
                db_med.quantidade_estoque_geral = max(0, db_med.quantidade_estoque_geral - presc.quantidade_dispensada)
                session.add(db_med)
            novas_prescricoes += 1

        # 5. Ajustes manuais de estoque ocorridos no barco
        for item in payload.estoque_local:
            db_med = None
            if item.id is not None:
                db_med = session.get(Medicamento, item.id)
            if not db_med:
                db_med = session.exec(select(Medicamento).where(Medicamento.nome == item.nome)).first()

            if db_med:
                db_med.capacidade_maxima = item.capacidade_maxima
                db_med.quantidade_estoque_geral = item.quantidade_disponivel
                session.add(db_med)
            else:
                novo_med = Medicamento(
                    nome=item.nome,
                    especificacao=item.especificacao,
                    quantidade_estoque_geral=item.quantidade_disponivel,
                    capacidade_maxima=item.capacidade_maxima
                )
                session.add(novo_med)
            estoques_atualizados += 1

        session.commit()

        # Serializa os dados consolidados do PostgreSQL para alimentar o SQLite móvel
        meds = [m.model_dump() for m in session.exec(select(Medicamento)).all()]
        pacs = [p.model_dump() for p in session.exec(select(Paciente)).all()]
        atends = [a.model_dump() for a in session.exec(select(Atendimento)).all()]
        prescs = [ps.model_dump() for ps in session.exec(select(PrescricaoItem)).all()]

        return {
            "status": "sucesso",
            "sincronizados": {
                "profissionais": novos_profissionais,
                "pacientes": novos_pacientes,
                "atendimentos": novos_atendimentos,
                "prescricoes": novas_prescricoes,
                "estoques_atualizados": estoques_atualizados
            },
            "dados_consolidados": {
                "medicamentos": meds,
                "pacientes": pacs,
                "atendimentos": atends,
                "prescricoes": prescs
            }
        }
    except Exception as e:
        session.rollback()
        print(f"Erro no processamento do lote: {e}")
        raise HTTPException(status_code=500, detail=f"Erro interno: {str(e)}")