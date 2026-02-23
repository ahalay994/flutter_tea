import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Значения по умолчанию (все пустые для безопасности)
  static const String defaultApiUrl = '';
  static const String defaultSupabaseUrl = '';
  static const String defaultAppName = 'Tea App';
  static const String defaultSupabaseKey = ''; // Не храните реальные ключи в коде!

  // Закешированные значения из .env
  static String? _cachedApiUrl;
  static String? _cachedSupabaseUrl;
  static String? _cachedSupabaseKey;
  static String? _cachedAppName;

  static String get apiUrl {
    // Сначала проверяем кешированное значение
    if (_cachedApiUrl != null) {
      return _cachedApiUrl!;
    }

    // Затем пробуем переменные окружения
    String? envValue = const String.fromEnvironment('API_URL', defaultValue: '');
    if (envValue.isNotEmpty) return envValue;

    // Пытаемся получить из dotenv, если доступно
    try {
      String? dotenvValue = dotenv.env['API_URL'];
      _cachedApiUrl = dotenvValue ?? defaultApiUrl;
      return _cachedApiUrl!;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, в вебе), используем значение по умолчанию
      _cachedApiUrl = defaultApiUrl;
      return _cachedApiUrl!;
    }
  }

  static String get supabaseUrl {
    // Сначала проверяем кешированное значение
    if (_cachedSupabaseUrl != null) {
      return _cachedSupabaseUrl!;
    }

    // Затем пробуем переменные окружения
    String? envValue = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    if (envValue.isNotEmpty) return envValue;

    // Пытаемся получить из dotenv, если доступно
    try {
      String? dotenvValue = dotenv.env['SUPABASE_URL'];
      _cachedSupabaseUrl = dotenvValue ?? defaultSupabaseUrl;
      return _cachedSupabaseUrl!;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, в вебе), используем значение по умолчанию
      _cachedSupabaseUrl = defaultSupabaseUrl;
      return _cachedSupabaseUrl!;
    }
  }

  static String get supabaseKey {
    // Сначала проверяем кешированное значение
    if (_cachedSupabaseKey != null) {
      return _cachedSupabaseKey!;
    }

    // Затем пробуем переменные окружения
    String? envValue = const String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
    if (envValue.isNotEmpty) return envValue;

    // Пытаемся получить из dotenv, если доступно
    try {
      String? dotenvValue = dotenv.env['SUPABASE_KEY'];
      _cachedSupabaseKey = dotenvValue ?? defaultSupabaseKey;
      return _cachedSupabaseKey!;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, в вебе), используем значение по умолчанию
      _cachedSupabaseKey = defaultSupabaseKey;
      return _cachedSupabaseKey!;
    }
  }

  static String get appName {
    // Сначала проверяем кешированное значение
    if (_cachedAppName != null) {
      return _cachedAppName!;
    }

    // Затем пробуем переменные окружения
    String? envValue = const String.fromEnvironment('APP_NAME', defaultValue: '');
    if (envValue.isNotEmpty) return envValue;

    // Пытаемся получить из dotenv, если доступно
    try {
      String? dotenvValue = dotenv.env['APP_NAME'];
      _cachedAppName = dotenvValue ?? defaultAppName;
      return _cachedAppName!;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, в вебе), используем значение по умолчанию
      _cachedAppName = defaultAppName;
      return _cachedAppName!;
    }
  }

  // Метод для предварительной загрузки конфигурации
  static Future<void> loadConfig() async {
    // Просто обращаемся к каждому геттеру, чтобы они закешировали значения
    apiUrl;
    supabaseUrl;
    supabaseKey;
    appName;
  }
}