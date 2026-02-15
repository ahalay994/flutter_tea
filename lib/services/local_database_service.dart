import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/api/responses/country_response.dart';
import 'package:tea/api/responses/type_response.dart';
import 'package:tea/api/responses/appearance_response.dart';
import 'package:tea/api/responses/flavor_response.dart';
import 'package:tea/utils/app_logger.dart';

class LocalDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tea_database.db');
    return await openDatabase(
      path,
      version: 2, // Увеличиваем версию базы данных
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teas (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,ещё
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
  }

  Future<void> insertTea(TeaModel tea) async {
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

  Future<void> insertTeas(List<TeaModel> teas) async {
    final db = await database;

    await db.transaction((txn) async {
      for (final tea in teas) {
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
      }
    });
  }

  Future<List<TeaModel>> getAllTeas() async {
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

  // Метод для получения чаёв с пагинацией
  Future<List<TeaModel>> getTeasPaginated({int page = 1, int perPage = 10}) async {
    final db = await database;

    final offset = (page - 1) * perPage;

    final List<Map<String, dynamic>> teaMaps = await db.query(
      'teas',
      orderBy: 'id DESC', // Сортировка по ID по убыванию
      limit: perPage,
      offset: offset,
    );

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

  // Метод для получения общего количества чаёв
  Future<int> getTotalTeasCount() async {
    final db = await database;
    final result = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM teas'));
    return result ?? 0;
  }

  Future<void> deleteTea(int id) async {
    final db = await database;
    await db.delete('teas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tea_images');
      await txn.delete('tea_flavors');
      await txn.delete('teas');
    });
  }

  // Метод для получения папки кеша изображений
  Future<String> get _imageCachePath async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/image_cache';
    await Directory(path).create(recursive: true);
    return path;
  }

  // Метод для сохранения изображения в локальный кеш
  Future<String> cacheImage(String imageUrl) async {
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
    final db = await database;
    final List<Map<String, dynamic>> imageMaps = await db.query('tea_images');
    return imageMaps.map((map) => map['url'] as String).where((url) => url.startsWith('http')).toList();
  }



  // Метод для получения чаёв с пагинацией с заполненными названиями из метаданных
  Future<List<TeaModel>> getTeasPaginatedWithNames({
    int page = 1, 
    int perPage = 10,
    required List<CountryResponse> countries,
    required List<TypeResponse> types,
    required List<AppearanceResponse> appearances,
    required List<FlavorResponse> flavors,
  }) async {
    final db = await database;

    final offset = (page - 1) * perPage;

    final List<Map<String, dynamic>> teaMaps = await db.query(
      'teas',
      orderBy: 'id DESC', // Сортировка по ID по убыванию
      limit: perPage,
      offset: offset,
    );

    final List<TeaModel> teas = [];

    for (final teaMap in teaMaps) {
      // Получаем вкусы для этого чая
      final List<Map<String, dynamic>> flavorMaps = await db.query(
        'tea_flavors',
        where: 'teaId = ?',
        whereArgs: [teaMap['id']],
      );

      final List<String> flavorIds = flavorMaps.map((map) => map['flavorId'].toString()).toList();

      // Получаем изображения для этого чая
      final List<Map<String, dynamic>> imageMaps = await db.query(
        'tea_images',
        where: 'teaId = ?',
        whereArgs: [teaMap['id']],
        orderBy: 'id ASC',
      );

      final List<String> images = imageMaps.map((map) => map['url'] as String).toList();

      final teaModel = TeaModel.fromLocalDB(
        id: teaMap['id'],
        name: teaMap['name'],
        countryId: teaMap['countryId']?.toString(),
        typeId: teaMap['typeId']?.toString(),
        appearanceId: teaMap['appearanceId']?.toString(),
        temperature: teaMap['temperature'],
        brewingGuide: teaMap['brewingGuide'],
        weight: teaMap['weight'],
        description: teaMap['description'],
        flavorIds: flavorIds,
        images: images,
        countries: countries,
        types: types,
        appearances: appearances,
        flavors: flavors,
      );
      
      // Временное логирование для отладки
      print('DEBUG TeaModel: id=${teaModel.id}, name=${teaModel.name}');
      print('  country: ${teaModel.country} (was ID: ${teaMap['countryId']})');
      print('  type: ${teaModel.type} (was ID: ${teaMap['typeId']})');
      print('  appearance: ${teaModel.appearance} (was ID: ${teaMap['appearanceId']})');
      print('  flavors: ${teaModel.flavors} (was IDs: $flavorIds)');
      
      teas.add(teaModel);
    }

    return teas;
  }

  Future<TeaModel?> getTea(int id) async {
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

  // Метод для получения чая с заполненными названиями из метаданных
  Future<TeaModel?> getTeaWithNames({
    required int id,
    required List<CountryResponse> countries,
    required List<TypeResponse> types,
    required List<AppearanceResponse> appearances,
    required List<FlavorResponse> flavors,
  }) async {
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

    final List<String> flavorIds = flavorMaps.map((map) => map['flavorId'].toString()).toList();

    // Получаем изображения для этого чая
    final List<Map<String, dynamic>> imageMaps = await db.query(
      'tea_images',
      where: 'teaId = ?',
      whereArgs: [teaMap['id']],
      orderBy: 'id ASC',
    );

    final List<String> images = imageMaps.map((map) => map['url'] as String).toList();

    return TeaModel.fromLocalDB(
      id: teaMap['id'],
      name: teaMap['name'],
      countryId: teaMap['countryId']?.toString(),
      typeId: teaMap['typeId']?.toString(),
      appearanceId: teaMap['appearanceId']?.toString(),
      temperature: teaMap['temperature'],
      brewingGuide: teaMap['brewingGuide'],
      weight: teaMap['weight'],
      description: teaMap['description'],
      flavorIds: flavorIds,
      images: images,
      countries: countries,
      types: types,
      appearances: appearances,
      flavors: flavors,
    );
  }

  // Методы для работы с метаданными

  // Сохранение стран
  Future<void> insertCountries(List<CountryResponse> countries) async {
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

  // Получение всех стран
  Future<List<CountryResponse>> getCountries() async {
    final db = await database;
    final List<Map<String, dynamic>> countryMaps = await db.query('countries', orderBy: 'name ASC');
    return countryMaps.map((map) => CountryResponse(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    )).toList();
  }

  // Сохранение типов
  Future<void> insertTypes(List<TypeResponse> types) async {
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

  // Получение всех типов
  Future<List<TypeResponse>> getTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> typeMaps = await db.query('types', orderBy: 'name ASC');
    return typeMaps.map((map) => TypeResponse(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    )).toList();
  }

  // Сохранение внешних видов
  Future<void> insertAppearances(List<AppearanceResponse> appearances) async {
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

  // Получение всех внешних видов
  Future<List<AppearanceResponse>> getAppearances() async {
    final db = await database;
    final List<Map<String, dynamic>> appearanceMaps = await db.query('appearances', orderBy: 'name ASC');
    return appearanceMaps.map((map) => AppearanceResponse(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    )).toList();
  }

  // Сохранение вкусов
  Future<void> insertFlavors(List<FlavorResponse> flavors) async {
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

  // Получение всех вкусов
  Future<List<FlavorResponse>> getFlavors() async {
    final db = await database;
    final List<Map<String, dynamic>> flavorMaps = await db.query('flavors', orderBy: 'name ASC');
    return flavorMaps.map((map) => FlavorResponse(
      id: map['id'] as int,
      name: map['name'] as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    )).toList();
  }

  // Метод для отладки - получения количества записей в базе
  Future<Map<String, int>> getDatabaseStats() async {
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
