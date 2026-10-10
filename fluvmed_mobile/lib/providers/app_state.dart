import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  TecnicoSaude? usuarioLogado;
  bool isOfflineSimulado = true;
  int totalPendencias = 0;
  String ultimaSincronizacao = "--:--";
  String? ultimoErroSync;

  // Acessibilidade e-MAG
  bool altoContraste = false;
  double escalaFonte = 1.0;

  List<PacienteModel> pacientes = [];
  List<MedicamentoModel> medicamentos = [];
  List<AtendimentoModel> atendimentosPendentes = [];
  List<PrescricaoItemModel> prescricoesPendentes = [];
  List<MedicamentoModel> medicamentosPendentes = [];

  PacienteModel? pacienteSelecionado;
  List<ItemPrescricaoRascunho> prescricoesRascunho = [];

  AppState() {
    inicializar();
  }

  Future<void> inicializar() async {
    await carregarDados();
    // Tenta puxar o estado central na inicialização sem bloquear o offline
    final pullOk = await ApiService.puxarDadosDoServidor();
    if (pullOk) {
      await carregarDados();
    }
  }

  void setUsuarioLogado(TecnicoSaude tec) {
    usuarioLogado = tec;
    notifyListeners();
  }

  void deslogar() {
    usuarioLogado = null;
    pacienteSelecionado = null;
    prescricoesRascunho.clear();
    notifyListeners();
  }

  void alternarConectividade() async {
    isOfflineSimulado = !isOfflineSimulado;
    notifyListeners();

    // Ao ligar o modo conectado, roda a rotina bidirecional automática
    if (!isOfflineSimulado) {
      await dispararSincronizacao();
    }
  }

  void setAltoContraste(bool val) {
    altoContraste = val;
    notifyListeners();
  }

  void alterarFonte(double delta) {
    escalaFonte = (escalaFonte + delta).clamp(0.8, 1.4);
    notifyListeners();
  }

  Future<void> carregarDados() async {
    final db = DatabaseService.instance;
    pacientes = await db.getPacientes();
    medicamentos = await db.getMedicamentos();
    atendimentosPendentes = await db.getAtendimentosPendentes();
    prescricoesPendentes = await db.getPrescricoesPendentes();
    medicamentosPendentes = await db.getMedicamentosPendentes();
    totalPendencias = await db.getTotalPendencias();
    notifyListeners();
  }

  void selecionarPaciente(PacienteModel pac) {
    pacienteSelecionado = pac;
    prescricoesRascunho.clear();
    notifyListeners();
  }

  void limparPacienteSelecionado() {
    pacienteSelecionado = null;
    prescricoesRascunho.clear();
    notifyListeners();
  }

  void adicionarMedicamentoRascunho(MedicamentoModel med, int qtd) {
    final index = prescricoesRascunho.indexWhere((item) => item.medicamento.id == med.id);
    if (index >= 0) {
      final novaQtd = prescricoesRascunho[index].quantidade + qtd;
      prescricoesRascunho[index] = ItemPrescricaoRascunho(medicamento: med, quantidade: novaQtd);
    } else {
      prescricoesRascunho.add(ItemPrescricaoRascunho(medicamento: med, quantidade: qtd));
    }
    notifyListeners();
  }

  void removerMedicamentoRascunho(int index) {
    prescricoesRascunho.removeAt(index);
    notifyListeners();
  }

  Future<bool> cadastrarNovoTecnico({
    required String nome,
    required String registro,
    required String cargo,
    required String usuario,
    required String senha,
  }) async {
    final tec = TecnicoSaude(
      nome: nome,
      registroProfissional: registro,
      cargo: cargo,
      usuario: usuario,
      senha: senha,
      synced: 0,
    );
    await DatabaseService.instance.insertProfissional(tec);
    await carregarDados();
    return true;
  }

  Future<void> atualizarEstoqueMedicamento(int id, int novaQtd, {int? novaCapacidade}) async {
    await DatabaseService.instance.atualizarEstoque(id, novaQtd, novaCapacidade: novaCapacidade);
    await carregarDados();
  }

  Future<void> cadastrarPaciente({
    required String nome,
    required String cpf,
    required String numeroSus,
    required String comunidade,
    required String dataNascimento,
  }) async {
    final pac = PacienteModel(
      nome: nome,
      cpf: cpf,
      numeroSus: numeroSus,
      comunidade: comunidade,
      dataNascimento: dataNascimento,
      synced: 0,
    );
    await DatabaseService.instance.insertPaciente(pac);
    await carregarDados();
  }

  Future<void> atualizarPaciente(PacienteModel pac) async {
    await DatabaseService.instance.updatePaciente(pac);
    await carregarDados();
  }

  Future<List<AtendimentoModel>> obterHistoricoPaciente(int pacienteId) async {
    return await DatabaseService.instance.getAtendimentosPorPaciente(pacienteId);
  }

  Future<List<PrescricaoItemModel>> obterPrescricoesAtendimento(int atendimentoId) async {
    return await DatabaseService.instance.getPrescricoesPorAtendimento(atendimentoId);
  }

  Future<void> salvarAtendimentoCompleto({
    required String anamnese,
    required String conduta,
  }) async {
    if (pacienteSelecionado == null) return;

    final db = DatabaseService.instance;
    final agora = DateFormat('dd/MM HH:mm').format(DateTime.now());

    final atend = AtendimentoModel(
      pacienteId: pacienteSelecionado!.id!,
      profissionalId: usuarioLogado?.id,
      pacienteNome: pacienteSelecionado!.nome,
      profissionalNome: usuarioLogado?.nome ?? 'Enfermeiro de Campo',
      profissionalRegistro: usuarioLogado?.registroProfissional ?? 'COREN/CRM',
      dataHora: agora,
      anamnese: anamnese,
      conduta: conduta,
      synced: 0,
    );

    final atendId = await db.insertAtendimento(atend);

    for (var item in prescricoesRascunho) {
      final presc = PrescricaoItemModel(
        atendimentoId: atendId,
        medicamentoId: item.medicamento.id!,
        medicamentoNome: item.medicamento.nome,
        quantidadeDisponibilizada: item.quantidade,
        dataHora: agora,
        synced: 0,
      );
      await db.insertPrescricao(presc);
    }

    limparPacienteSelecionado();
    await carregarDados();
  }

  Future<bool> dispararSincronizacao() async {
    if (isOfflineSimulado) return false;
    final ok = await ApiService.sincronizarLote(this);
    if (ok) {
      ultimaSincronizacao = DateFormat('HH:mm').format(DateTime.now());
      await carregarDados();
      return true;
    }
    return false;
  }
}