import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/pharmacy_models.dart';
import '../providers/app_state_provider.dart';
import '../utils/invoice_printer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalesHistoryView extends StatefulWidget {
  const SalesHistoryView({super.key});

  @override
  State<SalesHistoryView> createState() => _SalesHistoryViewState();
}

class _SalesHistoryViewState extends State<SalesHistoryView> {
  AppStateProvider get state => Provider.of<AppStateProvider>(context);
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedPeriod = 'Tous'; // 'Tous', 'Aujourd\'hui', 'Ce Mois', 'Cette Année'
  String _selectedPaymentMethod = 'Tous'; // 'Tous', 'ESPECES', 'CARTE', 'CHEQUE'
  String _activeTab = 'Ventes'; // 'Ventes' or 'Suppressions'

  String _formatCurrency(double amount) {
    return '${NumberFormat.decimalPattern('fr').format(amount)} GNF';
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11)),
          Text('$value GNF', style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11)),
        ],
      ),
    );
  }

  void _showSaleDetailsDialog(Sale sale, NumberFormat currencyFmt, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: state.bgSecondary,
          content: Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo in virtual receipt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      state.pharmacyLogo != null
                          ? Image.memory(
                              state.pharmacyLogo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D9488),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 14,
                                      color: Colors.white,
                                    ),
                                    Container(
                                      width: 14,
                                      height: 4,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(width: 8),
                      Text(
                        state.pharmacyName.toUpperCase(),
                        style: GoogleFonts.courierPrime(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${state.pharmacyQuartier}\nTel: ${state.pharmacyContact2.isNotEmpty ? "${state.pharmacyContact1} / ${state.pharmacyContact2}" : state.pharmacyContact1}\nNIF: 998274-A',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  Text(
                    'REÇU DE PAIEMENT\nN°: ${sale.id}\nDate: ${DateFormat("dd/MM/yyyy HH:mm").format(sale.date)}\n${(sale.cashierName.toLowerCase().contains("admin") || sale.cashierName.toLowerCase().contains("responsable") || state.users.any((u) => u.role == "ADMIN" && (u.username.toLowerCase() == sale.cashierName.toLowerCase() || u.fullName.toLowerCase() == sale.cashierName.toLowerCase()))) ? "Admin" : "Caissier"}: ${sale.cashierName}\nClient: ${sale.patientName ?? "Passage"}',
                    style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
                  ),
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  
                  // Items lines
                  ...sale.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '   ${item.quantity} x ${NumberFormat.decimalPattern('fr').format(item.unitPrice)} GNF',
                                style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11),
                              ),
                              Text(
                                '${NumberFormat.decimalPattern('fr').format(item.total)} GNF',
                                style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),

                  // Calculations
                  if (sale.discountAmount > 0)
                    _receiptRow('REMISE APPLIQUÉE', '- ${NumberFormat.decimalPattern('fr').format(sale.discountAmount)}'),
                  
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),

                  // Net Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TOTAL NET PAYÉ', style: GoogleFonts.courierPrime(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${NumberFormat.decimalPattern('fr').format(sale.netAmount)} GNF', style: GoogleFonts.courierPrime(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  _receiptRow('MODE DE PAIEMENT', sale.paymentMethod),
                  
                  Text(
                    '------------------------------------',
                    style: GoogleFonts.courierPrime(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Signature',
                            style: GoogleFonts.courierPrime(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 35),
                          Text(
                            '........................',
                            style: GoogleFonts.courierPrime(color: Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Merci de votre confiance !\nOn vous souhaite prompt rétablissement.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.courierPrime(color: Colors.black, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Fermer', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _printInvoice(state, sale);
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text('Imprimer Facture', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = const Color(0xFF10B981);
    final currencyFmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);

    // Apply period and filter logic
    final now = state.workingDate;
    final filteredSales = state.sales.where((s) {
      // 1. Period filter
      if (_selectedPeriod == 'Aujourd\'hui') {
        if (s.date.year != now.year || s.date.month != now.month || s.date.day != now.day) return false;
      } else if (_selectedPeriod == 'Ce Mois') {
        if (s.date.year != now.year || s.date.month != now.month) return false;
      } else if (_selectedPeriod == 'Cette Année') {
        if (s.date.year != now.year) return false;
      }

      // 2. Payment Method filter
      if (_selectedPaymentMethod != 'Tous') {
        if (s.paymentMethod != _selectedPaymentMethod) return false;
      }

      // 3. Search query (Receipt ID, Patient Name, Cashier Name, Product Names)
      final q = _searchCtrl.text.toLowerCase();
      if (q.isNotEmpty) {
        final matchesId = s.id.toLowerCase().contains(q);
        final matchesPatient = s.patientName?.toLowerCase().contains(q) ?? false;
        final matchesCashier = s.cashierName.toLowerCase().contains(q);
        final matchesProducts = s.items.any((item) => item.productName.toLowerCase().contains(q));
        if (!matchesId && !matchesPatient && !matchesCashier && !matchesProducts) return false;
      }

      return true;
    }).toList();

    // Sort order (most recent first)
    filteredSales.sort((a, b) => b.date.compareTo(a.date));

    // KPI Metrics calculation for the filtered list
    int periodSalesCount = filteredSales.length;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================
          // HEADER SECTION
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeTab == 'Ventes' ? 'Historique des Ventes' : 'Historique des Suppressions',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: state.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _activeTab == 'Ventes'
                        ? 'Consultez, recherchez et gérez les transactions de caisse'
                        : 'Journal complet de toutes les suppressions effectuées dans le système',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: state.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Tab toggle buttons
                  Container(
                    decoration: BoxDecoration(
                      color: state.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: state.borderTheme),
                    ),
                    child: Row(
                      children: [
                        _tabButton('Ventes', Icons.receipt_long_rounded, const Color(0xFF10B981)),
                        _tabButton('Suppressions', Icons.delete_sweep_rounded, Colors.redAccent),
                      ],
                    ),
                  ),
                  if (_activeTab == 'Ventes') ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _exportSalesPdf(state, filteredSales),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Exporter PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Show deletion history if that tab is active
          if (_activeTab == 'Suppressions') ...[
            Expanded(child: _buildDeletionHistory(state)),
          ] else ...[

          // ==========================================
          // KPI METRIC CARDS
          // ==========================================
          Row(
            children: [
              // Transaction Count Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: state.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_rounded, color: Color(0xFF3B82F6), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nombre de Ventes',
                              style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$periodSalesCount transactions',
                              style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ==========================================
          // FILTERS AND SEARCH SECTION
          // ==========================================
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() {}),
                  style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par reçu, client, caissier, médicament...',
                    hintStyle: GoogleFonts.inter(color: state.textSecondaryLight),
                    prefixIcon: Icon(Icons.search_rounded, color: state.textSecondaryLight, size: 20),
                    filled: true,
                    fillColor: state.bgSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Period Toggle Filter
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: state.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      'Tous',
                      'Aujourd\'hui',
                      'Ce Mois',
                      'Cette Année',
                    ].map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPeriod = period),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? themeColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              period,
                              style: GoogleFonts.inter(
                                color: isSelected ? Colors.white : state.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Payment Method Filter Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: state.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPaymentMethod,
                      dropdownColor: state.bgSecondary,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: state.textSecondary),
                      style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPaymentMethod = val);
                      },
                      items: const [
                        DropdownMenuItem(value: 'Tous', child: Text('Tous les Paiements')),
                        DropdownMenuItem(value: 'ESPECES', child: Text('Espèces')),
                        DropdownMenuItem(value: 'CARTE', child: Text('Carte')),
                        DropdownMenuItem(value: 'CHEQUE', child: Text('Chèque')),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ==========================================
          // MAIN LIST OF SALES
          // ==========================================
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: state.bgSecondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              clipBehavior: Clip.antiAlias,
              child: filteredSales.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, color: state.textSecondaryLight, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune transaction trouvée',
                            style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ajustez vos filtres ou effectuez une nouvelle recherche.',
                            style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredSales.length,
                      separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04), height: 1),
                      itemBuilder: (context, idx) {
                        final sale = filteredSales[idx];
                        final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(sale.date);
                        final totalItems = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Row(
                            children: [
                              // Receipt icon badge
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: themeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Sale summary text details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Facture #${sale.id.substring(0, math.min(sale.id.length, 8))}',
                                          style: GoogleFonts.inter(
                                            color: state.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            sale.paymentMethod,
                                            style: GoogleFonts.inter(
                                              color: state.textSecondary,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalItems article(s) • Vendu par @${sale.cashierName} • $timeStr',
                                      style: GoogleFonts.inter(
                                        color: state.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Price tag
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.maskRevenues ? '**** GNF' : _formatCurrency(sale.netAmount),
                                    style: GoogleFonts.outfit(
                                      color: themeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),

                              // Actions Row
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Detail action button
                                  IconButton(
                                    icon: Icon(Icons.remove_red_eye_rounded, color: state.textSecondary, size: 18),
                                    tooltip: 'Consulter le reçu',
                                    onPressed: () => _showSaleDetailsDialog(sale, currencyFmt, state),
                                  ),
                                  
                                  // Direct Reprint action button
                                  IconButton(
                                    icon: Icon(Icons.print_rounded, color: themeColor, size: 18),
                                    tooltip: 'Réimprimer facture',
                                    onPressed: () => _showSaleDetailsDialog(sale, currencyFmt, state),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
          ],  // end else block
        ],
      ),
    );
  }

  Widget _tabButton(String label, IconData icon, Color activeColor) {
    final isActive = _activeTab == label;
    final st = Provider.of<AppStateProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? activeColor : st.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : st.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletionHistory(AppStateProvider state) {
    // Keywords for filtering deletion/cancellation actions
    const deleteKeywords = [
      'DELETE', 'SUPPRESSION', 'ANNULER', 'REMOVE', 'PURGE',
      'LOAN_DELETE', 'VENTE_DELETE', 'VENTE_ANNULER',
      'STOCK_DELETE', 'PATIENT_DELETE', 'STAFF_DELETE',
      'SUPPLIER_DELETE', 'ADMIN_USER_DELETE', 'STAFF_SHIFT_REMOVE',
      'LOGS_PURGE',
    ];

    final deletionLogs = state.auditLogs.where((log) {
      final actionUpper = log.action.toUpperCase();
      return deleteKeywords.any((kw) => actionUpper.contains(kw));
    }).toList();

    // Sort most recent first
    deletionLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (deletionLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_sweep_outlined, color: state.textSecondaryLight, size: 52),
            const SizedBox(height: 16),
            Text(
              'Aucune suppression enregistrée',
              style: GoogleFonts.outfit(color: state.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Les suppressions effectuées dans le système apparaîtront ici.',
              style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Badge colour by action type
    Color _badgeColor(String action) {
      final a = action.toUpperCase();
      if (a.contains('VENTE')) return const Color(0xFFEF4444);
      if (a.contains('STOCK')) return const Color(0xFFFF7043);
      if (a.contains('PATIENT')) return const Color(0xFF8B5CF6);
      if (a.contains('STAFF') || a.contains('SHIFT')) return const Color(0xFFF59E0B);
      if (a.contains('SUPPLIER')) return const Color(0xFF3B82F6);
      if (a.contains('LOAN') || a.contains('DETTE')) return const Color(0xFF14B8A6);
      if (a.contains('ADMIN_USER')) return const Color(0xFFEC4899);
      if (a.contains('PURGE') || a.contains('LOGS')) return Colors.blueGrey;
      return Colors.redAccent;
    }

    return Container(
      decoration: BoxDecoration(
        color: state.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: state.borderTheme),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: deletionLogs.length,
        separatorBuilder: (_, __) => Divider(color: state.borderTheme.withOpacity(0.4), height: 1),
        itemBuilder: (context, idx) {
          final log = deletionLogs[idx];
          final timeStr = DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp);
          final badgeColor = _badgeColor(log.action);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_forever_rounded, color: badgeColor, size: 20),
                ),
                const SizedBox(width: 14),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.action,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: state.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.person_outline_rounded, size: 13, color: state.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            log.username,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: state.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        log.details,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: state.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _printInvoice(AppStateProvider stateProvider, Sale sale) async {
    await InvoicePrinter.printInvoice(
      sale,
      stateProvider.pharmacyLogo,
      pharmacyName: stateProvider.pharmacyName,
      quartier: stateProvider.pharmacyQuartier,
      contact1: stateProvider.pharmacyContact1,
      contact2: stateProvider.pharmacyContact2,
    );
  }

  // PDF EXPORT: SALES HISTORY
  Future<void> _exportSalesPdf(AppStateProvider state, List<Sale> sales) async {
    final doc = pw.Document();
    final fmt = NumberFormat.decimalPattern('fr');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();
    double totalAmount = 0;
    for(var s in sales) totalAmount += s.netAmount;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text('PHARMACIE GUINÉE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
            pw.Text('Historique des Ventes', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text('Période / Filtre: $_selectedPeriod | $_selectedPaymentMethod', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Text('Généré le : ${dateFmt.format(now)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Nombre de ventes: ${sales.length}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Montant Total: ${state.maskRevenues ? "****" : fmt.format(totalAmount)} GNF', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
              ]
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.teal700),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.5),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.2),
                4: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                  children: [
                    _pdfCell('ID Reçu', bold: true, isHeader: true),
                    _pdfCell('Date', bold: true, isHeader: true),
                    _pdfCell('Caissier', bold: true, isHeader: true),
                    _pdfCell('Méthode', bold: true, isHeader: true),
                    _pdfCell('Montant', bold: true, isHeader: true),
                  ],
                ),
                ...sales.map((s) {
                  return pw.TableRow(
                    children: [
                      _pdfCell(s.id.substring(0, math.min(s.id.length, 8))),
                      _pdfCell(dateFmt.format(s.date)),
                      _pdfCell(s.cashierName),
                      _pdfCell(s.paymentMethod),
                      _pdfCell(state.maskRevenues ? '****' : '${fmt.format(s.netAmount)} GNF', bold: true),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfCell(String text, {bool bold = false, bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }
}
