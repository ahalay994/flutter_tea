import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal() {
    initialize();
  }

  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  
  bool _isConnected = false; // Начальное значение - отключен
  bool get isConnected => _isConnected;
  
  // Future для отслеживания завершения первой проверки подключения
  final Completer<bool> _firstCheckCompleter = Completer<bool>();
  bool _firstCheckCompleted = false;
  bool get firstCheckCompleted => _firstCheckCompleted;
  
  Timer? _timer;
  
  void initialize() {
    // Начальная проверка подключения (асинхронно, чтобы не блокировать инициализацию)
    Future.microtask(_updateConnectionStatus);
    
    // Периодическая проверка подключения каждую минуту
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateConnectionStatus();
    });

    // Также слушаем события системы
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Берем результат из первого элемента списка
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatusBasedOnResult(result);
    });
  }

  void _updateConnectionStatusBasedOnResult(dynamic result) {
    final wasConnected = _isConnected;
    
    // Проверяем тип результата и обрабатываем соответственно
    bool isConnected;
    if (result is ConnectivityResult) {
      // Используем улучшенную проверку, особенно для веб-браузера
      isConnected = _evaluateConnectionResult(result);
    } else if (result is List<ConnectivityResult>) {
      final firstResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
      isConnected = _evaluateConnectionResult(firstResult);
    } else {
      isConnected = false;
    }
    
    _isConnected = isConnected;

    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  // Основной метод оценки результата проверки подключения
  bool _evaluateConnectionResult(ConnectivityResult result) {
    // Если результат не none, значит есть какое-то подключение
    if (result != ConnectivityResult.none) {
      return true;
    }
    
    // Если результат none, но мы в веб-браузере, пробуем дополнительные проверки
    // Проверяем, возможно ли, что мы в веб-браузере
    if (_isWebEnvironment()) {
      // В веб-браузере connectivity_plus может возвращать ненадежные результаты
      // Поэтому доверяем HTTP-запросу как основному источнику истины
      // Но так как мы не можем выполнить синхронный HTTP-запрос здесь,
      // мы возвращаем true как предположение, и проверим это в асинхронных методах
      return true; // предполагаем, что соединение есть, если мы в вебе
    }
    
    // В мобильных средах доверяем результату Connectivity
    return false;
  }

  Future<void> _updateConnectionStatus() async {
    try {
      // Проверяем подключение через наш улучшенный метод
      bool hasConnection = await checkConnection();
      final wasConnected = _isConnected;
      _isConnected = hasConnection;

      if (wasConnected != _isConnected) {
        _connectionStatusController.add(_isConnected);
      }
    } catch (e) {
      final wasConnected = _isConnected;
      _isConnected = false;

      if (wasConnected != _isConnected) {
        _connectionStatusController.add(_isConnected);
      }
    } finally {
      // Отмечаем, что первая проверка завершена, если она еще не была завершена
      if (!_firstCheckCompleted) {
        _firstCheckCompleted = true;
        _firstCheckCompleter.complete(_isConnected);
      }
    }
  }

  Future<bool> checkConnection() async {
    try {
      // Сначала пробуем использовать Connectivity для проверки подключения
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      
      // В веб-браузере connectivity_plus может не всегда корректно работать
      // Поэтому используем реальный HTTP-запрос как основной метод проверки в веб-среде
      if (_isWebEnvironment()) {
        // В веб-браузере используем HTTP-запрос как основной метод проверки
        return await _performHttpConnectionTest();
      }
      
      // В мобильных устройствах доверяем Connectivity, но делаем дополнительную проверку,
      // если результат none
      if (result == ConnectivityResult.none) {
        // Дополнительно проверяем через HTTP-запрос
        return await _performHttpConnectionTest();
      }
      
      // Возвращаем true, если есть любой тип подключения
      return result != ConnectivityResult.none;
    } catch (e) {
      // Если не удалось проверить подключение через Connectivity, пробуем альтернативный метод
      return await _performHttpConnectionTest();
    }
  }

  // Метод для определения веб-среды
  bool _isWebEnvironment() {
    // Проверяем, не является ли текущая среда мобильной/десктопной
    // Это простой способ определить веб-браузер
    return !Platform.isAndroid && 
           !Platform.isIOS && 
           !Platform.isLinux && 
           !Platform.isMacOS && 
           !Platform.isWindows;
  }

  // Метод для выполнения HTTP-теста подключения
  Future<bool> _performHttpConnectionTest() async {
    try {
      // Попробуем выполнить HEAD-запрос к базовому URL для проверки подключения
      final response = await http.head(Uri.parse('https://httpbin.org/get')).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Connection test timed out'),
      );
      
      // Если получили любой ответ (даже 404), значит соединение есть
      return response.statusCode < 500;
    } catch (e) {
      // Если HEAD не сработал, пробуем GET-запрос
      try {
        final response = await http.get(Uri.parse('https://httpbin.org/get')).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Connection test timed out'),
        );
        return response.statusCode < 500;
      } catch (e2) {
        // Если и GET не сработал, пробуем более надежный URL
        try {
          final response = await http.get(Uri.parse('https://httpbin.org/headers')).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Connection test timed out'),
          );
          return response.statusCode < 500;
        } catch (e3) {
          // Все HTTP-запросы не удалась выполнить
          return false;
        }
      }
    }
  }

  // Кешированное состояние доступности API
  bool? _apiAvailable;
  DateTime? _lastApiCheck;

  // Метод для проверки доступности API
  Future<bool> checkApiAvailability() async {
    // Кешируем результат на 5 минут
    if (_apiAvailable != null && 
        _lastApiCheck != null && 
        DateTime.now().difference(_lastApiCheck!) < const Duration(minutes: 5)) {
      return _apiAvailable!;
    }

    try {
      // Проверяем базовое подключение
      final hasConnectivity = await checkConnection();
      if (!hasConnectivity) {
        _apiAvailable = false;
        _lastApiCheck = DateTime.now();
        return false;
      }

      // Если есть подключение к интернету, пробуем запросить главную страницу API
      // Загружаем API URL из конфигурации приложения
      String apiUrl = 'https://httpbin.org/get'; // используем тестовый URL в качестве fallback
      
      // Выполняем тестовый запрос к API
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 10), // увеличиваем таймаут для веб-среды
        onTimeout: () => throw TimeoutException('API availability test timed out'),
      );

      // API считается доступным, если получили успешный ответ или хотя бы 4xx (но не 5xx)
      _apiAvailable = response.statusCode < 500;
      _lastApiCheck = DateTime.now();
      return _apiAvailable!;
    } catch (e) {
      _apiAvailable = false;
      _lastApiCheck = DateTime.now();
      return false;
    }
  }

  // Расширенный метод проверки подключения, включающий проверку API
  Future<bool> checkFullConnection() async {
    final hasConnectivity = await checkConnection();
    if (!hasConnectivity) {
      return false;
    }

    return await checkApiAvailability();
  }

  // Метод для ожидания завершения первой проверки подключения
  Future<bool> waitForFirstCheck() async {
    if (_firstCheckCompleted) {
      return _isConnected;
    }
    return _firstCheckCompleter.future;
  }

  void dispose() {
    _timer?.cancel();
    _connectionStatusController.close();
  }
}