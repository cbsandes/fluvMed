import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db_service.dart';
import '../providers/app_state.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usuarioCtrl = TextEditingController(text: 'enf.ana');
  final TextEditingController _senhaCtrl = TextEditingController(text: '123');
  bool _erroAutenticacao = false;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.darkSlate,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Identidade Visual
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.health_and_safety, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                const Text('FluvMed', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Equipe de saúde fluvial', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 24),

                // Heurística de Nielsen H1: Visibilidade do status do sistema
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Sem conexão. Entrando com credenciais em cache do último acesso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF004D40), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),

                // Card de Formulário
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usuarioCtrl,
                        decoration: InputDecoration(
                          labelText: 'Usuário',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _senhaCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (_erroAutenticacao)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text('Credenciais incorretas!', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final tec = await DatabaseService.instance.autenticar(
                              _usuarioCtrl.text.trim(),
                              _senhaCtrl.text.trim(),
                            );
                            if (tec != null) {
                              state.setUsuarioLogado(tec);
                            } else {
                              setState(() => _erroAutenticacao = true);
                            }
                          },
                          icon: const Icon(Icons.lock_open, color: Colors.white),
                          label: const Text(
                            'Entrar com credenciais em cache',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _mostrarDialogCadastroTecnico(context),
                        icon: const Icon(Icons.person_add, color: AppTheme.primaryTeal),
                        label: const Text('Cadastrar Novo Técnico (Local)', style: TextStyle(color: AppTheme.primaryTeal)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Acesso ao painel liberado mesmo sem internet.', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogCadastroTecnico(BuildContext context) {
    final nome = TextEditingController();
    final reg = TextEditingController();
    final cargo = TextEditingController(text: 'Técnico de Saúde');
    final user = TextEditingController();
    final pass = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Novo Técnico de Saúde'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome Completo')),
              TextField(controller: reg, decoration: const InputDecoration(labelText: 'Registro (CRM/COREN)')),
              TextField(controller: cargo, decoration: const InputDecoration(labelText: 'Cargo')),
              TextField(controller: user, decoration: const InputDecoration(labelText: 'Usuário de Login')),
              TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            onPressed: () async {
              if (nome.text.isNotEmpty && user.text.isNotEmpty && pass.text.isNotEmpty) {
                await ctx.read<AppState>().cadastrarNovoTecnico(
                  nome: nome.text,
                  registro: reg.text,
                  cargo: cargo.text,
                  usuario: user.text,
                  senha: pass.text,
                );
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Técnico cadastrado com sucesso no aparelho!')),
                );
              }
            },
            child: const Text('Salvar no Aparelho', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}