import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

Future<String> savePdfFileMobile(pw.Document pdf) async {
  final bytes = await pdf.save();

  // Use app's document directory instead of external storage
  // This doesn't require special permissions on modern Android
  final dir = await getApplicationDocumentsDirectory();

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final file = File('${dir.path}/transaction_report_$timestamp.pdf');

  await file.writeAsBytes(bytes);
  return file.path;
}

// Add the web function signature for compatibility (will not be called on mobile)
Future<void> savePdfFileWeb(pw.Document pdf) async {
  throw UnsupportedError('Web PDF saving not supported on mobile');
}
