import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/db_service.dart';
import '../../providers/app_state.dart';
import '../../utils/app_theme.dart';

class EstoqueSyncTab extends StatelessWidget {
  const EstoqueSyncTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estoque e Sincronização', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('Farmácia do barco e fila de envio', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),

          // Banner de Status de Conexão e Botão de Envio
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: state.isOfflineSimulado ? const Color(0xFFFFF7ED) : const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: state.isOfflineSimulado ? const Color(0xFFFDBA74) : const Color(0xFF80CBC4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      state.isOfflineSimulado ? Icons.wifi_off : Icons.wifi,
                      color: state.isOfflineSimulado ? AppTheme.amberWarning : AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isOfflineSimulado ? 'Aguardando conexão — offline' : 'Wi-Fi UBS — online',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: state.isOfflineSimulado ? const Color(0xFF9A3412) : const Color(0xFF004D40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.totalPendencias} registro(s) na fila local · última sincronização: ${state.ultimaSincronizacao}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isOfflineSimulado ? const Color(0xFF80CBC4) : AppTheme.primaryTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (state.isOfflineSimulado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ative o modo rede no topo da tela para simular a chegada à UBS!')),
                        );
                        return;
                      }
                      final ok = await state.dispararSincronizacao();
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lote sincronizado e dados consolidados com o PostgreSQL!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.ultimoErroSync ?? 'Falha ao conectar com o FastAPI.'),
                            backgroundColor: Colors.red.shade800,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.sync, color: Colors.white),
                    label: const Text('Sincronizar Lote com FastAPI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Seção PENDÊNCIAS
          const Text('PENDÊNCIAS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          if (state.totalPendencias == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Text('Tudo sincronizado. Nenhuma pendência no aparelho.', style: TextStyle(color: Colors.grey)),
            )
          else ...[
            ...state.atendimentosPendentes.map((a) => _buildPendenciaCard('Atendimento', a.pacienteNome, a.dataHora)),
            ...state.prescricoesPendentes.map((p) => _buildPendenciaCard('Prescrição', p.medicamentoNome, p.dataHora)),
            ...state.medicamentosPendentes.map((m) => _buildPendenciaCard(
              'Ajuste de Estoque',
              '${m.nome}: ${m.quantidadeDisponivel}/${m.capacidadeMaxima}',
              'na fila',
            )),
          ],
          const SizedBox(height: 20),

          // Seção SALDOS NO BARCO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SALDOS NO BARCO', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
              TextButton.icon(
                onPressed: () => _dialogAdicionarNovoMedicamento(context, state),
                icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryTeal),
                label: const Text('Novo Insumo', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...state.medicamentos.map((med) => _buildMedicamentoCard(context, med, state)),
        ],
      ),
    );
  }

  Widget _buildPendenciaCard(String tipo, String desc, String hora) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tipo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$desc · $hora', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFF3DC), borderRadius: BorderRadius.circular(8)),
            child: const Text('na fila', style: TextStyle(color: AppTheme.amberWarning, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicamentoCard(BuildContext context, MedicamentoModel med, AppState state) {
    final perc = med.percentualConsumido;
    // Regra de Negócio RN01: Se consumo > 70% alerta laranja, 100% bloqueio vermelho
    final Color barColor = perc >= 100
        ? Colors.red
        : perc >= 70
            ? Colors.orange
            : AppTheme.primaryTeal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(med.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${med.quantidadeDisponivel}/${med.capacidadeMaxima} ${med.especificacao}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (med.capacidadeMaxima - med.quantidadeDisponivel) / med.capacidadeMaxima,
              backgroundColor: const Color(0xFFE2E8F0),
              color: barColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${perc.toInt()}% consumido na viagem', style: TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.w600)),
              InkWell(
                onTap: () => _dialogAjustarEstoque(context, med, state),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 14, color: AppTheme.primaryTeal),
                      SizedBox(width: 4),
                      Text('Ajustar Estoque', style: TextStyle(color: AppTheme.primaryTeal, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  void _dialogAjustarEstoque(BuildContext context, MedicamentoModel med, AppState state) {
    final qtdCtrl = TextEditingController(text: '${med.quantidadeDisponivel}');
    final capCtrl = TextEditingController(text: '${med.capacidadeMaxima}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ajustar ${med.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade em posse no barco'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacidade Total máxima'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            onPressed: () async {
              final nQtd = int.tryParse(qtdCtrl.text) ?? med.quantidadeDisponivel;
              final nCap = int.tryParse(capCtrl.text) ?? med.capacidadeMaxima;
              await state.atualizarEstoqueMedicamento(med.id!, nQtd, novaCapacidade: nCap);
              if (!context.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('Salvar Novo Saldo', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _dialogAdicionarNovoMedicamento(BuildContext context, AppState state) {
    final nome = TextEditingController();
    final esp = TextEditingController(text: 'comprimidos');
    final qtd = TextEditingController(text: '100');
    final cap = TextEditingController(text: '100');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Adicionar Insumo ao Barco'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome do Medicamento')),
            TextField(controller: esp, decoration: const InputDecoration(labelText: 'Especificação')),
            TextField(controller: qtd, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade Inicial')),
            TextField(controller: cap, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacidade Máxima')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            onPressed: () async {
              if (nome.text.isNotEmpty) {
                final db = await DatabaseService.instance.database;
                await db.insert('medicamentos', {
                  'nome': nome.text,
                  'especificacao': esp.text,
                  'quantidade_disponivel': int.tryParse(qtd.text) ?? 100,
                  'capacidade_maxima': int.tryParse(cap.text) ?? 100,
                  'synced': 0,
                });
                await state.carregarDados();
                if (!context.mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}