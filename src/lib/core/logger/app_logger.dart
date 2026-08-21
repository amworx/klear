import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Severity of a log entry.
enum LogLevel { debug, info, warning, error }

/// A single log entry kept in the in-memory ring buffer.
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  String get formattedTime {
    final t = timestamp.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
  }

  String get levelLabel => level.name.toUpperCase();

  @override
  String toString() {
    final buf = StringBuffer()..write('[$formattedTime] [$levelLabel][$tag] $message');
    if (error != null) buf.write(' | $error');
    if (stackTrace != null) buf.write('\n$stackTrace');
    return buf.toString();
  }
}

/// In-memory ring-buffer logger for diagnostics.
///
/// Keeps the last [_maxEntries] entries (errors + warnings + info) so the
/// workflow can be inspected from the app itself (no need to retype long
/// SnackBar messages). Also mirrors every entry to `debugPrint` for `adb
/// logcat`. Exposed via Riverpod for the Logs UI.
///
/// Usage:
/// ```dart
/// ref.read(appLoggerProvider).e('auth', 'sign-in failed', error, stackTrace);
/// ref.read(appLoggerProvider).w('services', 'failed to load services');
/// ```
class AppLogger extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  AppLogger({int maxEntries = 120}) : _maxEntries = maxEntries;

  final int _maxEntries;
  final List<LogEntry> _entries = [];
  final StreamController<LogEntry> _streamController =
      StreamController<LogEntry>.broadcast();

  /// A process-wide singleton used before the Riverpod container exists
  /// (e.g., in `main()`'s global error handlers).
  static final AppLogger instance = AppLogger();

  List<LogEntry> get entries => List.unmodifiable(_entries);
  Stream<LogEntry> get stream => _streamController.stream;
  int get length => _entries.length;

  void _add(LogEntry entry) {
    if (_entries.length >= _maxEntries) {
      _entries.removeAt(0);
    }
    _entries.add(entry);
    _streamController.add(entry);
    // Mirror to logcat / debug console for `adb logcat` inspection.
    debugPrint(entry.toString());
    notifyListeners();
  }

  void d(String tag, String message, [Object? error, StackTrace? stack]) =>
      _add(LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        tag: tag,
        message: message,
        error: error,
        stackTrace: stack,
      ));

  void i(String tag, String message, [Object? error, StackTrace? stack]) =>
      _add(LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.info,
        tag: tag,
        message: message,
        error: error,
        stackTrace: stack,
      ));

  void w(String tag, String message, [Object? error, StackTrace? stack]) =>
      _add(LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.warning,
        tag: tag,
        message: message,
        error: error,
        stackTrace: stack,
      ));

  void e(String tag, String message, [Object? error, StackTrace? stack]) =>
      _add(LogEntry(
        timestamp: DateTime.now(),
        level: LogLevel.error,
        tag: tag,
        message: message,
        error: error,
        stackTrace: stack,
      ));

  /// Convenience for logging a caught exception.
  void logException(
    String tag,
    String message,
    Object error,
    StackTrace stackTrace,
  ) =>
      e(tag, message, error, stackTrace);

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  String exportAsText() => _entries.map((e) => e.toString()).join('\n');

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}

/// Riverpod provider for the app logger.
///
/// The default value is the process-wide [AppLogger.instance] so every
/// `ref.read(appLoggerProvider)` shares the same buffer. The singleton lives
/// for the lifetime of the process and is not disposed with the provider.
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.instance);

/// Helper to show a SnackBar that also logs the error and offers a one-tap
/// copy / view-logs action. Use this instead of a plain `SnackBar` for any
/// user-visible error so the long message never has to be retyped.
extension SnackBarLogger on AppLogger {
  /// Log [error] at `error` level and return the formatted message for UI.
  String logAndFormat(String tag, String userMessage, Object error, StackTrace st) {
    e(tag, userMessage, error, st);
    return '$userMessage: $error';
  }
}
