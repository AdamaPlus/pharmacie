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
  String _period = 'day'; // 'day', 'month', 'year'
  String _searchQuery = '';

  String _formatCurrency(double amount, {bool mask = false}) {
    if (mask) return '**** GNF';
    return '${NumberFormat.decimalPattern('fr').format(amount)} GNF';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = Color(0xFF10B981); // Emerald Green
    final now = DateTime.now();

    // 1. Filter sales based on chosen period
    final filteredSales = state.sales.where((s) {
      if (_period == 'day') {
        return s.date.year == now.year && s.date.month == now.month && s.date.day == now.day;
      } else if (_period == 'month') {
        return s.date.year == now.year && s.date.month == now.month;
      } else {
        return s.date.year == now.year;
      }
    }).toList();

    // 2. Aggregate quantities and amounts by product
    final Map<String, _ProductReportItem> productSales = {};

    for (var sale in filteredSales) {
      for (var item in sale.items) {
        final matchingProduct = state.products.where((p) => p.id == item.productId).toList();
        final purchasePrice = matchingProduct.isNotEmpty ? matchingProduct.first.purchasePrice : 0.0;
        final profitForItem = item.total - (purchasePrice * item.quantity);
        
        if (productSales.containsKey(item.productId)) {
          productSales[item.productId]!.quantity += item.quantity;
          productSales[item.productId]!.totalAmount += item.total;
          productSales[item.productId]!.totalProfit += profitForItem;
        } else {
          final category = matchingProduct.isNotEmpty ? matchingProduct.first.category : 'Inconnu';
          productSales[item.productId] = _ProductReportItem(
            productId: item.productId,
            productName: item.productName,
            category: category,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            totalAmount: item.total,
            totalProfit: profitForItem,
          );
        }
      }
    }

    // 3. Filter by search query
    final itemsList = productSales.values.where((item) {
      return item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.productId.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort by quantity sold descending
    itemsList.sort((a, b) => b.quantity.compareTo(a.quantity));

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
                    SizedBox(height: 6),
                    Text(
                      'Visualisez et imprimez les volumes de ventes par produit',
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
                      children: [
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
                    PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent), SizedBox(width: 8), Text('Exporter Rapport (PDF)')])),
                    PopupMenuItem(value: 'excel_ventes', child: Row(children: [Icon(Icons.table_view_rounded, color: Colors.green), SizedBox(width: 8), Text('Exporter Ventes (CSV)')])),
                    PopupMenuItem(value: 'excel_stock', child: Row(children: [Icon(Icons.inventory_2_rounded, color: Colors.blueAccent), SizedBox(width: 8), Text('Exporter Détails Stock (CSV)')])),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

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
                      _buildPeriodButton('month', 'Par Mois'),
                      _buildPeriodButton('year', 'Par Année'),
                    ],
                  ),
                ),
                SizedBox(width: 16),
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
            SizedBox(height: 24),

            // Summary KPIs
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Volume total vendu',
                    value: '$totalQuantity unités',
                    subtitle: 'Total cumulé des quantités',
                    icon: Icons.inventory_2_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Valeur totale vendue',
                    value: _formatCurrency(totalRevenue, mask: state.maskRevenues),
                    subtitle: 'Chiffre d\'affaires net sur la période',
                    icon: Icons.monetization_on_rounded,
                    color: Color(0xFF06B6D4),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Intérêt Total',
                    value: _formatCurrency(totalProfit, mask: state.maskRevenues),
                    subtitle: 'Bénéfice net estimé sur la période',
                    icon: Icons.trending_up_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

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
                            SizedBox(height: 16),
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
                                  child: Text('Prix Unitaire Moyen', style: _headerStyle, textAlign: TextAlign.right),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Quantité Vendue', style: _headerStyle, textAlign: TextAlign.center),
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
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                                            SizedBox(height: 2),
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
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${item.quantity}',
                                          style: GoogleFonts.outfit(
                                            color: themeColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          _formatCurrency(item.totalAmount, mask: state.maskRevenues),
                                          style: GoogleFonts.outfit(
                                            color: Color(0xFF06B6D4),
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
                                            color: Color(0xFFF59E0B),
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

  Widget _buildPeriodButton(String value, String label) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final isSelected = _period == value;
    final themeColor = Color(0xFF10B981);
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
                SizedBox(height: 8),
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
                SizedBox(height: 4),
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

  // Print PDF helper
  Future<void> _exportSalesCSV(List<_ProductReportItem> itemsList, AppStateProvider state) async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Exporter les ventes en CSV',
      fileName: 'rapport_ventes_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (outputFile != null) {
      final buffer = StringBuffer();
      buffer.writeln("Designation;Categorie;Prix Unitaire Moyen;Quantite Vendue;Total Ventes;Interet");
      for (var item in itemsList) {
        buffer.writeln("${item.productName};${item.category};${item.unitPrice};${item.quantity};${item.totalAmount};${state.maskRevenues ? 0 : item.totalProfit}");
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
                    pw.Text('PharmaGuinée', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    pw.Text('Ratoma, Conakry - Guinée', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('RAPPORT DE VENTES', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
                0: const pw.FlexColumnWidth(2.6), // Name
                1: const pw.FlexColumnWidth(1.6), // Category
                2: const pw.FlexColumnWidth(1.3), // Unit Price
                3: const pw.FlexColumnWidth(1.0), // Qty
                4: const pw.FlexColumnWidth(1.5), // Total
                5: const pw.FlexColumnWidth(1.5), // Interest
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Désignation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Catégorie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('P.U. Moyen', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Quantité', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total GNF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Intérêt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                  ],
                ),
                // Table Body
                ...items.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.productName, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(item.category, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(item.unitPrice)} GNF', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(item.totalAmount)} GNF', style: const pw.TextStyle(fontSize: 8), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(mask ? '**** GNF' : '${NumberFormat.decimalPattern("fr").format(item.totalProfit)} GNF', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right)),
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
  int quantity;
  double totalAmount;
  double totalProfit;

  _ProductReportItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitPrice,
    required this.quantity,
    required this.totalAmount,
    required this.totalProfit,
  });
}
