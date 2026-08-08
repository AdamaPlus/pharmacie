import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_state_provider.dart';
import '../models/pharmacy_models.dart';

class SupplierView extends StatefulWidget {
  const SupplierView({super.key});

  @override
  State<SupplierView> createState() => _SupplierViewState();
}

class _SupplierViewState extends State<SupplierView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  // Create order states
  Supplier? _selectedOrderSupplier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '${NumberFormat.decimalPattern('fr').format(amount)} GNF';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final themeColor = Color(0xFF10B981);

    if (_selectedOrderSupplier == null && state.suppliers.isNotEmpty) {
      _selectedOrderSupplier = state.suppliers[0];
    }

    return Scaffold(
      backgroundColor: state.bgPrimary,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subheader tabs
          Container(
            color: state.bgSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: themeColor,
                  labelColor: state.textPrimary,
                  unselectedLabelColor: state.textSecondary,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Annuaires Fournisseurs'),
                    Tab(text: 'Commandes de Produits'),
                    Tab(text: 'Factures à Régler'),
                  ],
                ),
                
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_tabController.index == 0) ...[
                      PopupMenuButton<String>(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFF1E293B),
                            border: Border.all(color: state.borderTheme),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.import_export_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Import / Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'export_csv') _exportSupplierCSV(state);
                          else if (value == 'import_csv') _importSupplierCSV(state);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'export_csv', child: Row(children: [Icon(Icons.download_rounded, color: Colors.blueAccent), SizedBox(width: 8), Text('Exporter CSV')])),
                          PopupMenuItem(value: 'import_csv', child: Row(children: [Icon(Icons.upload_rounded, color: Colors.green), SizedBox(width: 8), Text('Importer CSV')])),
                        ],
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddSupplierDialog(context, state),
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Enregistrer Fournisseur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                    if (_tabController.index == 1) ...[
                      ElevatedButton.icon(
                        onPressed: () => _showCreateOrderDialog(context, state),
                        icon: Icon(Icons.shopping_bag_rounded, size: 18),
                        label: Text('Passer une Commande'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _exportOrdersPdf(state),
                        icon: Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: Text('Exporter PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Main body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSupplierDirectoryTab(state, themeColor),
                _buildOrdersTab(state, themeColor),
                _buildInvoicesTab(state, themeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: SUPPLIERS DIRECTORY
  // ==========================================
  Widget _buildSupplierDirectoryTab(AppStateProvider state, Color themeColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(32),
      itemCount: state.suppliers.length,
      itemBuilder: (context, idx) {
        final sup = state.suppliers[idx];
        return Card(
          color: state.bgSecondary,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.local_shipping_rounded, color: themeColor, size: 24),
                    ),
                    SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sup.name,
                            style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Contact Principal : ${sup.contactPerson} • Conditions de règlement: ${sup.paymentTerms.replaceAll("_", " ")}',
                            style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: state.textSecondary, size: 18),
                      onPressed: () => _showAddSupplierDialog(context, state, sup),
                    ),
                    if (state.currentUserRole == 'ADMIN')
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        onPressed: () {
                          state.deleteSupplier(sup.id);
                        },
                      ),
                  ],
                ),
                SizedBox(height: 16),

                Divider(color: Color(0xFF334155)),
                SizedBox(height: 12),

                // Info columns: address, phone, email
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: state.textSecondaryLight, size: 14),
                          SizedBox(width: 8),
                          Text(sup.phone, style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.email, color: state.textSecondaryLight, size: 14),
                          SizedBox(width: 8),
                          Text(sup.email, style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: state.textSecondaryLight, size: 14),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sup.address,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: SUPPLIER ORDERS & RECEIVING STOCK
  // ==========================================
  Widget _buildOrdersTab(AppStateProvider state, Color themeColor) {
    // Gather all orders with supplier context
    List<Map<String, dynamic>> ordersList = [];
    for (var sup in state.suppliers) {
      for (var o in sup.orders) {
        ordersList.add({
          'supplierId': sup.id,
          'supplierName': sup.name,
          'order': o,
        });
      }
    }

    // Sort by date (newest first)
    ordersList.sort((a, b) {
      final SupplierOrder o1 = a['order'];
      final SupplierOrder o2 = b['order'];
      return o2.date.compareTo(o1.date);
    });

    if (ordersList.isEmpty) {
      return Center(
        child: Text('Aucune commande enregistrée.', style: GoogleFonts.inter(color: state.textSecondaryLight)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: state.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.0), // Order ID
            1: FlexColumnWidth(2.5), // Supplier Name
            2: FlexColumnWidth(3.0), // Items ordered
            3: FlexColumnWidth(1.5), // Total Amount
            4: FlexColumnWidth(1.3), // Status pill
            5: FlexColumnWidth(2.0), // Action button
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: state.bgPrimary.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              children: [
                _tableHeaderCell('Code Commande'),
                _tableHeaderCell('Fournisseur'),
                _tableHeaderCell('Détails des Articles'),
                _tableHeaderCell('Montant HT'),
                _tableHeaderCell('Statut'),
                _tableHeaderCell('Réception'),
              ],
            ),
            ...ordersList.map((item) {
              final String supId = item['supplierId'];
              final String supName = item['supplierName'];
              final SupplierOrder order = item['order'];

              final itemsStr = order.items.map((i) => '${i.productName} (x${i.quantityOrdered})').join(', ');
              final isPending = order.status == 'COMMANDE';

              return TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.02))),
                ),
                children: [
                  _tableCellText(order.id, bold: true, color: state.textSecondary),
                  _tableCellText(supName),
                  _tableCellText(itemsStr, maxLines: 2),
                  _tableCellText(_formatCurrency(order.totalAmount), bold: true),
                  
                  // Status pill
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.status == 'RECUE'
                              ? Color(0xFF10B981).withOpacity(0.12)
                              : Colors.orangeAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          order.status,
                          style: GoogleFonts.inter(
                            color: order.status == 'RECUE' ? Color(0xFF10B981) : Colors.orangeAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Reception Button
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: isPending
                        ? ElevatedButton.icon(
                            onPressed: () {
                              state.receiveSupplierOrder(supId, order.id);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Succès: Marchandise réceptionnée ! Les stocks et lots correspondants ont été automatiquement injectés.'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            },
                            icon: Icon(Icons.archive_rounded, size: 14),
                            label: Text('Réceptionner', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          )
                        : Text(
                            'Intégrée au Stock',
                            style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12),
                          ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: SUPPLIER INVOICES & SETTLEMENTS
  // ==========================================
  Widget _buildInvoicesTab(AppStateProvider state, Color themeColor) {
    // Gather all invoices with supplier context
    List<Map<String, dynamic>> invoicesList = [];
    for (var sup in state.suppliers) {
      for (int i = 0; i < sup.invoices.length; i++) {
        var inv = sup.invoices[i];
        SupplierOrder? correspondingOrder;
        if (i < sup.orders.length) {
          correspondingOrder = sup.orders[i];
        }
        invoicesList.add({
          'supplierId': sup.id,
          'supplierName': sup.name,
          'invoice': inv,
          'order': correspondingOrder,
        });
      }
    }

    invoicesList.sort((a, b) {
      final SupplierInvoice i1 = a['invoice'];
      final SupplierInvoice i2 = b['invoice'];
      return i2.date.compareTo(i1.date);
    });

    if (invoicesList.isEmpty) {
      return Center(
        child: Text('Aucune facture enregistrée.', style: GoogleFonts.inter(color: state.textSecondaryLight)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: state.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.0), // Invoice ID
            1: FlexColumnWidth(2.5), // Supplier Name
            2: FlexColumnWidth(2.0), // Bill Date
            3: FlexColumnWidth(1.8), // Amount GNF
            4: FlexColumnWidth(1.5), // Status
            5: FlexColumnWidth(1.8), // Action Pay
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: state.bgPrimary.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              children: [
                _tableHeaderCell('Numéro Facture'),
                _tableHeaderCell('Fournisseur'),
                _tableHeaderCell('Date d\'Émission'),
                _tableHeaderCell('Montant Net GNF'),
                _tableHeaderCell('Règlement'),
                _tableHeaderCell('Action Pay'),
              ],
            ),
            ...invoicesList.map((item) {
              final String supId = item['supplierId'];
              final String supName = item['supplierName'];
              final SupplierInvoice invoice = item['invoice'];

              final SupplierOrder? order = item['order'];

              final isUnpaid = !invoice.isPaid;

              return TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.02))),
                ),
                children: [
                  _tableCellText(invoice.invoiceNumber, bold: true, color: Color(0xFF3B82F6)),
                  _tableCellText(supName),
                  _tableCellText(DateFormat('dd / MM / yyyy').format(invoice.date)),
                  _tableCellText(_formatCurrency(invoice.amount), bold: true),
                  
                  // Status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: invoice.isPaid
                              ? Color(0xFF10B981).withOpacity(0.12)
                              : Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          invoice.isPaid ? 'PAYÉE' : 'NON PAYÉE',
                          style: GoogleFonts.inter(
                            color: invoice.isPaid ? Color(0xFF10B981) : Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Button
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (isUnpaid)
                          ElevatedButton.icon(
                            onPressed: () {
                              state.paySupplierInvoice(supId, invoice.id);
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Facture fournisseur réglée avec succès !'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            },
                            icon: Icon(Icons.payment_rounded, size: 14),
                            label: Text('Régler Facture', style: TextStyle(fontSize: 11.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          )
                        else
                          Text(
                            'Réglée ',
                            style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12),
                          ),
                        IconButton(
                          onPressed: () {
                            _printSupplierInvoice(state, invoice, supName, order);
                          },
                          icon: const Icon(Icons.print_rounded, size: 18),
                          color: state.textSecondary,
                          tooltip: 'Imprimer la facture',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPERS & DIALOGS
  // ==========================================
  Widget _tableHeaderCell(String text) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: GoogleFonts.inter(color: state.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _tableCellText(String text, {bool bold = false, Color? color, int maxLines = 1}) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: color ?? state.textPrimary,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  // ==========================================
  // PDF EXPORT: ORDERS LIST
  // ==========================================
  Future<void> _printSupplierInvoice(AppStateProvider state, SupplierInvoice invoice, String supplierName, SupplierOrder? correspondingOrder) async {
    final doc = pw.Document();
    final fmt = NumberFormat.decimalPattern('fr');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FACTURE FOURNISSEUR', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('De: $supplierName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(invoice.date)}'),
                      pw.Text('Numéro: ${invoice.invoiceNumber}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('A: ${state.pharmacyName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(state.pharmacyQuartier),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              if (correspondingOrder != null && correspondingOrder.items.isNotEmpty) ...[
                pw.Text('Détail des médicaments :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                      children: [
                        _pdfCell('Désignation', bold: true, isHeader: true),
                        _pdfCell('Quantité', bold: true, isHeader: true),
                        _pdfCell('Prix U. HT', bold: true, isHeader: true),
                        _pdfCell('Total HT', bold: true, isHeader: true),
                      ],
                    ),
                    ...correspondingOrder.items.map((item) {
                      return pw.TableRow(
                        children: [
                          _pdfCell(item.productName),
                          _pdfCell(item.quantityOrdered.toString()),
                          _pdfCell('${fmt.format(item.unitPrice)}'),
                          _pdfCell('${fmt.format(item.quantityOrdered * item.unitPrice)}', bold: true),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
              ] else ...[
                pw.SizedBox(height: 40),
              ],
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Montant Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    pw.Text('${_formatCurrency(invoice.amount)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Statut: ${invoice.isPaid ? "PAYÉE" : "NON PAYÉE"}', style: pw.TextStyle(
                fontSize: 14,
                color: invoice.isPaid ? PdfColors.green700 : PdfColors.red700,
                fontWeight: pw.FontWeight.bold,
              )),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _exportOrdersPdf(AppStateProvider state) async {
    final doc = pw.Document();
    final fmt = NumberFormat.decimalPattern('fr');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();

    // Gather sorted orders
    List<Map<String, dynamic>> ordersList = [];
    for (var sup in state.suppliers) {
      for (var o in sup.orders) {
        ordersList.add({'supplierName': sup.name, 'order': o});
      }
    }
    ordersList.sort((a, b) => (b['order'] as SupplierOrder).date.compareTo((a['order'] as SupplierOrder).date));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('PHARMACIE GUINÉE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
            pw.Text('Registre des Commandes Fournisseurs', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Généré le : ${dateFmt.format(now)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.Text('Total commandes : ${ordersList.length}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ]),
        ]),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1, color: PdfColors.teal700),
        pw.SizedBox(height: 4),
      ]),
      build: (_) => [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.8),
            1: const pw.FlexColumnWidth(2.2),
            2: const pw.FlexColumnWidth(3.0),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.0),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal700),
              children: [
                _pdfCell('Code', bold: true, isHeader: true),
                _pdfCell('Fournisseur', bold: true, isHeader: true),
                _pdfCell('Articles', bold: true, isHeader: true),
                _pdfCell('Montant HT', bold: true, isHeader: true),
                _pdfCell('Statut', bold: true, isHeader: true),
              ],
            ),
            // Data rows
            ...ordersList.map((item) {
              final SupplierOrder o = item['order'];
              final String supName = item['supplierName'];
              final itemsStr = o.items.map((i) => '${i.productName} x${i.quantityOrdered}').join(' | ');
              final isReceived = o.status == 'RECUE';
              return pw.TableRow(children: [
                _pdfCell(o.id),
                _pdfCell(supName),
                _pdfCell(itemsStr),
                _pdfCell('${fmt.format(o.totalAmount)} GNF', bold: true),
                _pdfCell(o.status, color: isReceived ? PdfColors.green700 : PdfColors.orange700, bold: true),
              ]);
            }),
          ],
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfCell(String text, {bool bold = false, bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (color ?? PdfColors.black),
        ),
      ),
    );
  }

  // ==========================================
  // ADD / EDIT SUPPLIER DIALOG
  void _showAddSupplierDialog(BuildContext context, AppStateProvider state, [Supplier? original]) {
    final isEdit = original != null;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: isEdit ? original.name : '');
    final contactCtrl = TextEditingController(text: isEdit ? original.contactPerson : '');
    final phoneCtrl = TextEditingController(text: isEdit ? original.phone : '');
    final emailCtrl = TextEditingController(text: isEdit ? original.email : '');
    final addCtrl = TextEditingController(text: isEdit ? original.address : '');
    
    String termVal = isEdit ? original.paymentTerms : 'A_LA_RECEPTION';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: state.bgSecondary,
              title: Text(isEdit ? 'Modifier la fiche Fournisseur' : 'Créer une fiche Fournisseur', style: GoogleFonts.outfit(color: state.textPrimary)),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dialogField(label: 'Raison Sociale / Société', controller: nameCtrl, required: true),
                      SizedBox(height: 12),
                      _dialogField(label: 'Contact Principal (Nom complet)', controller: contactCtrl, required: true),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _dialogField(label: 'Téléphone', controller: phoneCtrl, required: true, isPhone: true, hintText: 'ex: 620123456')),
                          SizedBox(width: 16),
                          Expanded(child: _dialogField(label: 'Email', controller: emailCtrl)),
                        ],
                      ),
                      SizedBox(height: 12),
                      _dialogField(label: 'Adresse Siège Social', controller: addCtrl, required: true),
                      SizedBox(height: 16),

                      Text('Conditions de règlement standard', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: state.bgPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: termVal,
                            isExpanded: true,
                            dropdownColor: state.bgSecondary,
                            style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
                            items: [
                              {'val': 'A_LA_RECEPTION', 'label': 'À la réception de facture'},
                              {'val': '30_JOURS', 'label': 'Échéance standard à 30 jours'},
                              {'val': '45_JOURS', 'label': 'Échéance standard à 45 jours'},
                            ].map((item) {
                              return DropdownMenuItem(value: item['val'], child: Text(item['label']!));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => termVal = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Annuler', style: GoogleFonts.inter(color: state.textSecondaryLight)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF10B981)),
                  child: Text(isEdit ? 'Modifier' : 'Créer Fournisseur', style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newSup = Supplier(
                        id: isEdit ? original.id : 'SUP00${state.suppliers.length + 1}',
                        name: nameCtrl.text.trim(),
                        contactPerson: contactCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        address: addCtrl.text.trim(),
                        paymentTerms: termVal,
                        orders: isEdit ? original.orders : [],
                        invoices: isEdit ? original.invoices : [],
                      );

                      if (isEdit) {
                        state.editSupplier(newSup);
                      } else {
                        state.addSupplier(newSup);
                      }
                      Navigator.pop(context);
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

  // Create Supplier Order Dialog
  void _showCreateOrderDialog(BuildContext context, AppStateProvider state) {
    if (state.suppliers.isEmpty || state.products.isEmpty) return;

    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController(text: "50");
    final customSupNameCtrl = TextEditingController();
    
    Supplier selSup = state.suppliers.firstWhere((s) => s.id != 'sup_autre', orElse: () => state.suppliers[0]);
    Product selProd = state.products[0];
    final priceCtrl = TextEditingController(text: selProd.purchasePrice.toStringAsFixed(0));
    List<OrderItem> orderItems = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double totalOrderAmount = orderItems.fold(0.0, (sum, item) => sum + (item.quantityOrdered * item.unitPrice));
            bool showCustomSup = selSup.id == 'sup_autre';

            return AlertDialog(
              backgroundColor: state.bgSecondary,
              title: Row(
                children: [
                  const Icon(Icons.shopping_cart_checkout_rounded, color: Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  Text(
                    "Émettre une Bonne commande Fournisseur", 
                    style: GoogleFonts.outfit(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)
                  ),
                ],
              ),
              content: SizedBox(
                width: 700,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Select Supplier
                        Text("Fournisseur", style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.bgPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Supplier>(
                              value: selSup,
                              isExpanded: true,
                              dropdownColor: state.bgSecondary,
                              style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                              items: (() {
                                final sorted = List<Supplier>.from(state.suppliers);
                                Supplier? autreSup;
                                sorted.removeWhere((s) {
                                  if (s.id == 'sup_autre') {
                                    autreSup = s;
                                    return true;
                                  }
                                  return false;
                                });
                                sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                                if (autreSup != null) {
                                  sorted.add(autreSup!);
                                }
                                return sorted.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList();
                              })(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selSup = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        if (showCustomSup) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: customSupNameCtrl,
                            style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: state.bgPrimary,
                              hintText: 'Saisir le nom du nouveau fournisseur',
                              hintStyle: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12.5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: state.borderTheme)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: state.borderTheme)),
                            ),
                            validator: (value) {
                              if (showCustomSup && (value == null || value.trim().isEmpty)) {
                                return 'Veuillez saisir le nom du fournisseur';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Section header: Ajouter des articles
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: state.bgPrimary.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add_shopping_cart_rounded, color: Colors.blueAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                "Ajouter des produits à la bonne commande",
                                style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Selector and Qty Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Product dropdown
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Produit à commander", style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: state.bgPrimary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Product>(
                                        value: selProd,
                                        isExpanded: true,
                                        dropdownColor: state.bgSecondary,
                                        style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13),
                                        items: (() {
                                          final sorted = List<Product>.from(state.products);
                                          sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                                          return sorted.map((p) {
                                            final isRupture = p.totalQuantity <= 0;
                                            return DropdownMenuItem(
                                              value: p, 
                                              child: Text(
                                                "${p.name} (Catégorie: ${p.category})",
                                                style: GoogleFonts.inter(
                                                  color: isRupture ? Colors.redAccent : state.textPrimary,
                                                  fontWeight: isRupture ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              )
                                            );
                                          }).toList();
                                        })(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setDialogState(() {
                                              selProd = val;
                                              priceCtrl.text = val.purchasePrice.toStringAsFixed(0);
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Prix d'achat
                            Expanded(
                              flex: 2,
                              child: _dialogField(
                                label: "Prix d'achat (GNF)", 
                                controller: priceCtrl, 
                                isNumber: true, 
                                required: true,
                                hintText: "10000"
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Quantity
                            Expanded(
                              flex: 1,
                              child: _dialogField(
                                label: "Quantité", 
                                controller: qtyCtrl, 
                                isNumber: true, 
                                required: true,
                                hintText: "50"
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Add Button
                            ElevatedButton.icon(
                              onPressed: () {
                                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                                final unitPrice = double.tryParse(priceCtrl.text) ?? selProd.purchasePrice;
                                if (qty <= 0) return;

                                setDialogState(() {
                                  // Check if item is already added to update quantity instead of duplicating
                                  final existingIdx = orderItems.indexWhere((item) => item.productId == selProd.id);
                                  if (existingIdx != -1) {
                                    final currentItem = orderItems[existingIdx];
                                    orderItems[existingIdx] = OrderItem(
                                      productId: currentItem.productId,
                                      productName: currentItem.productName,
                                      quantityOrdered: currentItem.quantityOrdered + qty,
                                      unitPrice: unitPrice,
                                    );
                                  } else {
                                    orderItems.add(OrderItem(
                                      productId: selProd.id,
                                      productName: selProd.name,
                                      quantityOrdered: qty,
                                      unitPrice: unitPrice,
                                    ));
                                  }
                                  // Reset quantity input
                                  qtyCtrl.text = "50";
                                });
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text("Ajouter"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Section header: Liste des articles ajoutés
                        Text(
                          "Articles dans la commande (${orderItems.length})",
                          style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // List container
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: state.bgPrimary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: orderItems.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_basket_outlined, color: state.textSecondaryLight, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Aucun produit ajouté pour le moment.",
                                        style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12.5),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: orderItems.length,
                                  separatorBuilder: (context, idx) => Divider(color: Colors.white.withOpacity(0.04), height: 12),
                                  itemBuilder: (context, index) {
                                    final item = orderItems[index];
                                    final totalItemPrice = item.quantityOrdered * item.unitPrice;

                                    return Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "${NumberFormat.decimalPattern('fr').format(item.unitPrice)} GNF / unité",
                                                style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 11.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          "Quantité: ${item.quantityOrdered}",
                                          style: GoogleFonts.inter(color: state.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 24),
                                        Text(
                                          "${NumberFormat.decimalPattern('fr').format(totalItemPrice)} GNF",
                                          style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                          onPressed: () {
                                            setDialogState(() {
                                              orderItems.removeAt(index);
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Grand total row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Montant Total Estimé :",
                              style: GoogleFonts.inter(color: state.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              "${NumberFormat.decimalPattern('fr').format(totalOrderAmount)} GNF",
                              style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Annuler", style: GoogleFonts.inter(color: state.textSecondaryLight)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  onPressed: orderItems.isEmpty
                      ? null
                      : () {
                          if (formKey.currentState!.validate()) {
                            String finalSupId = selSup.id;
                            String finalSupName = selSup.name;
                            if (showCustomSup) {
                              final newSupName = customSupNameCtrl.text.trim();
                              final newSupId = 'SUP-${DateTime.now().millisecondsSinceEpoch}';
                              final newSup = Supplier(
                                id: newSupId,
                                name: newSupName,
                                contactPerson: 'Autre',
                                phone: '',
                                email: '',
                                address: '',
                                paymentTerms: 'A_LA_RECEPTION',
                                orders: [],
                                invoices: [],
                              );
                              state.addSupplier(newSup);
                              finalSupId = newSupId;
                              finalSupName = newSupName;
                            }
                            state.createSupplierOrder(finalSupId, orderItems);
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Bonne commande émise pour $finalSupName avec ${orderItems.length} article(s) !"),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    "Créer la Bonne commande", 
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: state.bgPrimary,
                    disabledForegroundColor: state.textSecondaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    bool isNumber = false,
    bool isPhone = false,
    String? hintText,
  }) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(color: state.textPrimary, fontSize: 13.5),
          keyboardType: isPhone
              ? TextInputType.phone
              : (isNumber ? TextInputType.number : TextInputType.text),
          inputFormatters: isPhone
              ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]
              : (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
          decoration: InputDecoration(
            filled: true,
            fillColor: state.bgPrimary,
            hintText: hintText,
            hintStyle: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 12.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return 'Ce champ est requis';
            }
            if (isPhone && value != null && value.isNotEmpty && value.length != 9) {
              return 'Le numéro doit comporter exactement 9 chiffres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _exportSupplierCSV(AppStateProvider state) async {
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Exporter les fournisseurs en CSV',
      fileName: 'fournisseurs_${DateTime.now().millisecondsSinceEpoch}.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (outputFile != null) {
      final buffer = StringBuffer();
      buffer.writeln("ID;Nom;Contact;Telephone;Email;Adresse;Conditions");
      for (var s in state.suppliers) {
        buffer.writeln("${s.id};${s.name};${s.contactPerson};${s.phone};${s.email};${s.address};${s.paymentTerms}");
      }
      await File(outputFile).writeAsString(buffer.toString());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export CSV réussi'), backgroundColor: Colors.green));
    }
  }

  Future<void> _importSupplierCSV(AppStateProvider state) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final lines = await file.readAsLines();
        int count = 0;
        for (int i = 1; i < lines.length; i++) {
          final parts = lines[i].split(';');
          if (parts.length >= 7) {
            final id = parts[0];
            final name = parts[1];
            final contact = parts[2];
            final phone = parts[3];
            final email = parts[4];
            final address = parts[5];
            final terms = parts[6];

            final existing = state.suppliers.where((s) => s.id == id).toList();
            if (existing.isNotEmpty) {
              final newS = Supplier(
                id: existing.first.id,
                name: name,
                contactPerson: contact,
                phone: phone,
                email: email,
                address: address,
                paymentTerms: terms,
                orders: existing.first.orders,
                invoices: existing.first.invoices,
              );
              state.editSupplier(newS);
            } else {
              final newS = Supplier(
                id: id,
                name: name,
                contactPerson: contact,
                phone: phone,
                email: email,
                address: address,
                paymentTerms: terms,
                orders: [],
                invoices: [],
              );
              state.addSupplier(newS);
            }
            count++;
          }
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count fournisseurs importés !'), backgroundColor: Colors.green));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'importation'), backgroundColor: Colors.red));
      }
    }
  }
}
