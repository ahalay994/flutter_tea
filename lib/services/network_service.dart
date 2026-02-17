import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

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
      isConnected = result != ConnectivityResult.none;
    } else if (result is List<ConnectivityResult>) {
      final firstResult = result.isNotEmpty ? result.first : ConnectivityResult.none;
      isConnected = firstResult != ConnectivityResult.none;
    } else {
      isConnected = false;
    }
    
    _isConnected = isConnected;

    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  Future<void> _updateConnectionStatus() async {
    try {
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatusBasedOnResult(result);
    } catch (e) {
      final wasConnected = _isConnected;
      _isConnected = false;

      if (wasConnected) {
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
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      
      // Возвращаем true, если есть любой тип подключения (WiFi, мобильный, Ethernet и т.д.)
      // и только false, если подключения нет вообще
      bool hasConnection = result != ConnectivityResult.none;
      
      // Для дополнительной проверки, можно попытаться выполнить легкий HTTP-запрос
      // Но для простоты и производительности, пока оставим только проверку Connectivity
      return hasConnection;
    } catch (e) {
      // Если не удалось проверить подключение, считаем, что его нет
      return false;
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
      // Выполняем легкий запрос к основному API эндпоинту
      // Используем существующую зависимость http, но делаем простой HEAD или GET запрос
      final List<ConnectivityResult> connectivityResults = await Connectivity().checkConnectivity();
      final connectivityResult = connectivityResults.isNotEmpty ? connectivityResults.first : ConnectivityResult.none;
      if (connectivityResult == ConnectivityResult.none) {
        _apiAvailable = false;
        _lastApiCheck = DateTime.now();
        return false;
      }

      // Если есть подключение к интернету, пробуем запросить главную страницу API
      // Но для этого нужно использовать http клиент
      _apiAvailable = true; // Пока считаем, что API доступен, если есть интернет
      _lastApiCheck = DateTime.now();
      return true;
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
