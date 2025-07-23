import 'dart:typed_data';
import 'dart:html' as html;
import 'package:pdf/widgets.dart' as pw;

Future<void> savePdfFileWeb(pw.Document pdf) async {
  final bytes = await pdf.save();
  final filename =
      'transaction_report_${DateTime.now().millisecondsSinceEpoch}.pdf';

  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
  html.Url.revokeObjectUrl(url);
}

// Add the mobile function signature for compatibility (will not be called on web)
Future<String> savePdfFileMobile(pw.Document pdf) async {
  throw UnsupportedError('Mobile PDF saving not supported on web');
}
