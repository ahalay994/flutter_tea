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

// Утилита для безопасной загрузки .env файла
Future<void> loadEnvSafely() async {
  try {
    // Сначала пробуем загрузить .env файл как ассет (работает в релизных сборках)
    String envContent = await rootBundle.loadString('.env');
    await dotenv.load(string: envContent);
    _showToast('Загружен .env файл как ассет');
  } catch (e) {
    _showToast('Не удалось загрузить .env файл как ассет: $e');
    try {
      // Если не удалось как ассет, пробуем загрузить как обычный файл
      if (Platform.environment.containsKey('FLUTTER_WEB')) {
        // Для веба не пытаемся загружать .env файл через flutter_dotenv
        _showToast('Запуск в веб-окружении, используем переменные окружения Dart');
      } else {
        // На мобильных и десктопных платформах пробуем загрузить .env файл
        await dotenv.load(fileName: ".env");
        _showToast('Загружен .env файл как обычный файл');
      }
    } catch (e2) {
      _showToast('Не удалось загрузить .env файл как обычный файл: $e2');
      _showToast('Приложение будет использовать значения по умолчанию из AppConfig');
    }
  }
}

// Вспомогательная функция для показа Toast сообщений
void _showToast(String message) {
  print(message); // Сохраняем вывод в консоль для отладки
  // Показываем сообщение в интерфейсе, если контекст доступен
  if (navigatorKey.currentState != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        navigatorKey.currentState?.overlay?.insert(
          OverlayEntry(
            builder: (context) => Positioned(
              top: 50.0,
              left: 10.0,
              right: 10.0,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
        
        // Убираем сообщение через 3 секунды
        Future.delayed(Duration(seconds: 3), () {
          try {
            // Проверяем, что overlayEntry еще существует и можно его удалить
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (navigatorKey.currentState?.overlay?.entries.isNotEmpty == true) {
                navigatorKey.currentState?.overlay?.entries.last.remove();
              }
            });
          } catch (e) {
            // Игнорируем ошибки при удалении overlay
          }
        });
      } catch (e) {
        // Игнорируем ошибки при показе сообщения
      }
    });
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
    envSupabaseUrl = dotenv.env['SUPABASE_URL'];
    envSupabaseKey = dotenv.env['SUPABASE_KEY'];
  } catch (e) {
    // Если возникла ошибка доступа к dotenv (например, в вебе), используем только AppConfig
    _showToast('Ошибка доступа к переменным окружения: $e');
    envSupabaseUrl = null;
    envSupabaseKey = null;
  }
  
  String supabaseUrl = envSupabaseUrl ?? AppConfig.supabaseUrl;
  String supabaseKey = envSupabaseKey ?? AppConfig.supabaseKey;
  
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    // Инициализируем Supabase в фоне, чтобы не блокировать запуск приложения
    Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey).then((_) {
      SupabaseService().init(supabaseUrl, supabaseKey);
      _showToast('Supabase инициализирован успешно');
    }).catchError((error) {
      _showToast('Ошибка инициализации Supabase: $error');
    });
  } else {
    _showToast('Не удалось получить настройки Supabase, инициализация не выполнена');
    _showToast('Убедитесь, что в .env файле указаны правильные значения SUPABASE_URL и SUPABASE_KEY');
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
      String? envAppName = dotenv.env['APP_NAME'];
      if (envAppName != null && envAppName.isNotEmpty) {
        appName = envAppName;
      }
    } catch (e) {
      // Если возникла ошибка доступа к dotenv, используем AppConfig
      _showToast('Ошибка доступа к APP_NAME из dotenv: $e');
    }
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: appName, // Устанавливаем имя приложения как заголовок
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate, // Вот этот делегат обязателен для Quill
      ],
      supportedLocales: const [Locale('ru'), Locale('en')],
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
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