import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/app_state_provider.dart';
import 'package:flutter/services.dart';
import '../models/pharmacy_models.dart';

// ===== MAIN VIEW =====
class LoansView extends StatefulWidget {
  const LoansView({super.key});

  @override
  State<LoansView> createState() => _LoansViewState();
}

class _LoansViewState extends State<LoansView>
    with SingleTickerProviderStateMixin {
  AppStateProvider get state => Provider.of<AppStateProvider>(context);

  bool _isTableView = true; // Par défaut: Vue Tableau Général
  String _searchQuery = '';
  String _statusFilter = 'TOUTES'; // 'TOUTES', 'EN_COURS', 'REGLEES'
  final TextEditingController _searchCtrl = TextEditingController();

  final _fmt = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'GNF',
    decimalDigits: 0,
  );
  final themeColor = const Color(0xFF10B981);

  Patient? _findMatchingPatient(AppStateProvider state, MedicamentLoan loan) {
    final nameLower = loan.lenderName.trim().toLowerCase();
    if (nameLower.isEmpty) return null;
    final matches = state.patients.where((p) =>
        p.fullName.trim().toLowerCase() == nameLower ||
        (p.phone.isNotEmpty && p.phone.trim() == loan.lenderContact.trim()));
    return matches.isNotEmpty ? matches.first : null;
  }

  // ── IMPRESSION LISTE DES DETTES ──────────────────────────────────────────
  Future<void> _printLoansList(List<MedicamentLoan> loans, String title) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final logoBytes = state.pharmacyLogo;
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
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
                            width: 40,
                            height: 40,
                            child: pw.Image(
                              pw.MemoryImage(logoBytes),
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'PharmaGuinée',
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.teal,
                                ),
                              ),
                              pw.Text(
                                'Système de Gestion de Pharmacie',
                                style: pw.TextStyle(
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
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.teal,
                            ),
                          ),
                          pw.Text(
                            'Système de Gestion de Pharmacie',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'LISTE GÉNÉRALE DES DETTES',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    pw.Text(
                      'Imprimé le: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2), // N° Dette
                1: pw.FlexColumnWidth(1.0), // Date
                2: pw.FlexColumnWidth(2.2), // Client / Prêteur
                3: pw.FlexColumnWidth(1.0), // Points
                4: pw.FlexColumnWidth(2.5), // Médicaments
                5: pw.FlexColumnWidth(1.5), // Montant
                6: pw.FlexColumnWidth(1.0), // Statut
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                  children: [
                    'N° Dette', 'Date', 'Client / Prêteur', 'Points Fidélité', 'Médicaments', 'Montant Total', 'Statut'
                  ].map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      h,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                    ),
                  )).toList(),
                ),
                // Rows
                ...loans.map((loan) {
                  final patient = _findMatchingPatient(state, loan);
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(loan.id, style: pw.TextStyle(fontSize: 7.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(DateFormat('dd/MM/yyyy').format(loan.loanDate), style: pw.TextStyle(fontSize: 7.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(loan.lenderName, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                            if (loan.lenderContact.isNotEmpty)
                              pw.Text('Tél: ${loan.lenderContact}', style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          patient != null ? '${patient.loyaltyPoints} pts' : '—',
                          style: pw.TextStyle(fontSize: 7.5, color: patient != null ? PdfColors.amber800 : PdfColors.grey600),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(loan.medicamentName, style: pw.TextStyle(fontSize: 7.5)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          _fmt.format(loan.totalValue),
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          loan.isReturned ? 'Réglé' : 'En cours',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: loan.isReturned ? PdfColors.green700 : PdfColors.orange800,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 15),

            // Summary Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Total de dettes listées: ${loans.length}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        'Total valeur en cours : ${_fmt.format(loans.where((l) => !l.isReturned).fold(0.0, (s, l) => s + l.totalValue))}',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700),
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
      name: 'Liste_Dettes_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  // ── EXPORT PDF LISTE DES DETTES ──────────────────────────────────────────
  Future<void> _exportLoansListPdf(List<MedicamentLoan> loans, String title) async {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final logoBytes = state.pharmacyLogo;
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                logoBytes != null
                    ? pw.Row(
                        children: [
                          pw.Container(
                            width: 40,
                            height: 40,
                            child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.cover),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text('PharmaGuinée', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                        ],
                      )
                    : pw.Text('PharmaGuinée', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('EXPORTE - LISTE GÉNÉRALE DES DETTES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.teal, thickness: 1),
            pw.SizedBox(height: 10),
            pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(1.0),
                2: pw.FlexColumnWidth(2.0),
                3: pw.FlexColumnWidth(1.0),
                4: pw.FlexColumnWidth(2.5),
                5: pw.FlexColumnWidth(1.4),
                6: pw.FlexColumnWidth(0.9),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                  children: ['N° Dette', 'Date', 'Client / Prêteur', 'Points', 'Médicaments', 'Montant Total', 'Statut']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                          ))
                      .toList(),
                ),
                ...loans.map((loan) {
                  final patient = _findMatchingPatient(state, loan);
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(loan.id, style: pw.TextStyle(fontSize: 7.5))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('dd/MM/yy').format(loan.loanDate), style: pw.TextStyle(fontSize: 7.5))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(loan.lenderName, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                        if (loan.lenderContact.isNotEmpty)
                          pw.Text(loan.lenderContact, style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                      ],
                    )),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(patient != null ? '${patient.loyaltyPoints} pts' : '—', style: pw.TextStyle(fontSize: 7.5))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(loan.medicamentName, style: pw.TextStyle(fontSize: 7.5))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_fmt.format(loan.totalValue), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(loan.isReturned ? 'Réglé' : 'En cours', style: pw.TextStyle(fontSize: 7.5, color: loan.isReturned ? PdfColors.green700 : PdfColors.orange700))),
                  ]);
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('Total de dettes: ${loans.length}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text('Valeur totale en cours : ${_fmt.format(loans.where((l) => !l.isReturned).fold(0.0, (s, l) => s + l.totalValue))}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                ]),
              ),
            ]),
          ];
        },
      ),
    );

    try {
      final bytes = await doc.save();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Liste_Dettes_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fichier PDF enregistré : ${file.path}'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
        ));
      }
    } catch (_) {
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'Liste_Dettes_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    }
  }

  Future<void> _printSingleLoan(MedicamentLoan loan) async {
    final logoBytes = state.pharmacyLogo;
    final doc = pw.Document();
    final patient = _findMatchingPatient(state, loan);

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
                    'REÇU DE DETTE / PRÊT',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.teal),
              pw.SizedBox(height: 10),

              // Loan info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'N° Reçu: ${loan.id}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(loan.loanDate)}',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: loan.isReturned ? PdfColors.green50 : PdfColors.orange50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(
                        color: loan.isReturned ? PdfColors.green : PdfColors.orange,
                      ),
                    ),
                    child: pw.Text(
                      loan.isReturned ? 'STATUT: RÉGLÉ' : 'STATUT: EN COURS',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: loan.isReturned ? PdfColors.green700 : PdfColors.orange700,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Lender details
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CONCERNÉ(E) / DEBITEUR :',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      loan.lenderName,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Contact : ${loan.lenderContact.isNotEmpty ? loan.lenderContact : "N/A"} | Adresse: ${loan.lenderAddress.isNotEmpty ? loan.lenderAddress : "N/A"}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                    ),
                    if (patient != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        '⭐ Points de fidélité accumulés : ${patient.loyaltyPoints} pts',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                      ),
                    ],
                    if (loan.notes.isNotEmpty)
                      pw.Text(
                        'Note: ${loan.notes}',
                        style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Items table
              pw.Text(
                'DÉTAILS DES PRODUITS',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.0),
                  1: pw.FlexColumnWidth(1.0),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(1.8),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Désignation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Prix unitaire', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  ...loan.items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.productName, style: pw.TextStyle(fontSize: 7.5))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_fmt.format(item.unitValue), style: pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(_fmt.format(item.totalValue), style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ).toList(),
                ],
              ),
              pw.SizedBox(height: 10),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'MONTANT TOTAL DE LA DETTE : ',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    _fmt.format(loan.totalValue),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal700,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Signature du Client', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.SizedBox(height: 20),
                      pw.Text('____________________', style: pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Pour la Pharmacie', style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      pw.SizedBox(height: 20),
                      pw.Text('____________________', style: pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Reçu_${loan.id}',
    );
  }

  // ── MODAL ÉDITION POINTS CLIENT ──────────────────────────────────────────
  void _showEditLoyaltyPointsDialog(BuildContext context, Patient patient) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final pointsCtrl = TextEditingController(text: patient.loyaltyPoints.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: state.bgSecondary,
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Points de fidélité : ${patient.fullName}',
                style: GoogleFonts.outfit(
                  color: state.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modifier le solde des points de fidélité pour ce client.',
                style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pointsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: state.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Nombre de points',
                  labelStyle: TextStyle(color: state.textSecondary, fontSize: 12),
                  suffixText: 'pts',
                  suffixStyle: GoogleFonts.inter(color: Colors.amber, fontWeight: FontWeight.bold),
                  prefixIcon: const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                  filled: true,
                  fillColor: state.bgPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.inter(color: state.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final newPts = int.tryParse(pointsCtrl.text) ?? 0;
              state.updatePatientLoyaltyPoints(patient.id, newPts);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Points de fidélité mis à jour pour ${patient.fullName} : $newPts pts'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: Text('Enregistrer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── CONFIRMATION DE PURGE DES DETTES ──────────────────────────────────────
  void _confirmClearLoans({required bool onlyReturned}) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final count = onlyReturned
        ? state.loans.where((l) => l.isReturned).length
        : state.loans.length;

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(onlyReturned ? 'Aucune dette réglée à purger.' : 'Aucune dette à supprimer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: state.bgSecondary,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              onlyReturned ? 'Purger les dettes réglées' : 'Tout Supprimer',
              style: GoogleFonts.outfit(color: state.textPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          onlyReturned
              ? 'Voulez-vous vraiment supprimer définitivement les $count dette(s) déjà réglée(s) ?'
              : 'ATTENTION : Voulez-vous vraiment effacer TOUTES les $count dette(s) de la base de données ?',
          style: GoogleFonts.inter(color: state.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              state.clearLoans(onlyReturned: onlyReturned);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(onlyReturned ? 'Dettes réglées purgées avec succès.' : 'Toutes les dettes ont été effacées.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Confirmer la suppression'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── ENTÊTE PRINCIPAL ───────────────────────────────────────────────────────
  Widget _buildHeader(List<MedicamentLoan> allLoans, double grandTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        color: state.bgSecondary,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Gestion des Dettes',
                    style: GoogleFonts.outfit(
                      color: state.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Mode switcher
                  Container(
                    decoration: BoxDecoration(
                      color: state.bgPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _viewModeChip(
                          icon: Icons.table_chart_rounded,
                          label: 'Liste Générale',
                          selected: _isTableView,
                          onTap: () => setState(() => _isTableView = true),
                        ),
                        _viewModeChip(
                          icon: Icons.grid_view_rounded,
                          label: 'Vue Cartes',
                          selected: !_isTableView,
                          onTap: () => setState(() => _isTableView = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Suivi général des dettes clients, impression et export PDF',
                style: GoogleFonts.inter(
                  color: state.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              // Total active badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Total dettes actives : ${_fmt.format(grandTotal)}',
                      style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Header action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (allLoans.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => _exportLoansListPdf(allLoans, 'Liste Générale des Dettes'),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: Text('Exporter PDF', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _printLoansList(allLoans, 'Liste Générale des Dettes'),
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: Text('Imprimer tout', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.textSecondary,
                    side: const BorderSide(color: Color(0xFF475569)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                // Purger réglées button
                PopupMenuButton<String>(
                  color: state.bgSecondary,
                  tooltip: 'Options de suppression',
                  onSelected: (val) {
                    if (val == 'PURGE_REGLEES') {
                      _confirmClearLoans(onlyReturned: true);
                    } else if (val == 'CLEAR_ALL') {
                      _confirmClearLoans(onlyReturned: false);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'PURGE_REGLEES',
                      child: Row(
                        children: [
                          const Icon(Icons.cleaning_services_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text('Purger les dettes réglées', style: GoogleFonts.inter(color: state.textPrimary, fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'CLEAR_ALL',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Text('Tout supprimer', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                        const SizedBox(width: 6),
                        Text('Purger / Effacer', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Icon(Icons.arrow_drop_down, color: Colors.redAccent, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                onPressed: () => _showAddLoanDialog(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Nouvelle Dette',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewModeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : state.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : state.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── VUE TABLEAU GÉNÉRAL DES DETTES ─────────────────────────────────────────
  Widget _buildGeneralDebtTableTab(List<MedicamentLoan> loans) {
    final filtered = loans.where((loan) {
      // Status filter
      if (_statusFilter == 'EN_COURS' && loan.isReturned) return false;
      if (_statusFilter == 'REGLEES' && !loan.isReturned) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesId = loan.id.toLowerCase().contains(q);
        final matchesName = loan.lenderName.toLowerCase().contains(q);
        final matchesContact = loan.lenderContact.toLowerCase().contains(q);
        final matchesMed = loan.medicamentName.toLowerCase().contains(q);
        final matchesNotes = loan.notes.toLowerCase().contains(q);
        if (!matchesId && !matchesName && !matchesContact && !matchesMed && !matchesNotes) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Controls Row: Search & Filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          color: state.bgPrimary,
          child: Row(
            children: [
              // Search input
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: state.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par client, téléphone, n° dette, médicament...',
                      hintStyle: TextStyle(color: state.textSecondaryLight, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: state.textSecondaryLight, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: state.bgSecondary,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Filter Chips
              Row(
                children: [
                  _statusFilterChip('Toutes (${loans.length})', 'TOUTES'),
                  const SizedBox(width: 8),
                  _statusFilterChip(
                    'En cours (${loans.where((l) => !l.isReturned).length})',
                    'EN_COURS',
                    activeColor: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _statusFilterChip(
                    'Réglées (${loans.where((l) => l.isReturned).length})',
                    'REGLEES',
                    activeColor: themeColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Table List View
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('Aucune dette correspondant aux critères.')
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: state.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2), // N° Dette
                        1: FlexColumnWidth(1.1), // Date
                        2: FlexColumnWidth(2.2), // Client / Prêteur
                        3: FlexColumnWidth(1.3), // Points
                        4: FlexColumnWidth(2.6), // Médicaments
                        5: FlexColumnWidth(1.5), // Total
                        6: FlexColumnWidth(1.2), // Statut
                        7: FlexColumnWidth(1.6), // Actions
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        // Table Header
                        TableRow(
                          decoration: BoxDecoration(
                            color: state.bgPrimary,
                            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
                          ),
                          children: [
                            _thCell('N° Dette'),
                            _thCell('Date'),
                            _thCell('Client / Prêteur'),
                            _thCell('Points Fidélité'),
                            _thCell('Médicaments'),
                            _thCell('Montant Total', alignRight: true),
                            _thCell('Statut', alignCenter: true),
                            _thCell('Actions', alignRight: true),
                          ],
                        ),
                        // Table Rows
                        ...filtered.map((loan) {
                          final patient = _findMatchingPatient(state, loan);
                          return TableRow(
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04))),
                            ),
                            children: [
                              // N° Dette
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Text(
                                  loan.id,
                                  style: GoogleFonts.inter(
                                    color: state.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Date
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(loan.loanDate),
                                  style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11),
                                ),
                              ),
                              // Client / Prêteur
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.lenderName,
                                      style: GoogleFonts.inter(
                                        color: state.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (loan.lenderContact.isNotEmpty)
                                      Text(
                                        loan.lenderContact,
                                        style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 10.5),
                                      ),
                                  ],
                                ),
                              ),
                              // Points Fidélité
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: patient != null
                                    ? InkWell(
                                        onTap: () => _showEditLoyaltyPointsDialog(context, patient),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.stars_rounded, color: Colors.amber, size: 13),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${patient.loyaltyPoints} pts',
                                                style: GoogleFonts.inter(
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.edit_rounded, color: Colors.amber, size: 10),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Text('—', style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 11)),
                              ),
                              // Médicaments
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Text(
                                  loan.medicamentName,
                                  style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Montant Total
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Text(
                                  _fmt.format(loan.totalValue),
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.outfit(
                                    color: loan.isReturned ? state.textSecondaryLight : themeColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    decoration: loan.isReturned ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                ),
                              ),
                              // Statut (Bouton bascule rapide)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Center(
                                  child: InkWell(
                                    onTap: () {
                                      final s = Provider.of<AppStateProvider>(context, listen: false);
                                      s.updateLoan(MedicamentLoan(
                                        id: loan.id,
                                        items: loan.items,
                                        lenderType: loan.lenderType,
                                        lenderName: loan.lenderName,
                                        lenderContact: loan.lenderContact,
                                        lenderAddress: loan.lenderAddress,
                                        loanDate: loan.loanDate,
                                        isReturned: !loan.isReturned,
                                        notes: loan.notes,
                                        saleId: loan.saleId,
                                      ));
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: loan.isReturned
                                            ? themeColor.withOpacity(0.12)
                                            : Colors.orange.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: loan.isReturned ? themeColor : Colors.orange,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            loan.isReturned ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                                            size: 12,
                                            color: loan.isReturned ? themeColor : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            loan.isReturned ? 'Réglé' : 'En cours',
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: loan.isReturned ? themeColor : Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Actions
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // Print Reçu
                                    IconButton(
                                      icon: const Icon(Icons.print_rounded, size: 16),
                                      color: state.textSecondary,
                                      tooltip: 'Imprimer le reçu',
                                      onPressed: () => _printSingleLoan(loan),
                                    ),
                                    // Modifier
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, size: 16),
                                      color: Colors.blueAccent,
                                      tooltip: 'Modifier',
                                      onPressed: () => _showAddLoanDialog(context, loan),
                                    ),
                                    // Supprimer
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                      color: Colors.redAccent,
                                      tooltip: 'Supprimer cette dette',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (dCtx) => AlertDialog(
                                            backgroundColor: state.bgSecondary,
                                            title: Text(
                                              'Confirmer la suppression',
                                              style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold),
                                            ),
                                            content: Text(
                                              'Voulez-vous vraiment supprimer la dette N° ${loan.id} (${loan.lenderName}) ?',
                                              style: GoogleFonts.inter(color: state.textSecondary),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dCtx),
                                                child: const Text('Annuler'),
                                              ),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  final s = Provider.of<AppStateProvider>(context, listen: false);
                                                  s.deleteLoan(loan.id);
                                                  Navigator.pop(dCtx);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Dette ${loan.id} supprimée.'),
                                                      backgroundColor: Colors.redAccent,
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.delete_rounded, size: 16),
                                                label: const Text('Supprimer'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _thCell(String text, {bool alignRight = false, bool alignCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : (alignCenter ? TextAlign.center : TextAlign.left),
        style: GoogleFonts.inter(
          color: state.textSecondaryLight,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusFilterChip(String label, String value, {Color activeColor = const Color(0xFF10B981)}) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : state.bgSecondary,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? activeColor : state.textSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── VUE PAR CARTES (DEUX SECTIONS : EN COURS / RÉGLÉES) ───────────────────
  Widget _buildDetteListTab(List<MedicamentLoan> loansList, String typeLabel) {
    final pending = loansList.where((l) => !l.isReturned).toList();
    final returned = loansList.where((l) => l.isReturned).toList();
    final totalPending = pending.fold(0.0, (s, l) => s + l.totalValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                : () => _printLoansList(pending, 'Liste des $typeLabel en cours'),
            onExportPdf: pending.isEmpty
                ? null
                : () => _exportLoansListPdf(pending, 'Dettes $typeLabel en cours'),
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
                : () => _printLoansList(returned, 'Liste des $typeLabel réglées'),
            onExportPdf: returned.isEmpty
                ? null
                : () => _exportLoansListPdf(returned, 'Dettes $typeLabel réglées'),
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

  Widget _buildSectionTitle(
    String title,
    IconData icon,
    Color color, {
    VoidCallback? onPrint,
    VoidCallback? onExportPdf,
  }) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: state.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onPrint != null) ...[
          const SizedBox(width: 10),
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
        if (onExportPdf != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'Exporter en PDF',
            child: InkWell(
              onTap: onExportPdf,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 14),
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
    final patient = _findMatchingPatient(state, loan);

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
          // Top Row: ID + Status + Points + Date
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
              const SizedBox(width: 10),
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
              if (patient != null) ...[
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _showEditLoyaltyPointsDialog(context, patient),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${patient.loyaltyPoints} pts de fidélité',
                          style: GoogleFonts.inter(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_rounded, color: Colors.amber, size: 11),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Icon(
                Icons.calendar_today_rounded,
                color: state.textSecondaryLight,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy').format(loan.loanDate),
                style: GoogleFonts.inter(
                  color: state.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Info Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          const Icon(
                            Icons.medication_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
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
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.5),
                          1: FlexColumnWidth(0.8),
                          2: FlexColumnWidth(1.2),
                          3: FlexColumnWidth(1.5),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
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
                                child: Text('Produit', style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('Quantité', style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('P.U.', style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('Valeur', style: GoogleFonts.inter(color: state.textSecondaryLight, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          ...loan.items.map(
                            (item) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(item.productName, style: GoogleFonts.inter(color: state.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w600)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text('${item.quantity}', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(_fmt.format(item.unitValue), style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11), textAlign: TextAlign.right),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(_fmt.format(item.totalValue), style: GoogleFonts.inter(color: themeColor, fontSize: 11.5, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                          ).toList(),
                        ],
                      ),
                      Divider(color: Colors.white.withOpacity(0.04), height: 16),
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
                              color: loan.isReturned ? state.textSecondaryLight : themeColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              decoration: loan.isReturned ? TextDecoration.lineThrough : TextDecoration.none,
                              decorationColor: state.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Lender info
              Expanded(
                child: _infoBlock(
                  icon: loan.lenderType == 'pharmacie' ? Icons.local_pharmacy_rounded : Icons.person_rounded,
                  iconColor: loan.lenderType == 'pharmacie' ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B),
                  label: loan.lenderType == 'pharmacie' ? 'Pharmacie prêteuse' : 'Personne prêteuse / Client',
                  lines: [
                    loan.lenderName,
                    'Contact : ${loan.lenderContact.isNotEmpty ? loan.lenderContact : "Non renseigné"}',
                    'Adresse : ${loan.lenderAddress.isNotEmpty ? loan.lenderAddress : "Non renseignée"}',
                    if (loan.notes.isNotEmpty) 'Note : ${loan.notes}',
                  ],
                ),
              ),
            ],
          ),

          // Action buttons row
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddLoanDialog(context, loan),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: Text('Modifier', style: GoogleFonts.inter(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _printSingleLoan(loan),
                icon: const Icon(Icons.print_rounded, size: 16),
                label: Text('Imprimer le reçu', style: GoogleFonts.inter(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: state.textSecondary,
                  side: const BorderSide(color: Color(0xFF475569)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: state.bgSecondary,
                      title: Text('Confirmer la suppression', style: GoogleFonts.inter(color: state.textPrimary)),
                      content: Text('Voulez-vous vraiment supprimer cette dette ?', style: GoogleFonts.inter(color: state.textSecondary)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            final s = Provider.of<AppStateProvider>(context, listen: false);
                            s.deleteLoan(loan.id);
                            Navigator.pop(dCtx);
                          },
                          child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text('Supprimer', style: GoogleFonts.inter(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (!loan.isReturned) ...[
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    final s = Provider.of<AppStateProvider>(context, listen: false);
                    s.updateLoan(MedicamentLoan(
                      id: loan.id,
                      items: loan.items,
                      lenderType: loan.lenderType,
                      lenderName: loan.lenderName,
                      lenderContact: loan.lenderContact,
                      lenderAddress: loan.lenderAddress,
                      loanDate: loan.loanDate,
                      isReturned: true,
                      notes: loan.notes,
                      saleId: loan.saleId,
                    ));
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text('Marquer comme Réglé', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: state.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
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

  // ── DIALOGUE D'AJOUT / MODIFICATION DE DETTE ──────────────────────────────
  void _showAddLoanDialog(BuildContext context, [MedicamentLoan? original]) {
    final state = Provider.of<AppStateProvider>(context, listen: false);
    final isEdit = original != null;
    final List<LoanItem> dialogItems = isEdit ? List.from(original.items) : [];

    String? selectedProductName;
    Patient? selectedPatient;
    final quantityCtrl = TextEditingController();
    final valueCtrl = TextEditingController();

    final lenderNameCtrl = TextEditingController(text: isEdit ? original.lenderName : '');
    final lenderContactCtrl = TextEditingController(text: isEdit ? original.lenderContact : '');
    final lenderAddressCtrl = TextEditingController(text: isEdit ? original.lenderAddress : '');
    final notesCtrl = TextEditingController(text: isEdit ? original.notes : '');
    String lenderType = isEdit ? original.lenderType : 'personne';

    // If edit, pre-select matching patient
    if (isEdit) {
      selectedPatient = _findMatchingPatient(state, original);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: state.bgSecondary,
          title: Text(
            isEdit ? 'Modifier la Dette de Médicaments' : 'Enregistrer une Dette de Médicaments',
            style: GoogleFonts.outfit(
              color: state.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type de prêteur
                  Text(
                    'TYPE DE CONCERNÉ(E)',
                    style: GoogleFonts.inter(
                      color: state.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _typeChip(
                        'personne',
                        'Personne / Client',
                        Icons.person_rounded,
                        lenderType,
                        (v) => setS(() => lenderType = v),
                      ),
                      const SizedBox(width: 12),
                      _typeChip(
                        'pharmacie',
                        'Pharmacie',
                        Icons.local_pharmacy_rounded,
                        lenderType,
                        (v) => setS(() => lenderType = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Si c'est une personne, sélecteur de patient rapide
                  if (lenderType == 'personne' && state.patients.isNotEmpty) ...[
                    Text(
                      'SÉLECTIONNER UN CLIENT EXISTANT (OPTIONNEL)',
                      style: GoogleFonts.inter(
                        color: state.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Patient>(
                      value: selectedPatient,
                      dropdownColor: state.bgSecondary,
                      style: TextStyle(color: state.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Sélectionner un client enregistré',
                        labelStyle: TextStyle(color: state.textSecondary, fontSize: 12),
                        prefixIcon: const Icon(Icons.person_search_rounded, color: Colors.amber, size: 18),
                        filled: true,
                        fillColor: state.bgPrimary,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      items: state.patients
                          .map((p) => DropdownMenuItem<Patient>(
                                value: p,
                                child: Text('${p.fullName} (${p.loyaltyPoints} pts fidélité)'),
                              ))
                          .toList(),
                      onChanged: (pat) {
                        if (pat != null) {
                          setS(() {
                            selectedPatient = pat;
                            lenderNameCtrl.text = pat.fullName;
                            lenderContactCtrl.text = pat.phone;
                            lenderAddressCtrl.text = pat.quartier;
                          });
                        }
                      },
                    ),
                    if (selectedPatient != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Ce client possède ${selectedPatient!.loyaltyPoints} points de fidélité',
                              style: GoogleFonts.inter(color: Colors.amber, fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                  ],

                  // Information du prêteur
                  Text(
                    lenderType == 'pharmacie' ? 'INFORMATIONS DE LA PHARMACIE' : 'INFORMATIONS DU CLIENT / PERSONNE',
                    style: GoogleFonts.inter(
                      color: state.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dialogField(
                    lenderNameCtrl,
                    lenderType == 'pharmacie' ? 'Nom de la pharmacie' : 'Nom et Prénom',
                    Icons.badge_rounded,
                  ),
                  const SizedBox(height: 10),
                  _dialogField(
                    lenderContactCtrl,
                    'Numéro de téléphone',
                    Icons.phone_rounded,
                    isPhone: true,
                  ),
                  const SizedBox(height: 10),
                  _dialogField(
                    lenderAddressCtrl,
                    'Adresse / Quartier',
                    Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Médicaments au prêt
                  Text(
                    'AJOUTER DES MÉDICAMENTS À LA DETTE',
                    style: GoogleFonts.inter(
                      color: state.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedProductName,
                    dropdownColor: state.bgSecondary,
                    style: TextStyle(color: state.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Sélectionner un médicament',
                      labelStyle: TextStyle(color: state.textSecondary, fontSize: 12),
                      prefixIcon: Icon(Icons.medication_rounded, color: state.textSecondaryLight, size: 18),
                      filled: true,
                      fillColor: state.bgPrimary,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    items: (() {
                      final sortedProds = List<Product>.from(state.products);
                      sortedProds.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                      return sortedProds
                          .map((p) => DropdownMenuItem<String>(
                                value: p.name,
                                child: Text(p.name, overflow: TextOverflow.ellipsis),
                              ))
                          .toList();
                    })(),
                    onChanged: (val) {
                      setS(() {
                        selectedProductName = val;
                        final matching = state.products.where((p) => p.name == val);
                        if (matching.isNotEmpty) {
                          valueCtrl.text = matching.first.purchasePrice.toInt().toString();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
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
                      const SizedBox(width: 12),
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (selectedProductName == null || quantityCtrl.text.isEmpty || valueCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez sélectionner un produit, sa quantité et sa valeur.'),
                              backgroundColor: Colors.orangeAccent,
                            ),
                          );
                          return;
                        }
                        final qty = int.tryParse(quantityCtrl.text) ?? 0;
                        final val = double.tryParse(valueCtrl.text) ?? 0.0;
                        if (qty <= 0) return;

                        setS(() {
                          dialogItems.add(LoanItem(
                            productName: selectedProductName!,
                            quantity: qty,
                            unitValue: val,
                          ));
                          selectedProductName = null;
                          quantityCtrl.clear();
                          valueCtrl.clear();
                        });
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Ajouter l\'article'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),

                  if (dialogItems.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: state.bgPrimary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: dialogItems.length,
                        itemBuilder: (c, idx) {
                          final item = dialogItems[idx];
                          return ListTile(
                            dense: true,
                            title: Text(item.productName, style: GoogleFonts.inter(color: state.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5)),
                            subtitle: Text('Quantité: ${item.quantity} × ${_fmt.format(item.unitValue)}', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_fmt.format(item.totalValue), style: GoogleFonts.inter(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12.5)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () => setS(() => dialogItems.removeAt(idx)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valeur totale cumulée :', style: GoogleFonts.inter(color: state.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          _fmt.format(dialogItems.fold(0.0, (sum, item) => sum + item.totalValue)),
                          style: GoogleFonts.outfit(color: themeColor, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),
                  _dialogField(notesCtrl, 'Notes (optionnel)', Icons.notes_rounded),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler', style: GoogleFonts.inter(color: state.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (dialogItems.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Veuillez ajouter au moins un médicament au prêt.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }
                if (lenderNameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Veuillez renseigner le nom du prêteur/client.'), backgroundColor: Colors.redAccent),
                  );
                  return;
                }

                final s = Provider.of<AppStateProvider>(context, listen: false);
                if (isEdit) {
                  s.updateLoan(MedicamentLoan(
                    id: original!.id,
                    items: dialogItems,
                    lenderType: lenderType,
                    lenderName: lenderNameCtrl.text,
                    lenderContact: lenderContactCtrl.text,
                    lenderAddress: lenderAddressCtrl.text,
                    loanDate: original.loanDate,
                    isReturned: original.isReturned,
                    notes: notesCtrl.text,
                    saleId: original.saleId,
                  ));
                } else {
                  s.addLoan(MedicamentLoan(
                    id: 'DETTE-${DateTime.now().millisecondsSinceEpoch}',
                    items: dialogItems,
                    lenderType: lenderType,
                    lenderName: lenderNameCtrl.text,
                    lenderContact: lenderContactCtrl.text,
                    lenderAddress: lenderAddressCtrl.text,
                    loanDate: DateTime.now(),
                    notes: notesCtrl.text,
                  ));
                }
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.save_rounded, size: 16),
              label: Text('Enregistrer', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      keyboardType: isPhone ? TextInputType.phone : (isNumber ? TextInputType.number : TextInputType.text),
      inputFormatters: isPhone
          ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]
          : (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
      style: TextStyle(color: state.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: state.textSecondary, fontSize: 12),
        prefixIcon: Icon(icon, color: state.textSecondaryLight, size: 18),
        filled: true,
        fillColor: state.bgPrimary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
              const SizedBox(width: 6),
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

  @override
  Widget build(BuildContext context) {
    final allLoans = state.loans;
    final clientLoans = allLoans.where((l) => l.lenderType == 'personne').toList();
    final allPending = allLoans.where((l) => !l.isReturned).toList();
    final grandTotal = allPending.fold(0.0, (s, l) => s + l.totalValue);

    return Container(
      color: state.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header principal
          _buildHeader(allLoans, grandTotal),

          // Main View Content (Tableau Général ou Cartes)
          Expanded(
            child: _isTableView
                ? _buildGeneralDebtTableTab(allLoans)
                : _buildDetteListTab(clientLoans, 'dettes clients'),
          ),
        ],
      ),
    );
  }
}
