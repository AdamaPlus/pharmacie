import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_state_provider.dart';


class SalesReportView extends StatefulWidget {
  const SalesReportView({super.key});

  @override
  State<SalesReportView> createState() => _SalesReportViewState();
}

class _SalesReportViewState extends State<SalesReportView> {
  AppStateProvider get state => Provider.of<AppStateProvider>(context);
  String _period = 'day'; // 'day', 'week', 'month', 'year'
  String _searchQuery = '';

  String _formatCurrency(double amount, {bool mask = false}) {
    if (mask) return '**** GNF';
    return '${NumberFormat.decimalPattern('fr').format(amount)} GNF';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = const Color(0xFF10B981); // Emerald Green
    final now = state.workingDate;

    // Date boundaries for week calculation
    final DateTime startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    // Aggregate quantities and amounts by product for Day, Week, Month, Year
    final Map<String, _ProductReportItem> productSales = {};

    // Populate all catalog products first
    for (var p in state.products) {
      productSales[p.id] = _ProductReportItem(
        productId: p.id,
        productName: p.name,
        category: p.category,
        unitPrice: p.sellingPrice,
      );
    }

    // Process all recorded sales
    for (var sale in state.sales) {
      final isToday = sale.date.year == now.year && sale.date.month == now.month && sale.date.day == now.day;
      final isThisWeek = sale.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && sale.date.isBefore(endOfWeek);
      final isThisMonth = sale.date.year == now.year && sale.date.month == now.month;
      final isThisYear = sale.date.year == now.year;

      for (var item in sale.items) {
        final matchingProduct = state.products.where((p) => p.id == item.productId).toList();
        final purchasePrice = matchingProduct.isNotEmpty ? matchingProduct.first.purchasePrice : 0.0;
        final profitForItem = item.total - (purchasePrice * item.quantity);

        if (!productSales.containsKey(item.productId)) {
          final category = matchingProduct.isNotEmpty ? matchingProduct.first.category : 'Inconnu';
          productSales[item.productId] = _ProductReportItem(
            productId: item.productId,
            productName: item.productName,
            category: category,
            unitPrice: item.unitPrice,
          );
        }

        final reportItem = productSales[item.productId]!;

        if (isToday) {
          reportItem.qtyDay += item.quantity;
          reportItem.revenueDay += item.total;
          reportItem.profitDay += profitForItem;
        }
        if (isThisWeek) {
          reportItem.qtyWeek += item.quantity;
          reportItem.revenueWeek += item.total;
          reportItem.profitWeek += profitForItem;
        }
        if (isThisMonth) {
          reportItem.qtyMonth += item.quantity;
          reportItem.revenueMonth += item.total;
          reportItem.profitMonth += profitForItem;
        }
        if (isThisYear) {
          reportItem.qtyYear += item.quantity;
          reportItem.revenueYear += item.total;
          reportItem.profitYear += profitForItem;
        }
      }
    }

    // Set active period values for total sales & profit display
    for (var item in productSales.values) {
      if (_period == 'day') {
        item.quantity = item.qtyDay;
        item.totalAmount = item.revenueDay;
        item.totalProfit = item.profitDay;
      } else if (_period == 'week') {
        item.quantity = item.qtyWeek;
        item.totalAmount = item.revenueWeek;
        item.totalProfit = item.profitWeek;
      } else if (_period == 'month') {
        item.quantity = item.qtyMonth;
        item.totalAmount = item.revenueMonth;
        item.totalProfit = item.profitMonth;
      } else if (_period == 'year') {
        item.quantity = item.qtyYear;
        item.totalAmount = item.revenueYear;
        item.totalProfit = item.profitYear;
      } else {
        item.quantity = item.qtyYear;
        item.totalAmount = item.revenueYear;
        item.totalProfit = item.profitYear;
      }
    }

    // Filter by search query (displaying all products together in table)
    final itemsList = productSales.values.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.productName.toLowerCase().contains(q) ||
          item.productId.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();

    // Sort by quantity sold in selected period descending
    itemsList.sort((a, b) {
      int cmp = 0;
      if (_period == 'day') cmp = b.qtyDay.compareTo(a.qtyDay);
      else if (_period == 'week') cmp = b.qtyWeek.compareTo(a.qtyWeek);
      else if (_period == 'month') cmp = b.qtyMonth.compareTo(a.qtyMonth);
      else if (_period == 'year') cmp = b.qtyYear.compareTo(a.qtyYear);
      else cmp = b.quantity.compareTo(a.quantity);
      if (cmp != 0) return cmp;
      return a.productName.compareTo(b.productName);
    });

    // Calculate totals
    int totalQuantity = itemsList.fold(0, (sum, item) => sum + item.quantity);
    double totalRevenue = itemsList.fold(0.0, (sum, item) => sum + item.totalAmount);
    double totalProfit = itemsList.fold(0.0, (sum, item) => sum + item.totalProfit);

    return Scaffold(
      backgroundColor: state.bgPrimary,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rapport des Quantités Vendues',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: state.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Visualisez le volume vendu par produit (Jour, Semaine, Mois, Année)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: state.textSecondary,
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.file_download_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Exporter...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                  onSelected: (value) async {
                    if (value == 'pdf') {
                      if (itemsList.isNotEmpty) _printReport(itemsList, totalQuantity, totalRevenue, totalProfit, mask: state.maskRevenues);
                    } else if (value == 'excel_ventes') {
                      if (itemsList.isNotEmpty) await _exportSalesCSV(itemsList, state);
                    } else if (value == 'excel_stock') {
                      await _exportStockCSV(state);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'pdf', child: Row(children: const [Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent), SizedBox(width: 8), Text('Exporter Rapport (PDF)')])),
                    PopupMenuItem(value: 'excel_ventes', child: Row(children: const [Icon(Icons.table_view_rounded, color: Colors.green), SizedBox(width: 8), Text('Exporter Ventes (CSV)')])),
                    PopupMenuItem(value: 'excel_stock', child: Row(children: const [Icon(Icons.inventory_2_rounded, color: Colors.blueAccent), SizedBox(width: 8), Text('Exporter Détails Stock (CSV)')])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls & Filters Row
            Row(
              children: [
                // Period choice
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: state.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodButton('day', 'Par Jour'),
                      _buildPeriodButton('week', 'Par Semaine'),
                      _buildPeriodButton('month', 'Par Mois'),
                      _buildPeriodButton('year', 'Par Année'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Search bar
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: state.bgSecondary,
                      prefixIcon: Icon(Icons.search_rounded, color: state.textSecondaryLight),
                      hintText: 'Rechercher un produit dans le rapport...',
                      hintStyle: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Summary KPIs
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Volume total vendu',
                    value: '$totalQuantity unités',
                    subtitle: 'Total pour la période sélectionnée',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Valeur totale vendue',
                    value: _formatCurrency(totalRevenue, mask: state.maskRevenues),
                    subtitle: 'Chiffre d\'affaires net sur la période',
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Intérêt Total',
                    value: _formatCurrency(totalProfit, mask: state.maskRevenues),
                    subtitle: 'Bénéfice net estimé sur la période',
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table / List View
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: state.bgSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                clipBehavior: Clip.antiAlias,
                child: itemsList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, size: 48, color: state.textSecondaryLight),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune vente enregistrée sur cette période',
                              style: GoogleFonts.inter(color: state.textSecondary, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Table Header
                          Container(
                            color: state.bgPrimary.withOpacity(0.3),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text('Désignation', style: _headerStyle),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Catégorie', style: _headerStyle),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Prix Unitaire', style: _headerStyle, textAlign: TextAlign.right),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('Jour', style: _periodHeaderStyle('day'), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('Semaine', style: _periodHeaderStyle('week'), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('Mois', style: _periodHeaderStyle('month'), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text('Année', style: _periodHeaderStyle('year'), textAlign: TextAlign.center),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Total Ventes', style: _headerStyle, textAlign: TextAlign.right),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Intérêt', style: _headerStyle, textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                          ),
                          // Table Body
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: itemsList.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.03)),
                              itemBuilder: (context, index) {
                                final item = itemsList[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: GoogleFonts.inter(
                                                color: state.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'ID: ${item.productId}',
                                              style: GoogleFonts.inter(
                                                color: state.textSecondaryLight,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.04),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.category,
                                            style: GoogleFonts.inter(
                                              color: state.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatCurrency(item.unitPrice, mask: state.maskRevenues),
                                          style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      // Quantities by period
                                      Expanded(
                                        flex: 1,
                                        child: _buildQtyBadge(item.qtyDay, _period == 'day', themeColor),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: _buildQtyBadge(item.qtyWeek, _period == 'week', themeColor),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: _buildQtyBadge(item.qtyMonth, _period == 'month', themeColor),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: _buildQtyBadge(item.qtyYear, _period == 'year', themeColor),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatCurrency(item.totalAmount, mask: state.maskRevenues),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF06B6D4),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatCurrency(item.totalProfit, mask: state.maskRevenues),
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFFF59E0B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _headerStyle => GoogleFonts.inter(
        color: state.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

  TextStyle _periodHeaderStyle(String period) => GoogleFonts.inter(
        color: _period == period ? const Color(0xFF10B981) : state.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

  Widget _buildQtyBadge(int count, bool isHighlighted, Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted
            ? themeColor.withOpacity(0.18)
            : (count > 0 ? Colors.white.withOpacity(0.04) : Colors.transparent),
        borderRadius: BorderRadius.circular(6),
        border: isHighlighted
            ? Border.all(color: themeColor.withOpacity(0.4), width: 1)
            : null,
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: isHighlighted
              ? themeColor
              : (count > 0 ? state.textPrimary : state.textSecondaryLight.withOpacity(0.5)),
          fontWeight: isHighlighted || count > 0 ? FontWeight.bold : FontWeight.normal,
          fontSize: 13.5,
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final isSelected = _period == value;
    final themeColor = const Color(0xFF10B981);
    return InkWell(
      onTap: () {
        setState(() {
          _period = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : state.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: state.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: state.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      color: state.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: state.textSecondaryLight,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSalesCSV(List<_ProductReportItem> itemsList, AppStateProvider state) async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Exporter les ventes en CSV',
      fileName: 'rapport_ventes_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (outputFile != null) {
      final buffer = StringBuffer();
      buffer.writeln("Designation;Categorie;Prix Unitaire Moyen;Qte Jour;Qte Semaine;Qte Mois;Qte Annee;Total Ventes;Interet");
      for (var item in itemsList) {
        buffer.writeln("${item.productName};${item.category};${item.unitPrice};${item.qtyDay};${item.qtyWeek};${item.qtyMonth};${item.qtyYear};${item.totalAmount};${state.maskRevenues ? 0 : item.totalProfit}");
      }
      await File(outputFile).writeAsString(buffer.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export réussi : $outputFile'), backgroundColor: Colors.green));
    }
  }

  Future<void> _exportStockCSV(AppStateProvider state) async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Exporter les détails du stock en CSV',
      fileName: 'details_stock_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (outputFile != null) {
      final buffer = StringBuffer();
      buffer.writeln("ID;Nom;Categorie;Prix Achat;Prix Vente;Quantite Actuelle;Stock Minimum");
      for (var p in state.products) {
        buffer.writeln("${p.id};${p.name};${p.category};${p.purchasePrice};${p.sellingPrice};${p.totalQuantity};${p.minStock}");
      }
      await File(outputFile).writeAsString(buffer.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export réussi : $outputFile'), backgroundColor: Colors.green));
    }
  }

  Future<void> _printReport(List<_ProductReportItem> items, int totalQty, double totalRev, double totalProf, {bool mask = false}) async {
    final doc = pw.Document();
    final String dateString = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    String periodText = 'Journée';
    if (_period == 'week') periodText = 'Semaine';
    if (_period == 'month') periodText = 'Mois';
    if (_period == 'year') periodText = 'Année';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(state.pharmacyName.isNotEmpty ? state.pharmacyName : 'PharmaGuinée', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    if (state.pharmacyQuartier.isNotEmpty)
                      pw.Text(state.pharmacyQuartier, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('RAPPORT DE VENTES DE PRODUITS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Période: $periodText', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                    pw.Text('Généré le: $dateString', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            // Summary KPIs in PDF
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VOLUME VENDU', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text('$totalQty unités', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VALEUR VENTES', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(totalRev)} GNF', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('INTÉRÊT TOTAL', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(totalProf)} GNF', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.amber800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Table of items
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.2), // Name
                1: const pw.FlexColumnWidth(1.4), // Category
                2: const pw.FlexColumnWidth(1.2), // Unit Price
                3: const pw.FlexColumnWidth(0.7), // Jour
                4: const pw.FlexColumnWidth(0.7), // Semaine
                5: const pw.FlexColumnWidth(0.7), // Mois
                6: const pw.FlexColumnWidth(0.7), // Année
                7: const pw.FlexColumnWidth(1.3), // Total
                8: const pw.FlexColumnWidth(1.3), // Interest
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Désignation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Catégorie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('P.U. Moyen', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Jour', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sem.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Mois', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Année', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Total GNF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Intérêt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
                  ],
                ),
                // Table Body
                ...items.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 7.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(item.category, style: const pw.TextStyle(fontSize: 7.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(item.unitPrice)} GNF', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.qtyDay}', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.qtyWeek}', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.qtyMonth}', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${item.qtyYear}', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(item.totalAmount)} GNF', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(item.totalProfit)} GNF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Text(
                'Document officiel de gestion - Confidentiel',
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}

class _ProductReportItem {
  final String productId;
  final String productName;
  final String category;
  final double unitPrice;
  int qtyDay;
  int qtyWeek;
  int qtyMonth;
  int qtyYear;
  double revenueDay;
  double revenueWeek;
  double revenueMonth;
  double revenueYear;
  double profitDay;
  double profitWeek;
  double profitMonth;
  double profitYear;
  int quantity;
  double totalAmount;
  double totalProfit;

  _ProductReportItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitPrice,
    this.qtyDay = 0,
    this.qtyWeek = 0,
    this.qtyMonth = 0,
    this.qtyYear = 0,
    this.revenueDay = 0.0,
    this.revenueWeek = 0.0,
    this.revenueMonth = 0.0,
    this.revenueYear = 0.0,
    this.profitDay = 0.0,
    this.profitWeek = 0.0,
    this.profitMonth = 0.0,
    this.profitYear = 0.0,
    this.quantity = 0,
    this.totalAmount = 0.0,
    this.totalProfit = 0.0,
  });
}
