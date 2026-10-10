import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'db_service.dart';
import '../providers/app_state.dart';

class ApiService {
  static String get baseUrl => kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

  // Puxa o estado global do PostgreSQL para restaurar o aparelho local
  static Future<bool> puxarDadosDoServidor() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sync/pull'),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dados = jsonDecode(response.body);
        await DatabaseService.instance.atualizarComDadosConsolidados(dados);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Aviso: servidor central inacessível para pull inicial: $e');
      return false;
    }
  }

  // Executa o envio de lote das pendências locais e absorve a base consolidada
  static Future<bool> sincronizarLote(AppState state) async {
    state.ultimoErroSync = null;
    try {
      final db = DatabaseService.instance;
      final profs = await db.getProfissionaisPendentes();
      final pacs = await db.getPacientesPendentes();
      final atends = await db.getAtendimentosPendentes();
      final prescs = await db.getPrescricoesPendentes();
      final meds = await db.getMedicamentosPendentes();

      final payload = {
        "profissionais": profs.map((p) => p.toApiJson()).toList(),
        "pacientes": pacs.map((p) => p.toApiJson()).toList(),
        "atendimentos": atends.map((a) => {
          "paciente_id": a.pacienteId,
          "profissional_id": a.profissionalId,
          "paciente_nome": a.pacienteNome,
          "profissional_nome": a.profissionalNome,
          "profissional_registro": a.profissionalRegistro,
          "data_hora": a.dataHora,
          "anamnese": a.anamnese,
          "conduta": a.conduta,
          "classificacao_risco": a.classificacaoRisco,
          "status_sincronizacao": true,
        }).toList(),
        "prescricoes": prescs.map((pr) => {
          "atendimento_id": pr.atendimentoId,
          "medicamento_id": pr.medicamentoId,
          "medicamento_nome": pr.medicamentoNome,
          "quantidade_dispensada": pr.quantidadeDisponibilizada,
          "data_hora": pr.dataHora,
        }).toList(),
        "estoque_local": meds.map((m) => m.toApiSyncJson()).toList(),
      };

      debugPrint('Enviando sincronização em lote para: $baseUrl/sync/lote');

      final response = await http.post(
        Uri.parse('$baseUrl/sync/lote'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await db.marcarTudoComoSincronizado();
        final Map<String, dynamic> corpoResposta = jsonDecode(response.body);
        if (corpoResposta['dados_consolidados'] != null) {
          await db.atualizarComDadosConsolidados(corpoResposta['dados_consolidados']);
        }
        return true;
      } else {
        try {
          final erroJson = jsonDecode(response.body);
          state.ultimoErroSync = 'Servidor (${response.statusCode}): ${erroJson["detail"]}';
        } catch (_) {
          state.ultimoErroSync = 'Servidor retornou status ${response.statusCode}';
        }
        return false;
      }
    } catch (e) {
      debugPrint('Exceção ao comunicar com a API: $e');
      state.ultimoErroSync = 'Não foi possível contatar a API em $baseUrl.';
      return false;
    }
  }
}