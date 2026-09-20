import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../models/pharmacy_models.dart';
import '../providers/app_state_provider.dart';
import '../utils/invoice_printer.dart';
import '../utils/license_key.dart';
import 'dashboard_view.dart';
import 'stock_view.dart';
import 'sales_view.dart';
import 'archives_view.dart';
import 'supplier_view.dart';
import 'loans_view.dart';
import 'sales_report_view.dart';
import 'sales_history_view.dart';
import 'replenishment_view.dart';
import 'admin_view.dart';
import 'expenses_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  AppStateProvider get state => Provider.of<AppStateProvider>(context);
  bool _isSidebarVisible = true;

  // Custom Identity Settings
  String get _pharmacyName => state.pharmacyName;
  String _pharmacySubtitle = 'Gestion Officine v1.0';
  IconData _pharmacyIcon = Icons.local_pharmacy_rounded;
  Uint8List? get _pharmacyLogoBytes => state.pharmacyLogo;

  late final TextEditingController _nameController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _multiplierController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _subtitleFocusNode;
  late final FocusNode _multiplierFocusNode;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    _nameController = TextEditingController(text: appState.pharmacyName);
    _subtitleController = TextEditingController(text: _pharmacySubtitle);
    final initialM = appState.priceMultiplier > 0 ? appState.priceMultiplier : 1.4;
    _multiplierController = TextEditingController(
      text: (initialM % 1 == 0) ? initialM.toInt().toString() : initialM.toString(),
    );
    _nameFocusNode = FocusNode();
    _subtitleFocusNode = FocusNode();
    _multiplierFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _multiplierController.dispose();
    _nameFocusNode.dispose();
    _subtitleFocusNode.dispose();
    _multiplierFocusNode.dispose();
    super.dispose();
  }

  // Check permission for current role and user custom permissions
  bool _hasAccess(AppStateProvider state, String role, int tabIndex) {
    if (role == 'ADMIN') return true;

    final currentUser = state.users.firstWhere(
      (u) => u.username == state.currentUsername,
      orElse: () => UserAccount(username: '', role: 'GUEST'),
    );

    if (currentUser.role != 'VENDEUR' && currentUser.role != 'ADMIN') {
      return tabIndex == 14 || tabIndex == 15;
    }

    String permKey;
    switch (tabIndex) {
      case 0:
        permKey = 'dashboard';
        break;
      case 2:
        permKey = 'pos';
        break;
      case 1:
        // Tab stock accessible si add_product OU new_medicines est autorisé
        return currentUser.permissions.contains('add_product') ||
            currentUser.permissions.contains('new_medicines');
      case 10:
        permKey = 'reports';
        break;
      case 9:
        permKey = 'archives';
        break;
      case 8:
        permKey = 'loans';
        break;
      case 13:
        permKey = 'replenish';
        break;
      case 6:
        permKey = 'suppliers';
        break;
      case 11:
        permKey = 'history';
        break;
      case 14:
      case 15:
        return true; // Always allow details and documentation
      default:
        return false;
    }

    return currentUser.permissions.contains(permKey);
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = Color(0xFF10B981); // Emerald Green
    final currentRole = state.currentUserRole;

    final List<Map<String, dynamic>> allTabs = [
      {
        'index': 0,
        'title': 'Tableau de bord',
        'icon': Icons.dashboard_rounded,
        'group': 'Accueil'
      },
      {
        'index': 2,
        'title': 'Point de ventes',
        'icon': Icons.point_of_sale_rounded,
        'group': 'Ventes'
      },
      {
        'index': 1,
        'title': 'Stocks des médicaments',
        'icon': Icons.inventory_2_rounded,
        'group': 'Stock'
      },
      {
        'index': 10,
        'title': 'Rapport de ventes',
        'icon': Icons.analytics_rounded,
        'group': 'Ventes'
      },
      {
        'index': 9,
        'title': 'Archives réçu',
        'icon': Icons.archive_rounded,
        'group': 'Ventes'
      },
      {
        'index': 8,
        'title': 'Dettes',
        'icon': Icons.account_balance_wallet_rounded,
        'group': 'Admin'
      },
      {
        'index': 16,
        'title': 'Dépenses',
        'icon': Icons.payments_outlined,
        'group': 'Admin'
      },
      {
        'index': 13,
        'title': 'Réapprovisionnement',
        'icon': Icons.autorenew_rounded,
        'group': 'Stock'
      },
      {
        'index': 6,
        'title': 'Fournisseurs',
        'icon': Icons.local_shipping_rounded,
        'group': 'Stock'
      },
      {
        'index': 11,
        'title': 'Historique des ventes',
        'icon': Icons.receipt_long_rounded,
        'group': 'Système'
      },
      {
        'index': 7,
        'title': 'Gestion des comptes',
        'icon': Icons.manage_accounts_rounded,
        'group': 'Système'
      },
      {
        'index': 12,
        'title': 'Paramètres',
        'icon': Icons.settings_rounded,
        'group': 'Système'
      },
      {
        'index': 14,
        'title': 'Détails',
        'icon': Icons.info_outline_rounded,
        'group': 'Système'
      },
      {
        'index': 15,
        'title': 'Documentation',
        'icon': Icons.help_outline_rounded,
        'group': 'Système'
      },
    ];

    // Filter tabs based on role permissions
    final allowedTabs = allTabs
        .where((tab) => _hasAccess(state, currentRole, tab['index']))
        .toList();

    // Ensure state.activeTab is valid for allowedTabs, otherwise set to first allowed
    int activeIndex =
        allowedTabs.indexWhere((t) => t['index'] == state.activeTab);
    if (activeIndex == -1) {
      activeIndex = 0;
      // Schedule post frame callback to avoid setting state during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.setActiveTab(allowedTabs[0]['index']);
      });
    }

    // Get alerts counts
    final lowStockCount = state.products
        .where((p) =>
            p.totalQuantity <= p.minStock && !state.isProductOrdered(p.id))
        .length;
    final expiredCount =
        state.lots.where((l) => l.isExpired && l.quantity > 0).length;
    final alertCount = state.activeAlerts.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // ==========================================
          // LEFT SIDEBAR
          // ==========================================
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarVisible ? 280 : 78,
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                  right: BorderSide(
                      color: Theme.of(context).dividerTheme.color ??
                          Colors.white.withOpacity(0.05))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: _isSidebarVisible ? 24 : 12, vertical: 24),
                  decoration: BoxDecoration(
                    color: themeColor,
                    border: Border(
                        bottom: BorderSide(
                            color: Theme.of(context).dividerTheme.color ??
                                Colors.white.withOpacity(0.03))),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_pharmacyLogoBytes != null)
                          Container(
                            width: _isSidebarVisible ? 90 : 56,
                            height: _isSidebarVisible ? 90 : 56,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            clipBehavior: Clip.antiAlias,
                            child: Image.memory(_pharmacyLogoBytes!,
                                fit: BoxFit.cover),
                          )
                        else
                          Icon(_pharmacyIcon,
                              color: Colors.white,
                              size: _isSidebarVisible ? 52 : 34),
                        if (_isSidebarVisible) ...[
                          const SizedBox(height: 12),
                          Text(
                            _pharmacyName,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pharmacySubtitle,
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Sidebar items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                        vertical: 12, horizontal: _isSidebarVisible ? 12 : 8),
                    children: () {
                      final List<Widget> items = [];

                      for (final tab in allowedTabs) {
                        final isSelected = tab['index'] == state.activeTab;

                        final itemWidget = Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: InkWell(
                            onTap: () {
                              if (tab['index'] == 14) {
                                _showDetailDialog(context, state);
                              } else if (tab['index'] == 15) {
                                _showDocumentationDialog(context, state);
                              } else {
                                state.setActiveTab(tab['index']);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: _isSidebarVisible ? 14 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeColor.withOpacity(0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? themeColor.withOpacity(0.25)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: _isSidebarVisible
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tab['icon'],
                                    color: isSelected
                                        ? themeColor
                                        : state.textPrimary,
                                    size: 28,
                                  ),
                                  if (_isSidebarVisible) ...[
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        tab['title'],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          color: isSelected
                                              ? (state.isDarkMode
                                                  ? Colors.white
                                                  : themeColor)
                                              : state.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (tab['index'] == 1 && alertCount > 0)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF59E0B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );

                        if (_isSidebarVisible) {
                          items.add(itemWidget);
                        } else {
                          items.add(Tooltip(
                            message: tab['title'],
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            child: itemWidget,
                          ));
                        }
                      }
                      return items;
                    }(),
                  ),
                ),

                // Bouton déconnexion séparé
                InkWell(
                  onTap: () => state.logout(),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _isSidebarVisible ? 20 : 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.06),
                      border: Border(
                          top: BorderSide(
                              color: Colors.redAccent.withOpacity(0.12))),
                    ),
                    child: Row(
                      mainAxisAlignment: _isSidebarVisible
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Colors.redAccent, size: 20),
                        if (_isSidebarVisible) ...[
                          const SizedBox(width: 10),
                          Text(
                            'Se déconnecter',
                            style: GoogleFonts.inter(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // MAIN CONTENT AREA
          // ==========================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topbar Header
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border(
                        bottom: BorderSide(
                            color: Theme.of(context).dividerTheme.color ??
                                Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    children: [
                      // Toggle sidebar button
                      IconButton(
                        iconSize: 32,
                        icon: Icon(
                          _isSidebarVisible
                              ? Icons.menu_open_rounded
                              : Icons.menu_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? state.textSecondary
                              : Color(0xFF475569),
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSidebarVisible = !_isSidebarVisible;
                          });
                        },
                      ),
                      SizedBox(width: 8),
                      Text(
                        allTabs.firstWhere(
                            (t) => t['index'] == state.activeTab)['title'],
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.white,
                        ),
                      ),
                      // Badge Période d'essai (Mode Test)
                      if (!state.isLicensed) ...[
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: Colors.orange, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Mode Test : ${state.trialDaysRemaining} jour${state.trialDaysRemaining > 1 ? "s" : ""} restant${state.trialDaysRemaining > 1 ? "s" : ""}',
                                style: GoogleFonts.inter(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Compteur archives reçu affiché dans la topbar
                      if (state.activeTab == 9 && state.sales.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    const Color(0xFF06B6D4).withOpacity(0.25)),
                          ),
                          child: Text(
                            '${state.sales.length} reçu(s)',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF06B6D4),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Spacer(),

                      // Date au centre de la Navbar (encapsulée pour éviter l'overflow)
                      Expanded(
                        child: Center(
                          child: Text(
                            DateFormat('d MMMM yyyy', 'fr_FR')
                                .format(DateTime.now()),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? state.textSecondary
                                  : Color(0xFF475569),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      if (state.notificationsEnabled && alertCount > 0) ...[
                        Tooltip(
                          message:
                              'Alertes système : $lowStockCount ruptures/faibles & $expiredCount lots périmés',
                          child: InkWell(
                            onTap: () {
                              state.setActiveTab(1); // Jump to inventory
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: Color(0xFFF59E0B).withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Color(0xFFF59E0B), size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    '$alertCount alertes de stock',
                                    style: GoogleFonts.inter(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                      ],

                      // Notification Toggle
                      IconButton(
                        icon: Icon(
                          state.notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                          color: state.notificationsEnabled
                              ? const Color(0xFF10B981)
                              : state.textSecondary,
                          size: 24,
                        ),
                        tooltip: state.notificationsEnabled
                            ? 'Désactiver les alertes'
                            : 'Activer les alertes',
                        onPressed: () => state.toggleNotifications(),
                      ),
                      SizedBox(width: 16),

                      // Theme Toggle Button (Samsung One UI style)
                      GestureDetector(
                        onTap: () => state.toggleTheme(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: state.isDarkMode
                                ? state.bgSecondary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: state.borderTheme),
                            boxShadow: [
                              if (!state.isDarkMode)
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                state.isDarkMode
                                    ? Icons.dark_mode_rounded
                                    : Icons.light_mode_rounded,
                                color: state.isDarkMode
                                    ? Colors.amber
                                    : Colors.orangeAccent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                state.isDarkMode ? 'Sombre' : 'Clair',
                                style: GoogleFonts.inter(
                                  color: state.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      const SizedBox(width: 16),

                      // Compte utilisateur dans la Navbar (derrière la date)
                      (() {
                        final currentUser = state.users.firstWhere(
                          (u) => u.username == state.currentUsername,
                          orElse: () => UserAccount(
                              username: state.currentUsername,
                              role: state.currentUserRole),
                        );
                        final hasImg = currentUser.profileImageBase64 != null &&
                            currentUser.profileImageBase64!.isNotEmpty;
                        return Flexible(
                          child: GestureDetector(
                            onTap: () => _showProfileDialog(context, state),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: themeColor.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor:
                                          themeColor.withOpacity(0.2),
                                      backgroundImage: hasImg
                                          ? MemoryImage(base64Decode(
                                              currentUser.profileImageBase64!))
                                          : null,
                                      child: hasImg
                                          ? null
                                          : Text(
                                              state.currentUsername
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                  color: themeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12),
                                            ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            state.currentUsername.toLowerCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: state.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            state.currentUserRole,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              color: themeColor,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })(),
                    ],
                  ),
                ),

                // Actual subview loaded dynamically
                Expanded(
                  child: ClipRect(
                    child: _buildSubView(state.activeTab),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Switch between allowed modules
  Widget _buildSubView(int index) {
    switch (index) {
      case 0:
        return const DashboardView();
      case 1:
        return const StockView();
      case 2:
        return const SalesView();
      case 7:
        return const AdminView();
      case 9:
        return const ArchivesView();
      case 13:
        return const ReplenishmentView();
      case 6:
        return const SupplierView();
      case 8:
        return const LoansView();
      case 10:
        return const SalesReportView();
      case 11:
        return const SalesHistoryView();
      case 12:
        return _buildSettingsView();
      case 16:
        return const ExpensesView();
      default:
        return const DashboardView();
    }
  }

  void _showDetailDialog(BuildContext context, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Text('Détails du Développeur',
                style: GoogleFonts.outfit(
                    color: state.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Developer card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          const Color(0xFF10B981).withOpacity(0.15),
                      child: Text(
                        'A',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF10B981),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Adama Keita',
                              style: GoogleFonts.outfit(
                                  color: state.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text("Informaticien",
                              style: GoogleFonts.inter(
                                  color: state.textSecondary, fontSize: 12)),
                          Text("Département Informatique",
                              style: GoogleFonts.inter(
                                  color: state.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact info
              _detailRow(Icons.phone_rounded, 'Téléphone',
                  '624 064 642 / 663 507 183', state),
              const SizedBox(height: 8),
              _detailRow(Icons.location_on_rounded, 'Adresse', 'Guinée',
                  state),
              const SizedBox(height: 16),

              // Slogan
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Simplifiez la gestion de votre pharmacie avec une solution intelligente, rapide et sécurisée. '
                        'Contactez-moi dès maintenant et transformez votre gestion avec une solution moderne et performante.',
                        style: GoogleFonts.inter(
                          color: state.textSecondary,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer',
                style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value, AppStateProvider state) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF10B981), size: 14),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: state.textSecondaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: GoogleFonts.inter(
                    color: state.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // VIRTUAL MANUAL / DOCUMENTATION DIALOG
  // ==========================================
  void _showDocumentationDialog(BuildContext context, AppStateProvider state) {
    const themeColor = Color(0xFF10B981);

    // Sections de documentation avec leur contenu
    final List<Map<String, dynamic>> docSections = [
      {
        'key': 'general',
        'label': 'Présentation Générale',
        'icon': Icons.info_outline_rounded,
        'iconColor': Colors.purple,
        'emoji': '🚀',
        'subtitle': 'Découvrez PharmaGuinée et ses fonctionnalités clés',
      },
      {
        'key': 'pos',
        'label': 'Ventes (Point de Vente)',
        'icon': Icons.point_of_sale_rounded,
        'iconColor': Colors.amber,
        'emoji': '🛒',
        'subtitle': 'Comment réaliser des transactions et encaissements',
      },
      {
        'key': 'stock',
        'label': 'Stock & Médicaments',
        'icon': Icons.inventory_2_rounded,
        'iconColor': Colors.teal,
        'emoji': '📦',
        'subtitle': 'Gérer les produits, lots et alertes de rupture',
      },
      {
        'key': 'dettes',
        'label': 'Dettes & Crédits Clients',
        'icon': Icons.account_balance_wallet_rounded,
        'iconColor': Colors.indigo,
        'emoji': '💳',
        'subtitle': 'Suivre et gérer les crédits accordés aux patients',
      },
      {
        'key': 'recu',
        'label': 'Reçus & Impression PDF',
        'icon': Icons.receipt_long_rounded,
        'iconColor': Colors.blueGrey,
        'emoji': '📄',
        'subtitle': 'Imprimer et partager les factures professionnelles',
      },
      {
        'key': 'roles',
        'label': 'Rôles & Permissions',
        'icon': Icons.manage_accounts_rounded,
        'iconColor': Colors.orange,
        'emoji': '🔐',
        'subtitle': 'Comprendre les droits ADMIN et VENDEUR',
      },
      {
        'key': 'sauvegarde',
        'label': 'Sauvegarde & Restauration',
        'icon': Icons.backup_rounded,
        'iconColor': Colors.green,
        'emoji': '💾',
        'subtitle': 'Protéger et restaurer les données de la pharmacie',
      },
    ];

    showDialog(
      context: context,
      builder: (context) {
        String? selectedSection;
        return StatefulBuilder(
          builder: (context, setDocState) {
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              title: Row(
                children: [
                  if (selectedSection != null)
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded,
                          color: themeColor, size: 22),
                      onPressed: () => setDocState(() => selectedSection = null),
                      tooltip: 'Retour aux sections',
                    ),
                  if (selectedSection != null) const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: themeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSection == null
                              ? 'Documentation & Mode d\'emploi'
                              : docSections.firstWhere(
                                  (s) => s['key'] == selectedSection)['label'],
                          style: GoogleFonts.outfit(
                            color: state.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedSection != null)
                          Text(
                            docSections.firstWhere(
                                (s) => s['key'] == selectedSection)['subtitle'],
                            style: GoogleFonts.inter(
                                color: state.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 750,
                height: 580,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: selectedSection == null
                      // ── Grille des boutons de sélection ──
                      ? _buildDocSectionGrid(
                          state, docSections, themeColor,
                          (key) => setDocState(() => selectedSection = key))
                      // ── Contenu de la section sélectionnée ──
                      : _buildDocSectionContent(
                          state, selectedSection!, themeColor),
                ),
              ),
              actions: [
                if (selectedSection != null)
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: Color(0xFF10B981)),
                    label: Text(
                      'Retour',
                      style: GoogleFonts.inter(
                          color: themeColor, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => setDocState(() => selectedSection = null),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Fermer',
                    style: GoogleFonts.inter(
                      color: state.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDocSectionGrid(
    AppStateProvider state,
    List<Map<String, dynamic>> sections,
    Color themeColor,
    void Function(String key) onSelect,
  ) {
    return SingleChildScrollView(
      key: const ValueKey('grid'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              'Choisissez un module pour lire son guide complet :',
              style: GoogleFonts.inter(
                  color: state.textSecondary, fontSize: 13.5),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.6,
            ),
            itemCount: sections.length,
            itemBuilder: (context, i) {
              final s = sections[i];
              return InkWell(
                onTap: () => onSelect(s['key']),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: state.isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: state.borderTheme),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color:
                              (s['iconColor'] as Color).withOpacity(0.13),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(s['icon'] as IconData,
                            color: s['iconColor'] as Color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s['label'],
                              style: GoogleFonts.outfit(
                                color: state.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s['subtitle'],
                              style: GoogleFonts.inter(
                                color: state.textSecondary,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: state.textSecondaryLight, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocSectionContent(
      AppStateProvider state, String key, Color themeColor) {
    switch (key) {
      case 'general':
        return _buildDocGeneral(state);
      case 'pos':
        return _buildDocPOS(state);
      case 'stock':
        return _buildDocStock(state);
      case 'dettes':
        return _buildDocDettes(state);
      case 'recu':
        return _buildDocExport(state);
      case 'roles':
        return _buildDocRoles(state);
      case 'sauvegarde':
        return _buildDocSauvegarde(state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDocGeneral(AppStateProvider state) {
    return SingleChildScrollView(
      key: const ValueKey('general'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('🚀 Bienvenue sur PharmaGuinée',
              'Votre solution moderne pour gérer votre officine de pharmacie au quotidien.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'À propos de la plateforme',
            description:
                'PharmaGuinée est une application de gestion complète pour les pharmacies. Elle centralise et automatise l\'intégralité des opérations de votre officine :\n'
                '• Encaissement rapide et fiable des clients avec impression de reçus thermiques.\n'
                '• Gestion en temps réel du stock global et des alertes de rupture par seuil configurable.\n'
                '• Traçabilité absolue des ventes passées, des crédits accordés et de l\'historique complet.\n'
                '• Tableau de bord analytique avec indicateurs de performance (chiffre d\'affaires, top produits, flux de trésorerie).\n'
                '• Gestion multi-utilisateurs avec des rôles ADMIN et VENDEUR distincts.',
            icon: Icons.auto_awesome_rounded,
            iconColor: Colors.purple,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Navigation dans l\'application',
            description:
                'La barre de navigation à gauche affiche uniquement les modules auxquels vous avez accès selon votre rôle.\n'
                '• Cliquez sur un module pour l\'ouvrir directement.\n'
                '• Le titre du module actif s\'affiche en haut de la page.\n'
                '• L\'onglet actif est mémorisé : au prochain démarrage, vous revenez directement sur le dernier module consulté.\n'
                '• Sur la barre latérale, vous pouvez la réduire (icône flèche) pour gagner de l\'espace sur l\'écran.',
            icon: Icons.menu_open_rounded,
            iconColor: Colors.blue,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Gestion automatique des années',
            description:
                'Au début d\'une nouvelle année civile, l\'année de travail est mise à jour automatiquement au démarrage de l\'application.\n'
                '• Les opérations des années précédentes restent intactes et consultables.\n'
                '• Depuis le tableau de bord, vous pouvez sélectionner une année passée pour consulter ses opérations (ventes, dépenses, dettes).\n'
                '• Le catalogue produits et le stock ne sont jamais remis à zéro lors du changement d\'année.',
            icon: Icons.calendar_month_rounded,
            iconColor: Colors.orange,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Tableau de Bord',
            description:
                'Le tableau de bord affiche une vue globale de la santé financière de la pharmacie :\n'
                '• Chiffre d\'affaires du jour, de la semaine et du mois.\n'
                '• Nombre de ventes réalisées dans la période sélectionnée.\n'
                '• Alertes actives : produits en rupture de stock ou lots expirés.\n'
                '• Top 5 des produits les plus vendus et graphique d\'évolution des ventes.\n'
                '• Sélecteur d\'année pour naviguer entre les exercices.',
            icon: Icons.dashboard_rounded,
            iconColor: Colors.teal,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocPOS(AppStateProvider state) {
    return SingleChildScrollView(
      key: const ValueKey('pos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('🛒 Faire une Vente (Point de Vente)',
              'Comment réaliser des transactions rapidement et imprimer les reçus.'),
          const SizedBox(height: 16),
          _docCard(
            title: '1. Ouvrir le module POS',
            description:
                'Cliquez sur "Point de ventes" dans la barre de navigation à gauche.\n'
                'Si ce module n\'est pas visible, contactez l\'administrateur pour obtenir la permission "pos".\n'
                'L\'écran se divise en deux parties : à gauche la liste des produits disponibles, à droite le panier d\'achat.',
            icon: Icons.point_of_sale_rounded,
            iconColor: Colors.blue,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: '2. Sélectionner les produits',
            description:
                'Recherchez un produit par son nom ou scannez son code-barres dans la barre de recherche POS.\n'
                '• Cliquez sur un produit en stock pour l\'ajouter au panier. La quantité s\'incrémente automatiquement à chaque clic.\n'
                '• Les produits en rupture de stock sont grisés et non cliquables.\n'
                '• Filtrez par catégorie thérapeutique pour trouver rapidement un médicament.',
            icon: Icons.search_rounded,
            iconColor: Colors.amber,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: '3. Configurer le Panier',
            description:
                'Dans le panneau de droite, vous pouvez :\n'
                '• Ajuster la quantité de chaque ligne avec les boutons (+) et (-).\n'
                '• Supprimer un article du panier avec l\'icône poubelle.\n'
                '• Appliquer une remise globale en GNF dans le champ "Remise".\n'
                '• Saisir le nom du patient (facultatif) pour associer la vente à un client.',
            icon: Icons.shopping_basket_rounded,
            iconColor: Colors.green,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: '4. Mode de Paiement et Validation',
            description:
                'Sélectionnez le mode de paiement directement en bas du panier :\n'
                '• Espèces : saisissez le montant reçu, la monnaie à rendre est calculée automatiquement.\n'
                '• Crédit : génère automatiquement une dette dans l\'onglet Dettes associée au nom du patient.\n'
                '• Orange Money : validation électronique, aucun rendu de monnaie requis.\n\n'
                'Cliquez sur "Traiter le paiement" pour finaliser. Un reçu thermique s\'ouvre immédiatement.',
            icon: Icons.payment_rounded,
            iconColor: Colors.teal,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: '5. Après la Vente',
            description:
                'Après validation :\n'
                '• Le stock est automatiquement déduit en utilisant les lots qui expirent le plus tôt en priorité.\n'
                '• La vente apparaît dans l\'historique des ventes et dans les archives de reçus.\n'
                '• Si la vente était à crédit, la dette est visible dans le module Dettes.\n'
                '• Le tableau de bord met à jour les statistiques en temps réel.',
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.indigo,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocStock(AppStateProvider state) {
    return SingleChildScrollView(
      key: const ValueKey('stock'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('📦 Gestion des Stocks & Alertes',
              'Optimisez votre approvisionnement et évitez les ruptures ou produits périmés.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Consulter et Rechercher les Médicaments',
            description:
                'L\'onglet Stock présente l\'ensemble de vos produits avec leur prix d\'achat, prix de vente, et niveau de stock actuel.\n'
                '• Utilisez la barre de recherche pour trouver un produit par nom ou code-barres.\n'
                '• Filtrez par catégorie thérapeutique (antibiotiques, antalgiques, etc.) pour cibler un médicament.\n'
                '• Triez la liste par niveau de stock croissant pour identifier rapidement les produits à réapprovisionner.',
            icon: Icons.inventory_rounded,
            iconColor: Colors.teal,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Ajouter un Nouveau Produit',
            description:
                'Cliquez sur le bouton "Ajouter un produit" (si vous avez la permission "add_product") :\n'
                '• Renseignez le nom, la catégorie, le prix d\'achat et le prix de vente.\n'
                '• Définissez le seuil d\'alerte minimal (ex: 10 unités) pour activer les alertes de rupture.\n'
                '• Ajoutez éventuellement un code-barres, une image ou un fournisseur habituel.',
            icon: Icons.add_box_rounded,
            iconColor: Colors.green,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Gestion des Lots',
            description:
                'Chaque livraison de médicaments est enregistrée comme un lot distinct :\n'
                '• Un lot possède un numéro de lot, une date d\'expiration et une quantité.\n'
                '• L\'application suit chaque lot individuellement pour signaler les péremptions imminentes (moins de 30 jours).\n'
                '• Lors d\'une vente, les lots les plus anciens (date d\'expiration la plus proche) sont utilisés en priorité (méthode FEFO).',
            icon: Icons.view_module_rounded,
            iconColor: Colors.orange,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Alertes Automatiques',
            description:
                'L\'application vous alerte de façon proactive via des badges rouges dans la barre de navigation :\n'
                '• 🔴 Niveau faible/rupture : stock inférieur ou égal au seuil d\'alerte minimal.\n'
                '• 🟡 Produits périmés : un ou plusieurs lots d\'un produit ont dépassé leur date d\'expiration.\n'
                '• ⚠️ Péremption imminente : un lot expire dans moins de 30 jours.\n'
                'Ces alertes sont aussi visibles dans le tableau de bord pour une vue globale.',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.redAccent,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Réapprovisionnement et Fournisseurs',
            description:
                'Utilisez le module "Réapprovisionnement" pour enregistrer les nouvelles livraisons :\n'
                '• Sélectionnez le produit à réapprovisionner et spécifiez la quantité livrée.\n'
                '• Renseignez le numéro de lot et la date de péremption de la livraison.\n'
                '• Associez un fournisseur à la livraison pour une traçabilité complète.\n'
                '• Le stock du produit est automatiquement mis à jour après l\'enregistrement.',
            icon: Icons.local_shipping_rounded,
            iconColor: Colors.blue,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocDettes(AppStateProvider state) {
    return SingleChildScrollView(
      key: const ValueKey('dettes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('💳 Suivi des Dettes & Crédits Clients',
              'Gardez le contrôle sur les encaissements différés de vos clients.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Création d\'un crédit depuis le POS',
            description:
                'Lorsqu\'un client souhaite acheter à crédit :\n'
                '1. Ajoutez les produits au panier normalement.\n'
                '2. Saisissez obligatoirement le nom du patient dans le champ prévu.\n'
                '3. Sélectionnez l\'option "Crédit" dans les modes de paiement.\n'
                '4. Cliquez sur "Traiter le paiement".\n'
                'Une entrée de dette est créée automatiquement et le stock est déduit immédiatement.',
            icon: Icons.add_card_rounded,
            iconColor: Colors.indigo,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Consulter les Dettes',
            description:
                'Dans l\'onglet "Dettes", vous voyez la liste de toutes les dettes de l\'année sélectionnée :\n'
                '• Nom du patient débiteur, montant dû, date de la vente à crédit.\n'
                '• Statut : Impayée (rouge) ou Réglée (vert).\n'
                '• Filtrez par statut pour n\'afficher que les dettes en cours.\n'
                '• Le total des dettes impayées est affiché en haut de l\'onglet.',
            icon: Icons.list_alt_rounded,
            iconColor: Colors.blue,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Marquer une Dette comme Réglée',
            description:
                'Lorsqu\'un patient rembourse sa dette :\n'
                '• Trouvez la dette dans la liste (recherchez par nom du patient).\n'
                '• Cliquez sur le bouton "Marquer comme Réglée" ou cochez la case de paiement.\n'
                '• Le statut passe à "Réglé" et la dette disparaît des dettes en cours.\n'
                '• Cette action est enregistrée dans le journal d\'audit.',
            icon: Icons.price_check_rounded,
            iconColor: Colors.green,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Rappel des Dettes des Années Précédentes',
            description:
                'Après le passage à une nouvelle année, un bandeau jaune apparaît en haut du tableau de bord si une dette d\'une année précédente reste impayée.\n'
                '• Le message indique le montant total des dettes en souffrance.\n'
                '• Vous pouvez masquer ce message pour la journée en cliquant sur "Ignorer".\n'
                '• Il réapparaît automatiquement le lendemain tant que la dette n\'est pas réglée.\n'
                '• Changez l\'année dans le tableau de bord pour consulter et régler ces anciennes dettes.',
            icon: Icons.notification_important_rounded,
            iconColor: Colors.amber,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocExport(AppStateProvider state) {
    return SingleChildScrollView(
      key: const ValueKey('recu'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('📄 Gestion des Reçus, Impression et Partages',
              'Imprimez et partagez les reçus professionnels de vos clients.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Aperçu Virtuel Thermique',
            description:
                'Chaque validation de vente ouvre automatiquement un reçu virtuel compact au format thermique (80mm).\n'
                '• Il affiche le nom de la pharmacie, l\'adresse, la date et l\'heure de la vente.\n'
                '• La liste des produits vendus avec les quantités, prix unitaires et total.\n'
                '• Le montant total, la remise éventuelle, le mode de paiement et la monnaie rendue.\n'
                '• La mise en page respecte les standards des tickets de caisse thermiques.',
            icon: Icons.receipt_rounded,
            iconColor: Colors.blueGrey,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Impression Directe (Imprimante Physique)',
            description:
                'Pour imprimer le reçu sur votre imprimante thermique :\n'
                '• Cliquez sur le bouton "Imprimer Facture" dans la fenêtre du reçu.\n'
                '• Le gestionnaire d\'impression système s\'ouvre avec le document préformaté.\n'
                '• Sélectionnez votre imprimante thermique et validez.\n'
                '• Assurez-vous que l\'imprimante est connectée et que le pilote est installé.',
            icon: Icons.print_rounded,
            iconColor: Colors.green,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Exporter au Format PDF',
            description:
                'Pour sauvegarder une facture au format PDF :\n'
                '• Cliquez sur "Exporter" dans la fenêtre du reçu.\n'
                '• Choisissez l\'emplacement de sauvegarde sur votre ordinateur.\n'
                '• Le fichier PDF est généré et enregistré instantanément.\n'
                '• Vous pouvez ensuite envoyer ce fichier par e-mail ou messagerie.',
            icon: Icons.picture_as_pdf_rounded,
            iconColor: Colors.redAccent,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Retrouver les Anciens Reçus',
            description:
                'Tous les reçus sont archivés dans le module "Archives Reçu" :\n'
                '• Recherchez par date, nom du patient ou montant.\n'
                '• Cliquez sur une vente archivée pour rouvrir et réimprimer son reçu.\n'
                '• L\'historique des ventes dans "Historique des Ventes" offre une vue tabulaire complète.\n'
                '• Les rapports de ventes résument les performances par période.',
            icon: Icons.archive_rounded,
            iconColor: Colors.orange,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocRoles(AppStateProvider state) {
    return SingleChildScrollView(
      key: const ValueKey('roles'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('🔐 Rôles & Permissions',
              'Comprendre les droits d\'accès de l\'ADMIN et des VENDEURS.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Rôle ADMIN — Accès Complet',
            description:
                'L\'administrateur a un accès illimité à tous les modules de l\'application :\n'
                '• Tableau de bord, Point de Vente, Stock, Rapports, Archives.\n'
                '• Dettes, Réapprovisionnement, Fournisseurs, Historique des ventes.\n'
                '• Gestion des Comptes Vendeurs : créer, modifier, supprimer des comptes.\n'
                '• Paramètres : nom de la pharmacie, logo, code PIN, sauvegarde/restauration.\n'
                '• Dépenses : enregistrer et consulter les charges de la pharmacie.\n'
                '• Consulter les ventes réalisées par chaque vendeur individuellement.',
            icon: Icons.admin_panel_settings_rounded,
            iconColor: const Color(0xFFF59E0B),
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Rôle VENDEUR — Accès Limité par Permissions',
            description:
                'Un compte vendeur ne peut accéder qu\'aux modules autorisés par l\'administrateur.\n'
                'Chaque permission est activée ou désactivée individuellement :\n'
                '• "Tableau de bord" — voir les statistiques générales.\n'
                '• "Point de Vente (POS)" — effectuer des ventes et encaissements.\n'
                '• "Ajouter un produit" — ajouter de nouveaux médicaments au catalogue.\n'
                '• "Nouveaux médicaments" — consulter et modifier le stock.\n'
                '• "Rapports des Ventes" — consulter les rapports analytiques.\n'
                '• "Archives Reçu" — accéder aux factures passées.\n'
                '• "Dettes" — voir et gérer les crédits clients.\n'
                '• "Réapprovisionnement" — enregistrer les nouvelles livraisons.\n'
                '• "Fournisseurs" — gérer la liste des fournisseurs.\n'
                '• "Historique des Ventes" — consulter l\'historique complet.',
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF10B981),
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Créer un Compte Vendeur (Nombre illimité)',
            description:
                'Seul l\'ADMIN peut créer et gérer les comptes vendeurs (ajout illimité, autant de vendeurs que désiré) :\n'
                '1. Ouvrez le module "Gestion des Comptes" dans la barre de navigation.\n'
                '2. Cliquez sur "Ajouter un Vendeur".\n'
                '3. Renseignez l\'identifiant (unique), le nom complet, l\'email et le mot de passe.\n'
                '4. Cochez les permissions que le vendeur doit avoir.\n'
                '5. Cliquez sur "Créer le Compte".\n'
                'Le vendeur peut maintenant se connecter avec ses identifiants.',
            icon: Icons.person_add_rounded,
            iconColor: Colors.blue,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Connexion et Sécurité',
            description:
                'Chaque utilisateur se connecte avec son identifiant et son mot de passe.\n'
                '• Un code PIN à 4 chiffres peut être défini pour un verrouillage rapide.\n'
                '• L\'administrateur peut réinitialiser le mot de passe d\'un vendeur à tout moment.\n'
                '• En cas d\'inactivité prolongée, l\'application peut demander de ressaisir le PIN.\n'
                '• Toutes les actions importantes sont tracées dans le journal d\'audit.',
            icon: Icons.lock_outline_rounded,
            iconColor: Colors.redAccent,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocSauvegarde(AppStateProvider state) {
    return SingleChildScrollView(
      key: const ValueKey('sauvegarde'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('💾 Sauvegarde & Restauration',
              'Protégez vos données et restaurez-les en cas de besoin.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Pourquoi Sauvegarder ?',
            description:
                'Les données de PharmaGuinée sont stockées localement sur votre ordinateur dans une base SQLite.\n'
                '• En cas de panne matérielle, de virus ou de formatage, les données peuvent être perdues.\n'
                '• La sauvegarde régulière est la seule protection contre la perte de données.\n'
                '• Recommandé : effectuer une sauvegarde au minimum une fois par semaine, idéalement chaque jour de clôture.',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Effectuer une Sauvegarde',
            description:
                'Dans le module "Paramètres" (accessible uniquement à l\'ADMIN) :\n'
                '1. Cliquez sur le bouton "Exporter la Sauvegarde".\n'
                '2. Choisissez l\'emplacement de sauvegarde (clé USB, dossier réseau, etc.).\n'
                '3. Un fichier JSON contenant toutes les données est généré instantanément.\n'
                'Ce fichier contient : tous les produits, ventes, dettes, fournisseurs, utilisateurs et paramètres.',
            icon: Icons.backup_rounded,
            iconColor: Colors.green,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Restaurer une Sauvegarde',
            description:
                'Pour restaurer une sauvegarde précédente :\n'
                '1. Dans "Paramètres", cliquez sur "Restaurer depuis une Sauvegarde".\n'
                '2. Sélectionnez le fichier de sauvegarde JSON sur votre ordinateur.\n'
                '3. L\'application vérifie la validité du fichier avant tout remplacement.\n'
                '4. Confirmez la restauration (les données actuelles seront remplacées).\n'
                '⚠️ Attention : la restauration est irréversible. Les données actuelles seront remplacées par celles de la sauvegarde.',
            icon: Icons.restore_rounded,
            iconColor: Colors.blue,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Bonnes Pratiques',
            description:
                '• Conservez toujours une copie de sauvegarde sur un support EXTERNE à l\'ordinateur (clé USB, disque dur externe, cloud).\n'
                '• Ne jamais modifier directement le fichier SQLite pendant que l\'application est ouverte.\n'
                '• Tester périodiquement la restauration d\'une sauvegarde pour vérifier qu\'elle est valide.\n'
                '• Fermer normalement l\'application avant de déplacer ou copier la base de données.\n'
                '• En cas de mise à jour Windows, l\'ancienne base est automatiquement migrée vers le nouvel emplacement.',
            icon: Icons.tips_and_updates_rounded,
            iconColor: Colors.teal,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _docSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF10B981)),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12.5, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _docCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required AppStateProvider state,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: state.isDarkMode
            ? const Color(0xFF1E293B)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: state.borderTheme),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: state.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: state.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DIALOG PROFIL UTILISATEUR CONNECTÉ
  // ==========================================
  void _showProfileDialog(BuildContext context, AppStateProvider state) {
    const themeColor = Color(0xFF10B981);
    final formKey = GlobalKey<FormState>();

    // Pré-remplir avec les données actuelles de l'utilisateur
    final currentUser = state.users.firstWhere(
      (u) => u.username == state.currentUsername,
      orElse: () => UserAccount(
          username: state.currentUsername, role: state.currentUserRole),
    );

    final nameCtrl = TextEditingController(text: currentUser.fullName);
    final emailCtrl = TextEditingController(text: currentUser.email);
    final phoneCtrl = TextEditingController(text: state.pharmacyContact1);
    final passCtrl = TextEditingController();
    bool obscurePass = true;
    Uint8List? newProfileImageBytes;
    String? newProfileImageBase64;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasImg = newProfileImageBase64 != '' &&
                (newProfileImageBytes != null ||
                    (currentUser.profileImageBase64 != null &&
                        currentUser.profileImageBase64!.isNotEmpty));
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: themeColor.withOpacity(0.15),
                    backgroundImage: (() {
                      if (newProfileImageBase64 == '') return null;
                      if (newProfileImageBytes != null)
                        return MemoryImage(newProfileImageBytes!);
                      if (currentUser.profileImageBase64 != null &&
                          currentUser.profileImageBase64!.isNotEmpty) {
                        try {
                          return MemoryImage(
                              base64Decode(currentUser.profileImageBase64!));
                        } catch (_) {}
                      }
                      return null;
                    })(),
                    child: hasImg
                        ? null
                        : Text(
                            state.currentUsername.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.outfit(
                                color: themeColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mon Profil',
                            style: GoogleFonts.outfit(
                                color: state.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_rounded,
                                color: themeColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              state.currentUsername,
                              style: GoogleFonts.inter(
                                  color: state.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (state.currentUserRole == 'ADMIN'
                                        ? const Color(0xFFF59E0B)
                                        : themeColor)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                state.currentUserRole,
                                style: GoogleFonts.inter(
                                  color: state.currentUserRole == 'ADMIN'
                                      ? const Color(0xFFF59E0B)
                                      : themeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Photo de Profil
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: state.bgPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: themeColor.withOpacity(0.3),
                                      width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: (() {
                                  if (newProfileImageBase64 == '') {
                                    return Icon(Icons.person_rounded,
                                        color: themeColor.withOpacity(0.7),
                                        size: 40);
                                  }
                                  if (newProfileImageBytes != null) {
                                    return Image.memory(newProfileImageBytes!,
                                        fit: BoxFit.cover);
                                  }
                                  if (currentUser.profileImageBase64 != null &&
                                      currentUser
                                          .profileImageBase64!.isNotEmpty) {
                                    try {
                                      return Image.memory(
                                          base64Decode(
                                              currentUser.profileImageBase64!),
                                          fit: BoxFit.cover);
                                    } catch (e) {
                                      debugPrint('Error decoding base64: $e');
                                    }
                                  }
                                  return Icon(Icons.person_rounded,
                                      color: themeColor.withOpacity(0.7),
                                      size: 40);
                                })(),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final result = await FilePicker.pickFiles(
                                      type: FileType.image, withData: true);
                                  if (result != null &&
                                      result.files.single.bytes != null) {
                                    setDialogState(() {
                                      newProfileImageBytes =
                                          result.files.single.bytes;
                                      newProfileImageBase64 =
                                          base64Encode(newProfileImageBytes!);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: state.bgSecondary, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (newProfileImageBase64 != '' &&
                            (newProfileImageBytes != null ||
                                (currentUser.profileImageBase64 != null &&
                                    currentUser
                                        .profileImageBase64!.isNotEmpty)))
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  newProfileImageBytes = null;
                                  newProfileImageBase64 = '';
                                });
                              },
                              child: const Text('Retirer la photo',
                                  style: TextStyle(
                                      color: Colors.redAccent, fontSize: 12)),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Nom complet
                        Text('Nom complet',
                            style: GoogleFonts.inter(
                                color: state.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameCtrl,
                          style: GoogleFonts.inter(color: state.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgPrimary,
                            hintText: 'Votre nom complet',
                            hintStyle: GoogleFonts.inter(
                                color: state.textSecondaryLight),
                            prefixIcon: Icon(Icons.badge_outlined,
                                color: state.textSecondaryLight, size: 18),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: themeColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email
                        Text('Email',
                            style: GoogleFonts.inter(
                                color: state.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(color: state.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgPrimary,
                            hintText: 'votre@email.com',
                            hintStyle: GoogleFonts.inter(
                                color: state.textSecondaryLight),
                            prefixIcon: Icon(Icons.email_outlined,
                                color: state.textSecondaryLight, size: 18),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: themeColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Numéro de téléphone
                        Text('Numéro de téléphone',
                            style: GoogleFonts.inter(
                                color: state.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.inter(color: state.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgPrimary,
                            hintText: '622000000',
                            hintStyle: GoogleFonts.inter(
                                color: state.textSecondaryLight),
                            prefixIcon: Icon(Icons.phone_rounded,
                                color: state.textSecondaryLight, size: 18),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: themeColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Nouveau mot de passe
                        Text(
                            'Nouveau mot de passe (laisser vide pour ne pas changer)',
                            style: GoogleFonts.inter(
                                color: state.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: obscurePass,
                          style: GoogleFonts.inter(color: state.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgPrimary,
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(
                                color: state.textSecondaryLight),
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                color: state.textSecondaryLight, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: state.textSecondaryLight,
                                size: 18,
                              ),
                              onPressed: () => setDialogState(
                                  () => obscurePass = !obscurePass),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: themeColor, width: 1.5),
                            ),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 4) {
                              return 'Minimum 4 caractères';
                            }
                            return null;
                          },
                        ),

                        // Permissions (pour VENDEUR uniquement)
                        if (state.currentUserRole == 'VENDEUR') ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: themeColor.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.shield_outlined,
                                      color: themeColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Vos droits d\'accès',
                                      style: GoogleFonts.inter(
                                          color: themeColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ]),
                                const SizedBox(height: 8),
                                _permRow(
                                  currentUser.permissions.contains('dashboard')
                                      ? '✓'
                                      : '✗',
                                  'Tableau de bord',
                                  state,
                                  denied: !currentUser.permissions
                                      .contains('dashboard'),
                                ),
                                _permRow(
                                  currentUser.permissions.contains('pos')
                                      ? '✓'
                                      : '✗',
                                  'Point de ventes (POS)',
                                  state,
                                  denied:
                                      !currentUser.permissions.contains('pos'),
                                ),
                                _permRow(
                                  currentUser.permissions.contains('archives')
                                      ? '✓'
                                      : '✗',
                                  'Archives reçu',
                                  state,
                                  denied: !currentUser.permissions
                                      .contains('archives'),
                                ),
                                _permRow(
                                  (currentUser.permissions
                                              .contains('add_product') ||
                                          currentUser.permissions
                                              .contains('new_medicines') ||
                                          currentUser.permissions
                                              .contains('replenish'))
                                      ? '✓'
                                      : '✗',
                                  'Stock / Inventaire',
                                  state,
                                  denied: !(currentUser.permissions
                                          .contains('add_product') ||
                                      currentUser.permissions
                                          .contains('new_medicines') ||
                                      currentUser.permissions
                                          .contains('replenish')),
                                ),
                                _permRow(
                                  currentUser.permissions.contains('suppliers')
                                      ? '✓'
                                      : '✗',
                                  'Fournisseurs',
                                  state,
                                  denied: !currentUser.permissions
                                      .contains('suppliers'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Annuler',
                      style:
                          GoogleFonts.inter(color: state.textSecondaryLight)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: Text('Enregistrer',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      state.updateCurrentUserProfile(
                        fullName: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        newPassword:
                            passCtrl.text.isNotEmpty ? passCtrl.text : null,
                        profileImageBase64: newProfileImageBase64,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profil mis à jour avec succès !',
                              style: GoogleFonts.inter()),
                          backgroundColor: themeColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _permRow(String mark, String label, AppStateProvider state,
      {bool denied = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(mark,
              style: GoogleFonts.inter(
                  color: denied ? Colors.redAccent : const Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.inter(
                  color:
                      denied ? state.textSecondaryLight : state.textSecondary,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (_nameController.text != state.pharmacyName &&
        !_nameFocusNode.hasFocus) {
      _nameController.text = state.pharmacyName;
    }
    if (!_multiplierFocusNode.hasFocus) {
      final currentM = state.priceMultiplier > 0 ? state.priceMultiplier : 1.4;
      final formattedM = (currentM % 1 == 0)
          ? currentM.toInt().toString()
          : currentM.toString();
      if (_multiplierController.text.isEmpty) {
        _multiplierController.text = formattedM;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).dividerTheme.color ??
                    Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Configuration de la Pharmacie',
                      style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: state.textPrimary)),
                  IconButton(
                    icon: Icon(Icons.close, color: state.textSecondary),
                    tooltip: 'Fermer',
                    onPressed: () => state.setActiveTab(0),
                  )
                ],
              ),
              SizedBox(height: 24),
              TextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                style: TextStyle(color: state.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Nom de la Pharmacie',
                  labelStyle: TextStyle(color: state.textSecondary),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  final adminUser = state.users.firstWhere(
                    (u) => u.role == 'ADMIN',
                    orElse: () => UserAccount(username: '', role: 'ADMIN'),
                  );
                  state.registerPharmacy(
                    name: val,
                    quartier: state.pharmacyQuartier,
                    adminFullName: adminUser.fullName,
                    username: adminUser.username.isNotEmpty
                        ? adminUser.username
                        : state.pharmacyPinCode,
                    password: state.pharmacyPassword,
                    pinCode: state.pharmacyPinCode,
                    contact1: state.pharmacyContact1,
                    contact2: state.pharmacyContact2,
                  );
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: _subtitleController,
                focusNode: _subtitleFocusNode,
                style: TextStyle(color: state.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Sous-titre / Description',
                  labelStyle: TextStyle(color: state.textSecondary),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setState(() => _pharmacySubtitle = val);
                },
              ),
              SizedBox(height: 24),
              Text('Tarification & Marges',
                  style: GoogleFonts.inter(
                      color: state.textPrimary, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                'Définissez le coefficient de multiplication pour calculer automatiquement le prix de vente à partir du prix d\'achat (Exemple: 1.4).',
                style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _multiplierController,
                focusNode: _multiplierFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: state.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Coefficient de multiplication (ex: 1.4)',
                  labelStyle: TextStyle(color: state.textSecondary),
                  hintText: '1.4',
                  prefixIcon: const Icon(Icons.calculate_rounded, color: Color(0xFF10B981)),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 32),
              Text('Logo / Image de la Pharmacie',
                  style: GoogleFonts.inter(
                      color: state.textPrimary, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Row(
                children: [
                  if (_pharmacyLogoBytes != null)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child:
                          Image.memory(_pharmacyLogoBytes!, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.15),
                          shape: BoxShape.circle),
                      child: Icon(Icons.local_pharmacy_rounded,
                          color: Color(0xFF10B981), size: 40),
                    ),
                  SizedBox(width: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result != null && result.files.single.bytes != null) {
                        final adminUser = state.users.firstWhere(
                          (u) => u.role == 'ADMIN',
                          orElse: () =>
                              UserAccount(username: '', role: 'ADMIN'),
                        );
                        state.registerPharmacy(
                          name: state.pharmacyName,
                          quartier: state.pharmacyQuartier,
                          adminFullName: adminUser.fullName,
                          username: adminUser.username.isNotEmpty
                              ? adminUser.username
                              : state.pharmacyPinCode,
                          password: state.pharmacyPassword,
                          pinCode: state.pharmacyPinCode,
                          contact1: state.pharmacyContact1,
                          contact2: state.pharmacyContact2,
                          logo: result.files.single.bytes,
                        );
                      }
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text('Importer un logo...'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  if (_pharmacyLogoBytes != null) ...[
                    SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        final adminUser = state.users.firstWhere(
                          (u) => u.role == 'ADMIN',
                          orElse: () =>
                              UserAccount(username: '', role: 'ADMIN'),
                        );
                        state.registerPharmacy(
                          name: state.pharmacyName,
                          quartier: state.pharmacyQuartier,
                          adminFullName: adminUser.fullName,
                          username: adminUser.username.isNotEmpty
                              ? adminUser.username
                              : state.pharmacyPinCode,
                          password: state.pharmacyPassword,
                          pinCode: state.pharmacyPinCode,
                          contact1: state.pharmacyContact1,
                          contact2: state.pharmacyContact2,
                          logo: null,
                        );
                      },
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      label: Text('Retirer',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ]
                ],
              ),
              SizedBox(height: 32),
              Text('Licence de l’application',
                  style: GoogleFonts.inter(
                      color: state.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (state.isLicensed ? Colors.green : Colors.amber)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: (state.isLicensed ? Colors.green : Colors.amber)
                          .withOpacity(0.25)),
                ),
                child: Row(children: [
                  Icon(
                      state.isLicensed
                          ? Icons.verified_rounded
                          : Icons.vpn_key_rounded,
                      color: state.isLicensed ? Colors.green : Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          state.isLicensed
                              ? 'Licence activée définitivement'
                              : 'Mode test — ${state.trialDaysRemaining} jour(s) restant(s)',
                          style: GoogleFonts.inter(
                              color: state.textPrimary,
                              fontWeight: FontWeight.w600))),
                  if (!state.isLicensed)
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showLicenseActivationDialog(context, state),
                      icon: const Icon(Icons.key_rounded, size: 17),
                      label: const Text('Activer la licence'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white),
                    ),
                ]),
              ),
              SizedBox(height: 32),
              Text('Confidentialité des Rapports',
                  style: GoogleFonts.inter(
                      color: state.textPrimary, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              SwitchListTile(
                title: Text('Masquer les revenus totaux',
                    style: TextStyle(
                        color: state.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'Désactive l\'affichage des montants de chiffre d\'affaires (Jour, Mois, Année) dans le tableau de bord et les rapports pour éviter les regards indiscrets.',
                    style: TextStyle(color: state.textSecondary, fontSize: 12)),
                value: state.maskRevenues,
                onChanged: (val) {
                  state.setMaskRevenues(val);
                },
                activeColor: Color(0xFF10B981),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Text('Sauvegarde des données',
                  style: GoogleFonts.inter(
                      color: state.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Créez une copie complète des données de la pharmacie ou restaurez une sauvegarde existante.',
                style:
                    GoogleFonts.inter(color: state.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isBackingUp ? null : () => _backupData(state),
                    icon: _isBackingUp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(_isBackingUp
                        ? 'Sauvegarde en cours...'
                        : 'Sauvegarder les données'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _isRestoring ? null : () => _restoreData(state),
                    icon: _isRestoring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restore_rounded, size: 18),
                    label: Text(_isRestoring
                        ? 'Restauration en cours...'
                        : 'Restaurer les données'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: state.textPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final adminUser = state.users.firstWhere(
                        (u) => u.role == 'ADMIN',
                        orElse: () => UserAccount(username: '', role: 'ADMIN'),
                      );
                      state.registerPharmacy(
                        name: _nameController.text.trim(),
                        quartier: state.pharmacyQuartier,
                        adminFullName: adminUser.fullName,
                        username: adminUser.username.isNotEmpty
                            ? adminUser.username
                            : state.pharmacyPinCode,
                        password: state.pharmacyPassword,
                        pinCode: state.pharmacyPinCode,
                        contact1: state.pharmacyContact1,
                        contact2: state.pharmacyContact2,
                      );

                      final multText = _multiplierController.text.replaceAll(',', '.').trim();
                      final double? multVal = double.tryParse(multText);
                      if (multVal != null && multVal > 0) {
                        state.setPriceMultiplier(multVal);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Paramètres enregistrés avec succès !'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Enregistrer',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => state.setActiveTab(0),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Fermer'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: state.textPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _backupData(AppStateProvider state) async {
    setState(() => _isBackingUp = true);
    try {
      final backup = await state.backupDatabase();
      if (backup.isEmpty) throw Exception('La sauvegarde est vide.');

      final now = DateTime.now();
      String twoDigits(int value) => value.toString().padLeft(2, '0');
      final fileName = 'pharmaguinee_sauvegarde_'
          '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}_'
          '${twoDigits(now.hour)}${twoDigits(now.minute)}.json';
      final outputPath = await FilePicker.saveFile(
        dialogTitle: 'Enregistrer la sauvegarde',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (outputPath == null) return;

      await File(outputPath).writeAsString(backup, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Sauvegarde créée avec succès.'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Échec de la sauvegarde : $error'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreData(AppStateProvider state) async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Choisir une sauvegarde',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || !mounted) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Restaurer les données ?'),
            content: const Text(
              'Les données actuelles seront remplacées par celles de la sauvegarde sélectionnée. Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text('Restaurer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _isRestoring = true);
    try {
      final pickedFile = result.files.single;
      final backup = pickedFile.bytes != null
          ? utf8.decode(pickedFile.bytes!)
          : await File(pickedFile.path!).readAsString();
      final success = await state.restoreDatabase(backup);
      if (!success)
        throw const FormatException('Fichier de sauvegarde invalide.');

      if (!mounted) return;
      _nameController.text = state.pharmacyName;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Données restaurées avec succès.'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Échec de la restauration : $error'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  // ignore: unused_element
  void _showMontantsDialog(BuildContext context, dynamic state) {
    showDialog(
      context: context,
      builder: (context) {
        double todaySalesVal = 0.0;
        // ignore: unused_local_variable
        int todaySalesCount = 0;
        final now = state.workingDate;
        for (var sale in state.sales) {
          if (sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day) {
            todaySalesVal += sale.netAmount;
            todaySalesCount++;
          }
        }

        final stockValue = state.lots.fold(0.0, (sum, l) {
          final prod = state.products.where((p) => p.id == l.productId);
          if (prod.isNotEmpty)
            return sum + prod.first.purchasePrice * l.quantity;
          return sum;
        });

        final currencyFmt = NumberFormat.currency(
            locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);

        return DefaultTabController(
          length: 3,
          child: AlertDialog(
            backgroundColor: state.bgSecondary,
            insetPadding: const EdgeInsets.all(24),
            title: Row(
              children: [
                Icon(Icons.archive_rounded, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text(
                  'Archives des Reçus & Factures',
                  style: GoogleFonts.outfit(
                      color: state.textPrimary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 650,
              height: 520,
              child: Column(
                children: [
                  // KPI Cards Row
                  Row(
                    children: [
                      // Valeur du Stock Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: state.bgPrimary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Color(0xFF06B6D4).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valeur du Stock',
                                    style: GoogleFonts.inter(
                                        color: state.textSecondary,
                                        fontSize: 10),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    state.maskRevenues
                                        ? '**** GNF'
                                        : currencyFmt.format(stockValue),
                                    style: GoogleFonts.outfit(
                                        color: Color(0xFF06B6D4),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF06B6D4).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inventory_2_rounded,
                                    color: Color(0xFF06B6D4), size: 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Ventes du Jour Card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: state.bgPrimary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ventes du Jour',
                                    style: GoogleFonts.inter(
                                        color: state.textSecondary,
                                        fontSize: 10),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    state.maskRevenues
                                        ? '**** GNF'
                                        : currencyFmt.format(todaySalesVal),
                                    style: GoogleFonts.outfit(
                                        color: Color(0xFF10B981),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF10B981).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.monetization_on_rounded,
                                    color: Color(0xFF10B981), size: 24),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Tabbar Header for History
                  TabBar(
                    tabs: const [
                      Tab(text: 'Ventes Aujourd\'hui'),
                      Tab(text: 'Ce Mois'),
                      Tab(text: 'Cette Année'),
                    ],
                    labelColor: Color(0xFF10B981),
                    unselectedLabelColor: state.textSecondary,
                    indicatorColor: Color(0xFF10B981),
                  ),
                  SizedBox(height: 12),

                  // Tabbar View
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSalesTab(state, 'day'),
                        _buildSalesTab(state, 'month'),
                        _buildSalesTab(state, 'year'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer',
                    style: GoogleFonts.inter(color: state.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesTab(dynamic state, String period) {
    final now = state.workingDate;
    final sales = state.sales.where((s) {
      if (period == 'day')
        return s.date.year == now.year &&
            s.date.month == now.month &&
            s.date.day == now.day;
      if (period == 'month')
        return s.date.year == now.year && s.date.month == now.month;
      return s.date.year == now.year;
    }).toList();

    double total = sales.fold(0.0, (sum, s) => sum + s.netAmount);
    final fmt =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);

    if (sales.isEmpty) {
      return Center(
        child: Text('Aucune vente pour cette période.',
            style: GoogleFonts.inter(color: state.textSecondary)),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Color(0xFF064E3B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${sales.length} ventes',
                  style: GoogleFonts.inter(
                      color: state.textSecondary, fontSize: 12)),
              Text(
                  'Total: ${state.maskRevenues ? '**** GNF' : fmt.format(total)}',
                  style: GoogleFonts.outfit(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: sales.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, i) {
              final s = sales[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.receipt_rounded,
                        color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(s.date),
                            style: GoogleFonts.inter(
                                color: state.textPrimary, fontSize: 12),
                          ),
                          Text(
                            '${s.items.length} article(s) — ${s.paymentMethod}',
                            style: GoogleFonts.inter(
                                color: state.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(
                        state.maskRevenues
                            ? '**** GNF'
                            : fmt.format(s.netAmount),
                        style: GoogleFonts.outfit(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.keyboard_return_rounded,
                          color: Colors.orangeAccent, size: 16),
                      tooltip: 'Retour / Remboursement',
                      onPressed: () => _showRefundDialog(s),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.print_rounded,
                          color: Color(0xFF10B981), size: 16),
                      tooltip: 'Imprimer la facture',
                      onPressed: () => _printInvoice(s),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRefundDialog(Sale sale) {
    final fmt =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);
    final Map<String, Map<String, dynamic>> returnData = {};
    for (var item in sale.items) {
      returnData[item.productId] = {
        'selected': false,
        'quantity': 1,
        'maxQuantity': item.quantity,
        'unitPrice': item.unitPrice,
        'name': item.productName,
      };
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double totalRefund = 0.0;
            returnData.forEach((key, val) {
              if (val['selected'] == true) {
                totalRefund +=
                    (val['quantity'] as int) * (val['unitPrice'] as double);
              }
            });

            return AlertDialog(
              backgroundColor: state.bgSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.keyboard_return_rounded,
                      color: Colors.orangeAccent, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Retour & Remboursement',
                    style: GoogleFonts.inter(
                      color: state.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Sélectionnez les produits à retourner pour la facture ${sale.id} :',
                      style: GoogleFonts.inter(
                          color: state.textSecondary, fontSize: 13),
                    ),
                    SizedBox(height: 16),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: sale.items.map((item) {
                          final data = returnData[item.productId]!;
                          final isSelected = data['selected'] as bool;
                          final currentQty = data['quantity'] as int;
                          final maxQty = data['maxQuantity'] as int;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: state.bgPrimary.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orangeAccent.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.04),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  activeColor: Colors.orangeAccent,
                                  value: isSelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      data['selected'] = val ?? false;
                                    });
                                  },
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: GoogleFonts.inter(
                                          color: state.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        'Acheté: ${item.quantity} • ${fmt.format(item.unitPrice)} GNF',
                                        style: GoogleFonts.inter(
                                          color: state.textSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected) ...[
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline,
                                            color: Colors.orangeAccent,
                                            size: 20),
                                        onPressed: currentQty > 1
                                            ? () {
                                                setDialogState(() {
                                                  data['quantity'] =
                                                      currentQty - 1;
                                                });
                                              }
                                            : null,
                                      ),
                                      Text(
                                        '$currentQty',
                                        style: GoogleFonts.inter(
                                          color: state.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle_outline,
                                            color: Colors.orangeAccent,
                                            size: 20),
                                        onPressed: currentQty < maxQty
                                            ? () {
                                                setDialogState(() {
                                                  data['quantity'] =
                                                      currentQty + 1;
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Divider(color: Colors.white.withOpacity(0.08)),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL À REMBOURSER :',
                          style: GoogleFonts.inter(
                            color: state.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${fmt.format(totalRefund)} GNF',
                          style: GoogleFonts.outfit(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Annuler',
                      style: GoogleFonts.inter(color: state.textSecondary)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: totalRefund <= 0
                      ? null
                      : () {
                          final List<Map<String, dynamic>> itemsToReturn = [];
                          returnData.forEach((productId, value) {
                            if (value['selected'] == true) {
                              itemsToReturn.add({
                                'productId': productId,
                                'quantity': value['quantity'],
                              });
                            }
                          });

                          state.processItemsRefund(
                            saleId: sale.id,
                            itemsToReturn: itemsToReturn,
                          );

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Remboursement traité avec succès !'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        },
                  child: Text('Confirmer le Retour',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _printInvoice(Sale sale) async {
    await InvoicePrinter.printInvoice(
      sale,
      state.pharmacyLogo,
      pharmacyName: state.pharmacyName,
      quartier: state.pharmacyQuartier,
      contact1: state.pharmacyContact1,
      contact2: state.pharmacyContact2,
    );
  }

  void _showLicenseActivationDialog(
      BuildContext context, AppStateProvider state) {
    final licenseController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? errorMessage;
    bool isLoading = false;
    bool obscureText = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            const themeColor = Color(0xFF10B981);
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.vpn_key_rounded,
                        color: themeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Activation de la Licence',
                    style: GoogleFonts.outfit(
                      color: state.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    icon:
                        Icon(Icons.close, color: state.textSecondary, size: 20),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Saisissez votre clé de licence pour activer PharmaGuinée de façon définitive et masquer le bouton d\'activation.',
                        style: GoogleFonts.inter(
                          color: state.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: licenseController,
                        obscureText: obscureText,
                        inputFormatters: const [LicenseKeyFormatter()],
                        textCapitalization: TextCapitalization.characters,
                        style: GoogleFonts.inter(
                            color: state.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'XXXX-XXXX-XXXX-XXXX',
                          hintStyle: GoogleFonts.inter(
                              color: state.textSecondaryLight, fontSize: 13),
                          prefixIcon: Icon(Icons.key_rounded,
                              color: state.textSecondaryLight, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureText
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: state.textSecondaryLight,
                              size: 18,
                            ),
                            onPressed: () => setDialogState(
                                () => obscureText = !obscureText),
                          ),
                          filled: true,
                          fillColor: state.bgPrimary,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: state.borderTheme),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: themeColor, width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir votre clé de licence';
                          }
                          return null;
                        },
                      ),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.redAccent.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.inter(
                        color: state.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isLoading = true;
                            errorMessage = null;
                          });

                          // Simuler un léger chargement premium
                          await Future.delayed(
                              const Duration(milliseconds: 800));

                          final isValid = await state
                              .validateLicense(licenseController.text);

                          if (isValid) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Licence activée avec succès ! Merci pour votre confiance.',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: themeColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage =
                                  'Clé de licence invalide. Veuillez réessayer.';
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Activer',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
