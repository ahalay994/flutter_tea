import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_quill/flutter_quill.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/theme_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';
import 'utils/app_config.dart';
import 'utils/app_logger.dart';

// Глобальная переменная для хранения контекста главного виджета
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Глобальные переменные для хранения значений .env файла
Map<String, String> _envVariables = {};

// Утилита для безопасной загрузки .env файла
Future<void> loadEnvSafely() async {
  try {
    // Пробуем загрузить .env файл как ассет (работает в релизных сборках)
    String envContent = await rootBundle.loadString('.env');
    _envVariables = _parseEnvString(envContent);
    AppLogger.debug('Загружен .env файл как ассет, переменных: ${_envVariables.length}');
    // _showToast('Загружен .env файл как ассет');
  } catch (e) {
    AppLogger.debug('Не удалось загрузить .env файл как ассет: $e');
    // Просто продолжаем без env переменных, используя AppConfig
  }
}

// Вспомогательная функция для парсинга .env строки в Map
Map<String, String> _parseEnvString(String envContent) {
  Map<String, String> envMap = {};
  
  List<String> lines = envContent.split('\n');
  for (String line in lines) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    
    int separatorIndex = line.indexOf('=');
    if (separatorIndex != -1) {
      String key = line.substring(0, separatorIndex).trim();
      String value = line.substring(separatorIndex + 1).trim();
      
      // Убираем кавычки, если они есть
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      
      envMap[key] = value;
    }
  }
  
  return envMap;
}

// Вспомогательная функция для получения значения из .env
String? _getEnvValue(String key) {
  // Проверяем в следующем порядке приоритета:
  // 1. Переменная окружения Dart (для релизной сборки)
  String? envValue = String.fromEnvironment(key, defaultValue: '');
  if (envValue.isNotEmpty) {
    AppLogger.debug('Получено значение $key из String.fromEnvironment: $envValue');
    return envValue;
  }
  
  // 2. Переменная из flutter_dotenv
  try {
    String? dotenvValue = dotenv.env[key];
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      AppLogger.debug('Получено значение $key из dotenv: $dotenvValue');
      return dotenvValue;
    }
  } catch (e) {
    AppLogger.debug('Ошибка получения $key из dotenv: $e');
    // Если не удалось получить из flutter_dotenv, продолжаем
  }
  
  // 3. Переменная из нашего внутреннего парсера
  String? parsedValue = _envVariables[key];
  if (parsedValue != null && parsedValue.isNotEmpty) {
    AppLogger.debug('Получено значение $key из внутреннего парсера: $parsedValue');
  }
  return parsedValue;
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Включаем логирование в релизе
  AppLogger.setReleaseLogging(true);
  
  // Загружаем .env файл асинхронно и безопасно
  await loadEnvSafely();
  
  // Логируем значения, полученные из .env
  AppLogger.debug('API_URL из .env: ${_getEnvValue('API_URL')}');
  AppLogger.debug('SUPABASE_URL из .env: ${_getEnvValue('SUPABASE_URL')}');
  AppLogger.debug('APP_NAME из .env: ${_getEnvValue('APP_NAME')}');
  
  // Инициализируем менеджер тем
  await ThemeManager().initialize();
  
  // Инициализация Supabase асинхронно, чтобы не блокировать запуск приложения
  // Проверяем, что мы можем получить доступ к переменным окружения
  String? envSupabaseUrl, envSupabaseKey;
  try {
    // Проверяем, можем ли получить переменные из dotenv
    envSupabaseUrl = _getEnvValue('SUPABASE_URL');
    envSupabaseKey = _getEnvValue('SUPABASE_KEY');
  } catch (e) {
    AppLogger.debug('Ошибка получения переменных Supabase: $e');
    // Если возникла ошибка доступа к dotenv (например, в вебе), используем только AppConfig
    envSupabaseUrl = null;
    envSupabaseKey = null;
  }
  
  String supabaseUrl = envSupabaseUrl ?? AppConfig.supabaseUrl;
  String supabaseKey = envSupabaseKey ?? AppConfig.supabaseKey;
  
  AppLogger.debug('Финальный SUPABASE_URL: $supabaseUrl');
  AppLogger.debug('Финальный SUPABASE_KEY длина: ${supabaseKey.length}');
  
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    // Инициализируем Supabase в фоне, чтобы не блокировать запуск приложения
    Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey).then((_) {
      SupabaseService().init(supabaseUrl, supabaseKey);
      AppLogger.debug('Supabase инициализирован успешно');
    }).catchError((error) {
      AppLogger.error('Ошибка инициализации Supabase:', error: error);
    });
  } else {
    AppLogger.error('Не удалось получить настройки Supabase, инициализация не выполнена');
    AppLogger.error('Убедитесь, что в .env файле указаны правильные значения SUPABASE_URL и SUPABASE_KEY');
  }

  runApp(ProviderScope(child: TeaApp(navigatorKey: navigatorKey)));
}

class TeaApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const TeaApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    // Получаем имя приложения с приоритетом для .env переменной
    String appName = AppConfig.appName; // по умолчанию используем AppConfig
    try {
      // Пытаемся получить из dotenv, если доступно
      String? envAppName = _getEnvValue('APP_NAME');
      if (envAppName != null && envAppName.isNotEmpty) {
        appName = envAppName;
      }
    } catch (e) {
      // Если возникла ошибка доступа к dotenv, используем AppConfig
      // _showToast('Ошибка доступа к APP_NAME из dotenv: $e');
    }
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: appName, // Устанавливаем имя приложения как заголовок
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      home: ThemeWrapper(),
    );
  }
}

// Вспомогательный виджет для переключения темы
class ThemeWrapper extends ConsumerStatefulWidget {
  @override
  ConsumerState<ThemeWrapper> createState() => _ThemeWrapperState();
}

class _ThemeWrapperState extends ConsumerState<ThemeWrapper> {
  late ValueNotifier<AppTheme> _themeListenable;

  @override
  void initState() {
    super.initState();
    _themeListenable = ref.read(themeNotifierProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: _themeListenable,
      builder: (context, appTheme, child) {
        // Для пользовательской темы всегда используем цвета из ThemeManager
        Color primaryColor = ThemeManager().customPrimaryColor;
        Color secondaryColor = ThemeManager().customSecondaryColor;
        
        // Получаем имя приложения для использования в теме
        String appName = AppConfig.appName; // по умолчанию используем AppConfig
        try {
          // Пытаемся получить из dotenv, если доступно
          String? envAppName = _getEnvValue('APP_NAME');
          if (envAppName != null && envAppName.isNotEmpty) {
            appName = envAppName;
          }
        } catch (e) {
          // Если возникла ошибка доступа к dotenv, используем AppConfig
          // _showToast('Ошибка доступа к APP_NAME из dotenv: $e');
        }
        
        return MaterialApp(
          title: appName,
          theme: ThemeData(
            primarySwatch: Colors.grey,
            primaryColor: primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.light,
            ).copyWith(
              secondary: secondaryColor, // Явно устанавливаем вторичный цвет
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: CardTheme.of(context).copyWith(
              elevation: 6,
              shadowColor: secondaryColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}