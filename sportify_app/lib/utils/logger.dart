import 'dart:developer' as developer;

class Logger {
  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    final fullMessage = _buildMessage('ERROR', message, tag: tag);
    developer.log(fullMessage, error: error, stackTrace: stackTrace, level: 1000);
    print('🔴 $fullMessage');
    if (error != null) {
      print('   Error: $error');
    }
    if (stackTrace != null) {
      print('   StackTrace: $stackTrace');
    }
  }

  static void warning(String message, {Object? error, String? tag}) {
    final fullMessage = _buildMessage('WARNING', message, tag: tag);
    developer.log(fullMessage, error: error, level: 900);
    print('🟡 $fullMessage');
  }

  static void info(String message, {String? tag}) {
    final fullMessage = _buildMessage('INFO', message, tag: tag);
    developer.log(fullMessage, level: 800);
    print('🔵 $fullMessage');
  }

  static void debug(String message, {String? tag}) {
    final fullMessage = _buildMessage('DEBUG', message, tag: tag);
    developer.log(fullMessage, level: 500);
    print('🟢 $fullMessage');
  }

  static String _buildMessage(String level, String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    return '$timestamp $level$tagStr: $message';
  }
}
