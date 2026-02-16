import 'package:flutter/foundation.dart';
import 'package:tea/utils/app_logger.dart';

// Инициализация базы данных в зависимости от платформы
Future<void> initializeDatabase() async {
  try {
    // В веб-окружении устанавливаем databaseFactory для работы с sqflite
    // Проверяем, является ли это веб-окружением
    if (kIsWeb) {
      AppLogger.debug('Обнаружено веб-окружение, инициализация базы данных не требуется');
      // Для веба мы используем in-memory хранилище в LocalDatabaseService
    } else {
      // Для мобильных и десктопных платформ sqflite будет инициализирован автоматически
      AppLogger.debug('Инициализация базы данных не требуется для мобильных платформ');
    }
  } catch (e) {
    AppLogger.error('Ошибка инициализации базы данных', error: e);
  }
}