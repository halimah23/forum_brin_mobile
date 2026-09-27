# LoggerService Documentation

## Overview
`LoggerService` is a wrapper service around the Logger package that provides a simplified interface for logging with different levels and optional type categorization. Registered as a lazy singleton via dependency injection, it applies a custom filter for log level control and ensures consistent logging across the application.

## API Reference

### Constructor
| Constructor | Parameters | Description |
| --- | --- | --- |
| `LoggerService` | `Logger logger` | Creates a new LoggerService instance with the provided Logger. The logger parameter should be injected via dependency injection. |

### Internal State
| Field | Type | Description |
| --- | --- | --- |
| `_filter` | `LoggerFilter` | Custom filter instance for controlling log levels based on configured minimum level. |
| `_logger` | `Logger` | The underlying Logger instance from the logger package that handles actual log output. |

### Methods
| Method | Signature | Purpose |
| --- | --- | --- |
| `trace` | `void trace(String message, {String? type})` | Logs a trace message (most verbose level) with optional type categorization for detailed debugging. |
| `debug` | `void debug(String message, {String? type})` | Logs a debug message with optional type categorization for debugging purposes. |
| `info` | `void info(String message, {String? type})` | Logs an info message with optional type categorization for general application flow information. |
| `warn` | `void warn(String message, {String? type})` | Logs a warning message with optional type categorization for potential issues that don't prevent app continuation. |
| `error` | `void error(String message, {Object? error, StackTrace? stackTrace, String? type})` | Logs an error message with optional error object, stack trace, and type categorization for serious issues. |
| `fatal` | `void fatal(String message, {Object? error, StackTrace? stackTrace, String? type})` | Logs a fatal error message with optional error object, stack trace, and type categorization for critical errors. |

### Properties
| Property | Type | Description |
| --- | --- | --- |
| `logLevel` | `Level` (getter/setter) | Gets or sets the minimum log level. Only messages at or above this level will be logged. |

## Supporting Classes

### `LoggerFilter`
A custom log filter that extends `LogFilter` from the logger package to control which log events should be processed based on the configured log level.

| Method | Signature | Purpose |
| --- | --- | --- |
| `shouldLog` | `bool shouldLog(LogEvent event)` | Determines whether a log event should be processed based on the current minimum log level. |

## Usage Examples

### Basic Logging
```dart
import 'package:ops/core/core.dart';

class MyService {
  final LoggerService _logger = getIt<LoggerService>();
  
  void performAction() {
    _logger.info('Starting action execution', type: 'MyService');
    
    try {
      // Do some work...
      _logger.debug('Action completed successfully', type: 'MyService');
    } catch (e, stackTrace) {
      _logger.error(
        'Action failed to complete',
        error: e,
        stackTrace: stackTrace,
        type: 'MyService',
      );
    }
  }
}
```

### Log Level Control
```dart
import 'package:ops/core/core.dart';
import 'package:logger/logger.dart';

class AppConfig {
  static void configureLogging(LoggerService loggerService) {
    // Set minimum log level based on environment
    if (kDebugMode) {
      loggerService.logLevel = Level.debug;
    } else {
      loggerService.logLevel = Level.info;
    }
  }
}
```

### Using with ServicesMixin
```dart
import 'package:ops/core/core.dart';

class MyViewModel with ServicesMixin {
  Future<void> loadData() async {
    log.info('Loading data started', type: 'MyViewModel');
    
    try {
      // Simulate data loading
      await Future.delayed(Duration(seconds: 1));
      
      log.debug('Data loaded successfully', type: 'MyViewModel');
    } catch (e, stackTrace) {
      log.error(
        'Failed to load data',
        error: e,
        stackTrace: stackTrace,
        type: 'MyViewModel',
      );
    }
  }
}
```

## Log Levels

The LoggerService supports the following log levels in order of severity:

| Level | Description | Use Case |
| --- | --- | --- |
| `trace` | Most verbose level | Detailed step-by-step execution tracing |
| `debug` | Debugging information | Development and troubleshooting |
| `info` | General information | Application flow and state changes |
| `warning` | Warning messages | Potential issues that don't stop execution |
| `error` | Error messages | Serious issues that should be addressed |
| `fatal` | Fatal errors | Critical errors that may cause termination |

## Type Categorization

All logging methods support an optional `type` parameter that adds context to log messages:

```dart
// Without type
logger.info('User logged in');

// With type
logger.info('User logged in', type: 'AuthService');

// Output: [AuthService] User logged in
```

This helps in filtering and organizing logs by component or feature area.

## Configuration

### Dependency Injection Setup
The LoggerService is registered in `core_dependencies.dart`:

```dart
// In core_dependencies.dart
getIt.registerLazySingleton<LoggerService>(
  () => LoggerService(getIt<Logger>()),
);
```

### External Logger Configuration
The underlying Logger instance is configured in `external_dependencies.dart` with appropriate output formatting, filters, and output handlers.

## Best Practices

1. **Use Type Categorization**: Always provide a meaningful `type` parameter to help with log filtering and debugging.

2. **Appropriate Log Levels**: 
   - Use `trace` for detailed execution flow
   - Use `debug` for development troubleshooting
   - Use `info` for important application events
   - Use `warning` for recoverable issues
   - Use `error` for serious problems
   - Use `fatal` for critical system failures

3. **Include Context**: For error and fatal logs, always include the error object and stack trace when available.

4. **Environment-Specific Levels**: Configure different log levels for development vs production environments.

5. **Performance Considerations**: Avoid logging in tight loops or performance-critical code paths, especially at verbose levels.

## Integration with ServicesMixin

The LoggerService integrates seamlessly with the `ServicesMixin` for convenient access in classes that need logging capabilities:

```dart
class MyRepository with ServicesMixin {
  Future<void> saveData() async {
    log.info('Saving data to repository', type: 'MyRepository');
    // Implementation...
  }
}
```

This architecture provides a clean, consistent, and flexible logging solution for the entire application.