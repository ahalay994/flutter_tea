import 'dart:developer' as dev;
// Условный импорт или проверка внутри помогут избежать ошибок в Web
import 'dart:io' show File, FileMode;

// Важно: импортируем kDebugMode и kIsWeb
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tea/utils/app_config.dart';

class AppLogger {
  // Используем AppConfig в качестве резервного варианта и избегаем обращения к dotenv при инициализации
  static String get _tag {
    try {
      // Пытаемся получить из dotenv, если доступно
      String? envAppName = dotenv.env['APP_NAME'];
      return envAppName ?? AppConfig.appName;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, в вебе), используем AppConfig
      return AppConfig.appName;
    }
  }

  // Флаг для включения логирования в релизе
  static bool _enableReleaseLogging = true;

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
      // debugPrint("Не удалось записать лог в файл: $e");
    }
  }

  // Лог ошибки
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    // Всегда записываем ошибки в файл, независимо от режима
    _writeToFile('ERROR', message, error: error);
    
    if (kDebugMode || _enableReleaseLogging) {
      dev.log('❌ $message', name: _tag, error: error, stackTrace: stackTrace);
    }
  }

  // Лог информационной отладки
  static void debug(String message) {
    if (kDebugMode || _enableReleaseLogging) {
      dev.log('ℹ️ $message', name: _tag);
      // Записываем в файл только если включен релизный лог
      if (_enableReleaseLogging) {
        _writeToFile('DEBUG', message);
      }
    }
  }

  // Лог успешного действия
  static void success(String message) {
    if (kDebugMode || _enableReleaseLogging) {
      dev.log('✅ $message', name: _tag);
      // Записываем в файл только если включен релизный лог
      if (_enableReleaseLogging) {
        _writeToFile('SUCCESS', message);
      }
    }
  }

  // Метод для получения файла (например, чтобы отправить по почте)
  // Возвращает null в вебе
  static Future<dynamic> getLogFile() async {
    if (kIsWeb) return null;
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/app_logs.txt');
  }
  
  // Метод для включения/отключения логирования в релизе
  static void setReleaseLogging(bool enabled) {
    _enableReleaseLogging = enabled;
  }
  
  // Метод для проверки статуса логирования в релизе
  static bool get isReleaseLoggingEnabled => _enableReleaseLogging;
}
