import 'dart:developer' as dev;
// Условный импорт или проверка внутри помогут избежать ошибок в Web
import 'dart:io' show File, FileMode;

// Важно: импортируем kDebugMode и kIsWeb
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class AppLogger {
  static final String _tag = dotenv.env['APP_NAME'] ?? 'TeaApp';

  // Метод для записи лога в файл
  static Future<void> _writeToFile(String level, String message, {Object? error}) async {
    // 1. ПРОВЕРКА НА WEB: В браузере запись в файлы невозможна
    if (kIsWeb) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_logs.txt');

      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final logEntry = "[$timestamp] [$level] $message ${error != null ? ': $error' : ''}\n";

      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      // Используем debugPrint, так как print может быть запрещен линтером
      debugPrint("Не удалось записать лог в файл: $e");
    }
  }

  // Лог ошибки
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      dev.log('❌ $message', name: _tag, error: error, stackTrace: stackTrace);
    }

    // Запись в файл (пропустится автоматически, если это Web)
    _writeToFile('ERROR', message, error: error);
  }

  // Лог информационной отладки
  static void debug(String message) {
    if (kDebugMode) {
      dev.log('ℹ️ $message', name: _tag);
    }
    _writeToFile('DEBUG', message);
  }

  // Лог успешного действия
  static void success(String message) {
    if (kDebugMode) {
      dev.log('✅ $message', name: _tag);
    }
    _writeToFile('SUCCESS', message);
  }

  // Метод для получения файла (например, чтобы отправить по почте)
  // Возвращает null в вебе
  static Future<dynamic> getLogFile() async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app_logs.txt');
  }
}
