import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home/home_screen.dart';
import 'services/supabase_service.dart';
import 'utils/app_config.dart';

// Утилита для безопасной загрузки .env файла
Future<void> loadEnvSafely() async {
  try {
    // В веб-окружении (когда Platform.isAndroid и др. не определены как true) 
    // flutter_dotenv может вызвать ошибки, поэтому используем только переменные окружения Dart
    if (Platform.environment.containsKey('FLUTTER_WEB')) {
      // Для веба не пытаемся загружать .env файл через flutter_dotenv
      print('Запуск в веб-окружении, используем переменные окружения Dart');
    } else {
      // На мобильных и десктопных платформах пробуем загрузить .env файл
      await dotenv.load(fileName: ".env");
    }
  } catch (e) {
    // Игнорируем ошибки загрузки .env файла
    print('Не удалось загрузить .env файл: $e');
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
    print('Ошибка доступа к переменным окружения: $e');
    envSupabaseUrl = null;
    envSupabaseKey = null;
  }
  
  String supabaseUrl = envSupabaseUrl ?? AppConfig.supabaseUrl;
  String supabaseKey = envSupabaseKey ?? AppConfig.supabaseKey;
  
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    // Инициализируем Supabase в фоне, чтобы не блокировать запуск приложения
    Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey).then((_) {
      SupabaseService().init(supabaseUrl, supabaseKey);
    }).catchError((error) {
      print('Ошибка инициализации Supabase: $error');
    });
  } else {
    print('Не удалось получить настройки Supabase, инициализация не выполнена');
    print('Убедитесь, что в .env файле указаны правильные значения SUPABASE_URL и SUPABASE_KEY');
  }

  runApp(const ProviderScope(child: TeaApp()));
}

class TeaApp extends StatelessWidget {
  const TeaApp({super.key});

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
      print('Ошибка доступа к APP_NAME из dotenv: $e');
    }
    
    return MaterialApp(
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