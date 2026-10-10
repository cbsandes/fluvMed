import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'providers/app_state.dart';
import 'services/db_service.dart';
import 'utils/app_theme.dart';
import 'views/login_view.dart';
import 'views/main_container_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuração da fábrica SQLite para ambiente Web (Chrome)
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  try {
    await DatabaseService.instance.database;
  } catch (e) {
    debugPrint("Aviso de inicialização do banco local: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const FluvMedApp(),
    ),
  );
}

class FluvMedApp extends StatelessWidget {
  const FluvMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return MaterialApp(
      title: 'FluvMed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(
        altoContraste: state.altoContraste,
        escalaFonte: state.escalaFonte,
      ),
      home: state.usuarioLogado == null ? const LoginScreen() : const MainContainer(),
    );
  }
}