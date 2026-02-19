import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/flavor_response.dart';

class LocalDatabaseService {
  static Database? _database;
  
  // Веб-версия использует in-memory хранилище
  Map<String, dynamic>? _webStorage;

  Future<Database> get database async {
    if (kIsWeb) {
      // Для веба возвращаем null, так как мы используем in-memory хранилище
      throw StateError('Database is not available in web environment');
    }
    
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw StateError('Database is not available in web environment');
    }
    
    String path = join(await getDatabasesPath(), 'tea_database.db');
    return await openDatabase(
      path,
      version: 3, // Увеличиваем версию базы данных
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teas (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        countryId INTEGER,
        typeId INTEGER,
        appearanceId INTEGER,
        temperature TEXT,
        brewingGuide TEXT,
        weight TEXT,
        description TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tea_flavors (
        teaId INTEGER,
        flavorId INTEGER,
        PRIMARY KEY (teaId, flavorId),
        FOREIGN KEY (teaId) REFERENCES teas(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tea_images (
        id INTEGER PRIMARY KEY,
        teaId INTEGER,
        name TEXT,
        status TEXT,
        url TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (teaId) REFERENCES teas(id) ON DELETE CASCADE
      )
    ''');
    
    // Таблицы для хранения метаданных
    await db.execute('''
      CREATE TABLE countries (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE types (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE appearances (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE flavors (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    
    // Таблица для хранения истории чата
    await db.execute('''
      CREATE TABLE chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }
  
  // Метод для миграции базы данных
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Если мигрируем с версии 1 на 2, добавляем таблицы метаданных
    if (oldVersion < 2 && newVersion >= 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS countries (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS types (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS appearances (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS flavors (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
    }
    
    // Если мигрируем с версии 2 на 3, добавляем таблицу истории чата
    if (oldVersion < 3 && newVersion >= 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          role TEXT NOT NULL,
          content TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
  }

  // Инициализация in-memory хранилища для веба
  Map<String, dynamic> _getWebStorage() {
    _webStorage ??= {
      'teas': <Map<String, dynamic>>[],
      'tea_flavors': <Map<String, dynamic>>[],
      'tea_images': <Map<String, dynamic>>[],
      'countries': <Map<String, dynamic>>[],
      'types': <Map<String, dynamic>>[],
      'appearances': <Map<String, dynamic>>[],
      'flavors': <Map<String, dynamic>>[],
    };
    return _webStorage!;
  }

  Future<void> insertTea(TeaModel tea) async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      // Удаляем существующий чай
      storage['teas'].removeWhere((item) => item['id'] == tea.id);
      
      // Добавляем чай
      storage['teas'].add({
        'id': tea.id,
        'name': tea.name,
        'countryId': tea.country != null ? int.tryParse(tea.country!) : null,
        'typeId': tea.type != null ? int.tryParse(tea.type!) : null,
        'appearanceId': tea.appearance != null ? int.tryParse(tea.appearance!) : null,
        'temperature': tea.temperature,
        'brewingGuide': tea.brewingGuide,
        'weight': tea.weight,
        'description': tea.description,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Удаляем старые вкусы
      storage['tea_flavors'].removeWhere((item) => item['teaId'] == tea.id);
      // Добавляем новые вкусы
      for (String flavor in tea.flavors) {
        int? flavorId = int.tryParse(flavor);
        if (flavorId != null) {
          storage['tea_flavors'].add({'teaId': tea.id, 'flavorId': flavorId});
        }
      }

      // Удаляем старые изображения
      storage['tea_images'].removeWhere((item) => item['teaId'] == tea.id);
      // Добавляем новые изображения
      for (String imageUrl in tea.images) {
        storage['tea_images'].add({
          'teaId': tea.id,
          'name': imageUrl.split('/').last,
          'status': 'finished',
          'url': imageUrl,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    } else {
      // Мобильная/десктопная реализация
      final db = await database;

      await db.transaction((txn) async {
        // Вставляем или обновляем чай
        await txn.insert('teas', {
          'id': tea.id,
          'name': tea.name,
          'countryId': tea.country != null ? int.tryParse(tea.country!) : null,
          'typeId': tea.type != null ? int.tryParse(tea.type!) : null,
          'appearanceId': tea.appearance != null ? int.tryParse(tea.appearance!) : null,
          'temperature': tea.temperature,
          'brewingGuide': tea.brewingGuide,
          'weight': tea.weight,
          'description': tea.description,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Удаляем старые вкусы
        await txn.delete('tea_flavors', where: 'teaId = ?', whereArgs: [tea.id]);

        // Вставляем новые вкусы
        for (String flavor in tea.flavors) {
          int? flavorId = int.tryParse(flavor);
          if (flavorId != null) {
            await txn.insert('tea_flavors', {'teaId': tea.id, 'flavorId': flavorId});
          }
        }

        // Удаляем старые изображения
        await txn.delete('tea_images', where: 'teaId = ?', whereArgs: [tea.id]);

        // Вставляем новые изображения
        for (String imageUrl in tea.images) {
          await txn.insert('tea_images', {
            'teaId': tea.id,
            'name': imageUrl.split('/').last,
            'status': 'finished',
            'url': imageUrl,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      });
    }
  }

  Future<void> insertTeas(List<TeaModel> teas) async {
    for (final tea in teas) {
      await insertTea(tea);
    }
  }

  Future<List<TeaModel>> getAllTeas() async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      final List<TeaModel> teas = [];

      for (final teaMap in storage['teas']) {
        // Получаем вкусы для этого чая
        final flavorMaps = storage['tea_flavors'].where((map) => map['teaId'] == teaMap['id']).toList();
        final List<String> flavors = flavorMaps.map((map) => map['flavorId'].toString()).toList();

        // Получаем изображения для этого чая
        final imageMaps = storage['tea_images'].where((map) => map['teaId'] == teaMap['id']).toList();
        final List<String> images = imageMaps.map((map) => map['url'] as String).toList();

        teas.add(
          TeaModel(
            id: teaMap['id'],
            name: teaMap['name'],
            country: teaMap['countryId']?.toString(),
            type: teaMap['typeId']?.toString(),
            appearance: teaMap['appearanceId']?.toString(),
            temperature: teaMap['temperature'],
            brewingGuide: teaMap['brewingGuide'],
            weight: teaMap['weight'],
            description: teaMap['description'],
            flavors: flavors,
            images: images,
          ),
        );
      }

      return teas;
    } else {
      // Мобильная/десктопная реализация
      final db = await database;

      final List<Map<String, dynamic>> teaMaps = await db.query('teas', orderBy: 'id DESC');

      final List<TeaModel> teas = [];

      for (final teaMap in teaMaps) {
        // Получаем вкусы для этого чая
        final List<Map<String, dynamic>> flavorMaps = await db.query(
          'tea_flavors',
          where: 'teaId = ?',
          whereArgs: [teaMap['id']],
        );

        final List<String> flavors = flavorMaps.map((map) => map['flavorId'].toString()).toList();

        // Получаем изображения для этого чая
        final List<Map<String, dynamic>> imageMaps = await db.query(
          'tea_images',
          where: 'teaId = ?',
          whereArgs: [teaMap['id']],
          orderBy: 'id ASC',
        );

        final List<String> images = imageMaps.map((map) => map['url'] as String).toList();

        teas.add(
          TeaModel(
            id: teaMap['id'],
            name: teaMap['name'],
            country: teaMap['countryId']?.toString(),
            type: teaMap['typeId']?.toString(),
            appearance: teaMap['appearanceId']?.toString(),
            temperature: teaMap['temperature'],
            brewingGuide: teaMap['brewingGuide'],
            weight: teaMap['weight'],
            description: teaMap['description'],
            flavors: flavors,
            images: images,
          ),
        );
      }

      return teas;
    }
  }

  // Метод для получения чаёв с пагинацией
  Future<List<TeaModel>> getTeasPaginated({int page = 1, int perPage = 10}) async {
    final teas = await getAllTeas();
    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage;
    
    if (startIndex >= teas.length) return [];
    
    return teas.sublist(startIndex, endIndex > teas.length ? teas.length : endIndex);
  }

  // Метод для получения общего количества чаёв
  Future<int> getTotalTeasCount() async {
    if (kIsWeb) {
      final storage = _getWebStorage();
      return storage['teas'].length;
    } else {
      final db = await database;
      final result = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM teas'));
      return result ?? 0;
    }
  }

  Future<void> deleteTea(int id) async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      storage['teas'].removeWhere((item) => item['id'] == id);
      storage['tea_flavors'].removeWhere((item) => item['teaId'] == id);
      storage['tea_images'].removeWhere((item) => item['teaId'] == id);
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      await db.delete('teas', where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      storage['teas'].clear();
      storage['tea_flavors'].clear();
      storage['tea_images'].clear();
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('tea_images');
        await txn.delete('tea_flavors');
        await txn.delete('teas');
      });
    }
  }

  // Метод для получения папки кеша изображений
  Future<String> get _imageCachePath async {
    if (kIsWeb) {
      return ''; // Для веба возвращаем пустую строку
    }
    
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/image_cache';
    await Directory(path).create(recursive: true);
    return path;
  }

  // Метод для сохранения изображения в локальный кеш
  Future<String> cacheImage(String imageUrl) async {
    if (kIsWeb) {
      // В вебе просто возвращаем оригинальный URL
      return imageUrl;
    }
    
    try {
      // Генерируем имя файла из URL
      final fileName = Uri.parse(imageUrl).pathSegments.last;
      final filePath = '${await _imageCachePath}/$fileName';

      // Проверяем, существует ли уже файл
      final file = File(filePath);
      if (await file.exists()) {
        return filePath;
      }

      // Если файла нет, возвращаем оригинальный URL
      // Фактическое скачивание будет происходить через cached_network_image
      return imageUrl;
    } catch (e) {
      // В случае ошибки возвращаем оригинальный URL
      return imageUrl;
    }
  }

  // Метод для получения всех URL изображений для кеширования
  Future<List<String>> getAllImageUrls() async {
    if (kIsWeb) {
      final storage = _getWebStorage();
      return storage['tea_images']
          .map((map) => map['url'] as String)
          .where((url) => url.startsWith('http'))
          .toList();
    }
    
    final db = await database;
    final List<Map<String, dynamic>> imageMaps = await db.query('tea_images');
    return imageMaps.map((map) => map['url'] as String).where((url) => url.startsWith('http')).toList();
  }
  
  // Метод для получения уникальных URL изображений для кеширования
  Future<List<String>> getUniqueImageUrls() async {
    if (kIsWeb) {
      final storage = _getWebStorage();
      final urls = storage['tea_images']
          .map((map) => map['url'] as String)
          .where((url) => url.startsWith('http'))
          .toList();
      // Возвращаем только уникальные URL
      return urls.toSet().toList();
    }
    
    final db = await database;
    final List<Map<String, dynamic>> imageMaps = await db.query('tea_images', 
        columns: ['url'], 
        where: 'url LIKE ?', 
        whereArgs: ['http%']);
    final urls = imageMaps.map((map) => map['url'] as String).toList();
    // Возвращаем только уникальные URL
    return urls.toSet().toList();
  }

  // Метод для получения отфильтрованных чаёв с пагинацией с заполненными названиями из метаданных
  Future<List<TeaModel>> getFilteredTeasWithNames({
    int page = 1, 
    int perPage = 10,
    String? searchQuery,
    List<int> countryIds = const [],
    List<int> typeIds = const [],
    List<int> appearanceIds = const [],
    List<int> flavorIds = const [],
    required List<CountryResponse> countries,
    required List<TypeResponse> types,
    required List<AppearanceResponse> appearances,
    required List<FlavorResponse> flavors,
  }) async {
    final teas = await getAllTeas();
    
    // Применяем фильтрацию
    final filteredTeas = teas.where((tea) {
      // Поиск по тексту
      if (searchQuery != null && searchQuery.isNotEmpty) {
        bool matches = tea.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (tea.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (tea.brewingGuide?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (tea.temperature?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (tea.weight?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
        if (!matches) return false;
      }

      // Фильтрация по странам
      if (countryIds.isNotEmpty) {
        int? teaCountryId = tea.country != null ? int.tryParse(tea.country!) : null;
        if (teaCountryId != null && !countryIds.contains(teaCountryId)) {
          return false;
        }
      }

      // Фильтрация по типам
      if (typeIds.isNotEmpty) {
        int? teaTypeId = tea.type != null ? int.tryParse(tea.type!) : null;
        if (teaTypeId != null && !typeIds.contains(teaTypeId)) {
          return false;
        }
      }

      // Фильтрация по внешним видам
      if (appearanceIds.isNotEmpty) {
        int? teaAppearanceId = tea.appearance != null ? int.tryParse(tea.appearance!) : null;
        if (teaAppearanceId != null && !appearanceIds.contains(teaAppearanceId)) {
          return false;
        }
      }

      // Фильтрация по вкусам
      if (flavorIds.isNotEmpty) {
        final teaFlavorIds = tea.flavors.map((f) => int.tryParse(f)).where((id) => id != null).cast<int>().toList();
        if (!teaFlavorIds.any((flavorId) => flavorIds.contains(flavorId))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Применяем пагинацию
    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage;
    
    if (startIndex >= filteredTeas.length) return [];
    
    final pageTeas = filteredTeas.sublist(startIndex, endIndex > filteredTeas.length ? filteredTeas.length : endIndex);

    // Заполняем названиями из метаданных
    return pageTeas.map((tea) => TeaModel.fromLocalDB(
      id: tea.id,
      name: tea.name,
      countryId: tea.country,
      typeId: tea.type,
      appearanceId: tea.appearance,
      temperature: tea.temperature,
      brewingGuide: tea.brewingGuide,
      weight: tea.weight,
      description: tea.description,
      flavorIds: tea.flavors,
      images: tea.images,
      countries: countries,
      types: types,
      appearances: appearances,
      flavors: flavors,
    )).toList();
  }

  // Метод для получения общего количества отфильтрованных чаёв
  Future<int> getTotalTeasCountWithFilters({
    String? searchQuery,
    List<int> countryIds = const [],
    List<int> typeIds = const [],
    List<int> appearanceIds = const [],
    List<int> flavorIds = const [],
  }) async {
    final teas = await getAllTeas();
    
    // Применяем фильтрацию
    final filteredTeas = teas.where((tea) {
      // Поиск по тексту
      if (searchQuery != null && searchQuery.isNotEmpty) {
        bool matches = tea.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (tea.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (tea.brewingGuide?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (tea.temperature?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
            (tea.weight?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
        if (!matches) return false;
      }

      // Фильтрация по странам
      if (countryIds.isNotEmpty) {
        int? teaCountryId = tea.country != null ? int.tryParse(tea.country!) : null;
        if (teaCountryId != null && !countryIds.contains(teaCountryId)) {
          return false;
        }
      }

      // Фильтрация по типам
      if (typeIds.isNotEmpty) {
        int? teaTypeId = tea.type != null ? int.tryParse(tea.type!) : null;
        if (teaTypeId != null && !typeIds.contains(teaTypeId)) {
          return false;
        }
      }

      // Фильтрация по внешним видам
      if (appearanceIds.isNotEmpty) {
        int? teaAppearanceId = tea.appearance != null ? int.tryParse(tea.appearance!) : null;
        if (teaAppearanceId != null && !appearanceIds.contains(teaAppearanceId)) {
          return false;
        }
      }

      // Фильтрация по вкусам
      if (flavorIds.isNotEmpty) {
        final teaFlavorIds = tea.flavors.map((f) => int.tryParse(f)).where((id) => id != null).cast<int>().toList();
        if (!teaFlavorIds.any((flavorId) => flavorIds.contains(flavorId))) {
          return false;
        }
      }

      return true;
    }).toList();

    return filteredTeas.length;
  }

  Future<TeaModel?> getTea(int id) async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      final teaMap = storage['teas'].firstWhere((map) => map['id'] == id, orElse: () => null);
      if (teaMap == null) return null;

      // Получаем вкусы для этого чая
      final flavorMaps = storage['tea_flavors'].where((map) => map['teaId'] == teaMap['id']).toList();
      final List<String> flavors = flavorMaps.map((map) => map['flavorId'].toString()).toList();

      // Получаем изображения для этого чая
      final imageMaps = storage['tea_images'].where((map) => map['teaId'] == teaMap['id']).toList();
      final List<String> images = imageMaps.map((map) => map['url'] as String).toList();

      return TeaModel(
        id: teaMap['id'],
        name: teaMap['name'],
        country: teaMap['countryId']?.toString(),
        type: teaMap['typeId']?.toString(),
        appearance: teaMap['appearanceId']?.toString(),
        temperature: teaMap['temperature'],
        brewingGuide: teaMap['brewingGuide'],
        weight: teaMap['weight'],
        description: teaMap['description'],
        flavors: flavors,
        images: images,
      );
    } else {
      // Мобильная/десктопная реализация
      final db = await database;

      final List<Map<String, dynamic>> teaMaps = await db.query('teas', where: 'id = ?', whereArgs: [id]);

      if (teaMaps.isEmpty) return null;

      final teaMap = teaMaps.first;

      // Получаем вкусы для этого чая
      final List<Map<String, dynamic>> flavorMaps = await db.query(
        'tea_flavors',
        where: 'teaId = ?',
        whereArgs: [teaMap['id']],
      );

      final List<String> flavors = flavorMaps.map((map) => map['flavorId'].toString()).toList();

      // Получаем изображения для этого чая
      final List<Map<String, dynamic>> imageMaps = await db.query(
        'tea_images',
        where: 'teaId = ?',
        whereArgs: [teaMap['id']],
        orderBy: 'id ASC',
      );

      final List<String> images = imageMaps.map((map) => map['url'] as String).toList();

      return TeaModel(
        id: teaMap['id'],
        name: teaMap['name'],
        country: teaMap['countryId']?.toString(),
        type: teaMap['typeId']?.toString(),
        appearance: teaMap['appearanceId']?.toString(),
        temperature: teaMap['temperature'],
        brewingGuide: teaMap['brewingGuide'],
        weight: teaMap['weight'],
        description: teaMap['description'],
        flavors: flavors,
        images: images,
      );
    }
  }

  // Метод для получения чая с заполненными названиями из метаданных
  Future<TeaModel?> getTeaWithNames({
    required int id,
    required List<CountryResponse> countries,
    required List<TypeResponse> types,
    required List<AppearanceResponse> appearances,
    required List<FlavorResponse> flavors,
  }) async {
    final tea = await getTea(id);
    if (tea == null) return null;

    return TeaModel.fromLocalDB(
      id: tea.id,
      name: tea.name,
      countryId: tea.country,
      typeId: tea.type,
      appearanceId: tea.appearance,
      temperature: tea.temperature,
      brewingGuide: tea.brewingGuide,
      weight: tea.weight,
      description: tea.description,
      flavorIds: tea.flavors,
      images: tea.images,
      countries: countries,
      types: types,
      appearances: appearances,
      flavors: flavors,
    );
  }

  // Методы для работы с метаданными

  // Сохранение стран
  Future<void> insertCountries(List<CountryResponse> countries) async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      storage['countries'].clear();
      for (final country in countries) {
        storage['countries'].add({
          'id': country.id,
          'name': country.name,
          'createdAt': country.createdAt,
          'updatedAt': country.updatedAt,
        });
      }
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      await db.transaction((txn) async {
        // Очищаем таблицу перед вставкой новых данных
        await txn.delete('countries');
        
        for (final country in countries) {
          await txn.insert(
            'countries',
            {
              'id': country.id,
              'name': country.name,
              'createdAt': country.createdAt,
              'updatedAt': country.updatedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
  }

  // Получение всех стран
  Future<List<CountryResponse>> getCountries() async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      return storage['countries'].map((map) => CountryResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      final List<Map<String, dynamic>> countryMaps = await db.query('countries', orderBy: 'name ASC');
      return countryMaps.map((map) => CountryResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    }
  }

  // Сохранение типов
  Future<void> insertTypes(List<TypeResponse> types) async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      storage['types'].clear();
      for (final type in types) {
        storage['types'].add({
          'id': type.id,
          'name': type.name,
          'createdAt': type.createdAt,
          'updatedAt': type.updatedAt,
        });
      }
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      await db.transaction((txn) async {
        // Очищаем таблицу перед вставкой новых данных
        await txn.delete('types');
        
        for (final type in types) {
          await txn.insert(
            'types',
            {
              'id': type.id,
              'name': type.name,
              'createdAt': type.createdAt,
              'updatedAt': type.updatedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
  }

  // Получение всех типов
  Future<List<TypeResponse>> getTypes() async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      return storage['types'].map((map) => TypeResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      final List<Map<String, dynamic>> typeMaps = await db.query('types', orderBy: 'name ASC');
      return typeMaps.map((map) => TypeResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    }
  }

  // Сохранение внешних видов
  Future<void> insertAppearances(List<AppearanceResponse> appearances) async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      storage['appearances'].clear();
      for (final appearance in appearances) {
        storage['appearances'].add({
          'id': appearance.id,
          'name': appearance.name,
          'createdAt': appearance.createdAt,
          'updatedAt': appearance.updatedAt,
        });
      }
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      await db.transaction((txn) async {
        // Очищаем таблицу перед вставкой новых данных
        await txn.delete('appearances');
        
        for (final appearance in appearances) {
          await txn.insert(
            'appearances',
            {
              'id': appearance.id,
              'name': appearance.name,
              'createdAt': appearance.createdAt,
              'updatedAt': appearance.updatedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
  }

  // Получение всех внешних видов
  Future<List<AppearanceResponse>> getAppearances() async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      return storage['appearances'].map((map) => AppearanceResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      final List<Map<String, dynamic>> appearanceMaps = await db.query('appearances', orderBy: 'name ASC');
      return appearanceMaps.map((map) => AppearanceResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    }
  }

  // Сохранение вкусов
  Future<void> insertFlavors(List<FlavorResponse> flavors) async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      storage['flavors'].clear();
      for (final flavor in flavors) {
        storage['flavors'].add({
          'id': flavor.id,
          'name': flavor.name,
          'createdAt': flavor.createdAt,
          'updatedAt': flavor.updatedAt,
        });
      }
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      await db.transaction((txn) async {
        // Очищаем таблицу перед вставкой новых данных
        await txn.delete('flavors');
        
        for (final flavor in flavors) {
          await txn.insert(
            'flavors',
            {
              'id': flavor.id,
              'name': flavor.name,
              'createdAt': flavor.createdAt,
              'updatedAt': flavor.updatedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
  }

  // Получение всех вкусов
  Future<List<FlavorResponse>> getFlavors() async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      return storage['flavors'].map((map) => FlavorResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      final List<Map<String, dynamic>> flavorMaps = await db.query('flavors', orderBy: 'name ASC');
      return flavorMaps.map((map) => FlavorResponse(
        id: map['id'] as int,
        name: map['name'] as String,
        createdAt: map['createdAt'] as String,
        updatedAt: map['updatedAt'] as String,
      )).toList();
    }
  }

  // Метод для отладки - получения количества записей в базе
  Future<Map<String, int>> getDatabaseStats() async {
    if (kIsWeb) {
      // Веб-реализация
      final storage = _getWebStorage();
      return {
        'teas': storage['teas'].length,
        'tea_flavors': storage['tea_flavors'].length,
        'images': storage['tea_images'].length,
        'countries': storage['countries'].length,
        'types': storage['types'].length,
        'appearances': storage['appearances'].length,
        'flavors': storage['flavors'].length,
      };
    } else {
      // Мобильная/десктопная реализация
      final db = await database;
      final teasCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM teas'));
      final flavorsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tea_flavors'));
      final imagesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tea_images'));

      // Добавим подсчет метаданных
      final countriesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM countries'));
      final typesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM types'));
      final appearancesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM appearances'));
      final flavorsDbCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM flavors'));

      return {
        'teas': teasCount ?? 0, 
        'tea_flavors': flavorsCount ?? 0, 
        'images': imagesCount ?? 0,
        'countries': countriesCount ?? 0,
        'types': typesCount ?? 0,
        'appearances': appearancesCount ?? 0,
        'flavors': flavorsDbCount ?? 0,
      };
    }
  }
  
  // Методы для получения фасетов с подсчетом
  
  // Получение стран с подсчетом чаёв
  Future<List<Map<String, dynamic>>> getAllCountriesWithCount() async {
    final countries = await getCountries();
    final teas = await getAllTeas();
    
    return countries.map((country) {
      final count = teas.where((tea) {
        final teaCountryId = tea.country != null ? int.tryParse(tea.country!) : null;
        return teaCountryId == country.id;
      }).length;
      
      return {
        'id': country.id,
        'name': country.name,
        'count': count,
      };
    }).toList();
  }
  
  // Получение типов с подсчетом чаёв
  Future<List<Map<String, dynamic>>> getAllTypesWithCount() async {
    final types = await getTypes();
    final teas = await getAllTeas();
    
    return types.map((type) {
      final count = teas.where((tea) {
        final teaTypeId = tea.type != null ? int.tryParse(tea.type!) : null;
        return teaTypeId == type.id;
      }).length;
      
      return {
        'id': type.id,
        'name': type.name,
        'count': count,
      };
    }).toList();
  }
  
  // Получение внешних видов с подсчетом чаёв
  Future<List<Map<String, dynamic>>> getAllAppearancesWithCount() async {
    final appearances = await getAppearances();
    final teas = await getAllTeas();
    
    return appearances.map((appearance) {
      final count = teas.where((tea) {
        final teaAppearanceId = tea.appearance != null ? int.tryParse(tea.appearance!) : null;
        return teaAppearanceId == appearance.id;
      }).length;
      
      return {
        'id': appearance.id,
        'name': appearance.name,
        'count': count,
      };
    }).toList();
  }
  
  // Получение вкусов с подсчетом чаёв
  Future<List<Map<String, dynamic>>> getAllFlavorsWithCount() async {
    final flavors = await getFlavors();
    final teas = await getAllTeas();
    
    return flavors.map((flavor) {
      final count = teas.where((tea) {
        return tea.flavors.any((flavorId) => int.tryParse(flavorId) == flavor.id);
      }).length;
      
      return {
        'id': flavor.id,
        'name': flavor.name,
        'count': count,
      };
    }).toList();
  }
  
  // Метод для сохранения сообщения чата
  Future<void> saveChatMessage({
    required String sessionId,
    required String role,
    required String content,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final timestampStr = now.toIso8601String();
    
    if (kIsWeb) {
      // Для веба используем in-memory хранилище
      final storage = _getWebStorage();
      storage['chat_history'] ??= <Map<String, dynamic>>[];
      
      storage['chat_history'].add({
        'id': storage['chat_history'].length + 1,
        'session_id': sessionId,
        'role': role,
        'content': content,
        'timestamp': timestampStr,
      });
    } else {
      // Для мобильных/десктопных платформ используем SQLite
      final db = await database;
      await db.insert('chat_history', {
        'session_id': sessionId,
        'role': role,
        'content': content,
        'timestamp': timestampStr,
      });
    }
  }

  // Метод для получения истории чата для сессии
  Future<List<Map<String, String>>> getChatHistory(String sessionId) async {
    if (kIsWeb) {
      // Для веба используем in-memory хранилище
      final storage = _getWebStorage();
      final chatHistory = storage['chat_history'] ?? <Map<String, dynamic>>[];
      
      return chatHistory
          .where((item) => item['session_id'] == sessionId)
          .map((item) => {
            'role': item['role'] as String,
            'content': item['content'] as String,
          })
          .toList()
          .cast<Map<String, String>>();
    } else {
      // Для мобильных/десктопных платформ используем SQLite
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'chat_history',
        where: 'session_id = ?',
        orderBy: 'timestamp ASC',
        whereArgs: [sessionId],
      );
      
      return maps.map((map) => {
        'role': map['role'] as String,
        'content': map['content'] as String,
      }).toList();
    }
  }

  // Метод для получения списка сессий чата
  Future<List<String>> getChatSessions() async {
    if (kIsWeb) {
      // Для веба используем in-memory хранилище
      final storage = _getWebStorage();
      final chatHistory = storage['chat_history'] ?? <Map<String, dynamic>>[];
      
      return chatHistory
          .map((item) => item['session_id'] as String)
          .toSet()
          .toList();
    } else {
      // Для мобильных/десктопных платформ используем SQLite
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'chat_history',
        columns: ['DISTINCT session_id'],
      );
      
      return maps.map((map) => map['session_id'] as String).toList();
    }
  }

  // Метод для очистки истории чата для сессии
  Future<void> clearChatHistory(String sessionId) async {
    if (kIsWeb) {
      // Для веба используем in-memory хранилище
      final storage = _getWebStorage();
      storage['chat_history']?.removeWhere((item) => item['session_id'] == sessionId);
    } else {
      // Для мобильных/десктопных платформ используем SQLite
      final db = await database;
      await db.delete(
        'chat_history',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
    }
  }

  // Метод для очистки всех историй чата
  Future<void> clearAllChatHistory() async {
    if (kIsWeb) {
      // Для веба используем in-memory хранилище
      final storage = _getWebStorage();
      storage['chat_history']?.clear();
    } else {
      // Для мобильных/десктопных платформ используем SQLite
      final db = await database;
      await db.delete('chat_history');
    }
  }

  // Методы для получения фасетов с подсчетом, учитывающих фильтры
  Future<List<Map<String, dynamic>>> getFilteredCountriesWithCount({
    String? searchQuery,
    List<int> countryIds = const [],
    List<int> typeIds = const [],
    List<int> appearanceIds = const [],
    List<int> flavorIds = const [],
  }) async {
    final allCountries = await getCountries();
    final allTeas = await getAllTeas();
    
    return allCountries.map((country) {
      // Фильтруем чаи для подсчета, учитывая фильтры ТИПОВ, ВНЕШНИХ ВИДОВ и ВКУСОВ, но НЕ учитывая фильтр СТРАН
      final filteredTeas = allTeas.where((tea) {
        // Поиск по тексту
        if (searchQuery != null && searchQuery.isNotEmpty) {
          bool matches = tea.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (tea.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.brewingGuide?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.temperature?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.weight?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
          if (!matches) return false;
        }

        // Фильтрация по типам
        if (typeIds.isNotEmpty) {
          int? teaTypeId = tea.type != null ? int.tryParse(tea.type!) : null;
          if (teaTypeId != null && !typeIds.contains(teaTypeId)) {
            return false;
          }
        }

        // Фильтрация по внешним видам
        if (appearanceIds.isNotEmpty) {
          int? teaAppearanceId = tea.appearance != null ? int.tryParse(tea.appearance!) : null;
          if (teaAppearanceId != null && !appearanceIds.contains(teaAppearanceId)) {
            return false;
          }
        }

        // Фильтрация по вкусам
        if (flavorIds.isNotEmpty) {
          final teaFlavorIds = tea.flavors.map((f) => int.tryParse(f)).where((id) => id != null).cast<int>().toList();
          if (!teaFlavorIds.any((flavorId) => flavorIds.contains(flavorId))) {
            return false;
          }
        }

        // Проверяем, что это страна, для которой мы считаем
        int? teaCountryId = tea.country != null ? int.tryParse(tea.country!) : null;
        return teaCountryId == country.id;
      }).toList();
      
      return {
        'id': country.id,
        'name': country.name,
        'count': filteredTeas.length,
      };
    }).where((result) => result['count'] as int > 0).toList(); // Фильтруем, чтобы возвращать только элементы с count > 0
  }
  
  Future<List<Map<String, dynamic>>> getFilteredTypesWithCount({
    String? searchQuery,
    List<int> countryIds = const [],
    List<int> typeIds = const [],
    List<int> appearanceIds = const [],
    List<int> flavorIds = const [],
  }) async {
    final allTypes = await getTypes();
    final allTeas = await getAllTeas();
    
    return allTypes.map((type) {
      // Фильтруем чаи для подсчета, учитывая фильтры СТРАН, ВНЕШНИХ ВИДОВ и ВКУСОВ, но НЕ учитывая фильтр ТИПОВ
      final filteredTeas = allTeas.where((tea) {
        // Поиск по тексту
        if (searchQuery != null && searchQuery.isNotEmpty) {
          bool matches = tea.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (tea.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.brewingGuide?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.temperature?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.weight?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
          if (!matches) return false;
        }

        // Фильтрация по странам
        if (countryIds.isNotEmpty) {
          int? teaCountryId = tea.country != null ? int.tryParse(tea.country!) : null;
          if (teaCountryId != null && !countryIds.contains(teaCountryId)) {
            return false;
          }
        }

        // Фильтрация по внешним видам
        if (appearanceIds.isNotEmpty) {
          int? teaAppearanceId = tea.appearance != null ? int.tryParse(tea.appearance!) : null;
          if (teaAppearanceId != null && !appearanceIds.contains(teaAppearanceId)) {
            return false;
          }
        }

        // Фильтрация по вкусам
        if (flavorIds.isNotEmpty) {
          final teaFlavorIds = tea.flavors.map((f) => int.tryParse(f)).where((id) => id != null).cast<int>().toList();
          if (!teaFlavorIds.any((flavorId) => flavorIds.contains(flavorId))) {
            return false;
          }
        }

        // Проверяем, что это тип, для которого мы считаем
        int? teaTypeId = tea.type != null ? int.tryParse(tea.type!) : null;
        return teaTypeId == type.id;
      }).toList();
      
      return {
        'id': type.id,
        'name': type.name,
        'count': filteredTeas.length,
      };
    }).where((result) => result['count'] as int > 0).toList(); // Фильтруем, чтобы возвращать только элементы с count > 0
  }
  
  Future<List<Map<String, dynamic>>> getFilteredAppearancesWithCount({
    String? searchQuery,
    List<int> countryIds = const [],
    List<int> typeIds = const [],
    List<int> appearanceIds = const [],
    List<int> flavorIds = const [],
  }) async {
    final allAppearances = await getAppearances();
    final allTeas = await getAllTeas();
    
    return allAppearances.map((appearance) {
      // Фильтруем чаи для подсчета, учитывая фильтры СТРАН, ТИПОВ и ВКУСОВ, но НЕ учитывая фильтр ВНЕШНИХ ВИДОВ
      final filteredTeas = allTeas.where((tea) {
        // Поиск по тексту
        if (searchQuery != null && searchQuery.isNotEmpty) {
          bool matches = tea.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (tea.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.brewingGuide?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.temperature?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.weight?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
          if (!matches) return false;
        }

        // Фильтрация по странам
        if (countryIds.isNotEmpty) {
          int? teaCountryId = tea.country != null ? int.tryParse(tea.country!) : null;
          if (teaCountryId != null && !countryIds.contains(teaCountryId)) {
            return false;
          }
        }

        // Фильтрация по типам
        if (typeIds.isNotEmpty) {
          int? teaTypeId = tea.type != null ? int.tryParse(tea.type!) : null;
          if (teaTypeId != null && !typeIds.contains(teaTypeId)) {
            return false;
          }
        }

        // Фильтрация по вкусам
        if (flavorIds.isNotEmpty) {
          final teaFlavorIds = tea.flavors.map((f) => int.tryParse(f)).where((id) => id != null).cast<int>().toList();
          if (!teaFlavorIds.any((flavorId) => flavorIds.contains(flavorId))) {
            return false;
          }
        }

        // Проверяем, что это внешний вид, для которого мы считаем
        int? teaAppearanceId = tea.appearance != null ? int.tryParse(tea.appearance!) : null;
        return teaAppearanceId == appearance.id;
      }).toList();
      
      return {
        'id': appearance.id,
        'name': appearance.name,
        'count': filteredTeas.length,
      };
    }).where((result) => result['count'] as int > 0).toList(); // Фильтруем, чтобы возвращать только элементы с count > 0
  }
  
  Future<List<Map<String, dynamic>>> getFilteredFlavorsWithCount({
    String? searchQuery,
    List<int> countryIds = const [],
    List<int> typeIds = const [],
    List<int> appearanceIds = const [],
    List<int> flavorIds = const [],
  }) async {
    final allFlavors = await getFlavors();
    final allTeas = await getAllTeas();
    
    return allFlavors.map((flavor) {
      // Фильтруем чаи для подсчета, учитывая фильтры СТРАН, ТИПОВ и ВНЕШНИХ ВИДОВ, но НЕ учитывая фильтр ВКУСОВ
      final filteredTeas = allTeas.where((tea) {
        // Поиск по тексту
        if (searchQuery != null && searchQuery.isNotEmpty) {
          bool matches = tea.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (tea.description?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.brewingGuide?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.temperature?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              (tea.weight?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
          if (!matches) return false;
        }

        // Фильтрация по странам
        if (countryIds.isNotEmpty) {
          int? teaCountryId = tea.country != null ? int.tryParse(tea.country!) : null;
          if (teaCountryId != null && !countryIds.contains(teaCountryId)) {
            return false;
          }
        }

        // Фильтрация по типам
        if (typeIds.isNotEmpty) {
          int? teaTypeId = tea.type != null ? int.tryParse(tea.type!) : null;
          if (teaTypeId != null && !typeIds.contains(teaTypeId)) {
            return false;
          }
        }

        // Фильтрация по внешним видам
        if (appearanceIds.isNotEmpty) {
          int? teaAppearanceId = tea.appearance != null ? int.tryParse(tea.appearance!) : null;
          if (teaAppearanceId != null && !appearanceIds.contains(teaAppearanceId)) {
            return false;
          }
        }

        // Проверяем, что это вкус, для которого мы считаем
        return tea.flavors.any((flavorId) => int.tryParse(flavorId) == flavor.id);
      }).toList();
      
      return {
        'id': flavor.id,
        'name': flavor.name,
        'count': filteredTeas.length,
      };
    }).where((result) => result['count'] as int > 0).toList(); // Фильтруем, чтобы возвращать только элементы с count > 0
  }
}