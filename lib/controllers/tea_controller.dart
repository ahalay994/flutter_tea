import 'dart:ui';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tea/api/appearance_api.dart';
import 'package:tea/api/country_api.dart';
import 'package:tea/api/dto/create_tea_dto.dart';
import 'package:tea/api/flavor_api.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/api/responses/tea_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/api/tea_api.dart';
import 'package:tea/api/type_api.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/services/local_database_service.dart';
import 'package:tea/services/network_service.dart';
import 'package:tea/services/image_cache_service.dart';
import 'package:tea/utils/app_logger.dart';

// Структура для пагинации
class PaginationResult<T> {
  final List<T> data;
  final int currentPage;
  final int totalPages;
  final int perPage;
  final bool hasMore;

  PaginationResult({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
    required this.hasMore,
  });
}

final teaControllerProvider = Provider((ref) => TeaController());

final connectionStatusProvider = StreamProvider<bool>((ref) {
  final controller = ref.watch(teaControllerProvider);
  return controller.connectionStatusStream;
});

final teaListProvider = FutureProvider.family<PaginationResult<TeaModel>, int>((ref, page) {
  final controller = ref.watch(teaControllerProvider);
  return controller.fetchFullTeas(page: page);
});

class TeaController {
  final TeaApi _teaApi = TeaApi();
  final AppearanceApi _appearanceApi = AppearanceApi();
  final CountryApi _countryApi = CountryApi();
  final FlavorApi _flavorApi = FlavorApi();
  final TypeApi _typeApi = TypeApi();
  
  final LocalDatabaseService _localDatabase = LocalDatabaseService();
  final NetworkService _networkService = NetworkService();
  
  // Для фоновой синхронизации
  Timer? _syncTimer;
  
  // Отслеживание ошибок API
  DateTime? _lastApiError;
  static const Duration _apiErrorTimeout = Duration(minutes: 5);
  
  // Ключ для хранения времени последней ошибки API
  static const String _lastApiErrorKey = 'last_api_error_time';
  
  // Метод для загрузки времени последней ошибки API из локального хранилища
  Future<void> _loadLastApiError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastApiErrorKey);
      if (timestamp != null) {
        _lastApiError = DateTime.parse(timestamp);
      }
    } catch (e) {
      // Если не удалось загрузить, не страшно
      AppLogger.error('Не удалось загрузить время последней ошибки API', error: e);
    }
  }
  
  // Метод для сохранения времени последней ошибки API в локальное хранилище
  Future<void> _saveLastApiError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastApiErrorKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Если не удалось сохранить, не страшно
      AppLogger.error('Не удалось сохранить время последней ошибки API', error: e);
    }
  }
  
  // Метод для очистки времени последней ошибки API
  Future<void> _clearLastApiError() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastApiErrorKey);
    } catch (e) {
      // Если не удалось очистить, не страшно
      AppLogger.error('Не удалось очистить время последней ошибки API', error: e);
    }
  }

  TeaController() {
    // Подписываемся на изменения статуса подключения
    _networkService.connectionStatusStream.listen((isConnected) {
      if (isConnected) {
        // При восстановлении интернета запускаем фоновую синхронизацию
        _startBackgroundSync();
      }
    });
    
    // Проверяем, есть ли данные в базе при запуске
    _initializeData();
  }
  
  // Метод инициализации данных при запуске
  Future<void> _initializeData() async {
    try {
      // Проверяем подключение
      final hasConnection = await _networkService.checkConnection();
      
      // Если есть подключение, сбрасываем флаг ошибки API, чтобы использовать онлайн-режим
      if (hasConnection) {
        _lastApiError = null;
        await _clearLastApiError();
      }
      
      // Проверяем, есть ли данные в базе
      final totalTeasCount = await _localDatabase.getTotalTeasCount();
      
      // Проверяем существование таблиц метаданных
      bool metadataTablesExist = true;
      try {
        await _localDatabase.getCountries();
      } catch (e) {
        metadataTablesExist = false;
      }
      
      // Если база пуста и есть подключение, запускаем синхронизацию
      // Но делаем это асинхронно, чтобы не блокировать инициализацию
      if (totalTeasCount == 0 || !metadataTablesExist) {
        // Проверяем подключение асинхронно
        if (hasConnection) {
          // Запускаем синхронизацию в фоне, не дожидаясь завершения
          _syncAllTeas(); // Dart автоматически обрабатывает неподождённые Future
        }
      }
    } catch (e) {
      AppLogger.error('Ошибка при инициализации данных', error: e);
    }
  }

  // Метод для фоновой синхронизации всех данных
  void _startBackgroundSync() {
    if (_syncTimer != null) {
      // Если таймер уже запущен, отменяем его
      _syncTimer!.cancel();
    }
    
    // Сбрасываем флаг ошибки API при восстановлении подключения
    _lastApiError = null;
    
    // Запускаем синхронизацию через 2 секунды после подключения
    _syncTimer = Timer(const Duration(seconds: 2), () async {
      await _syncAllTeas();
    });
  }

  // Метод для синхронизации всех чаёв в фоновом режиме
  Future<void> _syncAllTeas() async {
    AppLogger.debug('Начало фоновой синхронизации всех чаёв');
    
    // Сбрасываем флаг ошибки API в начале синхронизации
    _lastApiError = null;
    await _clearLastApiError();
    
    // Проверяем подключение перед началом синхронизации
    if (!await _networkService.checkConnection()) {
      AppLogger.debug('Нет подключения к интернету, синхронизация не выполняется');
      return;
    }
    
    try {
      int page = 1;
      bool hasMore = true;
      
      // Получаем и сохраняем метаданные
      final countries = await _countryApi.getCountries();
      final types = await _typeApi.getTypes();
      final appearances = await _appearanceApi.getAppearances();
      final flavors = await _flavorApi.getFlavors();
      
      await _localDatabase.insertCountries(countries);
      await _localDatabase.insertTypes(types);
      await _localDatabase.insertAppearances(appearances);
      await _localDatabase.insertFlavors(flavors);
      
      // Очищаем локальную базу перед синхронизацией
      await _localDatabase.clearAll();
      
      while (hasMore) {
        final paginatedResponse = await _teaApi.getTeasPaginated(page: page, perPage: 20);
        
              // Сохраняем полученные данные в локальную базу
              for (final teaResponse in paginatedResponse.data) {
                final teaModel = TeaModel.fromApiResponseForDatabase(
                  response: teaResponse,
                );
                await _localDatabase.insertTea(teaModel);
              }        
        hasMore = paginatedResponse.hasMore;
        page++;
        
        // Проверяем, не потеряли ли мы соединение
        if (!await _networkService.checkConnection()) {
          AppLogger.debug('Соединение потеряно во время синхронизации');
          break;
        }
      }
      
      AppLogger.success('Фоновая синхронизация завершена');
    } catch (e) {
      AppLogger.error('Ошибка фоновой синхронизации', error: e);
    }
  }

  // Метод для получения списка чаёв с пагинацией и возможностью оффлайн-режима
  Future<PaginationResult<TeaModel>> fetchFullTeas({int page = 1, int perPage = 10}) async {
    // Загружаем время последней ошибки API при первом вызове
    if (_lastApiError == null) {
      await _loadLastApiError();
    }
    
    // Проверяем, не было ли недавно ошибки API
    bool recentApiError = _lastApiError != null && 
        DateTime.now().difference(_lastApiError!) < _apiErrorTimeout;
    
    // Проверяем подключение
    bool hasConnection = false;
    if (!recentApiError) {
      try {
        // Проверяем подключение с обработкой возможных ошибок
        hasConnection = await _networkService.checkConnection();
      } catch (e) {
        AppLogger.error('Ошибка при проверке подключения', error: e);
        hasConnection = false; // Если не удалось проверить, считаем, что нет подключения
      }
    }
    
    // Если недавно была ошибка API или нет подключения, сразу идем в оффлайн режим
    if (recentApiError || !hasConnection) {
      // Оффлайн режим - получаем данные из локальной базы с пагинацией
      AppLogger.debug('Загрузка данных в оффлайн-режиме (страница $page)');
      
      try {
        // Получаем метаданные для заполнения названий
        final metadata = await _getMetadata();
        
        AppLogger.debug('Вызов getTeasPaginatedWithNames в оффлайн-режиме');
        
        final pageTeas = await _localDatabase.getTeasPaginatedWithNames(
          page: page, 
          perPage: perPage,
          countries: metadata['countries'] as List<CountryResponse>,
          types: metadata['types'] as List<TypeResponse>,
          appearances: metadata['appearances'] as List<AppearanceResponse>,
          flavors: metadata['flavors'] as List<FlavorResponse>,
        );
        final totalTeasCount = await _localDatabase.getTotalTeasCount();
        final totalPages = (totalTeasCount / perPage).ceil();
        final hasMore = (page * perPage) < totalTeasCount;
        
        AppLogger.debug('Получено ${pageTeas.length} чаёв из локальной базы, страница $page, всего: $totalTeasCount, totalPages: $totalTeasCount, hasMore: $hasMore');
        
        return PaginationResult(
          data: pageTeas,
          currentPage: page,
          totalPages: totalPages,
          perPage: perPage,
          hasMore: hasMore,
        );
      } catch (offlineError) {
        AppLogger.error('Ошибка при получении данных из локальной базы', error: offlineError);
        // Если ошибка связана с отсутствием метаданных, возвращаем пустой результат
        if (offlineError.toString().contains('no such table')) {
          AppLogger.debug('Таблицы метаданных не существуют, возвращаем пустой результат');
          return PaginationResult(
            data: [],
            currentPage: page,
            totalPages: 0,
            perPage: perPage,
            hasMore: false,
          );
        }
        rethrow;
      }
    }
    
    // Онлайн режим - получаем данные с сервера с пагинацией
    try {
      AppLogger.debug('Загрузка данных в онлайн-режиме (страница $page)');
      
      final paginatedResponse = await _teaApi.getTeasPaginated(page: page, perPage: perPage);
      
      // Получаем метаданные для правильного преобразования
      final metadata = await _getMetadata();
      
      // Сохраняем полученные данные в локальную базу
      AppLogger.debug('Сохранение ${paginatedResponse.data.length} чаёв в локальную базу');
      for (final teaResponse in paginatedResponse.data) {
        final teaModel = TeaModel.fromResponse(
          response: teaResponse,
          countries: metadata['countries'] as List<CountryResponse>,
          types: metadata['types'] as List<TypeResponse>,
          appearances: metadata['appearances'] as List<AppearanceResponse>,
          flavors: metadata['flavors'] as List<FlavorResponse>,
        );
        await _localDatabase.insertTea(teaModel);
      }
      
      // Преобразуем полученные данные в модель
      final teas = paginatedResponse.data.map((response) => TeaModel.fromResponse(
        response: response,
        countries: metadata['countries'] as List<CountryResponse>,
        types: metadata['types'] as List<TypeResponse>,
        appearances: metadata['appearances'] as List<AppearanceResponse>,
        flavors: metadata['flavors'] as List<FlavorResponse>,
      )).toList();
      
      return PaginationResult(
        data: teas,
        currentPage: paginatedResponse.currentPage,
        totalPages: paginatedResponse.totalPages,
        perPage: paginatedResponse.perPage,
        hasMore: paginatedResponse.hasMore,
      );
          } catch (e, stack) {
            AppLogger.error('Ошибка при получении данных из API, переключаемся на оффлайн-режим', error: e, stackTrace: stack);
            // Запоминаем время последней ошибки
            _lastApiError = DateTime.now();
            // Сохраняем в локальное хранилище
            await _saveLastApiError();
            
            // Получаем данные из локальной базы
            try {
              AppLogger.debug('Загрузка данных в оффлайн-режиме (страница $page) после ошибки API');
              // Получаем метаданные для заполнения названий
              final metadata = await _getMetadata();
              
              AppLogger.debug('Вызов getTeasPaginatedWithNames в оффлайн-режиме после ошибки API');
              
              final pageTeas = await _localDatabase.getTeasPaginatedWithNames(
                page: page, 
                perPage: perPage,
                countries: metadata['countries'] as List<CountryResponse>,
                types: metadata['types'] as List<TypeResponse>,
                appearances: metadata['appearances'] as List<AppearanceResponse>,
                flavors: metadata['flavors'] as List<FlavorResponse>,
              );
              final totalTeasCount = await _localDatabase.getTotalTeasCount();
              final totalPages = (totalTeasCount / perPage).ceil();
              final hasMore = (page * perPage) < totalTeasCount;
              
              AppLogger.debug('Получено ${pageTeas.length} чаёв из локальной базы, страница $page, всего: $totalTeasCount, totalPages: $totalTeasCount, hasMore: $hasMore');
              
              return PaginationResult(
                data: pageTeas,
                currentPage: page,
                totalPages: totalPages,
                perPage: perPage,
                hasMore: hasMore,
              );
            } catch (offlineError) {
              AppLogger.error('Ошибка при получении данных из локальной базы', error: offlineError);
              // Если ошибка связана с отсутствием метаданных, возвращаем пустой результат
              if (offlineError.toString().contains('no such table')) {
                AppLogger.debug('Таблицы метаданных не существуют, возвращаем пустой результат');
                return PaginationResult(
                  data: [],
                  currentPage: page,
                  totalPages: 0,
                  perPage: perPage,
                  hasMore: false,
                );
              }
              rethrow;
            }    }
  }

  // Метод для получения одного чая
  Future<TeaResponse> getTea(int teaId) async {
    if (await _networkService.checkConnection()) {
      // Онлайн режим
      final teaResponse = await _teaApi.getTea(teaId);
      
      // Обновляем в локальной базе
      final metadata = await _getMetadata();
      final teaModel = TeaModel.fromResponse(
        response: teaResponse,
        countries: metadata['countries'] as List<CountryResponse>,
        types: metadata['types'] as List<TypeResponse>,
        appearances: metadata['appearances'] as List<AppearanceResponse>,
        flavors: metadata['flavors'] as List<FlavorResponse>,
      );
      await _localDatabase.insertTea(teaModel);
      
      return teaResponse;
    } else {
      // Оффлайн режим
      // Получаем метаданные для заполнения названий
      final metadata = await _getMetadata();
      
      final teaModel = await _localDatabase.getTeaWithNames(
        id: teaId,
        countries: metadata['countries'] as List<CountryResponse>,
        types: metadata['types'] as List<TypeResponse>,
        appearances: metadata['appearances'] as List<AppearanceResponse>,
        flavors: metadata['flavors'] as List<FlavorResponse>,
      );
      
      if (teaModel != null) {
        // Преобразуем TeaModel в TeaResponse
        return TeaResponse(
          id: teaModel.id,
          name: teaModel.name,
          countryId: teaModel.country != null ? int.tryParse(teaModel.country!) : null,
          typeId: teaModel.type != null ? int.tryParse(teaModel.type!) : null,
          appearanceId: teaModel.appearance != null ? int.tryParse(teaModel.appearance!) : null,
          temperature: teaModel.temperature,
          brewingGuide: teaModel.brewingGuide,
          weight: teaModel.weight,
          description: teaModel.description,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          flavors: teaModel.flavors.map((f) => int.tryParse(f)).where((f) => f != null).cast<int>().toList(),
          images: [], // Для оффлайн режима пока возвращаем пустой список изображений
        );
      } else {
        throw Exception('Чай не найден в оффлайн-режиме');
      }
    }
  }

  // Метод для создания чая
  Future<TeaResponse> createTeaWithResponse(CreateTeaDto dto, {required VoidCallback onSuccess}) async {
    if (await _networkService.checkConnection()) {
      // Онлайн режим - обычное создание
      final response = await _teaApi.saveTea(dto);
      onSuccess(); // Инвалидируем список
      
      // Возвращаем первый элемент, так как saveTea возвращает список
      return response.first;
    } else {
      // Оффлайн режим - не поддерживается
      throw Exception('Создание чая недоступно в оффлайн-режиме');
    }
  }

  // Метод для обновления чая
  Future<TeaResponse> updateTea(int teaId, CreateTeaDto dto, {required VoidCallback onSuccess}) async {
    if (await _networkService.checkConnection()) {
      // Онлайн режим - обычное обновление
      await _teaApi.updateTea(teaId, dto);
      onSuccess(); // Инвалидируем список
      
      // После инвалидации списка получаем обновленный чай
      // Ждем немного, чтобы список обновился
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Затем получаем список чаев и находим обновленный
      final teas = await _teaApi.getTeas();
      final updatedTea = teas.firstWhere((tea) => tea.id == teaId, 
          orElse: () => throw Exception("Обновленный чай не найден в списке"));

      AppLogger.success('Чай "${dto.name}" успешно обновлён');
      return updatedTea;
    } else {
      // Оффлайн режим - не поддерживается
      throw Exception('Обновление чая недоступно в оффлайн-режиме');
    }
  }

  // Метод для удаления чая
  Future<bool> deleteTea(int teaId, {required VoidCallback onSuccess}) async {
    if (await _networkService.checkConnection()) {
      // Онлайн режим - обычное удаление
      final response = await _teaApi.deleteTea(teaId);
      onSuccess(); // Инвалидируем список
      
      // Удаляем из локальной базы
      await _localDatabase.deleteTea(teaId);
      
      return response.ok;
    } else {
      // Оффлайн режим - не поддерживается
      throw Exception('Удаление чая недоступно в оффлайн-режиме');
    }
  }

  // Вспомогательный метод для получения метаданных
  Future<Map<String, dynamic>> _getMetadata() async {
    // Проверяем подключение
    final hasConnection = await _networkService.checkConnection();
    
    if (hasConnection) {
      try {
        // Онлайн режим - получаем данные с сервера
        final countries = await _countryApi.getCountries();
        final types = await _typeApi.getTypes();
        final appearances = await _appearanceApi.getAppearances();
        final flavors = await _flavorApi.getFlavors();
        
        AppLogger.debug('Получено метаданных онлайн: ${countries.length} стран, ${types.length} типов, ${appearances.length} внешних видов, ${flavors.length} вкусов');
        
        // Обязательно сохраняем метаданные в локальную базу при онлайн-режиме
        await _localDatabase.insertCountries(countries);
        await _localDatabase.insertTypes(types);
        await _localDatabase.insertAppearances(appearances);
        await _localDatabase.insertFlavors(flavors);
        
        return {
          'countries': countries,
          'types': types,
          'appearances': appearances,
          'flavors': flavors,
        };
      } catch (apiError) {
        // Если онлайн-запрос не удался, пробуем получить из локальной базы
        AppLogger.debug('Ошибка при получении метаданных из API, пробуем получить из локальной базы: $apiError');
        try {
          final countries = await _localDatabase.getCountries();
          final types = await _localDatabase.getTypes();
          final appearances = await _localDatabase.getAppearances();
          final flavors = await _localDatabase.getFlavors();
          
          AppLogger.debug('Получено метаданных из локальной базы: ${countries.length} стран, ${types.length} типов, ${appearances.length} внешних видов, ${flavors.length} вкусов');
          
          return {
            'countries': countries,
            'types': types,
            'appearances': appearances,
            'flavors': flavors,
          };
        } catch (localError) {
          // Если и локальные данные недоступны, возвращаем пустые списки
          AppLogger.debug('Ошибка при получении метаданных из локальной базы: $localError');
          return {
            'countries': <CountryResponse>[],
            'types': <TypeResponse>[],
            'appearances': <AppearanceResponse>[],
            'flavors': <FlavorResponse>[],
          };
        }
      }
    } else {
      // Оффлайн режим - получаем данные из локальной базы
      try {
        final countries = await _localDatabase.getCountries();
        final types = await _localDatabase.getTypes();
        final appearances = await _localDatabase.getAppearances();
        final flavors = await _localDatabase.getFlavors();
        
        AppLogger.debug('Получено метаданных из локальной базы в оффлайн-режиме: ${countries.length} стран, ${types.length} типов, ${appearances.length} внешних видов, ${flavors.length} вкусов');
        
        return {
          'countries': countries,
          'types': types,
          'appearances': appearances,
          'flavors': flavors,
        };
      } catch (localError) {
        // Если локальные данные недоступны в оффлайн-режиме, возвращаем пустые списки
        AppLogger.debug('Ошибка при получении метаданных из локальной базы в оффлайн-режиме: $localError');
        return {
          'countries': <CountryResponse>[],
          'types': <TypeResponse>[],
          'appearances': <AppearanceResponse>[],
          'flavors': <FlavorResponse>[],
        };
      }
    }
  }
  
  // Метод для проверки статуса подключения
  bool get isConnected => _networkService.isConnected;
  
  // Геттер для NetworkService
  NetworkService get networkService => _networkService;
  
  // Метод для получения потока изменения статуса подключения
  Stream<bool> get connectionStatusStream => _networkService.connectionStatusStream;
  
  // Метод для ручного запуска синхронизации
  Future<void> manualSync() async {
    if (await _networkService.checkConnection()) {
      await _syncAllTeas();
    }
  }
  
  // Метод для кеширования всех изображений
  Future<void> _cacheAllImages() async {
    try {
      final imageUrls = await _localDatabase.getAllImageUrls();
      AppLogger.debug('Начинаем кеширование ${imageUrls.length} изображений');
      
      // Кешируем изображения по одному, чтобы не перегружать систему
      for (final imageUrl in imageUrls) {
        try {
          // Используем кеш-менеджер для скачивания изображения
          await CustomCacheManager.instance.getSingleFile(imageUrl);
          AppLogger.debug('Изображение закешировано: $imageUrl');
        } catch (e) {
          AppLogger.error('Ошибка при кешировании изображения', error: e);
        }
      }
    } catch (e) {
      AppLogger.error('Ошибка при получении списка изображений для кеширования', error: e);
    }
  }
}