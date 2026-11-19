import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final navBgColor = state.altoContraste ? AppTheme.highContrastCard : Colors.white;
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: navBgColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: state.altoContraste ? Brightness.light : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: state.altoContraste ? AppTheme.highContrastBlack : AppTheme.darkSlate,
        body: Padding(
          padding: EdgeInsets.only(top: topInset),
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
        bottomNavigationBar: _buildBottomNav(context, state),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, AppState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'FluvMed',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '· ${state.usuarioLogado?.nome.split(' ').first ?? 'Equipe'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
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
                    Flexible(
                      child: Text(
                        state.isOfflineSimulado ? 'Modo Offline: Dados Locais' : 'Conectado à UBS Central',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amberWarning,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.totalPendencias}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
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
      width: 34,
      height: 34,
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

  Widget _buildBottomNav(BuildContext context, AppState state) {
    final bgColor = state.altoContraste ? AppTheme.highContrastCard : Colors.white;
    final borderColor = state.altoContraste ? Colors.white24 : const Color(0xFFE2E8F0);
    // Lê diretamente a altura física da barra do Android (3 botões ou gestos)
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(child: _buildNavItem(0, Icons.people_outline, 'Pacientes', state.totalPendencias, state)),
            Expanded(child: _buildNavItem(1, Icons.monitor_heart_outlined, 'Atendimento', 0, state)),
            Expanded(child: _buildNavItem(2, Icons.inventory_2_outlined, 'Estoque/Sync', state.totalPendencias, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int badgeCount, AppState state) {
    final isSelected = _tabIndex == index;
    final activeColor = state.altoContraste ? AppTheme.highContrastYellow : AppTheme.primaryTeal;
    final inactiveColor = state.altoContraste ? Colors.white70 : Colors.grey.shade600;
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: () => setState(() => _tabIndex = index),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (badgeCount > 0 && index != 1)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
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