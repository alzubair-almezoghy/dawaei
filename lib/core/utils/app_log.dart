import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Accept only fixed event names. Never pass patient data or raw exceptions.
abstract final class AppLog {
  static final Logger _logger = Logger(
    level: kDebugMode ? Level.warning : Level.off,
    printer: SimplePrinter(printTime: false),
  );

  static void preferencesLoadFailed() => _logger.w('preferences_load_failed');
  static void preferencesSaveFailed() => _logger.w('preferences_save_failed');
}
