import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Severity of a log record, ordered from least to most severe.
enum LogLevel {
  debug,
  info,
  warning,
  error;

  String get label => name.toUpperCase();
}

/// Receives structured log records. Swap the implementation to route logs to a
/// remote sink (Sentry, Crashlytics, Datadog) without touching call sites.
abstract class LogSink {
  const LogSink();

  void write(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  });
}

/// Writes records to the Dart developer console. Verbose levels are dropped in
/// release builds so production logs stay signal-only.
class ConsoleLogSink extends LogSink {
  const ConsoleLogSink();

  @override
  void write(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    if (kReleaseMode && level == LogLevel.debug) return;

    final buffer = StringBuffer(message);
    if (context != null && context.isNotEmpty) {
      buffer.write(' ');
      buffer.write(
          context.entries.map((e) => '${e.key}=${e.value}').join(' '));
    }

    developer.log(
      buffer.toString(),
      name: tag ?? 'victoria_fabrics',
      level: _levelValue(level),
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  int _levelValue(LogLevel level) => switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      };
}

/// Forwards errors to a crash-reporting backend. The default implementation is
/// inert; register a real reporter (e.g. Firebase Crashlytics) at startup.
abstract class CrashReporter {
  const CrashReporter();

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  });

  Future<void> setUser(String? userId);
}

class NoopCrashReporter extends CrashReporter {
  const NoopCrashReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {}

  @override
  Future<void> setUser(String? userId) async {}
}

/// Application-wide logging facade. Use this instead of `print` so log routing
/// and crash reporting can be configured in one place.
class AppLogger {
  AppLogger._();

  static LogSink _sink = const ConsoleLogSink();
  static CrashReporter _crashReporter = const NoopCrashReporter();
  static LogLevel _minLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;

  /// Wires the logger to production sinks. Call once during app startup.
  static void configure({
    LogSink? sink,
    CrashReporter? crashReporter,
    LogLevel? minLevel,
  }) {
    if (sink != null) _sink = sink;
    if (crashReporter != null) _crashReporter = crashReporter;
    if (minLevel != null) _minLevel = minLevel;
  }

  static void debug(
    String message, {
    String? tag,
    Map<String, Object?>? context,
  }) =>
      _log(LogLevel.debug, message, tag: tag, context: context);

  static void info(
    String message, {
    String? tag,
    Map<String, Object?>? context,
  }) =>
      _log(LogLevel.info, message, tag: tag, context: context);

  static void warning(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) =>
      _log(LogLevel.warning, message,
          tag: tag, error: error, stackTrace: stackTrace, context: context);

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
    bool report = true,
  }) {
    _log(LogLevel.error, message,
        tag: tag, error: error, stackTrace: stackTrace, context: context);
    if (report && error != null) {
      _crashReporter.recordError(
        error,
        stackTrace,
        fatal: false,
        context: context,
      );
    }
  }

  static Future<void> setUser(String? userId) =>
      _crashReporter.setUser(userId);

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    if (level.index < _minLevel.index) return;
    _sink.write(
      level,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }
}
