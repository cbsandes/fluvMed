from datetime import datetime
from typing import Optional, List
from sqlmodel import SQLModel, Field

class ProfissionalSaudeBase(SQLModel):
    nome: str
    registro_profissional: str
    cargo: str
    usuario: str

class ProfissionalSaude(ProfissionalSaudeBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    senha: str

class ProfissionalSaudeCreate(ProfissionalSaudeBase):
    senha: str

class ProfissionalSaudeRead(ProfissionalSaudeBase):
    id: int


class PacienteBase(SQLModel):
    nome: str
    cpf: Optional[str] = None
    numero_sus: Optional[str] = None
    data_nascimento: Optional[str] = None
    comunidade: str

class Paciente(PacienteBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

class PacienteCreate(PacienteBase):
    id: Optional[int] = None

class PacienteRead(PacienteBase):
    id: int


class MedicamentoBase(SQLModel):
    nome: str
    especificacao: Optional[str] = "comprimidos"
    quantidade_estoque_geral: int = 0
    capacidade_maxima: int = 200

class Medicamento(MedicamentoBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

class MedicamentoCreate(MedicamentoBase):
    pass

class MedicamentoRead(MedicamentoBase):
    id: int


class EstoqueLocalBase(SQLModel):
    medicamento_id: int
    quantidade_disponivel: int
    quantidade_total_barco: int
    ultima_sincronizacao: Optional[str] = None

class EstoqueLocal(EstoqueLocalBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

class EstoqueLocalCreate(EstoqueLocalBase):
    pass

class EstoqueLocalRead(EstoqueLocalBase):
    id: int


class AtendimentoBase(SQLModel):
    paciente_id: int
    profissional_id: Optional[int] = None
    paciente_nome: Optional[str] = None
    profissional_nome: Optional[str] = None
    profissional_registro: Optional[str] = None
    data_hora: str = Field(default_factory=lambda: datetime.utcnow().strftime("%d/%m %H:%M"))
    anamnese: Optional[str] = None
    conduta: Optional[str] = None
    classificacao_risco: str = "Verde"
    status_sincronizacao: bool = True

class Atendimento(AtendimentoBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

class AtendimentoCreate(AtendimentoBase):
    pass

class AtendimentoRead(AtendimentoBase):
    id: int


class PrescricaoItemBase(SQLModel):
    atendimento_id: Optional[int] = None
    medicamento_id: int
    medicamento_nome: Optional[str] = None
    quantidade_dispensada: int
    data_hora: Optional[str] = None

class PrescricaoItem(PrescricaoItemBase, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)

class PrescricaoItemCreate(PrescricaoItemBase):
    pass

class PrescricaoItemRead(PrescricaoItemBase):
    id: int


class MedicamentoSyncItem(SQLModel):
    id: Optional[int] = None
    nome: str
    especificacao: Optional[str] = "comprimidos"
    quantidade_disponivel: int
    capacidade_maxima: int


class SyncBatchPayload(SQLModel):
    profissionais: List[ProfissionalSaudeCreate] = []
    pacientes: List[PacienteCreate] = []
    atendimentos: List[AtendimentoCreate] = []
    prescricoes: List[PrescricaoItemCreate] = []
    estoque_local: List[MedicamentoSyncItem] = []