// Conditional exports for platform-specific PDF saving
export 'pdf_saver_mobile.dart' if (dart.library.html) 'pdf_saver_web.dart';
