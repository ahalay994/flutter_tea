class AppConfig {
  // Значения по умолчанию, соответствующие .env файлу
  static const String defaultApiUrl = '';
  static const String defaultSupabaseUrl = '';
  static const String defaultAppName = 'Tea App';
  static const String defaultSupabaseKey = ''; // Не храните реальные ключи в коде!

  // Вспомогательная функция для получения строки из окружения с резервным значением
  static String _getStringFromEnv(String key, String defaultValue) {
    try {
      String? envValue = String.fromEnvironment(key, defaultValue: '');
      return envValue.isNotEmpty ? envValue : defaultValue;
    } catch (e) {
      // Если возникла ошибка при получении переменной из окружения, используем значение по умолчанию
      return defaultValue;
    }
  }

  static String get apiUrl {
    return _getStringFromEnv('API_URL', defaultApiUrl);
  }

  static String get supabaseUrl {
    return _getStringFromEnv('SUPABASE_URL', defaultSupabaseUrl);
  }

  static String get supabaseKey {
    return _getStringFromEnv('SUPABASE_KEY', defaultSupabaseKey);
  }

  static String get appName {
    return _getStringFromEnv('APP_NAME', defaultAppName);
  }
}
