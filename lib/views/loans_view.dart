import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/app_state_provider.dart';
import 'package:flutter/services.dart';
import '../models/pharmacy_models.dart';

// ===== MODEL =====
class LoanItem {
  final String productName;
  final int quantity;
  final double unitValue;

  LoanItem({
    required this.productName,
    required this.quantity,
    required this.unitValue,
  });

  double get totalValue => quantity * unitValue;
}

class MedicamentLoan {
  final String id;
  final List<LoanItem> items;
  final String lenderType; // 'personne' or 'pharmacie'
  final String lenderName;
  final String lenderContact;
  final String lenderAddress;
  final DateTime loanDate;
  final bool isReturned;
  final String notes;

  MedicamentLoan({
    required this.id,
    required this.items,
    required this.lenderType,
    required this.lenderName,
    required this.lenderContact,
    required this.lenderAddress,
    required this.loanDate,
    this.isReturned = false,
    this.notes = '',
  });

  double get totalValue =>
      items.fold(0.0, (sum, item) => sum + item.totalValue);

  // Helper getters for backward compatibility
  String get medicamentName =>
      items.isNotEmpty ? items.map((i) => i.productName).join(', ') : 'Aucun';
  int get quantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get unitValue => items.isNotEmpty ? items.first.unitValue : 0.0;
}

// ===== MAIN VIEW =====
class LoansView extends StatefulWidget {
  const LoansView({super.key});

  @override
  State<LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<LoansView>
    with SingleTickerProviderStateMixin {
  AppStateProvider get state => Provider.of<AppStateProvider>(context);
  late TabController _tabController;

  final List<MedicamentLoan> _loans = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final _fmt = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'GNF',
    decimalDigits: 0,
  );
  final themeColor = Color(0xFF10B981);

  Future<void> _printLoansList(List<MedicamentLoan> loans, String title) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final logoBytes = state.pharmacyLogo;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                logoBytes != null
                    ? pw.Row(
                        children: [
                          pw.Container(
                            width: 45,
                            height: 45,
                            child: pw.Image(
                              pw.MemoryImage(logoBytes),
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'PharmaGuinée',
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.teal,
                                ),
                              ),
                              pw.Text(
                                'Système de Gestion de Pharmacie',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PharmaGuinée',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal,
                            ),
                          ),
                          pw.Text(
                            'Système de Gestion de Pharmacie',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'RAPPORT DES PRÊTS',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      'Généré le: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 15),

            // Title of list
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 12),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2), // ID
                1: const pw.FlexColumnWidth(2.5), // Médicament
                2: const pw.FlexColumnWidth(2.0), // Prêteur
                3: const pw.FlexColumnWidth(1.2), // Date
                4: const pw.FlexColumnWidth(0.8), // Quantité
                5: const pw.FlexColumnWidth(1.5), // Valeur Totale
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'ID',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Médicament',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Prêteur / Contact',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Date',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Quantité',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Valeur Totale',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                // Table Rows
                ...loans.map((loan) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          loan.id,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          loan.medicamentName,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              loan.lenderName,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '${loan.lenderType == 'pharmacie' ? 'Pharm.' : 'Pers.'} | ${loan.lenderContact}',
                              style: const pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          DateFormat('dd/MM/yyyy').format(loan.loanDate),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          loan.quantity.toString(),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          _fmt.format(loan.totalValue),
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 20),

            // Summary Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Nombre total de prêts: ${loans.length}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Valeur Totale Cumulée: ${_fmt.format(loans.fold(0.0, (s, l) => s + l.totalValue))}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name:
          '${title.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  Future<void> _printSingleLoan(MedicamentLoan loan) async {
    final logoBytes = state.pharmacyLogo;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  logoBytes != null
                      ? pw.Row(
                          children: [
                            pw.Container(
                              width: 30,
                              height: 30,
                              child: pw.Image(
                                pw.MemoryImage(logoBytes),
                                fit: pw.BoxFit.cover,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Text(
                              'PharmaGuinée',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.teal,
                              ),
                            ),
                          ],
                        )
                      : pw.Text(
                          'PharmaGuinée',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal,
                          ),
                        ),
                  pw.Text(
                    'REÇU DE PRÊT',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              // Loan ID and Date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Prêt N°: ${loan.id}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(loan.loanDate)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Statut:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    loan.isReturned ? 'REMBOURSÉ' : 'EN COURS',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: loan.isReturned
                          ? PdfColors.green
                          : PdfColors.orange,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // Lender details
              pw.Text(
                'PRÊTEUR / CRÉANCIER :',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nom: ${loan.lenderName} (${loan.lenderType == 'pharmacie' ? 'Pharmacie' : 'Personne'})',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Contact: ${loan.lenderContact}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      'Adresse: ${loan.lenderAddress}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // Item details
              pw.Text(
                'DÉTAILS DES MÉDICAMENTS EMPRUNTÉS :',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Désignation',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Quantité',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Prix Unit.',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'Valeur Totale',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...loan.items
                      .map(
                        (item) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                item.productName,
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                item.quantity.toString(),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                _fmt.format(item.unitValue),
                                style: const pw.TextStyle(fontSize: 8),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                _fmt.format(item.totalValue),
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          'TOTAL GLOBAL',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          '',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          _fmt.format(loan.totalValue),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              if (loan.notes.isNotEmpty) ...[
                pw.Text(
                  'Note / Objet : ${loan.notes}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Signature du Prêteur',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.Text(
                    'Signature de l\'Emprunteur',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Pret_${loan.id}',
    );
  }

  Widget _buildDetteListTab(List<MedicamentLoan> loansList, String typeLabel) {
    // Filtrer UNIQUEMENT les dettes non remboursées pour le total
    final pending = loansList.where((l) => !l.isReturned).toList();
    final returned = loansList.where((l) => l.isReturned).toList();
    // Le total d'intérêt ne compte QUE les dettes encore actives (non remboursées)
    final totalPending = pending.fold(0.0, (s, l) => s + l.totalValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary chip row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Résumé des ${typeLabel.toUpperCase()}',
                style: GoogleFonts.outfit(
                  color: state.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${pending.length} dette(s) en cours',
                      style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _fmt.format(totalPending),
                      style: GoogleFonts.outfit(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (returned.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${returned.length} réglée(s) — non comptée(s)',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF10B981),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pending loans
          _buildSectionTitle(
            'Dettes en cours',
            Icons.hourglass_top_rounded,
            Colors.orange,
            onPrint: pending.isEmpty
                ? null
                : () => _printLoansList(
                    pending,
                    'Liste des ${typeLabel} en cours',
                  ),
          ),
          const SizedBox(height: 12),
          if (pending.isEmpty)
            _buildEmptyState('Aucune dette en cours.')
          else
            ...pending.map((l) => _buildLoanCard(l)),

          const SizedBox(height: 28),

          // Returned loans
          _buildSectionTitle(
            'Dettes réglées',
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
            onPrint: returned.isEmpty
                ? null
                : () => _printLoansList(
                    returned,
                    'Liste des ${typeLabel} réglées',
                  ),
          ),
          const SizedBox(height: 12),
          if (returned.isEmpty)
            _buildEmptyState('Aucune dette réglée.')
          else
            ...returned.map((l) => _buildLoanCard(l)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientLoans = _loans
        .where((l) => l.lenderType == 'personne')
        .toList();

    return Container(
      color: state.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: state.bgSecondary,
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Dettes',
                      style: GoogleFonts.outfit(
                        color: state.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Suivi des dettes clients (personnes)',
                      style: GoogleFonts.inter(
                        color: state.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddLoanDialog(context),
                  icon: Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Enregistrer une Dette',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildDetteListTab(clientLoans, 'dettes clients')),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onPrint,
  }) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: state.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onPrint != null) ...[
          SizedBox(width: 10),
          Tooltip(
            message: 'Imprimer la liste',
            child: InkWell(
              onTap: onPrint,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.print_rounded, color: color, size: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: state.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Text(
          msg,
          style: GoogleFonts.inter(color: state.textSecondaryLight),
        ),
      ),
    );
  }

  Widget _buildLoanCard(MedicamentLoan loan) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: state.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: loan.isReturned
              ? themeColor.withOpacity(0.2)
              : Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ID + Status + Date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: state.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  loan.id,
                  style: GoogleFonts.inter(
                    color: state.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: loan.isReturned
                      ? themeColor.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  loan.isReturned ? 'Remboursé' : 'En cours',
                  style: GoogleFonts.inter(
                    color: loan.isReturned ? themeColor : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Spacer(),
              Icon(
                Icons.calendar_today_rounded,
                color: state.textSecondaryLight,
                size: 13,
              ),
              SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(loan.loanDate),
                style: GoogleFonts.inter(
                  color: state.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Main Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Médicament info
              // Médicaments info
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state.bgPrimary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Médicament(s) emprunté(s)',
                            style: GoogleFonts.inter(
                              color: state.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(0.8),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.5),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Produit',
                                  style: GoogleFonts.inter(
                                    color: state.textSecondaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Quantité',
                                  style: GoogleFonts.inter(
                                    color: state.textSecondaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'P.U.',
                                  style: GoogleFonts.inter(
                                    color: state.textSecondaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Valeur',
                                  style: GoogleFonts.inter(
                                    color: state.textSecondaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          ...loan.items
                              .map(
                                (item) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        item.productName,
                                        style: GoogleFonts.inter(
                                          color: state.textPrimary,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        '${item.quantity}',
                                        style: GoogleFonts.inter(
                                          color: state.textSecondary,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        _fmt.format(item.unitValue),
                                        style: GoogleFonts.inter(
                                          color: state.textSecondary,
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        _fmt.format(item.totalValue),
                                        style: GoogleFonts.inter(
                                          color: themeColor,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ],
                      ),
                      Divider(
                        color: Colors.white.withOpacity(0.04),
                        height: 16,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            loan.isReturned ? 'Montant Réglé ✓' : 'Valeur Totale du Prêt :',
                            style: GoogleFonts.inter(
                              color: loan.isReturned ? const Color(0xFF10B981) : state.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _fmt.format(loan.totalValue),
                            style: GoogleFonts.outfit(
                              // Si remboursée → gris (non comptée dans le total), sinon vert actif
                              color: loan.isReturned
                                  ? state.textSecondaryLight
                                  : themeColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              decoration: loan.isReturned
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              decorationColor: state.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16),

              // Lender info
              Expanded(
                child: _infoBlock(
                  icon: loan.lenderType == 'pharmacie'
                      ? Icons.local_pharmacy_rounded
                      : Icons.person_rounded,
                  iconColor: loan.lenderType == 'pharmacie'
                      ? Color(0xFF06B6D4)
                      : Color(0xFFF59E0B),
                  label: loan.lenderType == 'pharmacie'
                      ? 'Pharmacie prêteuse'
                      : 'Personne prêteuse',
                  lines: [
                    loan.lenderName,
                    'Contact : ${loan.lenderContact}',
                    'Adresse : ${loan.lenderAddress}',
                    if (loan.notes.isNotEmpty) 'Note : ${loan.notes}',
                  ],
                ),
              ),
            ],
          ),

          // Action buttons row
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddLoanDialog(context, loan),
                icon: Icon(Icons.edit_rounded, size: 16),
                label: Text('Modifier', style: GoogleFonts.inter(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _printSingleLoan(loan),
                icon: Icon(Icons.print_rounded, size: 16),
                label: Text(
                  'Imprimer le reçu',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: state.textSecondary,
                  side: BorderSide(color: Color(0xFF475569)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: state.bgSecondary,
                      title: Text(
                        'Confirmer',
                        style: GoogleFonts.inter(color: state.textPrimary),
                      ),
                      content: Text(
                        'Voulez-vous vraiment supprimer cette dette ?',
                        style: GoogleFonts.inter(color: state.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _loans.removeWhere((l) => l.id == loan.id);
                            });
                            Navigator.pop(dCtx);
                          },
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(
                  'Supprimer',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (!loan.isReturned) ...[
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      final idx = _loans.indexOf(loan);
                      if (idx != -1) {
                        _loans[idx] = MedicamentLoan(
                          id: loan.id,
                          items: loan.items,
                          lenderType: loan.lenderType,
                          lenderName: loan.lenderName,
                          lenderContact: loan.lenderContact,
                          lenderAddress: loan.lenderAddress,
                          loanDate: loan.loanDate,
                          isReturned: true,
                          notes: loan.notes,
                        );
                      }
                    });
                  },
                  icon: Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    'Marquer Remboursé',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBlock({
    required IconData icon,
    required Color iconColor,
    required String label,
    required List<String> lines,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: state.bgPrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 15),
              SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: state.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: GoogleFonts.inter(
                  color: state.textPrimary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLoanDialog(BuildContext context, [MedicamentLoan? original]) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final isEdit = original != null;
    final List<LoanItem> dialogItems = isEdit ? List.from(original.items) : [];

    String? selectedProductName;
    final quantityCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    final lenderNameCtrl = TextEditingController(
      text: isEdit ? original.lenderName : '',
    );
    final lenderContactCtrl = TextEditingController(
      text: isEdit ? original.lenderContact : '',
    );
    final lenderAddressCtrl = TextEditingController(
      text: isEdit ? original.lenderAddress : '',
    );
    final notesCtrl = TextEditingController(text: isEdit ? original.notes : '');
    String lenderType = isEdit ? original.lenderType : 'personne';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: state.bgSecondary,
          title: Text(
            isEdit
                ? 'Modifier la Dette de Médicaments'
                : 'Enregistrer une Dette de Médicaments',
            style: GoogleFonts.outfit(
              color: state.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Médicament selection
                  Text(
                    'AJOUTER UN MÉDICAMENT AU PRÊT',
                    style: GoogleFonts.inter(
                      color: state.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedProductName,
                    dropdownColor: state.bgSecondary,
                    style: TextStyle(color: state.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Sélectionner un médicament',
                      labelStyle: TextStyle(
                        color: state.textSecondary,
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.medication_rounded,
                        color: state.textSecondaryLight,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: state.bgPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                    ),
                    items: (() {
                      final sortedProds = List<Product>.from(state.products);
                      sortedProds.sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );
                      return sortedProds
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.name,
                              child: Text(
                                p.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList();
                    })(),
                    onChanged: (val) {
                      setS(() {
                        selectedProductName = val;
                        final matching = state.products.where(
                          (p) => p.name == val,
                        );
                        if (matching.isNotEmpty) {
                          valueCtrl.text = matching.first.purchasePrice
                              .toInt()
                              .toString();
                        }
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _dialogField(
                          quantityCtrl,
                          'Quantité',
                          Icons.format_list_numbered_rounded,
                          isNumber: true,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(
                          valueCtrl,
                          'Valeur unitaire (GNF)',
                          Icons.monetization_on_rounded,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (selectedProductName == null ||
                            quantityCtrl.text.isEmpty ||
                            valueCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Veuillez sélectionner un produit, saisir sa quantité et sa valeur.',
                              ),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                          return;
                        }
                        final qty = int.tryParse(quantityCtrl.text) ?? 0;
                        final val = double.tryParse(valueCtrl.text) ?? 0.0;
                        if (qty <= 0) return;

                        setS(() {
                          dialogItems.add(
                            LoanItem(
                              productName: selectedProductName!,
                              quantity: qty,
                              unitValue: val,
                            ),
                          );
                          selectedProductName = null;
                          quantityCtrl.clear();
                          valueCtrl.clear();
                        });
                      },
                      icon: Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        'Ajouter au panier du prêt',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor.withOpacity(0.12),
                        foregroundColor: themeColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),

                  // Selected items section
                  if (dialogItems.isNotEmpty) ...[
                    Text(
                      'PANIER DU PRÊT (${dialogItems.length})',
                      style: GoogleFonts.inter(
                        color: state.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: state.bgPrimary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: dialogItems.length,
                        itemBuilder: (c, idx) {
                          final item = dialogItems[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            title: Text(
                              item.productName,
                              style: GoogleFonts.inter(
                                color: state.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            subtitle: Text(
                              'Quantité: ${item.quantity} × ${_fmt.format(item.unitValue)}',
                              style: GoogleFonts.inter(
                                color: state.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _fmt.format(item.totalValue),
                                  style: GoogleFonts.inter(
                                    color: themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      setS(() => dialogItems.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valeur totale cumulée :',
                          style: GoogleFonts.inter(
                            color: state.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _fmt.format(
                            dialogItems.fold(
                              0.0,
                              (sum, item) => sum + item.totalValue,
                            ),
                          ),
                          style: GoogleFonts.outfit(
                            color: themeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],

                  // Lender type
                  Text(
                    'TYPE DE PRÊTEUR',
                    style: GoogleFonts.inter(
                      color: state.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      _typeChip(
                        'pharmacie',
                        'Pharmacie',
                        Icons.local_pharmacy_rounded,
                        lenderType,
                        (v) => setS(() => lenderType = v),
                      ),
                      SizedBox(width: 12),
                      _typeChip(
                        'personne',
                        'Personne',
                        Icons.person_rounded,
                        lenderType,
                        (v) => setS(() => lenderType = v),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // Lender info
                  Text(
                    lenderType == 'pharmacie'
                        ? 'INFORMATIONS DE LA PHARMACIE'
                        : 'INFORMATIONS DE LA PERSONNE',
                    style: GoogleFonts.inter(
                      color: state.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  _dialogField(
                    lenderNameCtrl,
                    lenderType == 'pharmacie'
                        ? 'Nom de la pharmacie'
                        : 'Nom et Prénom',
                    Icons.badge_rounded,
                  ),
                  SizedBox(height: 10),
                  _dialogField(
                    lenderContactCtrl,
                    'Numéro de téléphone',
                    Icons.phone_rounded,
                    isPhone: true,
                  ),
                  SizedBox(height: 10),
                  _dialogField(
                    lenderAddressCtrl,
                    'Adresse / Quartier',
                    Icons.location_on_rounded,
                  ),
                  SizedBox(height: 10),
                  _dialogField(
                    notesCtrl,
                    'Notes (optionnel)',
                    Icons.notes_rounded,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Annuler',
                style: GoogleFonts.inter(color: state.textSecondary),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (dialogItems.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Veuillez ajouter au moins un médicament au prêt.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                if (lenderNameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Veuillez renseigner le nom du prêteur.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                setState(() {
                  if (isEdit) {
                    final idx = _loans.indexOf(original);
                    if (idx != -1) {
                      _loans[idx] = MedicamentLoan(
                        id: original.id,
                        items: dialogItems,
                        lenderType: lenderType,
                        lenderName: lenderNameCtrl.text,
                        lenderContact: lenderContactCtrl.text,
                        lenderAddress: lenderAddressCtrl.text,
                        loanDate: original.loanDate,
                        isReturned: original.isReturned,
                        notes: notesCtrl.text,
                      );
                    }
                  } else {
                    _loans.insert(
                      0,
                      MedicamentLoan(
                        id: 'PRET-${_loans.length + 1}'.padLeft(7, '0'),
                        items: dialogItems,
                        lenderType: lenderType,
                        lenderName: lenderNameCtrl.text,
                        lenderContact: lenderContactCtrl.text,
                        lenderAddress: lenderAddressCtrl.text,
                        loanDate: DateTime.now(),
                        notes: notesCtrl.text,
                      ),
                    );
                  }
                });
                Navigator.pop(ctx);
              },
              icon: Icon(Icons.save_rounded, size: 16),
              label: Text(
                'Enregistrer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isNumber = false,
    bool isPhone = false,
  }) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return TextField(
      controller: ctrl,
      keyboardType: isPhone
          ? TextInputType.phone
          : (isNumber ? TextInputType.number : TextInputType.text),
      inputFormatters: isPhone
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ]
          : (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
      style: TextStyle(color: state.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: state.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: state.textSecondaryLight, size: 18),
        filled: true,
        fillColor: state.bgPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _typeChip(
    String value,
    String label,
    IconData icon,
    String current,
    Function(String) onTap,
  ) {
    final selected = current == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? themeColor.withOpacity(0.15) : state.bgPrimary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? themeColor : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? themeColor : state.textSecondaryLight,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? themeColor : state.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
