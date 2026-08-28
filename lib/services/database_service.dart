import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import '../models/pharmacy_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  // Les appels à save() sont souvent déclenchés sans await depuis l'interface.
  // Avec sqflite FFI, deux batchs exécutés en même temps peuvent provoquer une
  // DatabaseException. Cette file garantit une seule écriture à la fois.
  Future<bool> _saveQueue = Future<bool>.value(true);

  // ── Collections en mémoire (même API qu'avant) ──────────────────
  List<Product> products = [];
  List<Lot> lots = [];
  List<StockMovement> stockMovements = [];
  List<Sale> sales = [];
  List<Prescription> prescriptions = [];
  List<Patient> patients = [];
  List<Employee> employees = [];
  List<Supplier> suppliers = [];
  List<UserAccount> users = [];
  List<MedicamentLoan> loans = [];
  List<Expense> expenses = [];
  List<AuditLog> auditLogs = [];

  // Utilisateur connecté
  String currentUsername = 'anonymous';
  String currentUserRole = 'GUEST';

  // Informations pharmacie
  String pharmacyName = '';
  String pharmacyQuartier = '';
  String pharmacyPassword = '';
  String pharmacyPinCode = '';
  String pharmacyLogoBase64 = '';
  String pharmacyContact1 = '';
  String pharmacyContact2 = '';
  bool hasSeenOnboarding = false;
  String firstLaunchDate = '';
  bool isLicensed = false;
  int workingYear = DateTime.now().year;
  String debtReminderDismissedDate = '';

  // ────────────────────────────────────────────────────────────────
  // INITIALISATION
  // ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      // Activer FFI pour Linux / Windows / macOS
      if (!kIsWeb &&
          (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dbDir = await _resolveDatabaseDirectory();
      if (!await dbDir.exists()) await dbDir.create(recursive: true);
      final dbPath = p.join(dbDir.path, 'pharma_guinee.db');

      _db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _onCreate,
      );

      await _ensureCurrentSchema();

      // Migrer l'ancien fichier JSON si présent
      await _migrateFromJson();

      // Charger toutes les données en mémoire
      await _loadAll();

      logAction('INIT', 'Base de données SQLite initialisée : $dbPath');
    } catch (e) {
      debugPrint('Erreur init DB: $e');
      _loadEmptyData();
      logAction('INIT_ERROR', 'Erreur initialisation SQLite: $e');
    }
  }

  Future<Directory> _resolveDatabaseDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        final target = Directory(p.join(appData, 'PharmaGuinee'));
        if (!await target.exists()) await target.create(recursive: true);
        await _migrateLegacyWindowsDatabase(target);
        return target;
      }
    }

    final preferredRoots = <String>[];
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      preferredRoots.add(p.join(home, 'Documents', 'Pharma Guinée'));
    }

    final windowsUserProfile = Platform.environment['USERPROFILE'] ?? '';
    final windowsHomeDrive = Platform.environment['HOMEDRIVE'] ?? '';
    final windowsHomePath = Platform.environment['HOMEPATH'] ?? '';
    if (Platform.isWindows && windowsUserProfile.isNotEmpty) {
      preferredRoots
          .add(p.join(windowsUserProfile, 'Documents', 'Pharma Guinée'));
    } else if (Platform.isWindows &&
        windowsHomeDrive.isNotEmpty &&
        windowsHomePath.isNotEmpty) {
      preferredRoots.add(p.join(
          windowsHomeDrive + windowsHomePath, 'Documents', 'Pharma Guinée'));
    }

    if (Platform.isMacOS && home != null && home.isNotEmpty) {
      preferredRoots.add(p.join(home, 'Documents', 'Pharma Guinée'));
    }

    if (Platform.isLinux && home != null && home.isNotEmpty) {
      preferredRoots.add(p.join(home, 'Documents', 'Pharma Guinée'));
    }

    final appDocsDir = await getApplicationDocumentsDirectory();
    preferredRoots.add(p.join(appDocsDir.path, 'Pharma Guinée'));
    preferredRoots.add(p.join(appDocsDir.path, 'pharmaguinee'));

    for (final root in preferredRoots) {
      final dir = Directory(root);
      if (await dir.exists()) {
        return dir;
      }
    }

    final fallback = Directory(preferredRoots.first);
    if (!await fallback.exists()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  Future<void> _migrateLegacyWindowsDatabase(Directory target) async {
    final targetDatabase = File(p.join(target.path, 'pharma_guinee.db'));
    if (await targetDatabase.exists()) return;

    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile == null || userProfile.isEmpty) return;
    final legacyDirectories = [
      p.join(userProfile, 'Documents', 'Pharma Guinée'),
      p.join(userProfile, 'Documents', 'pharmaguinee'),
    ];
    for (final legacyDirectory in legacyDirectories) {
      final legacyDatabase = File(p.join(legacyDirectory, 'pharma_guinee.db'));
      if (await legacyDatabase.exists()) {
        await legacyDatabase.copy(targetDatabase.path);
        for (final suffix in ['-wal', '-shm']) {
          final sidecar = File('${legacyDatabase.path}$suffix');
          if (await sidecar.exists()) {
            await sidecar.copy('${targetDatabase.path}$suffix');
          }
        }
        return;
      }
    }
  }

  // ────────────────────────────────────────────────────────────────
  // CRÉATION DES TABLES
  // ────────────────────────────────────────────────────────────────
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS pharmacy_settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    for (final table in [
      'products',
      'lots',
      'stock_movements',
      'sales',
      'prescriptions',
      'patients',
      'employees',
      'suppliers',
      'users',
      'loans',
      'expenses',
    ]) {
      batch.execute('''
        CREATE TABLE IF NOT EXISTS $table (
          id   TEXT PRIMARY KEY,
          data TEXT NOT NULL
        )
      ''');
    }

    batch.execute('''
      CREATE TABLE IF NOT EXISTS audit_logs (
        id        TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        data      TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> _ensureCurrentSchema() async {
    if (_db == null) return;
    for (final table in [
      'products',
      'lots',
      'stock_movements',
      'sales',
      'prescriptions',
      'patients',
      'employees',
      'suppliers',
      'users',
      'loans',
      'expenses'
    ]) {
      await _db!.execute(
          'CREATE TABLE IF NOT EXISTS $table (id TEXT PRIMARY KEY, data TEXT NOT NULL)');
    }
    await _db!.execute(
        'CREATE TABLE IF NOT EXISTS audit_logs (id TEXT PRIMARY KEY, timestamp TEXT NOT NULL, data TEXT NOT NULL)');
  }

  // ────────────────────────────────────────────────────────────────
  // CHARGEMENT SQLITE → MÉMOIRE
  // ────────────────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    if (_db == null) return;

    // Paramètres pharmacie
    final rows = await _db!.query('pharmacy_settings');
    final settings = {
      for (var r in rows) r['key'] as String: r['value'] as String
    };
    pharmacyName = settings['pharmacyName'] ?? '';
    pharmacyQuartier = settings['pharmacyQuartier'] ?? '';
    pharmacyPassword = settings['pharmacyPassword'] ?? '';
    pharmacyPinCode = settings['pharmacyPinCode'] ?? '';
    pharmacyLogoBase64 = settings['pharmacyLogoBase64'] ?? '';
    pharmacyContact1 = settings['pharmacyContact1'] ?? '';
    pharmacyContact2 = settings['pharmacyContact2'] ?? '';
    hasSeenOnboarding = settings['hasSeenOnboarding'] == 'true';
    firstLaunchDate = settings['firstLaunchDate'] ?? '';
    isLicensed = settings['isLicensed'] == 'true';
    workingYear =
        int.tryParse(settings['workingYear'] ?? '') ?? DateTime.now().year;
    debtReminderDismissedDate = settings['debtReminderDismissedDate'] ?? '';
    currentUsername = 'anonymous';
    currentUserRole = 'GUEST';

    if (firstLaunchDate.isEmpty) {
      firstLaunchDate = DateTime.now().toIso8601String();
      save();
    }

    // Collections
    products = await _loadTable('products', (m) => Product.fromMap(m));
    lots = await _loadTable('lots', (m) => Lot.fromMap(m));
    stockMovements =
        await _loadTable('stock_movements', (m) => StockMovement.fromMap(m));
    sales = await _loadTable('sales', (m) => Sale.fromMap(m));
    prescriptions =
        await _loadTable('prescriptions', (m) => Prescription.fromMap(m));
    patients = await _loadTable('patients', (m) => Patient.fromMap(m));
    employees = await _loadTable('employees', (m) => Employee.fromMap(m));
    suppliers = await _loadTable('suppliers', (m) => Supplier.fromMap(m));
    users = await _loadTable('users', (m) => UserAccount.fromMap(m));
    loans = await _loadTable('loans', (m) => MedicamentLoan.fromMap(m));
    expenses = await _loadTable('expenses', (m) => Expense.fromMap(m));

    // Logs d'audit (ordre décroissant, limité à 2000)
    final logRows = await _db!.query(
      'audit_logs',
      orderBy: 'timestamp DESC',
      limit: 2000,
    );
    auditLogs = logRows
        .map((r) => AuditLog.fromMap(jsonDecode(r['data'] as String)))
        .toList();
  }

  Future<List<T>> _loadTable<T>(
      String table, T Function(Map<String, dynamic>) fromMap) async {
    final rows = await _db!.query(table);
    return rows.map((r) => fromMap(jsonDecode(r['data'] as String))).toList();
  }

  // ────────────────────────────────────────────────────────────────
  // SAUVEGARDE MÉMOIRE → SQLITE
  // ────────────────────────────────────────────────────────────────
  Future<bool> save() async {
    if (kIsWeb || _db == null) return true;
    _saveQueue = _saveQueue.then(
      (_) => _saveNow(),
      onError: (_) => _saveNow(),
    );
    return _saveQueue;
  }

  Future<bool> _saveNow() async {
    try {
      final batch = _db!.batch();

      // Paramètres
      void upsertSetting(String k, String v) => batch.insert(
            'pharmacy_settings',
            {'key': k, 'value': v},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
      upsertSetting('pharmacyName', pharmacyName);
      upsertSetting('pharmacyQuartier', pharmacyQuartier);
      upsertSetting('pharmacyPassword', pharmacyPassword);
      upsertSetting('pharmacyPinCode', pharmacyPinCode);
      upsertSetting('pharmacyLogoBase64', pharmacyLogoBase64);
      upsertSetting('pharmacyContact1', pharmacyContact1);
      upsertSetting('pharmacyContact2', pharmacyContact2);
      upsertSetting('hasSeenOnboarding', hasSeenOnboarding.toString());
      upsertSetting('firstLaunchDate', firstLaunchDate);
      upsertSetting('isLicensed', isLicensed.toString());
      upsertSetting('workingYear', workingYear.toString());
      upsertSetting('debtReminderDismissedDate', debtReminderDismissedDate);
      upsertSetting('currentUsername', currentUsername);
      upsertSetting('currentUserRole', currentUserRole);

      // Collections
      _upsertAll(batch, 'products', products, (e) => e.id, (e) => e.toMap());
      _upsertAll(batch, 'lots', lots, (e) => e.id, (e) => e.toMap());
      _upsertAll(batch, 'stock_movements', stockMovements, (e) => e.id,
          (e) => e.toMap());
      _upsertAll(batch, 'sales', sales, (e) => e.id, (e) => e.toMap());
      _upsertAll(
          batch, 'prescriptions', prescriptions, (e) => e.id, (e) => e.toMap());
      _upsertAll(batch, 'patients', patients, (e) => e.id, (e) => e.toMap());
      _upsertAll(batch, 'employees', employees, (e) => e.id, (e) => e.toMap());
      _upsertAll(batch, 'suppliers', suppliers, (e) => e.id, (e) => e.toMap());
      _upsertAll(batch, 'users', users, (e) => e.username, (e) => e.toMap());
      _upsertAll(batch, 'loans', loans, (e) => e.id, (e) => e.toMap());
      _upsertAll(batch, 'expenses', expenses, (e) => e.id, (e) => e.toMap());

      // Logs d'audit
      for (final log in auditLogs.take(2000)) {
        batch.insert(
          'audit_logs',
          {
            'id': log.id,
            'timestamp': log.timestamp.toIso8601String(),
            'data': jsonEncode(log.toMap()),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      return true;
    } catch (e) {
      debugPrint('Erreur save DB: $e');
      return false;
    }
  }

  void _upsertAll<T>(
    Batch batch,
    String table,
    List<T> list,
    String Function(T) getId,
    Map<String, dynamic> Function(T) toMap,
  ) {
    for (final item in list) {
      batch.insert(
        table,
        {'id': getId(item), 'data': jsonEncode(toMap(item))},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ────────────────────────────────────────────────────────────────
  // SUPPRESSION D'UN ENREGISTREMENT
  // ────────────────────────────────────────────────────────────────
  Future<void> deleteRecord(String table, String id) async {
    if (_db == null) return;
    await _db!.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // ────────────────────────────────────────────────────────────────
  // MIGRATION JSON → SQLITE
  // ────────────────────────────────────────────────────────────────
  Future<void> _migrateFromJson() async {
    if (kIsWeb) return;
    const jsonFileName = 'pharmaguinee_db.json';
    final jsonFile = File(jsonFileName);
    if (!await jsonFile.exists()) return;

    try {
      // Vérifier si SQLite a déjà des données
      final count = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM pharmacy_settings'),
      );
      if ((count ?? 0) > 0) {
        // Déjà migré, renommer le JSON en .bak
        await jsonFile.rename('$jsonFileName.migrated.bak');
        debugPrint('SQLite déjà peuplé, JSON archivé.');
        return;
      }

      // Lire le JSON
      final content = await jsonFile.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      products = (data['products'] as List? ?? [])
          .map((e) => Product.fromMap(e))
          .toList();
      lots = (data['lots'] as List? ?? []).map((e) => Lot.fromMap(e)).toList();
      stockMovements = (data['stockMovements'] as List? ?? [])
          .map((e) => StockMovement.fromMap(e))
          .toList();
      sales =
          (data['sales'] as List? ?? []).map((e) => Sale.fromMap(e)).toList();
      prescriptions = (data['prescriptions'] as List? ?? [])
          .map((e) => Prescription.fromMap(e))
          .toList();
      patients = (data['patients'] as List? ?? [])
          .map((e) => Patient.fromMap(e))
          .toList();
      employees = (data['employees'] as List? ?? [])
          .map((e) => Employee.fromMap(e))
          .toList();
      suppliers = (data['suppliers'] as List? ?? [])
          .map((e) => Supplier.fromMap(e))
          .toList();
      users = (data['users'] as List? ?? [])
          .map((e) => UserAccount.fromMap(e))
          .toList();
      auditLogs = (data['auditLogs'] as List? ?? [])
          .map((e) => AuditLog.fromMap(e))
          .toList();

      pharmacyName = data['pharmacyName'] ?? '';
      pharmacyQuartier = data['pharmacyQuartier'] ?? '';
      pharmacyPassword = data['pharmacyPassword'] ?? '';
      pharmacyPinCode = data['pharmacyPinCode'] ?? '';
      pharmacyLogoBase64 = data['pharmacyLogoBase64'] ?? '';
      pharmacyContact1 = data['pharmacyContact1'] ?? '';
      pharmacyContact2 = data['pharmacyContact2'] ?? '';
      hasSeenOnboarding = data['hasSeenOnboarding'] ?? false;

      // Persister vers SQLite
      await save();

      // Archiver le fichier JSON
      await jsonFile.rename('$jsonFileName.migrated.bak');
      debugPrint('✅ Migration JSON → SQLite réussie.');
    } catch (e) {
      debugPrint('Erreur migration JSON: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────
  // DONNÉES VIDES (premier lancement)
  // ────────────────────────────────────────────────────────────────
  void _loadEmptyData() {
    products = [];
    lots = [];
    stockMovements = [];
    sales = [];
    prescriptions = [];
    patients = [];
    employees = [];
    suppliers = [];
    users = [];
    loans = [];
    expenses = [];
    auditLogs = [];
    pharmacyName = '';
    pharmacyQuartier = '';
    pharmacyPassword = '';
    pharmacyPinCode = '';
    pharmacyLogoBase64 = '';
    pharmacyContact1 = '';
    pharmacyContact2 = '';
    hasSeenOnboarding = false;
    firstLaunchDate = '';
    isLicensed = false;
    workingYear = DateTime.now().year;
    debtReminderDismissedDate = '';
  }

  // ────────────────────────────────────────────────────────────────
  // JOURNAL D'AUDIT
  // ────────────────────────────────────────────────────────────────
  void logAction(String action, String details) {
    final log = AuditLog(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}-${auditLogs.length + 1}',
      timestamp: DateTime.now(),
      username: currentUsername,
      action: action,
      details: details,
    );
    auditLogs.insert(0, log);

    // Purger les logs > 30 jours
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    auditLogs.removeWhere((l) => l.timestamp.isBefore(thirtyDaysAgo));
    if (auditLogs.length > 2000) auditLogs.removeRange(2000, auditLogs.length);
  }

  // ────────────────────────────────────────────────────────────────
  // EXPORT / IMPORT (BACKUP JSON)
  // ────────────────────────────────────────────────────────────────
  Future<String> exportBackup() async {
    try {
      final data = {
        'products': products.map((e) => e.toMap()).toList(),
        'lots': lots.map((e) => e.toMap()).toList(),
        'stockMovements': stockMovements.map((e) => e.toMap()).toList(),
        'sales': sales.map((e) => e.toMap()).toList(),
        'prescriptions': prescriptions.map((e) => e.toMap()).toList(),
        'patients': patients.map((e) => e.toMap()).toList(),
        'employees': employees.map((e) => e.toMap()).toList(),
        'suppliers': suppliers.map((e) => e.toMap()).toList(),
        'users': users.map((e) => e.toMap()).toList(),
        'loans': loans.map((e) => e.toMap()).toList(),
        'auditLogs': auditLogs.map((e) => e.toMap()).toList(),
        'pharmacyName': pharmacyName,
        'pharmacyQuartier': pharmacyQuartier,
        'pharmacyPassword': pharmacyPassword,
        'pharmacyPinCode': pharmacyPinCode,
        'pharmacyLogoBase64': pharmacyLogoBase64,
        'pharmacyContact1': pharmacyContact1,
        'pharmacyContact2': pharmacyContact2,
        'hasSeenOnboarding': hasSeenOnboarding,
        'firstLaunchDate': firstLaunchDate,
        'isLicensed': isLicensed,
        'workingYear': workingYear,
      };
      logAction('BACKUP', 'Sauvegarde exportée avec succès.');
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      debugPrint('Erreur export: $e');
      return '';
    }
  }

  Future<bool> importBackup(String backupJson) async {
    try {
      final Map<String, dynamic> data = jsonDecode(backupJson);

      // Vider les tables SQLite
      if (_db != null) {
        final batch = _db!.batch();
        for (final t in [
          'products',
          'lots',
          'stock_movements',
          'sales',
          'prescriptions',
          'patients',
          'employees',
          'suppliers',
          'users',
          'loans',
          'audit_logs',
          'pharmacy_settings',
        ]) {
          batch.delete(t);
        }
        await batch.commit(noResult: true);
      }

      // Recharger depuis le JSON
      products = (data['products'] as List? ?? [])
          .map((e) => Product.fromMap(e))
          .toList();
      lots = (data['lots'] as List? ?? []).map((e) => Lot.fromMap(e)).toList();
      stockMovements = (data['stockMovements'] as List? ?? [])
          .map((e) => StockMovement.fromMap(e))
          .toList();
      sales =
          (data['sales'] as List? ?? []).map((e) => Sale.fromMap(e)).toList();
      prescriptions = (data['prescriptions'] as List? ?? [])
          .map((e) => Prescription.fromMap(e))
          .toList();
      patients = (data['patients'] as List? ?? [])
          .map((e) => Patient.fromMap(e))
          .toList();
      employees = (data['employees'] as List? ?? [])
          .map((e) => Employee.fromMap(e))
          .toList();
      suppliers = (data['suppliers'] as List? ?? [])
          .map((e) => Supplier.fromMap(e))
          .toList();
      users = (data['users'] as List? ?? [])
          .map((e) => UserAccount.fromMap(e))
          .toList();
      loans = (data['loans'] as List? ?? [])
          .map((e) => MedicamentLoan.fromMap(e))
          .toList();
      auditLogs = (data['auditLogs'] as List? ?? [])
          .map((e) => AuditLog.fromMap(e))
          .toList();
      pharmacyName = data['pharmacyName'] ?? '';
      pharmacyQuartier = data['pharmacyQuartier'] ?? '';
      pharmacyPassword = data['pharmacyPassword'] ?? '';
      pharmacyPinCode = data['pharmacyPinCode'] ?? '';
      pharmacyLogoBase64 = data['pharmacyLogoBase64'] ?? '';
      pharmacyContact1 = data['pharmacyContact1'] ?? '';
      pharmacyContact2 = data['pharmacyContact2'] ?? '';
      hasSeenOnboarding = data['hasSeenOnboarding'] ?? false;
      firstLaunchDate = data['firstLaunchDate'] ?? '';
      isLicensed = data['isLicensed'] ?? false;
      workingYear = data['workingYear'] ?? DateTime.now().year;

      // Persister vers SQLite
      await save();
      logAction('RESTORE', 'Base de données restaurée depuis une sauvegarde.');
      return true;
    } catch (e) {
      debugPrint('Erreur import: $e');
      logAction('RESTORE_FAILED', 'Échec de la restauration: $e');
      return false;
    }
  }
}
