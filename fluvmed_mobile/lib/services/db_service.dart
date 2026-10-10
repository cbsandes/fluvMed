import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fluvmed_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await openDatabase(
        filePath,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE medicamentos ADD COLUMN synced INTEGER NOT NULL DEFAULT 1');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE atendimentos ADD COLUMN profissional_nome TEXT');
        await db.execute('ALTER TABLE atendimentos ADD COLUMN profissional_registro TEXT');
      } catch (_) {}
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profissionais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        registro_profissional TEXT NOT NULL,
        cargo TEXT NOT NULL,
        usuario TEXT UNIQUE NOT NULL,
        senha TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE pacientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        cpf TEXT,
        numero_sus TEXT,
        comunidade TEXT NOT NULL,
        data_nascimento TEXT,
        idade INTEGER,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE medicamentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        especificacao TEXT,
        quantidade_disponivel INTEGER NOT NULL,
        capacidade_maxima INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE atendimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        paciente_id INTEGER NOT NULL,
        profissional_id INTEGER,
        paciente_nome TEXT NOT NULL,
        profissional_nome TEXT,
        profissional_registro TEXT,
        data_hora TEXT NOT NULL,
        anamnese TEXT,
        conduta TEXT,
        classificacao_risco TEXT DEFAULT 'Verde',
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE prescricoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        atendimento_id INTEGER NOT NULL,
        medicamento_id INTEGER NOT NULL,
        medicamento_nome TEXT NOT NULL,
        quantidade_dispensada INTEGER NOT NULL,
        data_hora TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.insert('profissionais', {
      'nome': 'Ana Paula Ribeiro',
      'registro_profissional': 'COREN-AM 102938',
      'cargo': 'Enfermeira de Campo',
      'usuario': 'enf.ana',
      'senha': '123',
      'synced': 1,
    });

    final defaultMedicamentos = [
      {'nome': 'Dipirona 500mg', 'especificacao': 'comprimidos', 'quantidade_disponivel': 120, 'capacidade_maxima': 200, 'synced': 1},
      {'nome': 'Amoxicilina 500mg', 'especificacao': 'cápsulas', 'quantidade_disponivel': 48, 'capacidade_maxima': 150, 'synced': 1},
      {'nome': 'Soro de reidratação oral', 'especificacao': 'sachês', 'quantidade_disponivel': 76, 'capacidade_maxima': 100, 'synced': 1},
      {'nome': 'Ivermectina 6mg', 'especificacao': 'comprimidos', 'quantidade_disponivel': 22, 'capacidade_maxima': 80, 'synced': 1},
      {'nome': 'Losartana 50mg', 'especificacao': 'comprimidos', 'quantidade_disponivel': 90, 'capacidade_maxima': 120, 'synced': 1},
    ];

    for (var med in defaultMedicamentos) {
      await db.insert('medicamentos', med);
    }

    final defaultPacientes = [
      {
        'nome': 'Maria das Graças Souza',
        'cpf': '012.345.678-90',
        'numero_sus': '700 5012 3456 7890',
        'comunidade': 'Comunidade Nossa Senhora do Livramento',
        'data_nascimento': '1970-05-12',
        'idade': 56,
        'synced': 1,
      },
      {
        'nome': 'Raimundo Nonato Lima',
        'cpf': '123.456.789-01',
        'numero_sus': '700 6023 4567 8901',
        'comunidade': 'Vila do Careiro da Várzea',
        'data_nascimento': '1957-08-20',
        'idade': 69,
        'synced': 1,
      }
    ];

    for (var pac in defaultPacientes) {
      await db.insert('pacientes', pac);
    }
  }

  // Pacientes
  Future<int> insertPaciente(PacienteModel pac) async {
    final db = await database;
    return await db.insert('pacientes', pac.toMap());
  }

  Future<void> updatePaciente(PacienteModel pac) async {
    final db = await database;
    await db.update(
      'pacientes',
      pac.toMap(),
      where: 'id = ?',
      whereArgs: [pac.id],
    );
  }

  Future<List<PacienteModel>> getPacientes() async {
    final db = await database;
    final res = await db.query('pacientes', orderBy: 'id DESC');
    return res.map((e) => PacienteModel.fromMap(e)).toList();
  }

  // Profissionais
  Future<int> insertProfissional(TecnicoSaude tec) async {
    final db = await database;
    return await db.insert('profissionais', tec.toMap());
  }

  Future<TecnicoSaude?> autenticar(String usuario, String senha) async {
    final db = await database;
    final res = await db.query(
      'profissionais',
      where: 'usuario = ? AND senha = ?',
      whereArgs: [usuario, senha],
    );
    if (res.isNotEmpty) {
      return TecnicoSaude.fromMap(res.first);
    }
    return null;
  }

  // Medicamentos
  Future<List<MedicamentoModel>> getMedicamentos() async {
    final db = await database;
    final res = await db.query('medicamentos', orderBy: 'id ASC');
    return res.map((e) => MedicamentoModel.fromMap(e)).toList();
  }

  Future<void> atualizarEstoque(int id, int novaQtd, {int? novaCapacidade}) async {
    final db = await database;
    Map<String, dynamic> updateData = {
      'quantidade_disponivel': novaQtd,
      'synced': 0,
    };
    if (novaCapacidade != null) {
      updateData['capacidade_maxima'] = novaCapacidade;
    }
    await db.update(
      'medicamentos',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Atendimentos e Histórico
  Future<int> insertAtendimento(AtendimentoModel atend) async {
    final db = await database;
    return await db.insert('atendimentos', atend.toMap());
  }

  Future<List<AtendimentoModel>> getAtendimentosPorPaciente(int pacienteId) async {
    final db = await database;
    final res = await db.query(
      'atendimentos',
      where: 'paciente_id = ?',
      whereArgs: [pacienteId],
      orderBy: 'id DESC',
    );
    return res.map((e) => AtendimentoModel.fromMap(e)).toList();
  }

  Future<List<PrescricaoItemModel>> getPrescricoesPorAtendimento(int atendimentoId) async {
    final db = await database;
    final res = await db.query(
      'prescricoes',
      where: 'atendimento_id = ?',
      whereArgs: [atendimentoId],
    );
    return res.map((e) => PrescricaoItemModel.fromMap(e)).toList();
  }

  Future<int> insertPrescricao(PrescricaoItemModel presc) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE medicamentos 
      SET quantidade_disponivel = quantidade_disponivel - ?,
          synced = 0
      WHERE id = ?
    ''', [presc.quantidadeDisponibilizada, presc.medicamentoId]);

    return await db.insert('prescricoes', presc.toMap());
  }

  // Pendências exclusivas (Apenas dados com synced == 0)
  Future<List<AtendimentoModel>> getAtendimentosPendentes() async {
    final db = await database;
    final res = await db.query('atendimentos', where: 'synced = 0');
    return res.map((e) => AtendimentoModel.fromMap(e)).toList();
  }

  Future<List<PrescricaoItemModel>> getPrescricoesPendentes() async {
    final db = await database;
    final res = await db.query('prescricoes', where: 'synced = 0');
    return res.map((e) => PrescricaoItemModel.fromMap(e)).toList();
  }

  Future<List<PacienteModel>> getPacientesPendentes() async {
    final db = await database;
    final res = await db.query('pacientes', where: 'synced = 0');
    return res.map((e) => PacienteModel.fromMap(e)).toList();
  }

  Future<List<TecnicoSaude>> getProfissionaisPendentes() async {
    final db = await database;
    final res = await db.query('profissionais', where: 'synced = 0');
    return res.map((e) => TecnicoSaude.fromMap(e)).toList();
  }

  Future<List<MedicamentoModel>> getMedicamentosPendentes() async {
    final db = await database;
    try {
      final res = await db.query('medicamentos', where: 'synced = 0');
      return res.map((e) => MedicamentoModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getTotalPendencias() async {
    final p1 = (await getProfissionaisPendentes()).length;
    final p2 = (await getPacientesPendentes()).length;
    final p3 = (await getAtendimentosPendentes()).length;
    final p4 = (await getPrescricoesPendentes()).length;
    final p5 = (await getMedicamentosPendentes()).length;
    return p1 + p2 + p3 + p4 + p5;
  }

  Future<void> marcarTudoComoSincronizado() async {
    final db = await database;
    await db.update('profissionais', {'synced': 1});
    await db.update('pacientes', {'synced': 1});
    await db.update('atendimentos', {'synced': 1});
    await db.update('prescricoes', {'synced': 1});
    await db.update('medicamentos', {'synced': 1});
  }

  // Two-Way Sync: Restauração consolidada do PostgreSQL no SQLite móvel
  Future<void> atualizarComDadosConsolidados(Map<String, dynamic> dados) async {
    final db = await database;

    // 1. Medicamentos consolidados
    if (dados['medicamentos'] != null) {
      for (var raw in dados['medicamentos']) {
        final med = Map<String, dynamic>.from(raw as Map);
        final nome = med['nome']?.toString() ?? '';
        if (nome.isEmpty) continue;

        final qtd = int.tryParse(med['quantidade_estoque_geral']?.toString() ?? '') ??
            int.tryParse(med['quantidade_disponivel']?.toString() ?? '') ??
            0;
        final cap = int.tryParse(med['capacidade_maxima']?.toString() ?? '') ?? 200;
        final esp = med['especificacao']?.toString() ?? 'comprimidos';

        final existe = await db.query('medicamentos', where: 'nome = ?', whereArgs: [nome]);
        if (existe.isNotEmpty) {
          await db.update(
            'medicamentos',
            {
              'quantidade_disponivel': qtd,
              'capacidade_maxima': cap,
              'especificacao': esp,
              'synced': 1,
            },
            where: 'nome = ?',
            whereArgs: [nome],
          );
        } else {
          await db.insert('medicamentos', {
            'nome': nome,
            'especificacao': esp,
            'quantidade_disponivel': qtd,
            'capacidade_maxima': cap,
            'synced': 1,
          });
        }
      }
    }

    // 2. Pacientes consolidados
    if (dados['pacientes'] != null) {
      for (var raw in dados['pacientes']) {
        final pac = Map<String, dynamic>.from(raw as Map);
        final cpf = pac['cpf']?.toString();
        final sus = pac['numero_sus']?.toString();
        final nome = pac['nome']?.toString() ?? '';
        if (nome.isEmpty) continue;

        List<Map<String, dynamic>> existe = [];
        if (cpf != null && cpf.isNotEmpty) {
          existe = await db.query('pacientes', where: 'cpf = ?', whereArgs: [cpf]);
        } else if (sus != null && sus.isNotEmpty) {
          existe = await db.query('pacientes', where: 'numero_sus = ?', whereArgs: [sus]);
        }

        if (existe.isNotEmpty) {
          await db.update(
            'pacientes',
            {
              'nome': nome,
              'cpf': cpf ?? existe.first['cpf'],
              'numero_sus': sus ?? existe.first['numero_sus'],
              'comunidade': pac['comunidade']?.toString() ?? existe.first['comunidade'],
              'data_nascimento': pac['data_nascimento']?.toString() ?? existe.first['data_nascimento'],
              'synced': 1,
            },
            where: 'id = ?',
            whereArgs: [existe.first['id']],
          );
        } else {
          await db.insert('pacientes', {
            'nome': nome,
            'cpf': cpf ?? '',
            'numero_sus': sus ?? '',
            'comunidade': pac['comunidade']?.toString() ?? '',
            'data_nascimento': pac['data_nascimento']?.toString() ?? '2000-01-01',
            'synced': 1,
          });
        }
      }
    }

    // 3. Atendimentos históricos salvos na central
    if (dados['atendimentos'] != null) {
      for (var raw in dados['atendimentos']) {
        final at = Map<String, dynamic>.from(raw as Map);
        final dataHora = at['data_hora']?.toString() ?? '';
        final pacNome = at['paciente_nome']?.toString() ?? '';

        final existe = await db.query(
          'atendimentos',
          where: 'data_hora = ? AND paciente_nome = ?',
          whereArgs: [dataHora, pacNome],
        );

        if (existe.isEmpty) {
          await db.insert('atendimentos', {
            'paciente_id': at['paciente_id'] ?? 1,
            'profissional_id': at['profissional_id'],
            'paciente_nome': pacNome,
            'profissional_nome': at['profissional_nome']?.toString() ?? 'Equipe Fluvial',
            'profissional_registro': at['profissional_registro']?.toString() ?? 'COREN/CRM',
            'data_hora': dataHora,
            'anamnese': at['anamnese']?.toString() ?? '',
            'conduta': at['conduta']?.toString() ?? '',
            'classificacao_risco': at['classificacao_risco']?.toString() ?? 'Verde',
            'synced': 1,
          });
        }
      }
    }

    // 4. Prescrições salvas na central
    if (dados['prescricoes'] != null) {
      for (var raw in dados['prescricoes']) {
        final pr = Map<String, dynamic>.from(raw as Map);
        final medNome = pr['medicamento_nome']?.toString() ?? '';
        final dataHora = pr['data_hora']?.toString() ?? '';

        final existe = await db.query(
          'prescricoes',
          where: 'medicamento_nome = ? AND data_hora = ?',
          whereArgs: [medNome, dataHora],
        );

        if (existe.isEmpty) {
          await db.insert('prescricoes', {
            'atendimento_id': pr['atendimento_id'] ?? 1,
            'medicamento_id': pr['medicamento_id'] ?? 1,
            'medicamento_nome': medNome,
            'quantidade_dispensada': int.tryParse(pr['quantidade_dispensada']?.toString() ?? '') ?? 1,
            'data_hora': dataHora,
            'synced': 1,
          });
        }
      }
    }
  }
}