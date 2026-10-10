import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../utils/app_theme.dart';

class AtendimentoTab extends StatefulWidget {
  final VoidCallback onVoltarParaPacientes;
  const AtendimentoTab({super.key, required this.onVoltarParaPacientes});

  @override
  State<AtendimentoTab> createState() => _AtendimentoTabState();
}

class _AtendimentoTabState extends State<AtendimentoTab> {
  final TextEditingController _anamneseCtrl = TextEditingController();
  final TextEditingController _condutaCtrl = TextEditingController();
  final TextEditingController _qtdCtrl = TextEditingController(text: '1');
  bool _incluirPrescricao = false;
  MedicamentoModel? _medicamentoEscolhido;

  @override
  void dispose() {
    _anamneseCtrl.dispose();
    _condutaCtrl.dispose();
    _qtdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pac = state.pacienteSelecionado;

    // Estado Vazio (Nenhum paciente selecionado)
    if (pac == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Selecione um paciente para iniciar o\natendimento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: widget.onVoltarParaPacientes,
              child: const Text('Ir para Pacientes', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _incluirPrescricao = false;
                    _medicamentoEscolhido = null;
                  });
                  state.limparPacienteSelecionado();
                },
              ),
              const Text('Atendimento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),

          // Resumo do Paciente & Assinatura do Técnico
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pac.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${pac.idade} anos (${pac.dataNascimentoFormatada}) · SUS ${pac.numeroSus}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(pac.comunidade, style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.w600)),
                const Divider(),
                Text(
                  'Técnico Responsável: ${state.usuarioLogado?.nome ?? 'Equipe'} (${state.usuarioLogado?.registroProfissional ?? 'Local'})',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Anamnese
          const Text('Anamnese', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _anamneseCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Queixa principal, história e exame físico',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Conduta
          const Text('Conduta', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _condutaCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Orientações, encaminhamentos e retorno',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Seção de Prescrição Opcional
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRESCRIÇÃO DE MEDICAMENTOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        SizedBox(height: 2),
                        Text('Dispensar insumos da farmácia do barco?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Switch.adaptive(
                      value: _incluirPrescricao,
                      activeColor: AppTheme.primaryTeal,
                      onChanged: (val) {
                        setState(() {
                          _incluirPrescricao = val;
                          if (!val) {
                            state.prescricoesRascunho.clear();
                            _medicamentoEscolhido = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
                if (!_incluirPrescricao) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Atendimento sem dispensação de remédios. O registro será salvo apenas com anamnese e orientações.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  )
                ] else ...[
                  const Divider(height: 24),
                  const Text('Selecione o insumo disponível:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<MedicamentoModel>(
                    value: _medicamentoEscolhido,
                    hint: const Text('Toque para escolher o medicamento...'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: state.medicamentos.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text('${m.nome} — Saldo: ${m.quantidadeDisponivel} ${m.especificacao}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _medicamentoEscolhido = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtdCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantidade',
                            filled: true,
                            fillColor: AppTheme.backgroundLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () {
                          if (_medicamentoEscolhido == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor, selecione um medicamento no menu acima!')),
                            );
                            return;
                          }
                          final q = int.tryParse(_qtdCtrl.text) ?? 0;
                          if (q <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('A quantidade dispensada deve ser de no mínimo 1 unidade!')),
                            );
                            return;
                          }
                          if (q > _medicamentoEscolhido!.quantidadeDisponivel) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Quantidade solicitada excede o saldo disponível no barco!')),
                            );
                            return;
                          }
                          state.adicionarMedicamentoRascunho(_medicamentoEscolhido!, q);
                          setState(() {
                            _medicamentoEscolhido = null;
                            _qtdCtrl.text = '1';
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Adicionar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Itens inclusos na receita deste atendimento:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 6),
                  if (state.prescricoesRascunho.isEmpty)
                    const Text('Nenhum item adicionado à receita ainda.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...state.prescricoesRascunho.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.medicamento.nome} — ${item.quantidade} unidade(s)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => state.removerMedicamentoRascunho(idx),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _incluirPrescricao = false;
                      _medicamentoEscolhido = null;
                      _anamneseCtrl.clear();
                      _condutaCtrl.clear();
                    });
                    state.limparPacienteSelecionado();
                  },
                  child: const Text('Cancelar', style: TextStyle(color: Colors.black87)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await state.salvarAtendimentoCompleto(
                      anamnese: _anamneseCtrl.text,
                      conduta: _condutaCtrl.text,
                    );
                    setState(() {
                      _incluirPrescricao = false;
                      _medicamentoEscolhido = null;
                      _anamneseCtrl.clear();
                      _condutaCtrl.clear();
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Atendimento salvo no dispositivo com sucesso!')),
                    );
                  },
                  child: const Text('Salvar Atendimento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}