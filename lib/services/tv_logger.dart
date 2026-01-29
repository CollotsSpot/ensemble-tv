import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// In-memory logger for debugging TV app issues.
class TVLogger {
  static final TVLogger _instance = TVLogger._internal();
  factory TVLogger() => _instance;
  TVLogger._internal();

  final List<TVLogEntry> _logs = [];
  static const int _maxLogs = 500;

  void log(String message) {
    _logs.add(TVLogEntry(
      level: TVLogLevel.info,
      message: message,
      timestamp: DateTime.now(),
    ));
    _trimLogs();
    if (kDebugMode) {
      print('[TV] $message');
    }
  }

  void warning(String message) {
    _logs.add(TVLogEntry(
      level: TVLogLevel.warning,
      message: message,
      timestamp: DateTime.now(),
    ));
    _trimLogs();
    if (kDebugMode) {
      print('[TV WARNING] $message');
    }
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    final sb = StringBuffer(message);
    if (error != null) {
      sb.write('\nError: $error');
    }
    if (stackTrace != null) {
      sb.write('\nStackTrace: $stackTrace');
    }

    _logs.add(TVLogEntry(
      level: TVLogLevel.error,
      message: sb.toString(),
      timestamp: DateTime.now(),
    ));
    _trimLogs();
    if (kDebugMode) {
      print('[TV ERROR] $sb');
    }
  }

  List<TVLogEntry> getLogs() => List.unmodifiable(_logs);

  void clearLogs() {
    _logs.clear();
  }

  void _trimLogs() {
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }
  }
}

class TVLogEntry {
  final TVLogLevel level;
  final String message;
  final DateTime timestamp;

  TVLogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  String get formattedTime => '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  String get levelIcon {
    switch (level) {
      case TVLogLevel.info:
        return 'ℹ️';
      case TVLogLevel.warning:
        return '⚠️';
      case TVLogLevel.error:
        return '❌';
    }
  }

  Color get color {
    switch (level) {
      case TVLogLevel.info:
        return const Color(0xFFFFFFFF);
      case TVLogLevel.warning:
        return const Color(0xFFFFA726);
      case TVLogLevel.error:
        return const Color(0xFFEF5350);
    }
  }
}

enum TVLogLevel { info, warning, error }
