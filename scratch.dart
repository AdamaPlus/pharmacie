import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  try {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (pw.Context context) {
        return pw.Text("Hello world");
      }
    ));
    final bytes = await doc.save();
    print("SUCCESS: ${bytes.length} bytes");
  } catch (e) {
    print("ERROR: $e");
  }
}
