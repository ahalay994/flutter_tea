# Руководство по работе с фильтрами в Tea App

## Общая информация

Система фильтров в Tea App позволяет пользователям отбирать чаи по различным критериям. В приложении реализованы два типа фильтров:
- **Мультиселект фильтры** - классические фильтры с возможностью выбора множественных значений
- **Фасетные фильтры** - фильтры с отображением количества результатов для каждого значения

## Архитектура системы фильтров

### 1. Провайдеры (lib/controllers/tea_controller.dart)

#### A. filterParamsProvider
**Тип:** `StateNotifierProvider<FilterParamsNotifier, Map<String, dynamic>>`  
**Назначение:** Хранение параметров фильтрации  
**Описание:** Хранит текущие параметры фильтров в виде Map, где ключ - название фильтра, значение - выбранное значение или список значений

**Методы:**
- `update(Map<String, dynamic> newParams)` - обновление параметров фильтрации
- `clear()` - очистка всех параметров фильтрации

#### B. filterTypeProvider
**Тип:** `StateNotifierProvider<FilterTypeNotifier, FilterType>`  
**Назначение:** Хранение текущего типа фильтров  
**Описание:** Определяет, какой тип фильтров используется в данный момент

**Методы:**
- `update(FilterType newType)` - смена типа фильтров

### 2. Типы фильтров (lib/utils/filter_type.dart)

```dart
enum FilterType {
  multiSelect,  // Мультиселект фильтры
  facets       // Фасетные фильтры
}
```

## Мультиселект фильтры

### 1. Основной компонент (lib/screens/home/widgets/tea_drawer.dart)

**Класс:** `TeaFilterDrawer`  
**Назначение:** Боковое меню с фильтрами  
**Функции:**
- Поиск по тексту
- Фильтр по странам (множественный выбор)
- Фильтр по типам (множественный выбор)
- Фильтр по внешнему виду (множественный выбор)
- Фильтр по вкусам (множественный выбор)

### 2. Структура компонента

#### A. Поиск (строки 70-85)
- `TextField` с иконкой поиска
- Поиск по названию, описанию, руководству и другим полям
- Обновление в режиме реального времени

#### B. Фильтр по странам (строки 90-200)
- `ExpansionTile` с заголовком "Страны"
- Внутри - `FutureBuilder` для загрузки списка стран
- `TextField` для поиска внутри списка стран
- `ListView.builder` с `CheckboxListTile` для выбора

#### C. Фильтр по типам (строки 200-310)
- Аналогично фильтру по странам
- Загрузка типов из провайдера

#### D. Фильтр по внешнему виду (строки 310-420)
- Аналогично предыдущим
- Загрузка внешних видов из провайдера

#### E. Фильтр по вкусам (строки 420-530)
- Аналогично предыдущим
- Загрузка вкусов из провайдера

#### F. Кнопки управления (строки 530-590)
- "Применить фильтры" - сохранение параметров и закрытие drawer
- "Сбросить фильтры" - очистка всех параметров и закрытие drawer

### 3. Методы взаимодействия

#### A. _applyFilters() (строки 525-565)
```dart
void _applyFilters() {
  // Формируем параметры фильтрации
  final filterParams = <String, dynamic>{};
  
  if (_searchController.text.isNotEmpty) {
    filterParams['search'] = _searchController.text;
  }
  
  if (_selectedCountries.isNotEmpty) {
    filterParams['countries'] = _selectedCountries.join(',');
  }
  
  if (_selectedTypes.isNotEmpty) {
    filterParams['types'] = _selectedTypes.join(',');
  }
  
  if (_selectedAppearances.isNotEmpty) {
    filterParams['appearances'] = _selectedAppearances.join(',');
  }
  
  if (_selectedFlavors.isNotEmpty) {
    filterParams['flavors'] = _selectedFlavors.join(',');
  }
  
  // Обновляем провайдер параметров фильтрации
  ref.read(filterParamsProvider.notifier).update(filterParams);
  
  // Закрываем drawer
  Navigator.of(context).pop();
}
```

#### B. _resetFilters() (строки 567-585)
```dart
void _resetFilters() {
  // Очищаем все параметры фильтрации
  setState(() {
    _searchController.clear();
    _selectedCountries.clear();
    _selectedTypes.clear();
    _selectedAppearances.clear();
    _selectedFlavors.clear();
  });
  
  // Сбрасываем параметры фильтрации в провайдере
  ref.read(filterParamsProvider.notifier).clear();
  
  // Закрывает drawer
  Navigator.of(context).pop();
}
```

## Фасетные фильтры

### 1. Основной компонент (lib/screens/home/widgets/tea_facet_filter_drawer.dart)

**Класс:** `TeaFacetFilterDrawer`  
**Назначение:** Боковое меню с фасетными фильтрами  
**Функции:**
- Отображение количества результатов для каждого значения
- Сортировка по количеству результатов
- Множественный выбор значений

### 2. Структура компонента

#### A. Загрузка данных
- Используется `FutureBuilder` для получения фасетов
- Фасеты содержат ID, название и количество чаёв

#### B. Отображение фасетов
- Сортировка по количеству результатов (по убыванию)
- Отображение названия и количества
- Чекбоксы для выбора

### 3. Особенности реализации
- В настоящее время использует заглушку до реализации API фасетов
- При готовности API фасетов будет включена полная функциональность

## Применение фильтров в UI

### 1. HomeScreen (lib/screens/home/home_screen.dart)

#### A. Отслеживание изменений
```dart
// В ConsumerStatefulWidget
ref.listen(filterParamsProvider, (previous, next) {
  // Если параметры фильтрации изменились, сбрасываем пагинацию и загружаем новые данные
  if (previous != next) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentPage = 1;
          _allTeas = [];
          _hasMore = true;
        });
        _loadFirstPage();
      }
    });
  }
});
```

#### B. Загрузка данных
```dart
Future<void> _loadFirstPage() async {
  // Получаем параметры фильтров из провайдера
  final filterParams = ref.read(filterParamsProvider);
  
  List<TeaModel> teaData;
  if (filterParams.isNotEmpty) {
    // Используем фильтрованные данные
    final result = await teaController.fetchFilteredTeas(filterParams);
    teaData = result.data;
    _currentPage = result.currentPage;
    _hasMore = result.hasMore;
  } else {
    // Используем обычные данные
    final result = await teaController.fetchFullTeas(page: 1);
    teaData = result.data;
    _currentPage = result.currentPage;
    _hasMore = result.hasMore;
  }
}
```

## Работа с API

### 1. TeaApi (lib/api/tea_api.dart)

#### A. getFilteredTeas() (строки 154-202)
```dart
Future<PaginatedTeaResponse> getFilteredTeas(Map<String, dynamic> filterParams) async {
  // Формируем query параметры
  final queryParams = <String, String>{};
  
  if (filterParams['search'] != null) {
    queryParams['search'] = filterParams['search'].toString();
  }
  
  if (filterParams['countries'] != null) {
    queryParams['countries'] = filterParams['countries'].toString();
  }
  
  // ... другие параметры
  
  // Запрашиваем данные с фильтрами
  final response = await getRequest('/tea?$queryString');
  // Обрабатываем ответ
}
```

#### B. getFacets() (строки 205-237)
```dart
Future<FacetResponse> getFacets(Map<String, dynamic> filterParams) async {
  // Формируем query параметры
  final queryParams = <String, String>{};
  
  // ... обработка параметров
  
  // Запрашиваем фасеты
  final response = await getRequest('/tea/facets?$queryString');
  return FacetResponse.fromJson(response.data as Map<String, dynamic>);
}
```

## Работа с локальной базой данных

### 1. LocalDatabaseService (lib/services/local_database_service.dart)

#### A. getFilteredTeasWithNames() (строки 410-480)
```dart
Future<List<TeaModel>> getFilteredTeasWithNames({
  required int page,
  required int perPage,
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
  // Комплексный SQL запрос с JOIN для фильтрации
  // Возвращает чаи с заполненными названиями
}
```

#### B. getTotalTeasCountWithFilters() (строки 482-560)
```dart
Future<int> getTotalTeasCountWithFilters({
  String? searchQuery,
  List<int> countryIds = const [],
  List<int> typeIds = const [],
  List<int> appearanceIds = const [],
  List<int> flavorIds = const [],
}) async {
  // SQL запрос COUNT с теми же фильтрами
  // Возвращает общее количество чаёв по фильтрам
}
```

## Пагинация с фильтрами

### 1. HomeScreen
- `_currentPage` - текущая страница
- `_hasMore` - есть ли ещё данные
- `_isLoadingMore` - состояние загрузки
- `_allTeas` - список всех загруженных чаёв

### 2. _loadMore() метод
- Загружает следующую страницу с учетом фильтров
- Добавляет данные к существующему списку
- Обновляет состояние пагинации

## Сброс фильтров

### 1. В TeaFilterDrawer
- Очищаются все выбранные значения
- Очищается текст поиска
- Обновляется провайдер фильтров

### 2. В HomeScreen
- Сбрасывается пагинация (currentPage = 1)
- Очищается список чаёв
- Загружается первая страница без фильтров

## Отладка фильтров

### 1. Система логирования
Все основные операции с фильтрами логируются:

#### A. В TeaFilterDrawer
- При выборе элементов
- При нажатии "Применить фильтры"
- При обновлении провайдера
- При закрытии drawer

#### B. В HomeScreen
- При загрузке данных
- При применении фильтров
- При ошибках загрузки

#### C. В TeaController
- При обновлении провайдера фильтров
- При загрузке отфильтрованных данных

### 2. Примеры логов
```
DEBUG: Добавлена страна: Китай (ID: 1)
DEBUG: Выбраны фильтры: {countries: 1, types: 2,3}
DEBUG: Применяем фильтры: {countries: 1, types: 2,3}
DEBUG: Загружено 5 фильтрованных чаёв
```

## Переключение между типами фильтров

### 1. В коде
```dart
// Переключение на фасетные фильтры
ref.read(filterTypeProvider.notifier).update(FilterType.facets);

// Переключение на мультиселект фильтры
ref.read(filterTypeProvider.notifier).update(FilterType.multiSelect);

// Получение текущего типа
FilterType currentType = ref.watch(filterTypeProvider);
```

### 2. В UI
- В настоящее время переключение между типами происходит в коде
- В будущем можно добавить переключатель в интерфейс

## Оффлайн режим с фильтрами

### 1. Логика работы
- При отсутствии интернета данные берутся из локальной базы
- Фильтрация происходит на уровне SQL запросов
- Все типы фильтров работают в оффлайн режиме

### 2. Особенности
- Метаданные (страны, типы, вкусы) должны быть предварительно загружены
- При первом запуске в оффлайн режиме может не быть данных

## Рекомендации по использованию

### 1. Для разработчиков
- Используйте `ref.listen` для отслеживания изменений фильтров
- Обновляйте пагинацию при изменении фильтров
- Обрабатывайте ошибки при работе с фильтрами
- Добавляйте логирование для отладки

### 2. Для пользователей
- Используйте множественный выбор для более точной фильтрации
- Комбинируйте несколько фильтров одновременно
- Используйте поиск для быстрого нахождения конкретного чая
- Нажимайте "Сбросить фильтры" для отображения всех чаёв

## Будущие улучшения

### 1. Фасетные фильтры
- Реализация полноценного API для получения фасетов
- Интеграция с UI компонентами
- Оптимизация производительности

### 2. Дополнительные фильтры
- Фильтр по диапазону цены
- Фильтр по дате добавления
- Сохранение фильтров между сеансами

### 3. Улучшения UX
- Сохранение истории поиска
- Избранные комбинации фильтров
- Быстрые фильтры для популярных запросов