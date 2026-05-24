import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../models/pharmacy_models.dart';
import '../providers/app_state_provider.dart';
import '../utils/invoice_printer.dart';
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
  late final FocusNode _nameFocusNode;
  late final FocusNode _subtitleFocusNode;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    _nameController = TextEditingController(text: appState.pharmacyName);
    _subtitleController = TextEditingController(text: _pharmacySubtitle);
    _nameFocusNode = FocusNode();
    _subtitleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subtitleController.dispose();
    _nameFocusNode.dispose();
    _subtitleFocusNode.dispose();
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
      {'index': 0,  'title': 'Tableau de bord',        'icon': Icons.dashboard_rounded,              'group': 'Accueil'},
      {'index': 2,  'title': 'Point de ventes',        'icon': Icons.point_of_sale_rounded,          'group': 'Ventes'},
      {'index': 1,  'title': 'Stocks des médicaments', 'icon': Icons.inventory_2_rounded,            'group': 'Stock'},
      {'index': 10, 'title': 'Rapport de ventes',      'icon': Icons.analytics_rounded,              'group': 'Ventes'},
      {'index': 9,  'title': 'Archives réçu',          'icon': Icons.archive_rounded,                'group': 'Ventes'},
      {'index': 8,  'title': 'Dettes',                 'icon': Icons.account_balance_wallet_rounded, 'group': 'Admin'},
      {'index': 13, 'title': 'Réapprovisionnement',    'icon': Icons.autorenew_rounded,              'group': 'Stock'},
      {'index': 6,  'title': 'Fournisseurs',           'icon': Icons.local_shipping_rounded,         'group': 'Stock'},
      {'index': 11, 'title': 'Historique des ventes',  'icon': Icons.receipt_long_rounded,           'group': 'Système'},
      {'index': 7,  'title': 'Gestion des comptes',    'icon': Icons.manage_accounts_rounded,        'group': 'Système'},
      {'index': 12, 'title': 'Paramètres',             'icon': Icons.settings_rounded,               'group': 'Système'},
      {'index': 14, 'title': 'Détails',                'icon': Icons.info_outline_rounded,           'group': 'Système'},
      {'index': 15, 'title': 'Documentation',          'icon': Icons.help_outline_rounded,           'group': 'Système'},
    ];

    // Filter tabs based on role permissions
    final allowedTabs = allTabs.where((tab) => _hasAccess(state, currentRole, tab['index'])).toList();

    // Ensure state.activeTab is valid for allowedTabs, otherwise set to first allowed
    int activeIndex = allowedTabs.indexWhere((t) => t['index'] == state.activeTab);
    if (activeIndex == -1) {
      activeIndex = 0;
      // Schedule post frame callback to avoid setting state during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.setActiveTab(allowedTabs[0]['index']);
      });
    }

    // Get alerts counts
    final lowStockCount = state.products.where((p) => p.totalQuantity <= p.minStock && !state.isProductOrdered(p.id)).length;
    final expiredCount = state.lots.where((l) => l.isExpired && l.quantity > 0).length;
    final alertCount = lowStockCount + expiredCount;

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
              border: Border(right: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.white.withOpacity(0.05))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
                Container(
                  padding: EdgeInsets.symmetric(horizontal: _isSidebarVisible ? 24 : 12, vertical: 24),
                  decoration: BoxDecoration(
                    color: themeColor,
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.white.withOpacity(0.03))),
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
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            clipBehavior: Clip.antiAlias,
                            child: Image.memory(_pharmacyLogoBytes!, fit: BoxFit.cover),
                          )
                        else
                          Icon(_pharmacyIcon, color: Colors.white, size: _isSidebarVisible ? 52 : 34),
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
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: _isSidebarVisible ? 12 : 8),
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
                                color: isSelected ? themeColor.withOpacity(0.12) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? themeColor.withOpacity(0.25) : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: _isSidebarVisible 
                                    ? MainAxisAlignment.start 
                                    : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tab['icon'],
                                    color: isSelected ? themeColor : state.textPrimary,
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
                                              ? (state.isDarkMode ? Colors.white : themeColor)
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


                // User footer (cliquable pour voir/modifier le profil)
                InkWell(
                  onTap: () => _showProfileDialog(context, state),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: _isSidebarVisible ? 20 : 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.white.withOpacity(0.03))),
                    ),
                    child: Row(
                      mainAxisAlignment: _isSidebarVisible
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        (() {
                          final currentUser = state.users.firstWhere(
                            (u) => u.username == state.currentUsername,
                            orElse: () => UserAccount(username: state.currentUsername, role: state.currentUserRole),
                          );
                          final hasImg = currentUser.profileImageBase64 != null && currentUser.profileImageBase64!.isNotEmpty;
                          return CircleAvatar(
                            radius: 22,
                            backgroundColor: themeColor.withOpacity(0.15),
                            backgroundImage: hasImg ? MemoryImage(base64Decode(currentUser.profileImageBase64!)) : null,
                            child: hasImg ? null : Text(
                              state.currentUsername.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.outfit(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          );
                        })(),
                        if (_isSidebarVisible) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.currentUsername.toLowerCase(),
                                  style: GoogleFonts.inter(
                                    color: state.textPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  state.currentUserRole,
                                  style: GoogleFonts.inter(
                                    color: themeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.edit_outlined, color: state.textSecondaryLight, size: 13),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bouton déconnexion séparé
                InkWell(
                  onTap: () => state.logout(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: _isSidebarVisible ? 20 : 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.06),
                      border: Border(top: BorderSide(color: Colors.redAccent.withOpacity(0.12))),
                    ),
                    child: Row(
                      mainAxisAlignment: _isSidebarVisible
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
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
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    children: [
                      // Toggle sidebar button
                      IconButton(
                        iconSize: 32,
                        icon: Icon(
                          _isSidebarVisible ? Icons.menu_open_rounded : Icons.menu_rounded,
                          color: Theme.of(context).brightness == Brightness.dark ? state.textSecondary : Color(0xFF475569),
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
                        allTabs.firstWhere((t) => t['index'] == state.activeTab)['title'],
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                        ),
                      ),
                      // Badge Période d'essai (Mode Test)
                      if (!state.isLicensed) ...[
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.orange, size: 14),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.25)),
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

                      // Compte utilisateur dans la Navbar
                      (() {
                        final currentUser = state.users.firstWhere(
                          (u) => u.username == state.currentUsername,
                          orElse: () => UserAccount(username: state.currentUsername, role: state.currentUserRole),
                        );
                        final hasImg = currentUser.profileImageBase64 != null && currentUser.profileImageBase64!.isNotEmpty;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: themeColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: themeColor.withOpacity(0.2),
                                backgroundImage: hasImg ? MemoryImage(base64Decode(currentUser.profileImageBase64!)) : null,
                                child: hasImg ? null : Text(
                                  state.currentUsername.substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.outfit(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    state.currentUsername.toLowerCase(),
                                    style: GoogleFonts.inter(
                                      color: state.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    state.currentUserRole,
                                    style: GoogleFonts.inter(
                                      color: themeColor,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      })(),
                      const SizedBox(width: 16),
                      if (state.notificationsEnabled && alertCount > 0) ...[
                        Tooltip(
                          message: 'Alertes système : $lowStockCount ruptures/faibles & $expiredCount lots périmés',
                          child: InkWell(
                            onTap: () {
                              state.setActiveTab(1); // Jump to inventory
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
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
                          state.notificationsEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                          color: state.notificationsEnabled ? const Color(0xFF10B981) : state.textSecondary,
                          size: 24,
                        ),
                        tooltip: state.notificationsEnabled ? 'Désactiver les alertes' : 'Activer les alertes',
                        onPressed: () => state.toggleNotifications(),
                      ),
                      SizedBox(width: 16),

                      // Theme Toggle Button (Samsung One UI style)
                      GestureDetector(
                        onTap: () => state.toggleTheme(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: state.isDarkMode ? state.bgSecondary : Colors.white,
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
                                state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                color: state.isDarkMode ? Colors.amber : Colors.orangeAccent,
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

                      // Simple Date Display
                      Text(
                        DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          color: Theme.of(context).brightness == Brightness.dark ? state.textSecondary : Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Text('Détails du Développeur', style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  color: state.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
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
                              style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text("Étudiant — Université de Labé",
                              style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12)),
                          Text("Département Informatique",
                              style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contact info
              _detailRow(Icons.phone_rounded, 'Téléphone', '624 064 642 / 663 507 183', state),
              const SizedBox(height: 8),
              _detailRow(Icons.location_on_rounded, 'Adresse', 'Kankan, Guinée', state),
              const SizedBox(height: 16),

              // Slogan
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: Color(0xFF10B981), size: 18),
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
            child: Text('Fermer', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, AppStateProvider state) {
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
            Text(label, style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.w600)),
            Text(value, style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: state.bgSecondary,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book_rounded, color: themeColor, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'Documentation & Mode d\'emploi',
              style: GoogleFonts.outfit(
                color: state.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          width: 750,
          height: 600,
          child: DefaultTabController(
            length: 5,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  labelColor: themeColor,
                  unselectedLabelColor: state.textSecondary,
                  indicatorColor: themeColor,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                  tabs: const [
                    Tab(text: 'Général', icon: Icon(Icons.info_outline, size: 18)),
                    Tab(text: 'Ventes (POS)', icon: Icon(Icons.point_of_sale, size: 18)),
                    Tab(text: 'Stock & Lots', icon: Icon(Icons.inventory_2, size: 18)),
                    Tab(text: 'Dettes', icon: Icon(Icons.account_balance_wallet, size: 18)),
                    Tab(text: 'Reçus & PDF', icon: Icon(Icons.receipt_long, size: 18)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildDocGeneral(state),
                      _buildDocPOS(state),
                      _buildDocStock(state),
                      _buildDocDettes(state),
                      _buildDocExport(state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocGeneral(AppStateProvider state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('🚀 Bienvenue sur PharmaGuinée', 'Votre solution moderne pour gérer votre officine de pharmacie au quotidien.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'À propos de la plateforme',
            description: 'PharmaGuinée permet de centraliser et d\'automatiser l\'intégralité des opérations de votre pharmacie :\n'
                '• Encaissement rapide et fiable des clients.\n'
                '• Gestion en temps réel du stock global et des alertes de rupture.\n'
                '• Traçabilité absolue des ventes passées et des crédits accordés.\n'
                '• Tableau de bord analytique des indicateurs de performance.',
            icon: Icons.auto_awesome_rounded,
            iconColor: Colors.purple,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Sécurité et Permissions',
            description: 'L\'accès est sécurisé par un code PIN à 4 chiffres unique pour chaque utilisateur. '
                'Le rôle ADMIN détient l\'accès complet (tarification, comptes, configurations), '
                'tandis que les VENDEURS sont restreints aux fonctionnalités de caisse et de consultation des stocks selon leurs droits.',
            icon: Icons.shield_rounded,
            iconColor: Colors.blue,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocPOS(AppStateProvider state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('🛒 Faire une Vente (Point de Vente)', 'Comment réaliser des transactions rapidement et imprimer les reçus.'),
          const SizedBox(height: 16),
          _docCard(
            title: '1. Sélectionner les produits',
            description: 'Recherchez un produit par son nom ou scannez son code-barres dans la barre de recherche POS. '
                'Cliquez sur un produit en stock pour l\'ajouter au panier. La quantité du produit dans le panier s\'incrémente automatiquement.',
            icon: Icons.search_rounded,
            iconColor: Colors.amber,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: '2. Configurer le Panier',
            description: 'Dans le panneau de droite, vous pouvez ajuster la quantité de chaque ligne avec les boutons (+) et (-). '
                'Vous pouvez appliquer une remise en GNF ou saisir le nom du patient (facultatif).',
            icon: Icons.shopping_basket_rounded,
            iconColor: Colors.green,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: '3. Mode de Paiement et Validation',
            description: 'Sélectionnez le mode de paiement directement en bas du panier :\n'
                '• Espèces (par défaut)\n'
                '• Crédit (génère une dette dans l\'onglet Dettes)\n'
                '• Orange Money (validation électronique)\n\n'
                'Cliquez ensuite sur "Traiter le paiement" pour valider la vente.',
            icon: Icons.payment_rounded,
            iconColor: Colors.teal,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocStock(AppStateProvider state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('📦 Gestion des Stocks & Alertes', 'Optimisez votre approvisionnement et évitez les ruptures ou produits périmés.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Suivi et Recherche des Médicaments',
            description: 'L\'onglet Stock présente l\'ensemble de vos produits avec leur prix d\'achat, prix de vente, et niveau de stock actuel. '
                'Vous pouvez filtrer par catégorie thérapeutique pour cibler un médicament particulier.',
            icon: Icons.inventory_rounded,
            iconColor: Colors.teal,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Alertes Automatiques',
            description: 'L\'application vous alerte de façon proactive :\n'
                '• Niveau faible/rupture : si un stock descend sous le seuil d\'alerte minimal spécifié.\n'
                '• Produits périmés : l\'application suit chaque lot individuellement pour signaler les péremptions imminentes.',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.redAccent,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Réapprovisionnement et Fournisseurs',
            description: 'Utilisez le module Réapprovisionnement pour enregistrer les nouvelles livraisons de médicaments, '
                'spécifier les numéros de lots, dates de péremption, et assigner un fournisseur.',
            icon: Icons.local_shipping_rounded,
            iconColor: Colors.orange,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocDettes(AppStateProvider state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('💳 Suivi des Dettes & Crédits Clients', 'Gardez le contrôle sur les encaissements différés de vos clients.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Création d\'un crédit',
            description: 'Lorsqu\'un client achète à crédit, sélectionnez l\'option "Crédit" dans le panier POS avant de cliquer sur "Traiter le paiement". '
                'Une entrée de dette sera créée automatiquement associée au nom du patient.',
            icon: Icons.add_card_rounded,
            iconColor: Colors.indigo,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Suivi et Remboursement',
            description: 'Dans l\'onglet Dettes, vous pouvez consulter la liste complète des impayés avec les montants restants. '
                'Pour enregistrer un versement, cliquez sur "Rembourser", saisissez la somme payée, et le solde restant se mettra à jour instantanément.',
            icon: Icons.price_check_rounded,
            iconColor: Colors.green,
            state: state,
          ),
        ],
      ),
    );
  }

  Widget _buildDocExport(AppStateProvider state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _docSectionHeader('📄 Gestion des Reçus, Impression et Partages', 'Imprimez et partagez les reçus professionnels de vos clients.'),
          const SizedBox(height: 16),
          _docCard(
            title: 'Aperçu Virtuel Thermique',
            description: 'Chaque validation de vente ouvre automatiquement un reçu virtuel compact au format thermique (80mm). '
                'Il respecte la mise en page standard des tickets de caisse avec toutes les mentions obligatoires.',
            icon: Icons.receipt_rounded,
            iconColor: Colors.blueGrey,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Impression direct physique',
            description: 'Cliquez sur le bouton "Imprimer Facture" pour envoyer le document PDF dynamique directement '
                'à l\'imprimante de reçus de l\'officine via le gestionnaire d\'impression.',
            icon: Icons.print_rounded,
            iconColor: Colors.green,
            state: state,
          ),
          const SizedBox(height: 12),
          _docCard(
            title: 'Export et Partage Numérique',
            description: 'Cliquez sur le bouton "Exporter" pour enregistrer la facture au format PDF, ou la partager instantanément '
                'par e-mail, messagerie ou toute autre application de votre ordinateur.',
            icon: Icons.share_rounded,
            iconColor: Colors.blue,
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
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
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
        color: state.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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
      orElse: () => UserAccount(username: state.currentUsername, role: state.currentUserRole),
    );

    final nameCtrl = TextEditingController(text: currentUser.fullName);
    final emailCtrl = TextEditingController(text: currentUser.email);
    final passCtrl = TextEditingController();
    bool obscurePass = true;
    Uint8List? newProfileImageBytes;
    String? newProfileImageBase64;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasImg = newProfileImageBase64 != '' && (newProfileImageBytes != null || (currentUser.profileImageBase64 != null && currentUser.profileImageBase64!.isNotEmpty));
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: themeColor.withOpacity(0.15),
                    backgroundImage: (() {
                      if (newProfileImageBase64 == '') return null;
                      if (newProfileImageBytes != null) return MemoryImage(newProfileImageBytes!);
                      if (currentUser.profileImageBase64 != null && currentUser.profileImageBase64!.isNotEmpty) {
                        try {
                          return MemoryImage(base64Decode(currentUser.profileImageBase64!));
                        } catch (_) {}
                      }
                      return null;
                    })(),
                    child: hasImg ? null : Text(
                      state.currentUsername.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(color: themeColor, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mon Profil', style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_rounded, color: themeColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              state.currentUsername,
                              style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (state.currentUserRole == 'ADMIN'
                                    ? const Color(0xFFF59E0B)
                                    : themeColor).withOpacity(0.12),
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
                                  border: Border.all(color: themeColor.withOpacity(0.3), width: 2),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: (() {
                                  if (newProfileImageBase64 == '') {
                                    return Icon(Icons.person_rounded, color: themeColor.withOpacity(0.7), size: 40);
                                  }
                                  if (newProfileImageBytes != null) {
                                    return Image.memory(newProfileImageBytes!, fit: BoxFit.cover);
                                  }
                                  if (currentUser.profileImageBase64 != null && currentUser.profileImageBase64!.isNotEmpty) {
                                    try {
                                      return Image.memory(base64Decode(currentUser.profileImageBase64!), fit: BoxFit.cover);
                                    } catch (e) {
                                      debugPrint('Error decoding base64: $e');
                                    }
                                  }
                                  return Icon(Icons.person_rounded, color: themeColor.withOpacity(0.7), size: 40);
                                })(),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
                                  if (result != null && result.files.single.bytes != null) {
                                    setDialogState(() {
                                      newProfileImageBytes = result.files.single.bytes;
                                      newProfileImageBase64 = base64Encode(newProfileImageBytes!);
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: state.bgSecondary, width: 2),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (newProfileImageBase64 != '' && (newProfileImageBytes != null || (currentUser.profileImageBase64 != null && currentUser.profileImageBase64!.isNotEmpty)))
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  newProfileImageBytes = null;
                                  newProfileImageBase64 = '';
                                });
                              },
                              child: const Text('Retirer la photo', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Nom complet
                        Text('Nom complet', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameCtrl,
                          style: GoogleFonts.inter(color: state.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgPrimary,
                            hintText: 'Votre nom complet',
                            hintStyle: GoogleFonts.inter(color: state.textSecondaryLight),
                            prefixIcon: Icon(Icons.badge_outlined, color: state.textSecondaryLight, size: 18),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: themeColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Email
                        Text('Email', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(color: state.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgPrimary,
                            hintText: 'votre@email.com',
                            hintStyle: GoogleFonts.inter(color: state.textSecondaryLight),
                            prefixIcon: Icon(Icons.email_outlined, color: state.textSecondaryLight, size: 18),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: themeColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Nouveau mot de passe
                        Text('Nouveau mot de passe (laisser vide pour ne pas changer)',
                            style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: obscurePass,
                          style: GoogleFonts.inter(color: state.textPrimary),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: state.bgPrimary,
                            hintText: '••••••••',
                            hintStyle: GoogleFonts.inter(color: state.textSecondaryLight),
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: state.textSecondaryLight, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: state.textSecondaryLight, size: 18,
                              ),
                              onPressed: () => setDialogState(() => obscurePass = !obscurePass),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: themeColor, width: 1.5),
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
                              border: Border.all(color: themeColor.withOpacity(0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.shield_outlined, color: themeColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text('Vos droits d\'accès', style: GoogleFonts.inter(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                ]),
                                const SizedBox(height: 8),
                                _permRow('✓', 'Tableau de bord', state),
                                _permRow('✓', 'Point de ventes (POS)', state),
                                _permRow('✓', 'Archives reçu', state),
                                _permRow('✗', 'Stock / Inventaire', state, denied: true),
                                _permRow('✗', 'Fournisseurs / Admin', state, denied: true),
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
                  child: Text('Annuler', style: GoogleFonts.inter(color: state.textSecondaryLight)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: Text('Enregistrer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      state.updateCurrentUserProfile(
                        fullName: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        newPassword: passCtrl.text.isNotEmpty ? passCtrl.text : null,
                        profileImageBase64: newProfileImageBase64,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profil mis à jour avec succès !', style: GoogleFonts.inter()),
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

  Widget _permRow(String mark, String label, AppStateProvider state, {bool denied = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(mark, style: GoogleFonts.inter(color: denied ? Colors.redAccent : const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: denied ? state.textSecondaryLight : state.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSettingsView() {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    if (_nameController.text != state.pharmacyName && !_nameFocusNode.hasFocus) {
      _nameController.text = state.pharmacyName;
    }

    return Center(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Configuration de la Pharmacie', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: state.textPrimary)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
                  username: adminUser.username.isNotEmpty ? adminUser.username : state.pharmacyPinCode,
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() => _pharmacySubtitle = val);
              },
            ),
            SizedBox(height: 32),
            Text('Logo / Image de la Pharmacie', style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                if (_pharmacyLogoBytes != null)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(_pharmacyLogoBytes!, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(color: Color(0xFF10B981).withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(Icons.local_pharmacy_rounded, color: Color(0xFF10B981), size: 40),
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
                        orElse: () => UserAccount(username: '', role: 'ADMIN'),
                      );
                      state.registerPharmacy(
                        name: state.pharmacyName,
                        quartier: state.pharmacyQuartier,
                        adminFullName: adminUser.fullName,
                        username: adminUser.username.isNotEmpty ? adminUser.username : state.pharmacyPinCode,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                if (_pharmacyLogoBytes != null) ...[
                  SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {
                      final adminUser = state.users.firstWhere(
                        (u) => u.role == 'ADMIN',
                        orElse: () => UserAccount(username: '', role: 'ADMIN'),
                      );
                      state.registerPharmacy(
                        name: state.pharmacyName,
                        quartier: state.pharmacyQuartier,
                        adminFullName: adminUser.fullName,
                        username: adminUser.username.isNotEmpty ? adminUser.username : state.pharmacyPinCode,
                        password: state.pharmacyPassword,
                        pinCode: state.pharmacyPinCode,
                        contact1: state.pharmacyContact1,
                        contact2: state.pharmacyContact2,
                        logo: null,
                      );
                    },
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    label: Text('Retirer', style: TextStyle(color: Colors.redAccent)),
                  ),
                ]
              ],
            ),
            SizedBox(height: 32),
            Text('Confidentialité des Rapports', style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Masquer les revenus totaux', style: TextStyle(color: state.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Désactive l\'affichage des montants de chiffre d\'affaires (Jour, Mois, Année) dans le tableau de bord et les rapports pour éviter les regards indiscrets.', style: TextStyle(color: state.textSecondary, fontSize: 12)),
              value: state.maskRevenues,
              onChanged: (val) {
                state.setMaskRevenues(val);
              },
              activeColor: Color(0xFF10B981),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => state.setActiveTab(0),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Fermer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }



  // ignore: unused_element
  void _showMontantsDialog(BuildContext context, dynamic state) {
    showDialog(
      context: context,
      builder: (context) {
        double todaySalesVal = 0.0;
        // ignore: unused_local_variable
        int todaySalesCount = 0;
        final now = DateTime.now();
        for (var sale in state.sales) {
          if (sale.date.year == now.year && sale.date.month == now.month && sale.date.day == now.day) {
            todaySalesVal += sale.netAmount;
            todaySalesCount++;
          }
        }

        final stockValue = state.lots.fold(0.0, (sum, l) {
          final prod = state.products.where((p) => p.id == l.productId);
          if (prod.isNotEmpty) return sum + prod.first.purchasePrice * l.quantity;
          return sum;
        });

        final currencyFmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);

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
                  style: GoogleFonts.outfit(color: state.textPrimary, fontWeight: FontWeight.bold),
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
                            border: Border.all(color: Color(0xFF06B6D4).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valeur du Stock',
                                    style: GoogleFonts.inter(color: state.textSecondary, fontSize: 10),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    state.maskRevenues ? '**** GNF' : currencyFmt.format(stockValue),
                                    style: GoogleFonts.outfit(color: Color(0xFF06B6D4), fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF06B6D4).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.inventory_2_rounded, color: Color(0xFF06B6D4), size: 24),
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
                            border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ventes du Jour',
                                    style: GoogleFonts.inter(color: state.textSecondary, fontSize: 10),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    state.maskRevenues ? '**** GNF' : currencyFmt.format(todaySalesVal),
                                    style: GoogleFonts.outfit(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFF10B981).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.monetization_on_rounded, color: Color(0xFF10B981), size: 24),
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
                child: Text('Fermer', style: GoogleFonts.inter(color: state.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesTab(dynamic state, String period) {
    final now = DateTime.now();
    final sales = state.sales.where((s) {
      if (period == 'day') return s.date.year == now.year && s.date.month == now.month && s.date.day == now.day;
      if (period == 'month') return s.date.year == now.year && s.date.month == now.month;
      return s.date.year == now.year;
    }).toList();

    double total = sales.fold(0.0, (sum, s) => sum + s.netAmount);
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);

    if (sales.isEmpty) {
      return Center(
        child: Text('Aucune vente pour cette période.', style: GoogleFonts.inter(color: state.textSecondary)),
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
              Text('${sales.length} ventes', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12)),
              Text('Total: ${state.maskRevenues ? '**** GNF' : fmt.format(total)}', style: GoogleFonts.outfit(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: sales.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, i) {
              final s = sales[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.receipt_rounded, color: Color(0xFF10B981), size: 16),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(s.date),
                            style: GoogleFonts.inter(color: state.textPrimary, fontSize: 12),
                          ),
                          Text(
                            '${s.items.length} article(s) — ${s.paymentMethod}',
                            style: GoogleFonts.inter(color: state.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Text(state.maskRevenues ? '**** GNF' : fmt.format(s.netAmount), style: GoogleFonts.outfit(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.keyboard_return_rounded, color: Colors.orangeAccent, size: 16),
                      tooltip: 'Retour / Remboursement',
                      onPressed: () => _showRefundDialog(s),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 16),
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
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);
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
                totalRefund += (val['quantity'] as int) * (val['unitPrice'] as double);
              }
            });

            return AlertDialog(
              backgroundColor: state.bgSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.keyboard_return_rounded, color: Colors.orangeAccent, size: 24),
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
                      style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                        icon: Icon(Icons.remove_circle_outline, color: Colors.orangeAccent, size: 20),
                                        onPressed: currentQty > 1
                                            ? () {
                                                setDialogState(() {
                                                  data['quantity'] = currentQty - 1;
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
                                        icon: Icon(Icons.add_circle_outline, color: Colors.orangeAccent, size: 20),
                                        onPressed: currentQty < maxQty
                                            ? () {
                                                setDialogState(() {
                                                  data['quantity'] = currentQty + 1;
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
                  child: Text('Annuler', style: GoogleFonts.inter(color: state.textSecondary)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              content: Text('Remboursement traité avec succès !'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                        },
                  child: Text('Confirmer le Retour', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
}
