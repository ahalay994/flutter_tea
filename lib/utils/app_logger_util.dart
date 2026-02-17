import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart'; // Для kDebugMode

class AppLoggerUtil {
  static const String _logFileName = 'app_debug.log';

  static Future<void> log(String message) async {
    // Записываем логи только в режиме отладки
    if (kDebugMode) {
      try {
        // Получаем текущую директорию (где находится проект)
        final currentDir = Directory.current;
        final logFile = File(path.join(currentDir.path, _logFileName));

        // Добавляем timestamp к сообщению
        final timestamp = DateTime.now().toString();
        final logMessage = '[$timestamp] $message\n';

        // Записываем сообщение в файл
        await logFile.writeAsString(logMessage, mode: FileMode.append);
      } catch (e) {
        // Если не удалось записать в файл, просто игнорируем ошибку
        // print('Failed to write log: $e');
      }
    }
  }

  static Future<void> clearLogs() async {
    // Очищаем логи только в режиме отладки
    if (kDebugMode) {
      try {
        final currentDir = Directory.current;
        final logFile = File(path.join(currentDir.path, _logFileName));
        if (await logFile.exists()) {
          await logFile.writeAsString('');
        }
      } catch (e) {
        // print('Failed to clear logs: $e');
      }
    }
  }

  static Future<String> readLogs() async {
    // Читаем логи только в режиме отладки
    if (kDebugMode) {
      try {
        final currentDir = Directory.current;
        final logFile = File(path.join(currentDir.path, _logFileName));
        if (await logFile.exists()) {
          return await logFile.readAsString();
        } else {
          return '';
        }
      } catch (e) {
        return 'Failed to read logs: $e';
      }
    } else {
      return 'Logging disabled in release mode';
    }
  }
}