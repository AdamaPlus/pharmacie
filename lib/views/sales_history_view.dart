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

  String _formatCurrency(double amount) {
    return '${NumberFormat.decimalPattern('fr').format(amount)} GNF';
  }

  void _showSaleDetailsDialog(Sale sale, NumberFormat currencyFmt, AppStateProvider state) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: state.bgSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: const Color(0xFF10B981)),
              const SizedBox(width: 10),
              Text(
                'Détails du Reçu #${sale.id.substring(0, math.min(sale.id.length, 8))}',
                style: GoogleFonts.outfit(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Meta details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: state.bgPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Date & Heure', DateFormat('dd/MM/yyyy HH:mm:ss').format(sale.date), state),
                        const SizedBox(height: 6),
                        _buildDetailRow('Caissier', '@${sale.cashierName}', state),
                        const SizedBox(height: 6),
                        _buildDetailRow('Méthode de Paiement', sale.paymentMethod, state),
                        if (sale.patientName != null && sale.patientName!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildDetailRow('Client/Patient', sale.patientName!, state),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Articles Achetés :',
                    style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...sale.items.map((item) {
                    final product = state.products.firstWhere((p) => p.id == item.productId, orElse: () => Product(id: '', name: '', barcode: '', description: '', category: '', purchasePrice: 0, sellingPrice: 0, totalQuantity: 0, minStock: 0, vat: 0, supplierName: '', image: ''));
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: state.bgPrimary.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: state.bgPrimary,
                              borderRadius: BorderRadius.circular(6),
                              image: product.image.isNotEmpty && !product.image.startsWith('generic_pill') && product.image.length > 50
                                  ? DecorationImage(
                                      image: MemoryImage(base64Decode(product.image)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !(product.image.isNotEmpty && !product.image.startsWith('generic_pill') && product.image.length > 50)
                                ? Icon(Icons.medication_rounded, color: state.textSecondary, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.w600, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity} x ${_formatCurrency(item.unitPrice)}',
                                  style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(item.total),
                            style: GoogleFonts.outfit(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 10),
                  _buildSummaryRow('Montant Total', sale.totalAmount, currencyFmt, state),
                  if (sale.discountAmount > 0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow('Remise', sale.discountAmount, currencyFmt, state, isNegative: true),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MONTANT NET PAYÉ',
                        style: GoogleFonts.inter(color: state.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        state.maskRevenues ? '**** GNF' : currencyFmt.format(sale.netAmount),
                        style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fermer', style: GoogleFonts.inter(color: state.textSecondary)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _printInvoice(state, sale);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.print_rounded, size: 16),
              label: Text('Imprimer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, AppStateProvider state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12)),
        Text(value, style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double val, NumberFormat fmt, AppStateProvider state, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12)),
        Text(
          '${isNegative ? "-" : ""}${state.maskRevenues ? "****" : fmt.format(val)}',
          style: GoogleFonts.outfit(
            color: isNegative ? Colors.redAccent : state.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = const Color(0xFF10B981);
    final currencyFmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);

    // Apply period and filter logic
    final now = DateTime.now();
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
                    'Historique des Ventes',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: state.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consultez, recherchez et gérez les transactions de caisse',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: state.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _exportSalesPdf(state, filteredSales),
                icon: Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text('Exporter PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

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
                                    onPressed: () => _printInvoice(state, sale),
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
        ],
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
