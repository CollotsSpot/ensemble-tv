import 'package:flutter/foundation.dart';

/// Simple debug logger for TV app.
class DebugLogger {
  final bool enabled = kDebugMode;

  void log(String message) {
    if (enabled) {
      print('[TV] $message');
    }
  }

  void warning(String message, {String? context}) {
    if (enabled) {
      final ctx = context != null ? ' [$context]' : '';
      print('[TV WARNING]$ctx $message');
    }
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (enabled) {
      print('[TV ERROR] $message');
      if (error != null) {
        print(error);
      }
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
}
