class AppConfig {
  // Значения по умолчанию (все пустые для безопасности)
  static const String defaultApiUrl = '';
  static const String defaultSupabaseUrl = '';
  static const String defaultAppName = 'Tea App';
  static const String defaultSupabaseKey = ''; // Не храните реальные ключи в коде!
  
  static String get apiUrl {
    String? envValue = const String.fromEnvironment('API_URL', defaultValue: '');
    return envValue.isNotEmpty ? envValue : defaultApiUrl;
  }
  
  static String get supabaseUrl {
    String? envValue = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    return envValue.isNotEmpty ? envValue : defaultSupabaseUrl;
  }
  
  static String get supabaseKey {
    String? envValue = const String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
    // Возвращаем пустую строку по умолчанию, чтобы избежать утечки ключа
    return envValue.isNotEmpty ? envValue : defaultSupabaseKey;
  }
  
  static String get appName {
    String? envValue = const String.fromEnvironment('APP_NAME', defaultValue: '');
    return envValue.isNotEmpty ? envValue : defaultAppName;
  }
}