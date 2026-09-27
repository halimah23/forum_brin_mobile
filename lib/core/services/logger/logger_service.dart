import 'package:logger/logger.dart';
import 'package:forum_brin_mobile/core/core.dart';

/// A wrapper service around the Logger package that provides a simplified interface
/// for logging with different levels and optional type categorization.
///
/// This service uses dependency injection to receive a Logger instance and applies
/// a custom filter for log level control.
///
/// Example usage:
/// ```dart
/// final loggerService = getIt<LoggerService>();
/// loggerService.info('Application started');
/// loggerService.error('Something went wrong', error: exception);
/// ```
class LoggerService {
  /// Creates a new LoggerService instance with the provided [logger].
  ///
  /// The [logger] parameter should be injected via dependency injection.
  /// This service applies a custom filter to control log levels.
  LoggerService(Logger logger) {
    _logger = logger;
  }

  /// Custom filter instance for controlling log levels
  final LoggerFilter _filter = LoggerFilter();

  /// The underlying Logger instance from the logger package
  late final Logger _logger;

  /// Logs a trace message with optional type categorization.
  ///
  /// Trace messages are the most verbose level and typically used for
  /// detailed debugging information.
  ///
  /// [message] The log message to display
  /// [type] Optional category/type for the log message
  void trace(String message, {String? type}) {
    _logger.t(type != null ? '[$type] $message' : message);
  }

  /// Logs a debug message with optional type categorization.
  ///
  /// Debug messages provide detailed information for debugging purposes.
  ///
  /// [message] The log message to display
  /// [type] Optional category/type for the log message
  void debug(String message, {String? type}) {
    _logger.d(type != null ? '[$type] $message' : message);
  }

  /// Logs an info message with optional type categorization.
  ///
  /// Info messages provide general information about application flow.
  ///
  /// [message] The log message to display
  /// [type] Optional category/type for the log message
  void info(String message, {String? type}) {
    _logger.i(type != null ? '[$type] $message' : message);
  }

  /// Logs a warning message with optional type categorization.
  ///
  /// Warning messages indicate potential issues that don't prevent the application
  /// from continuing to run.
  ///
  /// [message] The log message to display
  /// [type] Optional category/type for the log message
  void warn(String message, {String? type}) {
    _logger.w(type != null ? '[$type] $message' : message);
  }

  /// Logs an error message with optional error object and stack trace.
  ///
  /// Error messages indicate serious issues that should be addressed.
  ///
  /// [message] The error message to display
  /// [error] Optional error object containing exception details
  /// [stackTrace] Optional stack trace for debugging
  /// [type] Optional category/type for the log message
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? type,
  }) {
    _logger.e(
      type != null ? '[$type] $message' : message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Logs a fatal error message with optional error object and stack trace.
  ///
  /// Fatal messages indicate critical errors that may cause the application
  /// to terminate.
  ///
  /// [message] The fatal error message to display
  /// [error] Optional error object containing exception details
  /// [stackTrace] Optional stack trace for debugging
  /// [type] Optional category/type for the log message
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? type,
  }) {
    _logger.f(
      type != null ? '[$type] $message' : message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Sets the minimum log level for this logger instance.
  ///
  /// Only messages at or above this level will be logged.
  /// For example, if set to [Level.warning], trace, debug, and info
  /// messages will be filtered out.
  ///
  /// [level] The minimum log level to display
  set logLevel(Level level) {
    _filter.level = level;
  }

  /// Gets the current minimum log level for this logger instance.
  ///
  /// Returns the current log level, or [Level.all] if no specific
  /// level has been set.
  Level get logLevel => _filter.level ?? Level.all;
}
