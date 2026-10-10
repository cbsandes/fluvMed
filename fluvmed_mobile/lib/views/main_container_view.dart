import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_theme.dart';
import 'tabs/pacientes_tab.dart';
import 'tabs/atendimento_tab.dart';
import 'tabs/estoque_sync_tab.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: state.altoContraste ? AppTheme.highContrastBlack : AppTheme.darkSlate,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(context, state),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: state.altoContraste ? const Color(0xFF121212) : AppTheme.backgroundLight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    PacientesTab(onIniciarAtendimento: () => setState(() => _tabIndex = 1)),
                    AtendimentoTab(onVoltarParaPacientes: () => setState(() => _tabIndex = 0)),
                    const EstoqueSyncTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(state),
    );
  }

  Widget _buildTopAppBar(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('FluvMed', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(
                    '· ${state.usuarioLogado?.nome.split(' ').first ?? 'Equipe'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: state.isOfflineSimulado ? AppTheme.amberWarning : Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.isOfflineSimulado ? 'Modo Offline: Dados Locais' : 'Conectado à UBS Central',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amberWarning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${state.totalPendencias}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 6),
              _buildTopIconBtn(
                icon: state.isOfflineSimulado ? Icons.wifi_off : Icons.wifi,
                onPressed: () => state.alternarConectividade(),
                tooltip: 'Alternar Modo Rede',
              ),
              const SizedBox(width: 6),
              _buildTopIconBtn(
                icon: Icons.help_outline,
                onPressed: () => _mostrarGuiaAjuda(context),
                tooltip: 'Guia Rápido Offline',
              ),
              const SizedBox(width: 6),
              _buildTopIconBtn(
                icon: Icons.settings,
                onPressed: () => _mostrarAcessibilidade(context, state),
                tooltip: 'Acessibilidade',
              ),
              const SizedBox(width: 6),
              _buildTopIconBtn(
                icon: Icons.logout,
                onPressed: () => _confirmarLogout(context, state),
                tooltip: 'Trocar de Técnico (Sair)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmarLogout(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trocar de Técnico?'),
        content: const Text('Deseja desconectar da sessão atual? Seus dados continuam seguros e salvos no aparelho.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              state.deslogar();
            },
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildTopIconBtn({required IconData icon, required VoidCallback onPressed, required String tooltip}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomNav(AppState state) {
    return Container(
      color: Colors.white,
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.people_outline, 'Pacientes', state.totalPendencias),
          _buildNavItem(1, Icons.monitor_heart_outlined, 'Atendimento', 0),
          _buildNavItem(2, Icons.inventory_2_outlined, 'Estoque/Sync', state.totalPendencias),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int badgeCount) {
    final isSelected = _tabIndex == index;
    final color = isSelected ? AppTheme.primaryTeal : Colors.grey.shade600;

    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          ),
          if (badgeCount > 0 && index != 1)
            Positioned(
              top: 4,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarGuiaAjuda(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Guia Rápido Offline', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Cadastre ou selecione o paciente na aba Pacientes.'),
              Text('2. Prescrição é opcional: dispense apenas se necessário.'),
              Text('3. Consulte o histórico de atendimentos e assinaturas.'),
              Text('4. Sincronize com a UBS Central após retornar do mutirão fluvial.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _mostrarAcessibilidade(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Acessibilidade & Preferências'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Alto Contraste'),
                value: state.altoContraste,
                onChanged: (val) {
                  state.setAltoContraste(val);
                  setModalState(() {});
                },
              ),
              const Divider(),
              const Text('Tamanho da fonte'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.text_decrease), onPressed: () => state.alterarFonte(-0.1)),
                  Text('${(state.escalaFonte * 100).toInt()}%'),
                  IconButton(icon: const Icon(Icons.text_increase), onPressed: () => state.alterarFonte(0.1)),
                ],
              )
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Concluir', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}