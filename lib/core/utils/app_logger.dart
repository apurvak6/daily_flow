import 'package:flutter/foundation.dart';

/// Lightweight application logger adhering to production standards.
class AppLogger {
  AppLogger._();

  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[DailyFlow]';
      debugPrint('$prefix 🐛 DEBUG: $message');
    }
  }

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[DailyFlow]';
      debugPrint('$prefix ℹ️ INFO: $message');
    }
  }

  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag]' : '[DailyFlow]';
      debugPrint('$prefix ⚠️ WARNING: $message');
    }
  }

  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    final prefix = tag != null ? '[$tag]' : '[DailyFlow]';
    debugPrint('$prefix ❌ ERROR: $message');
    if (error != null) {
      debugPrint('$prefix Exception: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('$prefix StackTrace:\n$stackTrace');
    }
  }
}
