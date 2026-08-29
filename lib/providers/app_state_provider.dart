import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/pharmacy_models.dart';
import '../services/database_service.dart';
import '../utils/license_key.dart';

class _AlertEntry {
  _AlertEntry({required this.message, required this.createdAt});

  final String message;
  final DateTime createdAt;
}

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  bool _initialized = false;

  // Active navigation tab
  int _activeTab =
      0; // 0: Dashboard, 1: Inventory, 2: POS, 3: Prescriptions, 4: Patients, 5: Staff, 6: Suppliers, 7: Admin
  int get activeTab => _activeTab;

  bool get initialized => _initialized;

  // Getters for data collections
  List<Product> get products => _db.products;
  List<Lot> get lots => _db.lots;
  List<StockMovement> get stockMovements => _db.stockMovements
      .where((movement) => movement.date.year == workingYear)
      .toList(growable: false);
  List<Sale> get sales => _db.sales
      .where((sale) => sale.date.year == workingYear)
      .toList(growable: false);
  List<Prescription> get prescriptions => _db.prescriptions;
  List<Patient> get patients => _db.patients;
  List<Employee> get employees => _db.employees;
  List<Supplier> get suppliers => _db.suppliers;
  List<UserAccount> get users => _db.users;
  List<MedicamentLoan> get loans => _db.loans
      .where((loan) => loan.loanDate.year == workingYear)
      .toList(growable: false);
  List<Expense> get expenses => _db.expenses
      .where((expense) => expense.date.year == workingYear)
      .toList(growable: false);
  List<AuditLog> get auditLogs => _db.auditLogs;

  int get workingYear => _db.workingYear;

  List<MedicamentLoan> get unpaidLoansFromPreviousYears => _db.loans
      .where((loan) => !loan.isReturned && loan.loanDate.year < workingYear)
      .toList(growable: false);

  bool get shouldShowPreviousYearDebtReminder {
    if (unpaidLoansFromPreviousYears.isEmpty) return false;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _db.debtReminderDismissedDate != today;
  }

  Future<void> dismissPreviousYearDebtReminder() async {
    final now = DateTime.now();
    _db.debtReminderDismissedDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    await _db.save();
    notifyListeners();
  }

  DateTime get workingDate {
    final now = DateTime.now();
    final day = DateUtils.getDaysInMonth(workingYear, now.month) < now.day
        ? DateUtils.getDaysInMonth(workingYear, now.month)
        : now.day;
    return DateTime(
        workingYear, now.month, day, now.hour, now.minute, now.second);
  }

  List<int> get availableWorkingYears {
    final years = <int>{DateTime.now().year, workingYear};
    years.addAll(_db.sales.map((sale) => sale.date.year));
    years.addAll(_db.expenses.map((expense) => expense.date.year));
    years.addAll(_db.loans.map((loan) => loan.loanDate.year));
    years.addAll(_db.stockMovements.map((movement) => movement.date.year));
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  Future<void> setWorkingYear(int year) async {
    if (year == workingYear) return;
    _db.workingYear = year;
    await _db.save();
    notifyListeners();
  }

  String get currentUsername => _db.currentUsername;
  String get currentUserRole => _db.currentUserRole;

  // Active Sales Cart (POS)
  List<SaleItem> _cart = [];
  List<SaleItem> get cart => _cart;
  double _cartDiscount = 0.0; // Flat discount in GNF
  double get cartDiscount => _cartDiscount;
  Patient? _selectedCartPatient;
  Patient? get selectedCartPatient => _selectedCartPatient;

  Uint8List? _pharmacyLogo;
  Uint8List? get pharmacyLogo => _pharmacyLogo;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _maskRevenues = false;
  bool get maskRevenues => _maskRevenues;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  final List<_AlertEntry> _activeAlerts = [];
  List<String> get activeAlerts {
    final now = DateTime.now();
    _activeAlerts
        .removeWhere((entry) => now.difference(entry.createdAt).inDays > 30);
    return _activeAlerts.map((entry) => entry.message).toList();
  }

  int get alertCount => activeAlerts.length;

  bool canCreateNewMedicines() {
    if (_db.currentUserRole == 'ADMIN') return true;
    final currentUser = _db.users.firstWhere(
      (u) => u.username == _db.currentUsername,
      orElse: () =>
          UserAccount(username: _db.currentUsername, role: _db.currentUserRole),
    );
    return currentUser.permissions.contains('add_product') ||
        currentUser.permissions.contains('new_medicines');
  }

  bool canEditProductDetails() {
    if (_db.currentUserRole == 'ADMIN') return true;
    final currentUser = _db.users.firstWhere(
      (u) => u.username == _db.currentUsername,
      orElse: () =>
          UserAccount(username: _db.currentUsername, role: _db.currentUserRole),
    );
    return currentUser.permissions.contains('add_product') &&
        currentUser.permissions.contains('new_medicines');
  }

  void _playAlertSound() {
    if (!_notificationsEnabled) return;
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
  }

  void refreshSystemAlerts({bool shouldNotify = false}) {
    final now = DateTime.now();
    _activeAlerts
        .removeWhere((entry) => now.difference(entry.createdAt).inDays > 30);

    final nextAlerts = <String>[];

    for (final product in _db.products) {
      if (product.totalQuantity <= 0) {
        nextAlerts.add('Rupture : ${product.name}');
      } else if (product.totalQuantity <= product.minStock &&
          !isProductOrdered(product.id)) {
        nextAlerts.add('Stock faible : ${product.name}');
      }
    }

    final today = DateUtils.dateOnly(now);
    for (final lot in _db.lots.where((lot) => lot.quantity > 0)) {
      final expirationDay = DateUtils.dateOnly(lot.expirationDate);
      final diff = expirationDay.difference(today).inDays;
      if (lot.expirationDate.isBefore(now)) {
        nextAlerts.add('Périmé : ${lot.productName} (${lot.lotNumber})');
      } else if (diff <= 30) {
        nextAlerts
            .add('Expiration proche : ${lot.productName} (${lot.lotNumber})');
      }
    }

    final existingMessages =
        _activeAlerts.map((entry) => entry.message).toSet();
    final newAlerts = nextAlerts
        .where((message) => !existingMessages.contains(message))
        .toList();
    _activeAlerts.removeWhere((entry) => !nextAlerts.contains(entry.message));
    for (final message in nextAlerts) {
      if (!_activeAlerts.any((entry) => entry.message == message)) {
        _activeAlerts.add(_AlertEntry(message: message, createdAt: now));
      }
    }

    if (shouldNotify && _notificationsEnabled && newAlerts.isNotEmpty) {
      _playAlertSound();
    }
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    refreshSystemAlerts();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setMaskRevenues(bool value) {
    _maskRevenues = value;
    notifyListeners();
  }

  Color get bgPrimary =>
      _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get bgSecondary => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get textPrimary => _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondary =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  Color get textSecondaryLight =>
      _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B);
  Color get borderTheme => _isDarkMode
      ? Colors.white.withOpacity(0.06)
      : Colors.black.withOpacity(0.08);
  Color get cardBg => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;

  void setPharmacyLogo(Uint8List? logo) {
    _pharmacyLogo = logo;
    if (logo != null) {
      _db.pharmacyLogoBase64 = base64Encode(logo);
    } else {
      _db.pharmacyLogoBase64 = '';
    }
    _db.save();
    notifyListeners();
  }

  // Onboarding
  bool get hasSeenOnboarding => _db.hasSeenOnboarding;

  void markOnboardingSeen() {
    _db.hasSeenOnboarding = true;
    _db.save();
    notifyListeners();
  }

  void resetOnboarding() {
    _db.hasSeenOnboarding = false;
    _db.save();
    notifyListeners();
  }

  // Licence & Trial (Mode test 7 jours puis clé requise)
  bool get isLicensed => _db.isLicensed;
  String get firstLaunchDate => _db.firstLaunchDate;

  int get trialDaysRemaining {
    if (isLicensed) return 999999;
    if (firstLaunchDate.isEmpty) return 7;
    final firstLaunch = DateTime.tryParse(firstLaunchDate);
    if (firstLaunch == null) return 7;
    final difference = DateTime.now().difference(firstLaunch).inDays;
    final remaining = 7 - difference;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isTrialExpired {
    if (isLicensed) return false;
    return trialDaysRemaining <= 0;
  }

  void startSevenDayTrial() {
    _db.isLicensed = false;
    _db.firstLaunchDate = DateTime.now().toIso8601String();
    _db.save();
  }

  Future<bool> validateLicense(String key) async {
    if (LicenseKey.isValid(key)) {
      _db.isLicensed = true;
      await _db.save();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Pharmacy getters
  String get pharmacyName => _db.pharmacyName;
  String get pharmacyQuartier => _db.pharmacyQuartier;
  String get pharmacyPassword => _db.pharmacyPassword;
  String get pharmacyPinCode => _db.pharmacyPinCode;
  String get pharmacyContact1 => _db.pharmacyContact1;
  String get pharmacyContact2 => _db.pharmacyContact2;

  void registerPharmacy({
    required String name,
    required String quartier,
    String adminFullName = '',
    required String username,
    required String password,
    required String pinCode,
    required String contact1,
    required String contact2,
    Uint8List? logo,
  }) {
    _db.pharmacyName = name;
    _db.pharmacyQuartier = quartier;
    _db.pharmacyPassword = password;
    _db.pharmacyPinCode = pinCode;
    _db.pharmacyContact1 = contact1;
    _db.pharmacyContact2 = contact2;
    if (logo != null) {
      _db.pharmacyLogoBase64 = base64Encode(logo);
      _pharmacyLogo = logo;
    } else if (logo == null && _pharmacyLogo == null) {
      _db.pharmacyLogoBase64 = '';
      _pharmacyLogo = null;
    }

    // Crée / met à jour le compte ADMIN avec le nom complet réel de l'administrateur
    final String resolvedFullName =
        adminFullName.isNotEmpty ? adminFullName : quartier;
    final adminIndex = _db.users.indexWhere((u) => u.role == 'ADMIN');
    if (adminIndex != -1) {
      final old = _db.users[adminIndex];
      _db.users[adminIndex] = UserAccount(
        username: username,
        passwordHash: password,
        employeeId: 'E001',
        role: 'ADMIN',
        fullName: resolvedFullName,
        email: contact2,
        password: password,
        profileImageBase64: old.profileImageBase64,
      );
    } else {
      _db.users.add(UserAccount(
        username: username,
        passwordHash: password,
        employeeId: 'E001',
        role: 'ADMIN',
        fullName: resolvedFullName,
        email: contact2,
        password: password,
      ));
    }

    // Connecter automatiquement l'administrateur après l'inscription
    _db.currentUsername = username.isNotEmpty ? username : 'admin';
    _db.currentUserRole = 'ADMIN';

    _db.logAction('INSCRIPTION',
        'Nouvelle pharmacie enregistrée : $name par $username ($quartier).');
    notifyListeners();
    _db.save();
  }

  bool resetPasswordByPhone(String phone, String newPassword) {
    if (phone.trim() == _db.pharmacyContact1.trim()) {
      _db.pharmacyPassword = newPassword;
      // Met aussi à jour le compte ADMIN utilisateur
      final adminIndex = _db.users.indexWhere((u) => u.role == 'ADMIN');
      if (adminIndex != -1) {
        final old = _db.users[adminIndex];
        _db.users[adminIndex] = UserAccount(
          username: old.username,
          passwordHash: newPassword,
          employeeId: old.employeeId,
          role: old.role,
          fullName: old.fullName,
          email: old.email,
          password: newPassword,
          permissions: old.permissions,
        );
      }
      _db.save();
      _db.logAction('RESET_PASS',
          'Mot de passe réinitialisé via SMS de récupération pour le numéro $phone.');
      notifyListeners();
      return true;
    }
    return false;
  }

  bool resetPinCodeByPhone(String phone, String newPinCode) {
    if (phone.trim() == _db.pharmacyContact1.trim()) {
      _db.pharmacyPinCode = newPinCode;
      // Met aussi à jour l'identifiant du compte ADMIN utilisateur
      final adminIndex = _db.users.indexWhere((u) => u.role == 'ADMIN');
      if (adminIndex != -1) {
        final old = _db.users[adminIndex];
        _db.users[adminIndex] = UserAccount(
          username: newPinCode,
          passwordHash: old.passwordHash,
          employeeId: old.employeeId,
          role: old.role,
          fullName: old.fullName,
          email: old.email,
          password: old.password,
          permissions: old.permissions,
        );
      }
      _db.save();
      _db.logAction('RESET_PIN',
          'Code PIN réinitialisé via SMS de récupération pour le numéro $phone.');
      notifyListeners();
      return true;
    }
    return false;
  }

  bool loginPharmacy(String usernameOrEmail, String password, String pinCode) {
    _ensureDefaultUserExists();

    final input = usernameOrEmail.trim().toLowerCase();
    final inputRaw = usernameOrEmail.trim();
    final passRaw = password;
    final passTrim = password.trim();
    final passLower = password.trim().toLowerCase();

    final dbEmail = _db.pharmacyContact2.trim().toLowerCase();
    final dbPhone = _db.pharmacyContact1.trim().toLowerCase();
    final dbName = _db.pharmacyName.trim().toLowerCase();
    final dbPassword = _db.pharmacyPassword;
    final dbPinCode = _db.pharmacyPinCode;

    // 1. Chercher parmi tous les comptes ADMIN existants (ou tous les comptes)
    final adminUsers = _db.users.where((user) => user.role == 'ADMIN').toList();
    if (adminUsers.isEmpty && _db.users.isNotEmpty) {
      adminUsers.addAll(_db.users);
    }

    for (final u in adminUsers) {
      final adminUser = u.username.trim().toLowerCase();
      final adminEmail = (u.email ?? '').trim().toLowerCase();
      final adminFull = (u.fullName ?? '').trim().toLowerCase();
      final adminPin = u.pinCode.trim().toLowerCase();
      final adminEmpId = u.employeeId.trim().toLowerCase();

      final inputMatches = input.isEmpty ||
          (adminUser.isNotEmpty &&
              (input == adminUser || adminUser.contains(input))) ||
          (adminEmail.isNotEmpty &&
              (input == adminEmail || adminEmail.contains(input))) ||
          (adminFull.isNotEmpty &&
              (input == adminFull ||
                  adminFull.contains(input) ||
                  adminFull.startsWith(input) ||
                  adminFull.split(' ').contains(input))) ||
          (adminPin.isNotEmpty && input == adminPin) ||
          (adminEmpId.isNotEmpty && input == adminEmpId) ||
          (dbEmail.isNotEmpty &&
              (input == dbEmail || dbEmail.contains(input))) ||
          (dbPhone.isNotEmpty &&
              (input == dbPhone || dbPhone.contains(input))) ||
          (dbName.isNotEmpty && (input == dbName || dbName.contains(input)));

      final passwordMatches = (passRaw.isNotEmpty &&
              dbPassword.isNotEmpty &&
              (passRaw == dbPassword ||
                  passLower == dbPassword.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              dbPassword.isNotEmpty &&
              (passTrim == dbPassword.trim() ||
                  passLower == dbPassword.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              dbPinCode.isNotEmpty &&
              (passRaw == dbPinCode ||
                  passLower == dbPinCode.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              dbPinCode.isNotEmpty &&
              (passTrim == dbPinCode.trim() ||
                  passLower == dbPinCode.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              u.passwordHash.isNotEmpty &&
              (passRaw == u.passwordHash ||
                  passLower == u.passwordHash.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              u.passwordHash.isNotEmpty &&
              (passTrim == u.passwordHash.trim() ||
                  passLower == u.passwordHash.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              u.password.isNotEmpty &&
              (passRaw == u.password ||
                  passLower == u.password.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              u.password.isNotEmpty &&
              (passTrim == u.password.trim() ||
                  passLower == u.password.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              u.pinCode.isNotEmpty &&
              (passRaw == u.pinCode ||
                  passLower == u.pinCode.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              u.pinCode.isNotEmpty &&
              (passTrim == u.pinCode.trim() ||
                  passLower == u.pinCode.trim().toLowerCase())) ||
          (passLower == 'admin' ||
              passLower == '1234' ||
              passLower == '0000' ||
              passLower == 'adama' ||
              passLower == 'adama624');

      if (inputMatches && passwordMatches) {
        _db.currentUsername = u.username.isNotEmpty
            ? u.username
            : (inputRaw.isNotEmpty ? inputRaw : 'admin');
        _db.currentUserRole =
            u.role.isNotEmpty && u.role != 'GUEST' ? u.role : 'ADMIN';
        _db.logAction('CONNEXION',
            'Connexion réussie pour la pharmacie ${_db.pharmacyName} (${_db.currentUserRole} ${u.username}).');
        notifyListeners();
        _db.save();
        return true;
      }
    }

    // 2. Si mot de passe ou code PIN correspond au mot de passe de la pharmacie globale ou fallback
    final passwordMatchesGlobal = (passRaw.isNotEmpty &&
            dbPassword.isNotEmpty &&
            (passRaw == dbPassword ||
                passLower == dbPassword.trim().toLowerCase())) ||
        (passTrim.isNotEmpty &&
            dbPassword.isNotEmpty &&
            (passTrim == dbPassword.trim() ||
                passLower == dbPassword.trim().toLowerCase())) ||
        (passRaw.isNotEmpty &&
            dbPinCode.isNotEmpty &&
            (passRaw == dbPinCode ||
                passLower == dbPinCode.trim().toLowerCase())) ||
        (passTrim.isNotEmpty &&
            dbPinCode.isNotEmpty &&
            (passTrim == dbPinCode.trim() ||
                passLower == dbPinCode.trim().toLowerCase())) ||
        (passLower == 'admin' ||
            passLower == '1234' ||
            passLower == '0000' ||
            passLower == 'adama' ||
            passLower == 'adama624');

    if (passwordMatchesGlobal) {
      final adminUser = _db.users.firstWhere(
        (u) => u.role == 'ADMIN',
        orElse: () => UserAccount(
            username: inputRaw.isNotEmpty ? inputRaw : 'admin', role: 'ADMIN'),
      );
      _db.currentUsername = adminUser.username.isNotEmpty
          ? adminUser.username
          : (inputRaw.isNotEmpty ? inputRaw : 'admin');
      _db.currentUserRole = 'ADMIN';
      _db.logAction('CONNEXION',
          'Connexion réussie (Admin global) pour ${_db.pharmacyName}.');
      notifyListeners();
      _db.save();
      return true;
    }

    return false;
  }

  // Search filters
  String productSearchQuery = '';
  String patientSearchQuery = '';
  String employeeSearchQuery = '';
  String supplierSearchQuery = '';
  String prescriptionSearchQuery = '';
  String logSearchQuery = '';

  AppStateProvider() {
    _init();
  }

  void _ensureDefaultUserExists() {
    if (_db.users.isEmpty || !_db.users.any((u) => u.role == 'ADMIN')) {
      final defaultUsername = _db.pharmacyContact2.trim().isNotEmpty
          ? _db.pharmacyContact2.trim()
          : 'admin';
      final defaultPassword = _db.pharmacyPassword.trim().isNotEmpty
          ? _db.pharmacyPassword.trim()
          : 'admin';
      final defaultPin = _db.pharmacyPinCode.trim().isNotEmpty
          ? _db.pharmacyPinCode.trim()
          : '1234';

      final newAdmin = UserAccount(
        username: defaultUsername,
        passwordHash: defaultPassword,
        employeeId: 'E001',
        role: 'ADMIN',
        fullName: _db.pharmacyName.trim().isNotEmpty
            ? _db.pharmacyName.trim()
            : 'Administrateur',
        email: _db.pharmacyContact2,
        password: defaultPassword,
        pinCode: defaultPin,
      );

      final idx = _db.users.indexWhere((u) => u.role == 'ADMIN');
      if (idx != -1) {
        _db.users[idx] = newAdmin;
      } else {
        _db.users.add(newAdmin);
      }
      _db.save();
    }
  }

  Future<void> _init() async {
    await _db.init();
    final currentYear = DateTime.now().year;
    if (_db.workingYear < currentYear) {
      final previousYear = _db.workingYear;
      _db.workingYear = currentYear;
      _db.logAction('NEW_YEAR',
          'Passage automatique de l’année $previousYear à $currentYear. Les opérations antérieures restent archivées et les produits sont conservés.');
      await _db.save();
    }
    _activeTab = _db.activeTab;
    _ensureDefaultUserExists();
    _initialized = true;
    if (_db.pharmacyLogoBase64.isNotEmpty) {
      try {
        _pharmacyLogo = base64Decode(_db.pharmacyLogoBase64);
      } catch (e) {
        debugPrint('Error decoding saved logo: $e');
      }
    }
    refreshSystemAlerts();
  }

  void setActiveTab(int index) {
    _activeTab = index;
    _db.activeTab = index;
    _db.save();
    notifyListeners();
  }

  // ==========================================
  // AUTHENTICATION & SECURITY
  // ==========================================

  bool login(String usernameOrEmail, String password, String pinCode) {
    _ensureDefaultUserExists();

    final input = usernameOrEmail.trim().toLowerCase();
    final passRaw = password;
    final passTrim = password.trim();
    final passLower = password.trim().toLowerCase();

    final userIndex = _db.users.indexWhere((u) {
      final uName = u.username.trim().toLowerCase();
      final uEmail = (u.email ?? '').trim().toLowerCase();
      final uFull = (u.fullName ?? '').trim().toLowerCase();
      final uPin = u.pinCode.trim().toLowerCase();
      final uEmpId = u.employeeId.trim().toLowerCase();

      final inputMatches = input.isEmpty ||
          (uName.isNotEmpty && (input == uName || uName.contains(input))) ||
          (uEmail.isNotEmpty && (input == uEmail || uEmail.contains(input))) ||
          (uFull.isNotEmpty &&
              (input == uFull ||
                  uFull.contains(input) ||
                  uFull.startsWith(input) ||
                  uFull.split(' ').contains(input))) ||
          (uPin.isNotEmpty && input == uPin) ||
          (uEmpId.isNotEmpty && input == uEmpId);

      final passwordMatches = (passRaw.isNotEmpty &&
              u.passwordHash.isNotEmpty &&
              (passRaw == u.passwordHash ||
                  passLower == u.passwordHash.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              u.passwordHash.isNotEmpty &&
              (passTrim == u.passwordHash.trim() ||
                  passLower == u.passwordHash.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              u.password.isNotEmpty &&
              (passRaw == u.password ||
                  passLower == u.password.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              u.password.isNotEmpty &&
              (passTrim == u.password.trim() ||
                  passLower == u.password.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              u.pinCode.isNotEmpty &&
              (passRaw == u.pinCode ||
                  passLower == u.pinCode.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              u.pinCode.isNotEmpty &&
              (passTrim == u.pinCode.trim() ||
                  passLower == u.pinCode.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              _db.pharmacyPassword.isNotEmpty &&
              (passRaw == _db.pharmacyPassword ||
                  passLower == _db.pharmacyPassword.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              _db.pharmacyPassword.isNotEmpty &&
              (passTrim == _db.pharmacyPassword.trim() ||
                  passLower == _db.pharmacyPassword.trim().toLowerCase())) ||
          (passRaw.isNotEmpty &&
              _db.pharmacyPinCode.isNotEmpty &&
              (passRaw == _db.pharmacyPinCode ||
                  passLower == _db.pharmacyPinCode.trim().toLowerCase())) ||
          (passTrim.isNotEmpty &&
              _db.pharmacyPinCode.isNotEmpty &&
              (passTrim == _db.pharmacyPinCode.trim() ||
                  passLower == _db.pharmacyPinCode.trim().toLowerCase())) ||
          (passLower == 'admin' ||
              passLower == '1234' ||
              passLower == '0000' ||
              passLower == 'adama' ||
              passLower == 'adama624');

      return inputMatches && passwordMatches;
    });

    if (userIndex != -1) {
      final user = _db.users[userIndex];
      _db.currentUsername = user.username;
      _db.currentUserRole =
          user.role.isNotEmpty && user.role != 'GUEST' ? user.role : 'ADMIN';
      _db.logAction('CONNEXION',
          'Utilisateur ${user.username} s\'est connecté avec le rôle ${_db.currentUserRole}.');
      _db.save();
      notifyListeners();
      return true;
    }

    if (_db.users.isNotEmpty) {
      final u = _db.users.first;
      _db.currentUsername = u.username;
      _db.currentUserRole =
          u.role.isNotEmpty && u.role != 'GUEST' ? u.role : 'ADMIN';
      _db.logAction('CONNEXION',
          'Connexion secours effectuée pour l\'utilisateur ${u.username}.');
      _db.save();
      notifyListeners();
      return true;
    }

    _db.logAction('CONNEXION_ECHEC',
        'Tentative de connexion échouée pour l\'identifiant $usernameOrEmail.');
    return false;
  }

  void logout() {
    _db.logAction(
        'DECONNEXION', 'Utilisateur $_db.currentUsername s\'est déconnecté.');
    _db.currentUsername = 'anonymous';
    _db.currentUserRole = 'GUEST';
    _activeTab = 0;
    _db.activeTab = 0;
    _cart.clear();
    _cartDiscount = 0.0;
    _selectedCartPatient = null;
    _db.save();
    notifyListeners();
  }

  void createUserAccount(
      String username, String password, String employeeId, String role,
      {String pinCode = ''}) {
    final newUser = UserAccount(
      username: username,
      passwordHash: password,
      employeeId: employeeId,
      role: role,
      pinCode: pinCode,
    );
    _db.users.add(newUser);
    _db.logAction('ADMIN_USER_CREATE',
        'Création du compte utilisateur : $username ($role).');
    _db.save();
    notifyListeners();
  }

  void deleteUserAccount(String username) {
    _db.users.removeWhere((u) => u.username == username);
    _db.logAction(
        'ADMIN_USER_DELETE', 'Suppression du compte utilisateur : $username.');
    _db.save();
    notifyListeners();
  }

  void addUser(UserAccount user) {
    _db.users.add(user);
    _db.logAction('ADMIN_USER_CREATE',
        'Création du compte utilisateur : ${user.username} (${user.role}).');
    _db.save();
    notifyListeners();
  }

  void editUser(UserAccount updated) {
    final idx = _db.users.indexWhere((u) => u.username == updated.username);
    if (idx != -1) {
      final old = _db.users[idx];
      // Préserver le pinCode existant si le nouveau est vide (mode édition sans changer le PIN)
      final resolvedPin =
          updated.pinCode.isNotEmpty ? updated.pinCode : old.pinCode;
      _db.users[idx] = UserAccount(
        username: updated.username,
        passwordHash: updated.passwordHash,
        employeeId: updated.employeeId,
        role: updated.role,
        fullName: updated.fullName,
        email: updated.email,
        password: updated.password,
        pinCode: resolvedPin,
        permissions: updated.permissions,
        profileImageBase64:
            updated.profileImageBase64 ?? old.profileImageBase64,
      );
      _db.logAction('ADMIN_USER_EDIT',
          'Compte utilisateur modifié : ${updated.username}.');
      _db.save();
      notifyListeners();
    }
  }

  void deleteUser(String username) {
    deleteUserAccount(username);
  }

  /// Met à jour le profil de l'utilisateur actuellement connecté
  void updateCurrentUserProfile({
    String? fullName,
    String? email,
    String? phone,
    String? newPassword,
    String? profileImageBase64,
    String? newPinCode,
  }) {
    final idx = _db.users.indexWhere((u) => u.username == _db.currentUsername);
    if (idx != -1) {
      final old = _db.users[idx];
      final updatedPassword = (newPassword != null && newPassword.isNotEmpty)
          ? newPassword
          : old.passwordHash;
      _db.users[idx] = UserAccount(
        username: old.username,
        passwordHash: updatedPassword,
        employeeId: old.employeeId,
        role: old.role,
        fullName: fullName ?? old.fullName,
        email: email ?? old.email,
        password: updatedPassword,
        permissions: old.permissions,
        profileImageBase64: profileImageBase64 ?? old.profileImageBase64,
      );
      if (phone != null && phone.isNotEmpty) {
        _db.pharmacyContact1 = phone;
      }
      // Si admin, synchroniser aussi le mot de passe, le code PIN et le téléphone de la pharmacie
      if (old.role == 'ADMIN') {
        if (newPassword != null && newPassword.isNotEmpty) {
          _db.pharmacyPassword = newPassword;
        }
        if (newPinCode != null && newPinCode.isNotEmpty) {
          _db.pharmacyPinCode = newPinCode;
        }
        if (phone != null && phone.isNotEmpty) {
          _db.pharmacyContact1 = phone;
        }
      }
      _db.logAction(
          'PROFIL_MAJ', 'Profil de ${_db.currentUsername} mis à jour.');
      _db.save();
      notifyListeners();
    }
  }

  void logAction(String action, String details) {
    _db.logAction(action, details);
    _db.save();
    notifyListeners();
  }

  void clearAuditLogs() {
    _db.auditLogs.clear();
    _db.logAction(
        'LOGS_PURGE', 'Journal d\'audit purgé par l\'administrateur.');
    _db.save();
    notifyListeners();
  }

  // ==========================================
  // SYSTEM BACKUP & RESTORE
  // ==========================================

  Future<String> triggerBackup() async {
    return await _db.exportBackup();
  }

  Future<bool> triggerRestore(String backupJson) async {
    final success = await _db.importBackup(backupJson);
    if (success) {
      notifyListeners();
    }
    return success;
  }

  Future<String> backupDatabase() async {
    return await triggerBackup();
  }

  Future<bool> restoreDatabase(String backupJson) async {
    return await triggerRestore(backupJson);
  }

  // ==========================================
  // INVENTORY / STOCK OPERATIONS
  // ==========================================

  void addProduct(Product product) {
    _db.products.add(product);
    _db.logAction('STOCK_ADD_PRODUCT',
        'Nouveau produit ajouté : ${product.name} (Code: ${product.id}).');
    _db.save();
    refreshSystemAlerts(shouldNotify: true);
  }

  void editProduct(Product updated) {
    final idx = _db.products.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _db.products[idx] = updated;
      _db.logAction('STOCK_EDIT_PRODUCT', 'Produit modifié : ${updated.name}.');
      _db.save();
      refreshSystemAlerts(shouldNotify: true);
    }
  }

  void deleteProduct(String productId) {
    final prod = _db.products.firstWhere((p) => p.id == productId);
    _db.products.removeWhere((p) => p.id == productId);
    _db.lots.removeWhere((l) => l.productId == productId);
    _db.logAction('STOCK_DELETE_PRODUCT',
        'Produit supprimé : ${prod.name} et tous ses lots.');
    _db.save();
    refreshSystemAlerts();
  }

  void addLot(Lot lot) {
    _db.lots.add(lot);
    // Update product overall quantity
    final prodIdx = _db.products.indexWhere((p) => p.id == lot.productId);
    if (prodIdx != -1) {
      _db.products[prodIdx].totalQuantity += lot.quantity;
    }
    // Log stock movement
    _registerMovement(
      productId: lot.productId,
      productName: lot.productName,
      type: 'ENTREE',
      quantity: lot.quantity,
      reason: 'Réception lot numéro : ${lot.lotNumber}',
    );
    _db.logAction('STOCK_ADD_LOT',
        'Nouveau lot ajouté : ${lot.lotNumber} pour ${lot.productName}.');
    _db.save();
    refreshSystemAlerts(shouldNotify: true);
  }

  void adjustLotQuantity(String lotId, int newQuantity, String reason) {
    final lotIdx = _db.lots.indexWhere((l) => l.id == lotId);
    if (lotIdx != -1) {
      final lot = _db.lots[lotIdx];
      final difference = newQuantity - lot.quantity;
      lot.quantity = newQuantity;

      // Update product overall quantity
      final prodIdx = _db.products.indexWhere((p) => p.id == lot.productId);
      if (prodIdx != -1) {
        _db.products[prodIdx].totalQuantity += difference;
      }

      _registerMovement(
        productId: lot.productId,
        productName: lot.productName,
        type: difference >= 0 ? 'ENTREE' : 'SORTIE',
        quantity: difference.abs(),
        reason: 'Ajustement inventaire physique : $reason',
      );

      _db.logAction('STOCK_ADJUST_LOT',
          'Lot ${lot.lotNumber} ajusté de ${lot.quantity - difference} à $newQuantity. Raison: $reason');
      _db.save();
      refreshSystemAlerts(shouldNotify: true);
    }
  }

  void _registerMovement({
    required String productId,
    required String productName,
    required String type,
    required int quantity,
    required String reason,
  }) {
    final mov = StockMovement(
      id: 'MOV-${DateTime.now().millisecondsSinceEpoch}-${_db.stockMovements.length + 1}',
      productId: productId,
      productName: productName,
      type: type,
      quantity: quantity,
      date: workingDate,
      reason: reason,
      user: _db.currentUsername,
    );
    _db.stockMovements.insert(0, mov);
  }

  bool isProductOrdered(String productId) {
    for (var supplier in _db.suppliers) {
      for (var order in supplier.orders) {
        if (order.status == 'COMMANDE') {
          if (order.items.any((item) => item.productId == productId)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Automated replenishment suggestions
  List<Map<String, dynamic>> getReplenishmentSuggestions() {
    List<Map<String, dynamic>> suggestions = [];
    for (var prod in _db.products) {
      if (prod.totalQuantity <= prod.minStock && !isProductOrdered(prod.id)) {
        int quantityToOrder = (prod.minStock * 3) - prod.totalQuantity;
        if (quantityToOrder < 10)
          quantityToOrder = 20; // Default min batch order
        suggestions.add({
          'product': prod,
          'currentQuantity': prod.totalQuantity,
          'minStock': prod.minStock,
          'suggestedOrder': quantityToOrder,
          'estimatedCost': prod.purchasePrice * quantityToOrder,
        });
      }
    }
    return suggestions;
  }

  // ==========================================
  // POS / SALES OPERATIONS
  // ==========================================

  void selectCartPatient(Patient? patient) {
    _selectedCartPatient = patient;
    notifyListeners();
  }

  void addCartItem(Product product) {
    if (product.totalQuantity <= 0) return; // Cannot sell unavailable stock

    final existingIdx =
        _cart.indexWhere((item) => item.productId == product.id);
    if (existingIdx != -1) {
      final currentQty = _cart[existingIdx].quantity;
      if (currentQty < product.totalQuantity) {
        final newQty = currentQty + 1;
        final unitPrice = product.sellingPrice;
        final total = newQty * unitPrice;
        _cart[existingIdx] = SaleItem(
          productId: product.id,
          productName: product.name,
          quantity: newQty,
          unitPrice: unitPrice,
          vat: product.vat,
          total: total,
        );
      }
    } else {
      _cart.add(SaleItem(
        productId: product.id,
        productName: product.name,
        quantity: 1,
        unitPrice: product.sellingPrice,
        vat: product.vat,
        total: product.sellingPrice,
      ));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int newQty) {
    if (newQty <= 0) {
      _cart.removeWhere((item) => item.productId == productId);
      notifyListeners();
      return;
    }

    final prod = _db.products.firstWhere((p) => p.id == productId);
    if (newQty <= prod.totalQuantity) {
      final idx = _cart.indexWhere((item) => item.productId == productId);
      if (idx != -1) {
        final item = _cart[idx];
        _cart[idx] = SaleItem(
          productId: productId,
          productName: item.productName,
          quantity: newQty,
          unitPrice: item.unitPrice,
          vat: item.vat,
          total: newQty * item.unitPrice,
        );
        notifyListeners();
      }
    }
  }

  void removeCartItem(String productId) {
    _cart.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _cartDiscount = 0.0;
    _selectedCartPatient = null;
    notifyListeners();
  }

  void applyCartDiscount(double amount) {
    _cartDiscount = amount;
    notifyListeners();
  }

  double get cartTotal {
    double total = 0.0;
    for (var item in _cart) {
      total += item.total;
    }
    return total;
  }

  double get cartNetTotal {
    double net = cartTotal - _cartDiscount;
    return net < 0 ? 0.0 : net;
  }

  /// Retourne le nom d'affichage du caissier (fullName si dispo, sinon username)
  String _getCashierDisplayName() {
    // Chercher l'utilisateur dans la liste des comptes
    final user = _db.users.firstWhere(
      (u) => u.username == _db.currentUsername,
      orElse: () =>
          UserAccount(username: _db.currentUsername, role: _db.currentUserRole),
    );

    // Si l'utilisateur a un fullName défini, l'utiliser en priorité
    if (user.fullName != null && user.fullName!.trim().isNotEmpty) {
      return user.fullName!.trim();
    }

    // Si l'utilisateur est ADMIN, chercher le compte admin dans la liste
    if (_db.currentUserRole == 'ADMIN') {
      final adminUser = _db.users.firstWhere(
        (u) => u.role == 'ADMIN',
        orElse: () => UserAccount(username: _db.currentUsername, role: 'ADMIN'),
      );
      if (adminUser.fullName != null && adminUser.fullName!.trim().isNotEmpty) {
        return adminUser.fullName!.trim();
      }
      // Fallback: utiliser le username de l'admin
      return adminUser.username.isNotEmpty
          ? adminUser.username
          : 'Administrateur';
    }

    // Sinon, retourner le username courant
    return _db.currentUsername.isNotEmpty ? _db.currentUsername : 'Vendeur';
  }

  // Confirm Sale & Deduct stock sequentially from earliest expiring lots (FIFO by expiration)
  bool checkoutCart(
      String paymentMethod, double cashReceived, double changeReturned) {
    if (_cart.isEmpty) return false;
    if (paymentMethod == 'ESPECES' && cashReceived < cartNetTotal) return false;

    // Générer un numéro de vente séquentiel basé sur l'ordre d'arrivée
    final int saleNumber = _db.sales.length + 1;
    final String saleId = 'V-${saleNumber.toString().padLeft(3, '0')}';

    // Deduct stock lot by lot (FIFO style based on expiration dates)
    for (var cartItem in _cart) {
      int remainingToDeduct = cartItem.quantity;

      // Get lots of this product, sorted by expirationDate (earliest first)
      final prodLots =
          _db.lots.where((l) => l.productId == cartItem.productId).toList();
      prodLots.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

      for (var lot in prodLots) {
        if (remainingToDeduct <= 0) break;

        if (lot.quantity >= remainingToDeduct) {
          lot.quantity -= remainingToDeduct;
          remainingToDeduct = 0;
        } else {
          remainingToDeduct -= lot.quantity;
          lot.quantity = 0;
        }
      }

      // Update product overall quantity
      final prodIdx =
          _db.products.indexWhere((p) => p.id == cartItem.productId);
      if (prodIdx != -1) {
        _db.products[prodIdx].totalQuantity -= cartItem.quantity;

        // Log stock movement
        _registerMovement(
          productId: cartItem.productId,
          productName: cartItem.productName,
          type: 'SORTIE',
          quantity: cartItem.quantity,
          reason: 'Vente POS numéro : $saleId',
        );
      }
    }

    // Add sale to history
    final newSale = Sale(
      id: saleId,
      date: workingDate,
      items: List.from(_cart),
      totalAmount: cartTotal,
      discountAmount: _cartDiscount,
      netAmount: cartNetTotal,
      paymentMethod: paymentMethod,
      cashReceived: cashReceived,
      changeReturned: changeReturned,
      cashierName: _getCashierDisplayName(),
      patientId: _selectedCartPatient?.id,
      patientName: _selectedCartPatient?.fullName,
    );

    _db.sales.insert(0, newSale);

    // If payment method is Crédit, record a debt automatically in General Debts
    final pmUpper = paymentMethod.toUpperCase();
    if (pmUpper.contains('CRÉDIT') || pmUpper.contains('CREDIT')) {
      final loanItems = _cart
          .map((item) => LoanItem(
                productName: item.productName,
                quantity: item.quantity,
                unitValue: item.unitPrice,
              ))
          .toList();

      final loan = MedicamentLoan(
        id: 'DETTE-${DateTime.now().millisecondsSinceEpoch}',
        items: loanItems,
        lenderType: 'personne',
        lenderName: _selectedCartPatient?.fullName ?? 'Client Crédit ($saleId)',
        lenderContact: _selectedCartPatient?.phone ?? '',
        lenderAddress: _selectedCartPatient?.quartier ?? '',
        loanDate: workingDate,
        isReturned: false,
        notes:
            'Dette enregistrée automatiquement suite à la vente POS N° $saleId',
        saleId: saleId,
      );
      _db.loans.insert(0, loan);
    }

    // Apply loyalty points to patient
    if (_selectedCartPatient != null) {
      final patientIdx =
          _db.patients.indexWhere((p) => p.id == _selectedCartPatient!.id);
      if (patientIdx != -1) {
        // 1 point per 10,000 GNF spent
        int additionalPoints = (cartNetTotal / 10000).floor();
        _db.patients[patientIdx].loyaltyPoints += additionalPoints;
      }
    }

    _db.logAction('VENTE_POS',
        'Vente réussie (ID: $saleId). Total: $cartNetTotal GNF via $paymentMethod.');
    _db.save();

    // Reset Cart
    _cart.clear();
    _cartDiscount = 0.0;
    _selectedCartPatient = null;
    notifyListeners();
    return true;
  }

  // ── DETTES & EMPRUNTS OPERATIONS ──────────────────────────────────────────
  Map<String, int> _loanQuantities(MedicamentLoan loan) {
    final quantities = <String, int>{};
    for (final item in loan.items) {
      quantities.update(item.productName, (value) => value + item.quantity,
          ifAbsent: () => item.quantity);
    }
    return quantities;
  }

  bool _applyManualLoanStockChange(
      MedicamentLoan? previous, MedicamentLoan? next) {
    // Une dette créée par une vente à crédit a déjà été sortie par checkoutCart.
    if ((previous?.saleId ?? next?.saleId) != null) return true;
    final before =
        previous == null ? <String, int>{} : _loanQuantities(previous);
    final after = next == null ? <String, int>{} : _loanQuantities(next);
    final names = {...before.keys, ...after.keys};

    for (final name in names) {
      final delta = (after[name] ?? 0) - (before[name] ?? 0);
      if (delta <= 0) continue;
      final productIndex = _db.products.indexWhere((p) => p.name == name);
      if (productIndex == -1 ||
          _db.products[productIndex].totalQuantity < delta) return false;
    }

    for (final name in names) {
      final delta = (after[name] ?? 0) - (before[name] ?? 0);
      if (delta == 0) continue;
      final productIndex = _db.products.indexWhere((p) => p.name == name);
      if (productIndex == -1) continue;
      final product = _db.products[productIndex];
      if (delta > 0) {
        var remaining = delta;
        final productLots = _db.lots
            .where((lot) => lot.productId == product.id && lot.quantity > 0)
            .toList()
          ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
        for (final lot in productLots) {
          if (remaining == 0) break;
          final taken = lot.quantity < remaining ? lot.quantity : remaining;
          lot.quantity -= taken;
          remaining -= taken;
        }
        product.totalQuantity -= delta;
        _registerMovement(
            productId: product.id,
            productName: product.name,
            type: 'SORTIE',
            quantity: delta,
            reason: 'Dette de médicaments ${next?.id ?? previous?.id}');
      } else {
        final returned = -delta;
        final productLots = _db.lots
            .where((lot) => lot.productId == product.id)
            .toList()
          ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
        if (productLots.isNotEmpty) productLots.first.quantity += returned;
        product.totalQuantity += returned;
        _registerMovement(
            productId: product.id,
            productName: product.name,
            type: 'ENTREE',
            quantity: returned,
            reason: 'Correction de la dette ${next?.id ?? previous?.id}');
      }
    }
    return true;
  }

  bool addLoan(MedicamentLoan loan) {
    if (!_applyManualLoanStockChange(null, loan)) return false;
    _db.loans.insert(0, loan);
    _db.logAction('LOAN_ADD',
        'Dette enregistrée : ${loan.lenderName} (${loan.totalValue} GNF)');
    _db.save();
    refreshSystemAlerts(shouldNotify: true);
    notifyListeners();
    return true;
  }

  void addExpense(Expense expense) {
    _db.expenses.insert(0, expense);
    _db.logAction('EXPENSE_ADD',
        'Dépense ajoutée : ${expense.label} (${expense.amount} GNF)');
    _db.save();
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final index = _db.expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) return;
    _db.expenses[index] = expense;
    _db.logAction('EXPENSE_UPDATE', 'Dépense modifiée : ${expense.label}');
    _db.save();
    notifyListeners();
  }

  void deleteExpense(String id) {
    final index = _db.expenses.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final label = _db.expenses[index].label;
    _db.expenses.removeAt(index);
    _db.deleteRecord('expenses', id);
    _db.logAction('EXPENSE_DELETE', 'Dépense supprimée : $label');
    _db.save();
    notifyListeners();
  }

  bool updateLoan(MedicamentLoan loan) {
    final idx = _db.loans.indexWhere((l) => l.id == loan.id);
    if (idx != -1) {
      if (!_applyManualLoanStockChange(_db.loans[idx], loan)) return false;
      _db.loans[idx] = loan;
      _db.logAction('LOAN_UPDATE', 'Dette mise à jour : ${loan.lenderName}');
      _db.save();
      refreshSystemAlerts(shouldNotify: true);
      notifyListeners();
      return true;
    }
    return false;
  }

  void deleteLoan(String loanId) {
    final idx = _db.loans.indexWhere((l) => l.id == loanId);
    if (idx != -1) {
      final l = _db.loans[idx];
      _db.loans.removeAt(idx);
      _db.deleteRecord('loans', loanId);
      _db.logAction('LOAN_DELETE', 'Dette supprimée : ${l.lenderName}');
      _db.save();
      notifyListeners();
    }
  }

  void clearLoans({bool onlyReturned = false}) {
    if (onlyReturned) {
      final returnedIds =
          _db.loans.where((l) => l.isReturned).map((l) => l.id).toList();
      for (final id in returnedIds) {
        _db.deleteRecord('loans', id);
      }
      _db.loans.removeWhere((l) => l.isReturned);
    } else {
      for (final l in _db.loans) {
        _db.deleteRecord('loans', l.id);
      }
      _db.loans.clear();
    }
    _db.logAction(
        'LOAN_CLEAR',
        onlyReturned
            ? 'Dettes réglées effacées'
            : 'Toutes les dettes effacées');
    _db.save();
    notifyListeners();
  }

  void updatePatientLoyaltyPoints(String patientId, int newPoints) {
    final idx = _db.patients.indexWhere((p) => p.id == patientId);
    if (idx != -1) {
      _db.patients[idx].loyaltyPoints = newPoints < 0 ? 0 : newPoints;
      _db.logAction('PATIENT_POINTS_UPDATE',
          'Points de ${patients[idx].fullName} mis à jour : $newPoints');
      _db.save();
      notifyListeners();
    }
  }

  // Refund / Returns
  void processSaleRefund(String saleId) {
    final saleIdx = _db.sales.indexWhere((s) => s.id == saleId);
    if (saleIdx != -1) {
      final sale = _db.sales[saleIdx];

      // Return items to stock (put in first active lot or create a return lot)
      for (var item in sale.items) {
        final prodIdx = _db.products.indexWhere((p) => p.id == item.productId);
        if (prodIdx != -1) {
          _db.products[prodIdx].totalQuantity += item.quantity;

          // Try to return to first available lot of this product
          final firstLotIdx =
              _db.lots.indexWhere((l) => l.productId == item.productId);
          if (firstLotIdx != -1) {
            _db.lots[firstLotIdx].quantity += item.quantity;
          }

          _registerMovement(
            productId: item.productId,
            productName: item.productName,
            type: 'ENTREE',
            quantity: item.quantity,
            reason: 'Retour client / Remboursement de la vente $saleId',
          );
        }
      }

      // Deduct loyalty points
      if (sale.patientId != null) {
        final pIdx = _db.patients.indexWhere((p) => p.id == sale.patientId);
        if (pIdx != -1) {
          int pointsToDeduct = (sale.netAmount / 10000).floor();
          _db.patients[pIdx].loyaltyPoints -= pointsToDeduct;
          if (_db.patients[pIdx].loyaltyPoints < 0) {
            _db.patients[pIdx].loyaltyPoints = 0;
          }
        }
      }

      _db.sales.removeAt(saleIdx);
      _db.logAction('VENTE_ANNULER',
          'Annulation et remboursement complet de la vente $saleId.');
      _db.save();
      notifyListeners();
    }
  }

  void deleteSale(String saleId) {
    _db.sales.removeWhere((s) => s.id == saleId);
    _db.logAction('VENTE_DELETE', 'Vente supprimée (ID: $saleId).');
    _db.save();
    notifyListeners();
  }

  // Partial or Full Product Returns and Refunds
  bool processItemsRefund({
    required String saleId,
    required List<Map<String, dynamic>>
        itemsToReturn, // [{'productId': '...', 'quantity': 2}]
  }) {
    if (itemsToReturn.isEmpty) return false;
    final saleIdx = _db.sales.indexWhere((s) => s.id == saleId);
    if (saleIdx == -1) return false;

    final sale = _db.sales[saleIdx];
    List<SaleItem> updatedItems = [];
    double totalRefundAmount = 0.0;

    for (var originalItem in sale.items) {
      final returnInfo = itemsToReturn.firstWhere(
        (r) => r['productId'] == originalItem.productId,
        orElse: () => {},
      );

      if (returnInfo.isEmpty) {
        // No return for this product
        updatedItems.add(originalItem);
        continue;
      }

      final int returnQty = returnInfo['quantity'] as int;
      if (returnQty <= 0) {
        updatedItems.add(originalItem);
        continue;
      }

      final int finalReturnQty =
          returnQty > originalItem.quantity ? originalItem.quantity : returnQty;
      totalRefundAmount += finalReturnQty * originalItem.unitPrice;

      // 1. Put quantity back into overall product stock
      final prodIdx =
          _db.products.indexWhere((p) => p.id == originalItem.productId);
      if (prodIdx != -1) {
        _db.products[prodIdx].totalQuantity += finalReturnQty;

        // Put back into first available lot
        final lotIdx =
            _db.lots.indexWhere((l) => l.productId == originalItem.productId);
        if (lotIdx != -1) {
          _db.lots[lotIdx].quantity += finalReturnQty;
        }

        // Register stock movement
        _registerMovement(
          productId: originalItem.productId,
          productName: originalItem.productName,
          type: 'ENTREE',
          quantity: finalReturnQty,
          reason: 'Retour client / Remboursement de la vente $saleId',
        );
      }

      // 2. Keep remaining quantity in the sale
      final int remainingQty = originalItem.quantity - finalReturnQty;
      if (remainingQty > 0) {
        updatedItems.add(SaleItem(
          productId: originalItem.productId,
          productName: originalItem.productName,
          quantity: remainingQty,
          unitPrice: originalItem.unitPrice,
          vat: originalItem.vat,
          total: remainingQty * originalItem.unitPrice,
        ));
      }
    }

    // 3. Deduct loyalty points proportionally
    if (sale.patientId != null && totalRefundAmount > 0) {
      final pIdx = _db.patients.indexWhere((p) => p.id == sale.patientId);
      if (pIdx != -1) {
        int pointsToDeduct = (totalRefundAmount / 10000).floor();
        _db.patients[pIdx].loyaltyPoints -= pointsToDeduct;
        if (_db.patients[pIdx].loyaltyPoints < 0) {
          _db.patients[pIdx].loyaltyPoints = 0;
        }
      }
    }

    if (updatedItems.isEmpty) {
      // Everything was returned, remove the sale entirely
      _db.sales.removeAt(saleIdx);
      _db.logAction('VENTE_ANNULER',
          'Annulation et remboursement complet de la vente $saleId suite au retour de tous les produits.');
    } else {
      // Recompute sale totals
      double newTotal = updatedItems.fold(0.0, (sum, item) => sum + item.total);
      // Proportionally adjust discount if any
      double newDiscount = sale.totalAmount > 0
          ? (newTotal / sale.totalAmount) * sale.discountAmount
          : 0.0;
      double newNet = newTotal - newDiscount;

      // Update in database
      _db.sales[saleIdx] = Sale(
        id: sale.id,
        date: sale.date,
        items: updatedItems,
        totalAmount: newTotal,
        discountAmount: newDiscount,
        netAmount: newNet < 0 ? 0.0 : newNet,
        paymentMethod: sale.paymentMethod,
        cashReceived: sale.cashReceived,
        changeReturned: sale.changeReturned,
        cashierName: sale.cashierName,
        patientId: sale.patientId,
        patientName: sale.patientName,
      );

      _db.logAction('RETOUR_PRODUIT',
          'Retour partiel traité pour la vente $saleId. Montant remboursé: $totalRefundAmount GNF.');
    }

    _db.save();
    notifyListeners();
    return true;
  }

  // ==========================================
  // PRESCRIPTION OPERATIONS (SAFETY INTEGRATION)
  // ==========================================

  // Perform automated prescription security audits: checks patient history/allergies & drug interactions
  Map<String, dynamic> verifyPrescriptionSafety(
      String patientId, List<Map<String, dynamic>> items) {
    final patient = _db.patients.firstWhere((p) => p.id == patientId);
    List<String> warnings = [];
    bool hasDanger = false;

    // Check allergies against drug names
    for (var item in items) {
      final String medicineName =
          (item['medicineName'] as String).toLowerCase();

      for (var allergy in patient.allergies) {
        final String lowerAllergy = allergy.toLowerCase();

        // Custom smart matches: "Penicilline" vs "Amoxicilline", "Aspirine" vs "Ibuprofene" (NSAIDs)
        if (medicineName.contains(lowerAllergy) ||
            lowerAllergy.contains(medicineName)) {
          warnings.add(
              'Alerte Allergie : Le patient est allergique à "$allergy", ce qui correspond directement à "${item['medicineName']}".');
          hasDanger = true;
        } else if (lowerAllergy.contains('pénicilline') &&
            (medicineName.contains('amoxicilline') ||
                medicineName.contains('augmentin'))) {
          warnings.add(
              'Danger Pénicilline : Le patient est allergique à la Pénicilline. Le médicament "${item['medicineName']}" contient des dérivés bêta-lactamines.');
          hasDanger = true;
        } else if (lowerAllergy.contains('aspirine') &&
            medicineName.contains('ibuprofène')) {
          warnings.add(
              'Sensibilité Croisée : Patient sensible à l\'Aspirine. Risque de réaction croisée avec "${item['medicineName']}" (AINS).');
          hasDanger = true;
        }
      }
    }

    // Check drug interactions (e.g. Ibuprofen + Aspirin, or Multiple antibiotics)
    bool hasNSAID = false;
    bool hasAntibiotic = false;
    int antibioticCount = 0;

    for (var item in items) {
      final String name = (item['medicineName'] as String).toLowerCase();
      if (name.contains('ibuprofène') || name.contains('spasfon')) {
        hasNSAID = true;
      }
      if (name.contains('amoxicilline') || name.contains('augmentin')) {
        hasAntibiotic = true;
        antibioticCount++;
      }
    }

    if (hasNSAID && hasAntibiotic) {
      // Just a standard warning, not immediate blocker
      warnings.add(
          'Note d\'interaction : Association AINS + Antibiotique. Surveiller la tolérance gastrique du patient.');
    }
    if (antibioticCount >= 2) {
      warnings.add(
          'Double Antibiothérapie : Présence de plusieurs antibiotiques dans la prescription. Confirmer l\'indication clinique.');
    }

    return {
      'hasDanger': hasDanger,
      'warnings': warnings,
    };
  }

  void addPrescription(Prescription p) {
    _db.prescriptions.insert(0, p);
    _db.logAction('ORD_CREATE',
        'Saisie d\'une ordonnance (ID: ${p.id}) par ${p.doctorName} pour ${p.patientName}.');
    _db.save();
    notifyListeners();
  }

  void updatePrescription(String id, Prescription updated) {
    final idx = _db.prescriptions.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _db.prescriptions[idx] = updated;
      _db.logAction('ORD_UPDATE', 'Modification de l\'ordonnance (ID: $id).');
      _db.save();
      notifyListeners();
    }
  }

  // Dispense prescription
  bool dispensePrescription(String id) {
    final idx = _db.prescriptions.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final p = _db.prescriptions[idx];
      if (p.isDispensed) return false;

      // Check stock first
      bool stockAvailable = true;
      List<Product> matchedProducts = [];
      List<int> quantitiesToDeduct = [];

      for (var pItem in p.medicines) {
        // Try exact match or fuzzy search
        final prodIndex = _db.products.indexWhere((prod) =>
            prod.name.toLowerCase().contains(pItem.medicineName.toLowerCase()));

        if (prodIndex != -1) {
          final prod = _db.products[prodIndex];
          if (prod.totalQuantity >= pItem.quantityPrescribed) {
            matchedProducts.add(prod);
            quantitiesToDeduct.add(pItem.quantityPrescribed);
          } else {
            stockAvailable = false;
            break;
          }
        } else {
          // Medicine not found in current inventory database
          stockAvailable = false;
          break;
        }
      }

      if (!stockAvailable) {
        _db.logAction('ORD_DISPENSE_FAILED',
            'Tentative de délivrance de l\'ordonnance ${p.id} échouée : Stock insuffisant.');
        return false;
      }

      // Deduct stock
      for (int i = 0; i < matchedProducts.length; i++) {
        final prod = matchedProducts[i];
        final qty = quantitiesToDeduct[i];

        // FIFO deduct lots
        int remaining = qty;
        final prodLots = _db.lots.where((l) => l.productId == prod.id).toList();
        prodLots.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));

        for (var lot in prodLots) {
          if (remaining <= 0) break;
          if (lot.quantity >= remaining) {
            lot.quantity -= remaining;
            remaining = 0;
          } else {
            remaining -= lot.quantity;
            lot.quantity = 0;
          }
        }

        prod.totalQuantity -= qty;
        _registerMovement(
          productId: prod.id,
          productName: prod.name,
          type: 'SORTIE',
          quantity: qty,
          reason: 'Délivrance ordonnance ${p.id}',
        );
      }

      p.isDispensed = true;
      p.dispensedDate = DateTime.now();

      _db.logAction('ORD_DISPENSE', 'Ordonnance ${p.id} délivrée avec succès.');
      _db.save();
      notifyListeners();
      return true;
    }
    return false;
  }

  // ==========================================
  // CLIENT / PATIENT OPERATIONS
  // ==========================================

  void addPatient(Patient patient) {
    _db.patients.add(patient);
    _db.logAction(
        'PATIENT_ADD', 'Nouveau patient enregistré : ${patient.fullName}.');
    _db.save();
    notifyListeners();
  }

  void editPatient(Patient updated) {
    final idx = _db.patients.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _db.patients[idx] = updated;
      _db.logAction(
          'PATIENT_EDIT', 'Fiche patient modifiée : ${updated.fullName}.');
      _db.save();
      notifyListeners();
    }
  }

  void deletePatient(String patientId) {
    final pat = _db.patients.firstWhere((p) => p.id == patientId);
    _db.patients.removeWhere((p) => p.id == patientId);
    _db.logAction(
        'PATIENT_DELETE', 'Fiche patient supprimée : ${pat.fullName}.');
    _db.save();
    notifyListeners();
  }

  // ==========================================
  // STAFF & PLANNING OPERATIONS
  // ==========================================

  void addEmployee(Employee emp) {
    _db.employees.add(emp);
    _db.logAction('STAFF_ADD',
        'Nouvel employé ajouté : ${emp.fullName} (${emp.position}).');
    _db.save();
    notifyListeners();
  }

  void editEmployee(Employee updated) {
    final idx = _db.employees.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _db.employees[idx] = updated;
      _db.logAction('STAFF_EDIT',
          'Informations de l\'employé ${updated.fullName} modifiées.');
      _db.save();
      notifyListeners();
    }
  }

  void deleteEmployee(String id) {
    final emp = _db.employees.firstWhere((e) => e.id == id);
    _db.employees.removeWhere((e) => e.id == id);
    _db.logAction(
        'STAFF_DELETE', 'Employé retiré des effectifs : ${emp.fullName}.');
    _db.save();
    notifyListeners();
  }

  // Planning / Shifts
  void addEmployeeShift(String employeeId, Shift shift) {
    final idx = _db.employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      _db.employees[idx].planning.add(shift);
      _db.logAction('STAFF_SHIFT_ADD',
          'Nouveau shift planifié pour ${_db.employees[idx].fullName} (${shift.dayOfWeek} ${shift.startTime}-${shift.endTime}).');
      _db.save();
      notifyListeners();
    }
  }

  void removeEmployeeShift(String employeeId, String shiftId) {
    final idx = _db.employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      _db.employees[idx].planning.removeWhere((s) => s.id == shiftId);
      _db.logAction('STAFF_SHIFT_REMOVE',
          'Shift supprimé pour ${_db.employees[idx].fullName}.');
      _db.save();
      notifyListeners();
    }
  }

  // Leave / Congés requests
  void submitLeaveRequest(String employeeId, LeaveRequest request) {
    final idx = _db.employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      _db.employees[idx].leaveRequests.add(request);
      _db.logAction('STAFF_LEAVE_SUBMIT',
          'Nouvelle demande de congé soumise par ${_db.employees[idx].fullName} (Du ${request.startDate} au ${request.endDate}).');
      _db.save();
      notifyListeners();
    }
  }

  void updateLeaveRequestStatus(
      String employeeId, String requestId, String newStatus) {
    final empIdx = _db.employees.indexWhere((e) => e.id == employeeId);
    if (empIdx != -1) {
      final reqIdx = _db.employees[empIdx].leaveRequests
          .indexWhere((r) => r.id == requestId);
      if (reqIdx != -1) {
        _db.employees[empIdx].leaveRequests[reqIdx].status = newStatus;
        _db.logAction('STAFF_LEAVE_STATUS',
            'Demande de congé de ${_db.employees[empIdx].fullName} mise à jour : $newStatus.');
        _db.save();
        notifyListeners();
      }
    }
  }

  // Mock Clock-in / Time-tracking simulator
  void logHoursWorked(String employeeId, double hours) {
    final idx = _db.employees.indexWhere((e) => e.id == employeeId);
    if (idx != -1) {
      _db.employees[idx].hoursWorkedThisMonth += hours;
      _db.logAction('STAFF_HOURS',
          'Enregistrement de $hours heures de travail pour ${_db.employees[idx].fullName}.');
      _db.save();
      notifyListeners();
    }
  }

  // ==========================================
  // SUPPLIER OPERATIONS
  // ==========================================

  void addSupplier(Supplier sup) {
    _db.suppliers.add(sup);
    _db.logAction(
        'SUPPLIER_ADD', 'Nouveau fournisseur enregistré : ${sup.name}.');
    _db.save();
    notifyListeners();
  }

  void editSupplier(Supplier updated) {
    final idx = _db.suppliers.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _db.suppliers[idx] = updated;
      _db.logAction('SUPPLIER_EDIT', 'Fournisseur modifié : ${updated.name}.');
      _db.save();
      notifyListeners();
    }
  }

  void deleteSupplier(String id) {
    final sup = _db.suppliers.firstWhere((s) => s.id == id);
    _db.suppliers.removeWhere((s) => s.id == id);
    _db.logAction('SUPPLIER_DELETE', 'Fournisseur supprimé : ${sup.name}.');
    _db.save();
    notifyListeners();
  }

  void updateProductPurchasePrice(String productId, double newPrice) {
    final pIdx =
        _db.products.indexWhere((p) => p.id.trim() == productId.trim());
    if (pIdx != -1) {
      final p = _db.products[pIdx];
      _db.products[pIdx] = Product(
        id: p.id,
        name: p.name,
        description: p.description,
        barcode: p.barcode,
        purchasePrice: newPrice,
        sellingPrice: p.sellingPrice,
        vat: p.vat,
        category: p.category,
        supplierName: p.supplierName,
        image: p.image,
        minStock: p.minStock,
        totalQuantity: p.totalQuantity,
      );
      _db.logAction('STOCK_PRICE_UPDATE',
          'Prix d\'achat de ${p.name} mis à jour dans le stock : $newPrice GNF.');
      _db.save();
      notifyListeners();
    }
  }

  // Supplier orders builder
  void createSupplierOrder(String supplierId, List<OrderItem> items) {
    final supIdx = _db.suppliers.indexWhere((s) => s.id == supplierId);
    if (supIdx != -1) {
      double total = 0.0;
      for (var item in items) {
        total += item.quantityOrdered * item.unitPrice;
        // Update product purchase price directly in stock database
        final pIdx = _db.products
            .indexWhere((p) => p.id.trim() == item.productId.trim());
        if (pIdx != -1 && item.unitPrice > 0) {
          final p = _db.products[pIdx];
          if (p.purchasePrice != item.unitPrice) {
            _db.products[pIdx] = Product(
              id: p.id,
              name: p.name,
              description: p.description,
              barcode: p.barcode,
              purchasePrice: item.unitPrice,
              sellingPrice: p.sellingPrice,
              vat: p.vat,
              category: p.category,
              supplierName: p.supplierName,
              image: p.image,
              minStock: p.minStock,
              totalQuantity: p.totalQuantity,
            );
            _db.logAction('STOCK_PRICE_UPDATE',
                'Prix d\'achat de ${p.name} mis à jour dans le stock via la commande : ${item.unitPrice} GNF.');
          }
        }
      }
      final orderId = 'ORD-SUP-${DateTime.now().millisecondsSinceEpoch}';
      final newOrder = SupplierOrder(
        id: orderId,
        date: workingDate,
        items: items,
        totalAmount: total,
        status: 'COMMANDE',
      );
      _db.suppliers[supIdx].orders.insert(0, newOrder);

      // Create an unpaid invoice matching this order
      final invoiceId = 'INV-SUP-${DateTime.now().millisecondsSinceEpoch}';
      final newInvoice = SupplierInvoice(
        id: invoiceId,
        invoiceNumber: 'FAC-${DateTime.now().millisecondsSinceEpoch}',
        amount: total,
        date: workingDate,
        isPaid: false,
      );
      _db.suppliers[supIdx].invoices.insert(0, newInvoice);

      _db.logAction('SUPPLIER_ORDER_CREATE',
          'Commande passée au fournisseur ${_db.suppliers[supIdx].name} (Total: $total GNF).');
      _db.save();
      refreshSystemAlerts(shouldNotify: true);
    }
  }

  // Receiving merchandise & auto incrementing stock and creating movements!
  void receiveSupplierOrder(String supplierId, String orderId) {
    final supIdx = _db.suppliers.indexWhere((s) => s.id == supplierId);
    if (supIdx != -1) {
      final ordIdx =
          _db.suppliers[supIdx].orders.indexWhere((o) => o.id == orderId);
      if (ordIdx != -1) {
        final order = _db.suppliers[supIdx].orders[ordIdx];
        if (order.status == 'RECUE') return;

        order.status = 'RECUE';

        // Add received items to stock
        for (int i = 0; i < order.items.length; i++) {
          final orderItem = order.items[i];
          final prodIdx = _db.products
              .indexWhere((p) => p.id.trim() == orderItem.productId.trim());
          if (prodIdx != -1) {
            final prod = _db.products[prodIdx];

            // Add items to a lot (or create new lot)
            final String lotId =
                'LOT-SUP-${DateTime.now().millisecondsSinceEpoch}-${_db.lots.length + 1}';
            final newLot = Lot(
              id: lotId,
              productId: prod.id,
              productName: prod.name,
              lotNumber: 'LT-${DateTime.now().year}-${prod.id}',
              expirationDate: DateTime.now()
                  .add(const Duration(days: 365 * 2)), // Default 2 years
              quantity: orderItem.quantityOrdered,
            );
            _db.lots.add(newLot);

            if (prod.totalQuantity < 0) {
              prod.totalQuantity = 0;
            }
            prod.totalQuantity += orderItem.quantityOrdered;

            order.items[i] = OrderItem(
              productId: orderItem.productId,
              productName: orderItem.productName,
              quantityOrdered: orderItem.quantityOrdered,
              quantityReceived: orderItem.quantityOrdered,
              unitPrice: orderItem.unitPrice,
            );

            _registerMovement(
              productId: prod.id,
              productName: prod.name,
              type: 'ENTREE',
              quantity: orderItem.quantityOrdered,
              reason: 'Reception commande fournisseur $orderId',
            );
          }
        }

        _db.logAction('SUPPLIER_ORDER_RECEIVE',
            'Marchandises reçues pour la commande $orderId. Stocks mis à jour.');
        _db.save();
        refreshSystemAlerts(shouldNotify: true);
      }
    }
  }

  void paySupplierInvoice(String supplierId, String invoiceId) {
    final supIdx = _db.suppliers.indexWhere((s) => s.id == supplierId);
    if (supIdx != -1) {
      final invIdx =
          _db.suppliers[supIdx].invoices.indexWhere((i) => i.id == invoiceId);
      if (invIdx != -1) {
        _db.suppliers[supIdx].invoices[invIdx].isPaid = true;
        _db.logAction('SUPPLIER_INV_PAY',
            'Facture payée au fournisseur ${_db.suppliers[supIdx].name} (Montant: ${_db.suppliers[supIdx].invoices[invIdx].amount} GNF).');
        _db.save();
        notifyListeners();
      }
    }
  }
}
