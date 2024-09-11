import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:my_expense/_index.g.dart';

class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      levelEmojis: {
        Level.info: "ℹ️",
        Level.warning: "⚠️",
        Level.fatal: "💀",
        Level.error: "🛑",
      },
      noBoxingByDefault: true,
    )
  );
  static final DateFormat _df = DateFormat("yyyy-MM-dd hh:mm:ss");

  static void info({required String message}) {
    _logger.i('\x1B[34m[info]\x1B[0m [${_df.formatLocal(DateTime.now())}] $message');
  }

  static void success({required String message}) {
    _logger.i('\x1B[32m[success]\x1B[0m [${_df.formatLocal(DateTime.now())}] $message');
  }

  static void warning({required String message}) {
    _logger.w('\x1B[33m[warning]\x1B[0m [${_df.formatLocal(DateTime.now())}] $message');
  }

  static void error({required String message, Object? error, StackTrace? stackTrace}) {
    _logger.f('\x1B[31m[error]\x1B[0m [${_df.formatLocal(DateTime.now())}] $message', error: error, stackTrace: stackTrace);
  }
}