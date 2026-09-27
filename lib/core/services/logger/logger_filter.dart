import 'package:logger/logger.dart';

/// A custom log filter that controls which log events should be processed
/// based on the configured log level.
class LoggerFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    final currentLevel = level ?? Level.all;
    return event.level.index >= currentLevel.index;
  }
}
