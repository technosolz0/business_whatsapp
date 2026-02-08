// Conditional export based on platform
export 'webutils_stub.dart' if (dart.library.html) 'webutils_web.dart';
