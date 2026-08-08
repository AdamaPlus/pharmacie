import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/pharmacy_models.dart';

class InvoicePrinter {
  static Future<void> printInvoice(
    Sale sale,
    Uint8List? logoBytes, {
    String pharmacyName = 'PHARMACIE GUINÉE',
    String quartier = 'Ratoma, Conakry – Guinée',
    String contact1 = '+224 622 34 56 78',
    String contact2 = '',
    bool share = false,
    int? patientLoyaltyPoints,
    int? loyaltyPointsEarned,
  }) async {
    final doc = pw.Document();
    final fmt = NumberFormat.decimalPattern('fr');

    // ── Helpers ─────────────────────────────────────────────────────────────
    pw.Widget buildRow(
      String label,
      String value, {
      double fontSize = 8,
      pw.FontWeight fontWeight = pw.FontWeight.normal,
      PdfColor color = PdfColors.black,
    }) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: fontSize, color: color),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
            ),
          ),
        ],
      );
    }

    pw.Widget buildDivider({bool dashed = false}) => pw.Divider(
      thickness: 0.6,
      color: PdfColors.grey500,
      borderStyle: dashed ? pw.BorderStyle.dashed : pw.BorderStyle.solid,
    );

    // ── Build content list ───────────────────────────────────────────────────
    final List<pw.Widget> content = [];

    // HEADER
    content.add(
      pw.Center(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoBytes != null)
              pw.Container(
                width: 44,
                height: 44,
                margin: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  fit: pw.BoxFit.cover,
                ),
              )
            else
              pw.Container(
                width: 36,
                height: 36,
                margin: const pw.EdgeInsets.only(bottom: 4),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.teal700,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Stack(
                    alignment: pw.Alignment.center,
                    children: [
                      pw.Container(
                        width: 5,
                        height: 18,
                        color: PdfColors.white,
                      ),
                      pw.Container(
                        width: 18,
                        height: 5,
                        color: PdfColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            pw.Text(
              pharmacyName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              quartier,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
            pw.Text(
              contact2.isNotEmpty
                  ? 'Tél: $contact1 / $contact2'
                  : 'Tél: $contact1',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
            pw.Text(
              'NIF: 998274-A',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );

    content.add(pw.SizedBox(height: 8));
    content.add(buildDivider(dashed: true));
    content.add(pw.SizedBox(height: 6));

    // TICKET TITLE
    content.add(
      pw.Center(
        child: pw.Text(
          'REÇU DE PAIEMENT',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
    content.add(pw.SizedBox(height: 6));

    // META
    content.add(buildRow('Reçu N°:', sale.id, fontWeight: pw.FontWeight.bold));
    content.add(pw.SizedBox(height: 2));
    content.add(
      buildRow('Date:', DateFormat('dd/MM/yyyy HH:mm').format(sale.date)),
    );
    content.add(pw.SizedBox(height: 2));
    content.add(
      buildRow(
        (sale.cashierName.toLowerCase().contains('admin') ||
         sale.cashierName.toLowerCase().contains('responsable') ||
         sale.cashierName.toLowerCase().contains('le-responsable') ||
         sale.cashierName.toLowerCase().contains('administrateur'))
            ? 'Admin:'
            : 'Caissier:',
        sale.cashierName.toUpperCase(),
        fontWeight: pw.FontWeight.bold,
      ),
    );
    content.add(pw.SizedBox(height: 2));
    content.add(
      buildRow(
        'Client:',
        sale.patientName ?? 'Passager',
        fontWeight: pw.FontWeight.bold,
      ),
    );
    // Loyalty points section (if patient linked)
    if (patientLoyaltyPoints != null && sale.patientName != null) {
      content.add(pw.SizedBox(height: 2));
      content.add(
        buildRow(
          'Points fidélité:',
          '${patientLoyaltyPoints} pts ${loyaltyPointsEarned != null && loyaltyPointsEarned > 0 ? '(+$loyaltyPointsEarned ce jour)' : ''}',
          color: PdfColors.teal700,
          fontWeight: pw.FontWeight.bold,
        ),
      );
    }
    content.add(pw.SizedBox(height: 8));

    // ITEMS HEADER
    content.add(
      pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                'Désignation',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 20,
              child: pw.Text(
                'Quantité',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 40,
              child: pw.Text(
                'P.U',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(
              width: 44,
              child: pw.Text(
                'Total',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // ITEMS ROWS
    for (final item in sale.items) {
      content.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  item.productName,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(
                width: 20,
                child: pw.Text(
                  '${item.quantity}',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(
                width: 40,
                child: pw.Text(
                  fmt.format(item.unitPrice),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
              pw.SizedBox(
                width: 44,
                child: pw.Text(
                  fmt.format(item.total),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    content.add(pw.SizedBox(height: 4));
    content.add(buildDivider());
    content.add(pw.SizedBox(height: 4));

    // TOTALS
    content.add(buildRow('Total Brut:', '${fmt.format(sale.totalAmount)} GNF'));
    if (sale.discountAmount > 0) {
      content.add(pw.SizedBox(height: 2));
      content.add(
        buildRow(
          'Remise:',
          '- ${fmt.format(sale.discountAmount)} GNF',
          color: PdfColors.red700,
        ),
      );
    }
    content.add(pw.SizedBox(height: 4));

    // NET À PAYER (highlighted)
    content.add(
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(width: 1, color: PdfColors.teal800),
            bottom: pw.BorderSide(width: 1, color: PdfColors.teal800),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'NET À PAYER:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
            pw.Text(
              '${fmt.format(sale.netAmount)} GNF',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
          ],
        ),
      ),
    );
    content.add(pw.SizedBox(height: 5));

    // PAYMENT METHOD
    content.add(
      buildRow(
        'Règlement:',
        sale.paymentMethod,
        fontWeight: pw.FontWeight.bold,
      ),
    );

    content.add(pw.SizedBox(height: 10));
    content.add(buildDivider(dashed: true));
    content.add(pw.SizedBox(height: 6));

    // FOOTER
    content.add(
      pw.Center(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              '★  MERCI DE VOTRE CONFIANCE  ★',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'On vous souhaite prompt rétablissement.',
              style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // ── Build the page with DYNAMIC height ──────────────────────────────────
    // Use a fixed-width roll (80mm) but compute height from content
    const double pageWidthPt = 80 * PdfPageFormat.mm;

    final dynamicFormat = PdfPageFormat.roll80.copyWith(
      marginBottom: 12.0,
      marginTop: 12.0,
      marginLeft: 12.0,
      marginRight: 12.0,
    );

    doc.addPage(
      pw.Page(
        pageFormat: dynamicFormat,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context ctx) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              mainAxisSize: pw.MainAxisSize.min,
              children: content,
            ),
          );
        },
      ),
    );

    if (share) {
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'facture_${sale.id.replaceAll(RegExp(r'[^\w-]'), "_")}.pdf',
      );
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
      );
    }
  }
}
