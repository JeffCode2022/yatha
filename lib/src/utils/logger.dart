import 'dart:developer' as developer;

class Logger {
  static void info(String message) {
    developer.log(message, name: 'INFO');
  }

  static void error(String message, [dynamic error]) {
    developer.log('ERROR: $message',
        name: 'ERROR',
        error: error,
        stackTrace: error is Error ? error.stackTrace : null);
  }

  static void debug(String message) {
    developer.log(message, name: 'DEBUG');
  }

  static void warning(String message) {
    developer.log(message, name: 'WARNING');
  }
}
