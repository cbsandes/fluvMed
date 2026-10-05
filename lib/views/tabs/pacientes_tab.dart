import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/app_theme.dart';

class PacientesTab extends StatefulWidget {
  final VoidCallback onIniciarAtendimento;
  const PacientesTab({super.key, required this.onIniciarAtendimento});

  @override
  State<PacientesTab> createState() => _PacientesTabState();
}

class _PacientesTabState extends State<PacientesTab> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtrados = state.pacientes.where((p) {
      final q = _busca.toLowerCase();
      return p.nome.toLowerCase().contains(q) || p.cpf.contains(q) || p.numeroSus.contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pacientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Cadastro local da equipe fluvial', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          // Campo de busca
          TextField(
            onChanged: (val) => setState(() => _busca = val),
            decoration: InputDecoration(
              hintText: 'Buscar por Nome, CPF ou Cartão SUS',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Botão Novo Paciente
          InkWell(
            onTap: () => _dialogFormularioPaciente(context, state),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
              ),
              child: const Center(
                child: Text('+ Novo Paciente', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lista de Pacientes
          Expanded(
            child: ListView.builder(
              itemCount: filtrados.length,
              itemBuilder: (ctx, i) {
                final pac = filtrados[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFE0F2F1),
                                child: const Icon(Icons.person, color: AppTheme.primaryTeal),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pac.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${pac.idade} anos (${pac.dataNascimentoFormatada}) · CPF ${pac.cpf}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  Text('SUS ${pac.numeroSus}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTeal),
                            tooltip: 'Editar Dados do Paciente',
                            onPressed: () => _dialogFormularioPaciente(context, state, pacienteExistente: pac),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(pac.comunidade, style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _mostrarHistoricoPaciente(context, state, pac),
                              icon: const Icon(Icons.history, size: 16, color: AppTheme.primaryTeal),
                              label: const Text('Histórico', style: TextStyle(color: AppTheme.primaryTeal)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                state.selecionarPaciente(pac);
                                widget.onIniciarAtendimento();
                              },
                              child: const Text('Iniciar Atendimento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _dialogFormularioPaciente(BuildContext context, AppState state, {PacienteModel? pacienteExistente}) {
    final nome = TextEditingController(text: pacienteExistente?.nome ?? '');
    final cpf = TextEditingController(text: pacienteExistente?.cpf ?? '');
    final sus = TextEditingController(text: pacienteExistente?.numeroSus ?? '');
    final com = TextEditingController(text: pacienteExistente?.comunidade ?? '');

    DateTime dataSelecionada = pacienteExistente != null
        ? DateTime.tryParse(pacienteExistente.dataNascimento) ?? DateTime(1995, 1, 1)
        : DateTime(1995, 1, 1);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final idadeCalculada = () {
            final hoje = DateTime.now();
            int anos = hoje.year - dataSelecionada.year;
            if (hoje.month < dataSelecionada.month || (hoje.month == dataSelecionada.month && hoje.day < dataSelecionada.day)) {
              anos--;
            }
            return anos < 0 ? 0 : anos;
          }();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(pacienteExistente == null ? 'Novo Paciente' : 'Atualizar Paciente'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome completo')),
                  TextField(controller: cpf, decoration: const InputDecoration(labelText: 'CPF')),
                  TextField(controller: sus, decoration: const InputDecoration(labelText: 'Cartão SUS (15 dígitos)')),
                  TextField(controller: com, decoration: const InputDecoration(labelText: 'Comunidade ribeirinha')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data de Nascimento', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            DateFormat('dd/MM/yyyy').format(dataSelecionada),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Idade calculada: $idadeCalculada anos',
                            style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE0F2F1), elevation: 0),
                        onPressed: () async {
                          final escolhida = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada,
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (escolhida != null) {
                            setModalState(() => dataSelecionada = escolhida);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryTeal),
                        label: const Text('Calendário', style: TextStyle(color: AppTheme.primaryTeal)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                onPressed: () async {
                  if (nome.text.isNotEmpty) {
                    final dataStr = DateFormat('yyyy-MM-dd').format(dataSelecionada);
                    if (pacienteExistente == null) {
                      await state.cadastrarPaciente(
                        nome: nome.text,
                        cpf: cpf.text,
                        numeroSus: sus.text,
                        comunidade: com.text,
                        dataNascimento: dataStr,
                      );
                    } else {
                      final pacAtualizado = PacienteModel(
                        id: pacienteExistente.id,
                        nome: nome.text,
                        cpf: cpf.text,
                        numeroSus: sus.text,
                        comunidade: com.text,
                        dataNascimento: dataStr,
                        synced: 0,
                      );
                      await state.atualizarPaciente(pacAtualizado);
                    }
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Salvar no Aparelho', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarHistoricoPaciente(BuildContext context, AppState state, PacienteModel pac) async {
    final atendimentos = await state.obterHistoricoPaciente(pac.id!);

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prontuário: ${pac.nome}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${pac.comunidade} · ${pac.idade} anos', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            if (atendimentos.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Nenhum atendimento registrado anteriormente para este paciente.', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: atendimentos.length,
                  itemBuilder: (ctx, idx) {
                    final at = atendimentos[idx];
                    return FutureBuilder<List<PrescricaoItemModel>>(
                      future: state.obterPrescricoesAtendimento(at.id!),
                      builder: (context, snapshot) {
                        final prescs = snapshot.data ?? [];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Atendimento em: ${at.dataHora}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(at.classificacaoRisco, style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user, size: 14, color: AppTheme.primaryTeal),
                                    const SizedBox(width: 4),
                                    Text('Atendido por: ${at.profissionalNome} (${at.profissionalRegistro})', style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Anamnese: ${at.anamnese}', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Conduta: ${at.conduta}', style: const TextStyle(fontSize: 13)),
                                const SizedBox(height: 8),
                                const Text('Medicamentos Prescritos:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                                if (prescs.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2.0),
                                    child: Text('Nenhum medicamento dispensado (apenas orientações clínicas).', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54)),
                                  )
                                else
                                  ...prescs.map((p) => Text('• ${p.medicamentoNome}: ${p.quantidadeDisponibilizada} unidade(s)', style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}