// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Sentin8:Flutter
// SPDX-License-Identifier: Apache-2.0

import '../bff/correlation.dart';

export '../bff/correlation.dart' show generateCorrelationId;

/// Structured log entry with correlation ID.
class LogEntry {
  final String level; // INFO, WARN, ERROR
  final String message;
  final String correlationId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.level,
    required this.message,
    required this.correlationId,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'level': level,
    'message': message,
    'correlationId': correlationId,
    'timestamp': timestamp.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };
}

/// Simple in-memory logger. In production, logs are sent to the platform
/// logging pipeline via BFF correlation headers.
///
/// [prefix] is a short app identifier (e.g. 'eBank', 'eTeller').
class AppLogger {
  static final List<LogEntry> _entries = [];
  static const int _maxEntries = 1000;
  static String prefix = 'App';

  static void info(String message, {String? correlationId, Map<String, dynamic>? metadata}) {
    _log('INFO', message, correlationId, metadata);
  }

  static void warn(String message, {String? correlationId, Map<String, dynamic>? metadata}) {
    _log('WARN', message, correlationId, metadata);
  }

  static void error(String message, {String? correlationId, Map<String, dynamic>? metadata}) {
    _log('ERROR', message, correlationId, metadata);
  }

  static void _log(String level, String message, String? correlationId, Map<String, dynamic>? metadata) {
    final entry = LogEntry(
      level: level,
      message: message,
      correlationId: correlationId ?? generateCorrelationId(prefix: prefix.toLowerCase().substring(0, 3)),
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    _entries.add(entry);
    if (_entries.length > _maxEntries) _entries.removeAt(0);

    // ignore: avoid_print
    print('[${entry.level}] ${entry.timestamp} [${entry.correlationId}] $message');
  }

  static List<LogEntry> get entries => List.unmodifiable(_entries);
}