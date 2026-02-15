# Архитектурные изменения для функциональности фильтрации

## Обзор

В этом документе описаны архитектурные изменения, внесённые в приложение Tea App для реализации функциональности фильтрации чаёв с поддержкой оффлайн режима.

## Структура проекта

```
lib/
├── api/
│   ├── tea_api.dart              # Добавлен метод getFilteredTeas
├── controllers/
│   └── tea_controller.dart       # Добавлены методы фильтрации
├── models/
│   └── tea.dart                  # Обновлены методы преобразования
├── screens/
│   └── home/
│       ├── home_screen.dart      # Добавлена логика управления фильтрами
│       └── widgets/
│           └── tea_drawer.dart   # Полностью переработан компонент фильтров
├── services/
│   └── local_database_service.dart # Добавлены методы фильтрации в БД
└── providers/
    └── metadata_provider.dart    # Обновлены провайдеры метаданных
```

## Ключевые изменения

### 1. LocalDatabaseService

Добавлены методы для фильтрации данных в локальной базе:

```dart
// Получение отфильтрованных чаёв с пагинацией и заполненными названиями
Future<List<TeaModel>> getFilteredTeasWithNames({
  int page,
  int perPage,
  String? searchQuery,
  List<int> countryIds,
  List<int> typeIds,
  List<int> appearanceIds,
  List<int> flavorIds,
  required List<CountryResponse> countries,
  required List<TypeResponse> types,
  required List<AppearanceResponse> appearances,
  required List<FlavorResponse> flavors,
})

// Подсчёт общего количества отфильтрованных записей
Future<int> getTotalTeasCountWithFilters({
  String? searchQuery,
  List<int> countryIds,
  List<int> typeIds,
  List<int> appearanceIds,
  List<int> flavorIds,
})
```

### 2. TeaModel

Обновлены методы для корректного преобразования данных:

```dart
// Метод для сохранения в локальную БД с ID вместо названий
static TeaModel fromApiResponseForDatabase({
  required TeaResponse response,
})

// Метод для чтения из локальной БД с преобразованием ID в названия
factory TeaModel.fromLocalDB({
  required dynamic id,
  required String name,
  required String? countryId,
  required String? typeId,
  required String? appearanceId,
  required String? temperature,
  required String? brewingGuide,
  required String? weight,
  required String? description,
  required List<String> flavorIds,
  required List<String> images,
  required List<CountryResponse> countries,
  required List<TypeResponse> types,
  required List<AppearanceResponse> appearances,
  required List<FlavorResponse> flavors,
})
```

### 3. TeaController

Добавлены методы для управления фильтрацией:

```dart
// Получение отфильтрованных чаёв с поддержкой онлайн/оффлайн режимов
Future<PaginationResult<TeaModel>> fetchFilteredTeas(Map<String, dynamic> filterParams)

// Свойства для доступа к метаданным
Future<List<CountryResponse>> get countries
Future<List<TypeResponse>> get types
Future<List<AppearanceResponse>> get appearances
Future<List<FlavorResponse>> get flavors
```

### 4. TeaApi

Добавлен метод для серверных фильтров:

```dart
// Получение отфильтрованных чаёв с сервера
Future<PaginatedTeaResponse> getFilteredTeas(Map<String, dynamic> filterParams)
```

### 5. HomeScreen

Добавлена логика управления фильтрами:

```dart
// Параметры фильтрации
Map<String, dynamic> _filterParams = {};
bool _isFiltered = false;

// Методы для применения и сброса фильтров
void _applyFilters(Map<String, dynamic> filterParams)
void _resetFilters()
```

### 6. TeaFilterDrawer

Полностью переработан компонент фильтров:

```dart
// Состояния для хранения выбранных значений
List<int> _selectedCountries = [];
List<int> _selectedTypes = [];
List<int> _selectedAppearances = [];
List<int> _selectedFlavors = [];

// Методы для управления фильтрами
void _applyFilters()
void _resetFilters()
```

## Поток данных

### Онлайн режим
1. Пользователь выбирает фильтры в TeaFilterDrawer
2. Фильтры передаются в HomeScreen
3. HomeScreen вызывает fetchFilteredTeas в TeaController
4. TeaController делает запрос к TeaApi
5. Результаты отображаются в списке чаёв

### Оффлайн режим
1. Пользователь выбирает фильтры в TeaFilterDrawer
2. Фильтры передаются в HomeScreen
3. HomeScreen вызывает fetchFilteredTeas в TeaController
4. TeaController получает данные из LocalDatabaseService
5. Результаты отображаются в списке чаёв

## SQL-запросы

Для фильтрации используются сложные SQL-запросы с JOIN:

```sql
SELECT t.* FROM teas t
LEFT JOIN tea_flavors tf ON t.id = tf.teaId
WHERE 1=1
AND (t.name LIKE ? OR t.description LIKE ? OR ...)
AND t.countryId IN (?, ?, ...)
AND t.typeId IN (?, ?, ...)
AND tf.flavorId IN (?, ?, ?)
GROUP BY t.id
ORDER BY t.id DESC
LIMIT ? OFFSET ?
```

## Пагинация

Фильтрация поддерживает пагинацию:
- Загрузка данных порциями
- Поддержка "бесконечного скролла"
- Подсчёт общего количества отфильтрованных записей

## Обработка ошибок

- Обработка ошибок при отсутствии метаданных
- Резервное использование локальных данных при ошибках API
- Проверка подключения перед онлайн-запросами
- Таймауты для предотвращения повторных ошибок