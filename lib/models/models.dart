class TecnicoSaude {
  final int? id;
  final String nome;
  final String registroProfissional;
  final String cargo;
  final String usuario;
  final String senha;
  final int synced;

  TecnicoSaude({
    this.id,
    required this.nome,
    required this.registroProfissional,
    required this.cargo,
    required this.usuario,
    required this.senha,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'registro_profissional': registroProfissional,
    'cargo': cargo,
    'usuario': usuario,
    'senha': senha,
    'synced': synced,
  };

  factory TecnicoSaude.fromMap(Map<String, dynamic> map) => TecnicoSaude(
    id: map['id'],
    nome: map['nome'],
    registroProfissional: map['registro_profissional'],
    cargo: map['cargo'],
    usuario: map['usuario'],
    senha: map['senha'],
    synced: map['synced'] ?? 0,
  );

  Map<String, dynamic> toApiJson() => {
    'nome': nome,
    'registro_profissional': registroProfissional,
    'cargo': cargo,
    'usuario': usuario,
    'senha': senha,
  };
}

class PacienteModel {
  final int? id;
  final String nome;
  final String cpf;
  final String numeroSus;
  final String comunidade;
  final String dataNascimento; // Formato YYYY-MM-DD
  final int synced;

  PacienteModel({
    this.id,
    required this.nome,
    required this.cpf,
    required this.numeroSus,
    required this.comunidade,
    required this.dataNascimento,
    this.synced = 0,
  });

  // Cálculo automático da idade a partir da data de nascimento
  int get idade {
    try {
      final partes = dataNascimento.split('-');
      if (partes.length == 3) {
        final nasc = DateTime(int.parse(partes[0]), int.parse(partes[1]), int.parse(partes[2]));
        final hoje = DateTime.now();
        int anos = hoje.year - nasc.year;
        if (hoje.month < nasc.month || (hoje.month == nasc.month && hoje.day < nasc.day)) {
          anos--;
        }
        return anos < 0 ? 0 : anos;
      }
    } catch (_) {}
    return 0;
  }

  String get dataNascimentoFormatada {
    try {
      final partes = dataNascimento.split('-');
      if (partes.length == 3) {
        return '${partes[2]}/${partes[1]}/${partes[0]}';
      }
    } catch (_) {}
    return dataNascimento;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'cpf': cpf,
    'numero_sus': numeroSus,
    'comunidade': comunidade,
    'data_nascimento': dataNascimento,
    'idade': idade,
    'synced': synced,
  };

  factory PacienteModel.fromMap(Map<String, dynamic> map) => PacienteModel(
    id: map['id'],
    nome: map['nome'],
    cpf: map['cpf'] ?? '',
    numeroSus: map['numero_sus'] ?? '',
    comunidade: map['comunidade'],
    dataNascimento: map['data_nascimento'] ?? '2000-01-01',
    synced: map['synced'] ?? 0,
  );

  Map<String, dynamic> toApiJson() => {
    'id': id,
    'nome': nome,
    'cpf': cpf,
    'numero_sus': numeroSus,
    'data_nascimento': dataNascimento,
    'comunidade': comunidade,
  };
}

class MedicamentoModel {
  final int? id;
  final String nome;
  final String especificacao;
  int quantidadeDisponivel;
  int capacidadeMaxima;
  int synced;

  MedicamentoModel({
    this.id,
    required this.nome,
    required this.especificacao,
    required this.quantidadeDisponivel,
    required this.capacidadeMaxima,
    this.synced = 1,
  });

  double get percentualConsumido =>
      capacidadeMaxima == 0 ? 0.0 : ((capacidadeMaxima - quantidadeDisponivel) / capacidadeMaxima) * 100;

  Map<String, dynamic> toMap() => {
    'id': id,
    'nome': nome,
    'especificacao': especificacao,
    'quantidade_disponivel': quantidadeDisponivel,
    'capacidade_maxima': capacidadeMaxima,
    'synced': synced,
  };

  factory MedicamentoModel.fromMap(Map<String, dynamic> map) => MedicamentoModel(
    id: map['id'],
    nome: map['nome'],
    especificacao: map['especificacao'] ?? '',
    quantidadeDisponivel: map['quantidade_disponivel'],
    capacidadeMaxima: map['capacidade_maxima'] ?? 200,
    synced: map['synced'] ?? 1,
  );

  Map<String, dynamic> toApiSyncJson() => {
    'id': id,
    'nome': nome,
    'especificacao': especificacao,
    'quantidade_disponivel': quantidadeDisponivel,
    'capacidade_maxima': capacidadeMaxima,
  };
}

class AtendimentoModel {
  final int? id;
  final int pacienteId;
  final int? profissionalId;
  final String pacienteNome;
  final String profissionalNome;
  final String profissionalRegistro;
  final String dataHora;
  final String anamnese;
  final String conduta;
  final String classificacaoRisco;
  final int synced;

  AtendimentoModel({
    this.id,
    required this.pacienteId,
    this.profissionalId,
    required this.pacienteNome,
    required this.profissionalNome,
    required this.profissionalRegistro,
    required this.dataHora,
    required this.anamnese,
    required this.conduta,
    this.classificacaoRisco = 'Verde',
    this.synced = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'paciente_id': pacienteId,
    'profissional_id': profissionalId,
    'paciente_nome': pacienteNome,
    'profissional_nome': profissionalNome,
    'profissional_registro': profissionalRegistro,
    'data_hora': dataHora,
    'anamnese': anamnese,
    'conduta': conduta,
    'classificacao_risco': classificacaoRisco,
    'synced': synced,
  };

  factory AtendimentoModel.fromMap(Map<String, dynamic> map) => AtendimentoModel(
    id: map['id'],
    pacienteId: map['paciente_id'],
    profissionalId: map['profissional_id'],
    pacienteNome: map['paciente_nome'] ?? '',
    profissionalNome: map['profissional_nome'] ?? 'Equipe Fluvial',
    profissionalRegistro: map['profissional_registro'] ?? 'COREN/CRM',
    dataHora: map['data_hora'],
    anamnese: map['anamnese'] ?? '',
    conduta: map['conduta'] ?? '',
    classificacaoRisco: map['classificacao_risco'] ?? 'Verde',
    synced: map['synced'] ?? 0,
  );
}

class PrescricaoItemModel {
  final int? id;
  final int atendimentoId;
  final int medicamentoId;
  final String medicamentoNome;
  final int quantidadeDisponibilizada;
  final String dataHora;
  final int synced;

  PrescricaoItemModel({
    this.id,
    required this.atendimentoId,
    required this.medicamentoId,
    required this.medicamentoNome,
    required this.quantidadeDisponibilizada,
    required this.dataHora,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'atendimento_id': atendimentoId,
    'medicamento_id': medicamentoId,
    'medicamento_nome': medicamentoNome,
    'quantidade_dispensada': quantidadeDisponibilizada,
    'data_hora': dataHora,
    'synced': synced,
  };

  factory PrescricaoItemModel.fromMap(Map<String, dynamic> map) => PrescricaoItemModel(
    id: map['id'],
    atendimentoId: map['atendimento_id'],
    medicamentoId: map['medicamento_id'],
    medicamentoNome: map['medicamento_nome'] ?? '',
    quantidadeDisponibilizada: map['quantidade_dispensada'],
    dataHora: map['data_hora'] ?? '',
    synced: map['synced'] ?? 0,
  );
}

class ItemPrescricaoRascunho {
  final MedicamentoModel medicamento;
  final int quantidade;

  ItemPrescricaoRascunho({required this.medicamento, required this.quantidade});
}