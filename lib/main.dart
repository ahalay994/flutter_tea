import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_quill/flutter_quill.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';
import 'utils/app_config.dart';

// Глобальная переменная для хранения контекста главного виджета
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Глобальные переменные для хранения значений .env файла
Map<String, String> _envVariables = {};

// Утилита для безопасной загрузки .env файла
Future<void> loadEnvSafely() async {
  try {
    // Сначала пробуем загрузить .env файл как ассет (работает в релизных сборках)
    String envContent = await rootBundle.loadString('.env');
    _envVariables = _parseEnvString(envContent);
    await dotenv.load(fileName: ".env"); // Попробуем также загрузить как обычный файл на всякий случай
    // _showToast('Загружен .env файл как ассет');
  } catch (e) {
    // _showToast('Не удалось загрузить .env файл как ассет: $e');
    try {
      // Если не удалось как ассет, пробуем загрузить как обычный файл
      if (Platform.environment.containsKey('FLUTTER_WEB')) {
        // Для веба не пытаемся загрузить .env файл через flutter_dotenv
        // _showToast('Запуск в веб-окружении, используем переменные окружения Dart');
      } else {
        // На мобильных и десктопных платформах пробуем загрузить .env файл
        await dotenv.load(fileName: ".env");
        // _showToast('Загружен .env файл как обычный файл');
      }
    } catch (e2) {
      // _showToast('Не удалось загрузить .env файл как обычный файл: $e2');
      // _showToast('Приложение будет использовать значения по умолчанию из AppConfig');
    }
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
  // Сначала пробуем получить из flutter_dotenv
  try {
    return dotenv.env[key];
  } catch (e) {
    // Если не удалось, пробуем получить из нашего парсера
    return _envVariables[key];
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Загружаем .env файл асинхронно и безопасно
  await loadEnvSafely();
  
  // Инициализация Supabase асинхронно, чтобы не блокировать запуск приложения
  // Проверяем, что мы можем получить доступ к переменным окружения
  String? envSupabaseUrl, envSupabaseKey;
  try {
    // Проверяем, можем ли получить переменные из dotenv
    envSupabaseUrl = _getEnvValue('SUPABASE_URL');
    envSupabaseKey = _getEnvValue('SUPABASE_KEY');
  } catch (e) {
    // Если возникла ошибка доступа к dotenv (например, в вебе), используем только AppConfig
    envSupabaseUrl = null;
    envSupabaseKey = null;
  }
  
  String supabaseUrl = envSupabaseUrl ?? AppConfig.supabaseUrl;
  String supabaseKey = envSupabaseKey ?? AppConfig.supabaseKey;
  
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    // Инициализируем Supabase в фоне, чтобы не блокировать запуск приложения
    Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey).then((_) {
      SupabaseService().init(supabaseUrl, supabaseKey);
      // _showToast('Supabase инициализирован успешно');
    }).catchError((error) {
      // _showToast('Ошибка инициализации Supabase: $error');
    });
  } else {
    // _showToast('Не удалось получить настройки Supabase, инициализация не выполнена');
    // _showToast('Убедитесь, что в .env файле указаны правильные значения SUPABASE_URL и SUPABASE_KEY');
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
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Основной цвет - глубокий фиолетовый
        primaryColor: const Color(0xFF9B59B6), // Фиолетовый
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9B59B6), // Фиолетовый как основной цвет
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF9B59B6), // Фиолетовый заголовок
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme.of(context).copyWith(
          elevation: 6,
          shadowColor: const Color(0xFFFF69B4).withOpacity(0.3), // Розовая тень
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9B59B6), // Фиолетовая кнопка
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
    );
  }
}