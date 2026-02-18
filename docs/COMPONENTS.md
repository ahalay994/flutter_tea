# Основные компоненты Tea App

## lib/api/
### Клиенты API
- **api_client.dart**: Базовый класс для HTTP-запросов
- **tea_api.dart**: API для работы с чаями (CRUD, фильтрация)
- **country_api.dart**: API для работы со странами
- **type_api.dart**: API для работы с типами чаёв
- **appearance_api.dart**: API для работы с внешним видом
- **flavor_api.dart**: API для работы с вкусами
- **image_api.dart**: API для работы с изображениями

## lib/controllers/
### Бизнес-логика
- **tea_controller.dart**: Основной контроллер приложения с:
  - Методами загрузки данных (fetchFullTeas, fetchFilteredTeas)
  - Управлением фильтрами (FilterParamsNotifier, FilterTypeNotifier)
  - Методами CRUD для чаёв
  - Провайдерами Riverpod

## lib/models/
### Модели данных
- **tea.dart**: Модель чая с методами преобразования:
  - fromResponse() - из API-ответа
  - fromApiResponseForDatabase() - для сохранения в базу (ID вместо названий)
  - fromLocalDB() - из локальной базы (названия вместо ID)
- **image.dart**: Модель изображения

## lib/screens/
### Экраны приложения

#### home/
- **home_screen.dart**: Главный экран с:
  - Списком чаёв
  - Пагинацией и бесконечным скроллом
  - Интеграцией фильтров
  - Статусом подключения
- **widgets/tea_drawer.dart**: Мультиселект фильтры
- **widgets/tea_facet_filter_drawer.dart**: Фасетные фильтры
- **widgets/tea_card.dart**: Карточка чая

#### add/
- **add_screen.dart**: Экран добавления чая с:
  - Формой ввода
  - Выбором изображений
  - Rich Text редакторами

#### details/
- **details_screen.dart**: Экран деталей чая

## lib/services/
### Службы приложения
- **local_database_service.dart**: Работа с SQLite:
  - Хранение чаёв, стран, типов, вкусов
  - Методы фильтрации в оффлайн режиме
  - Пагинация данных
- **network_service.dart**: Проверка подключения к интернету

- **tea_service.dart**: Бизнес-логика работы с чаями

## lib/utils/
### Вспомогательные утилиты
- **app_logger.dart**: Система логирования
- **ui_helpers.dart**: Помощники UI
- **json_utils.dart**: Работа с JSON
- **filter_type.dart**: Типы фильтров (multiSelect, facets)

## lib/widgets/
### Повторно используемые виджеты
- **animated_loader.dart**: Анимированный индикатор загрузки
- **image_gallery_view.dart**: Галерея изображений
- **info_chip.dart**: Информационные чипы

## lib/providers/
### Riverpod провайдеры
- **metadata_provider.dart**: Хранение метаданных
- **connection_status_provider.dart**: Статус подключения

## lib/helpers/
### Вспомогательные классы
- **data_mapper.dart**: Преобразование данных по ID

## Механизмы работы

### Система фильтров
1. **Провайдеры:**
   - filterParamsProvider - хранит параметры фильтрации
   - filterTypeProvider - тип фильтров (мультиселект/фасеты)

2. **UI компоненты:**
   - TeaFilterDrawer - мультиселект фильтры
   - TeaFacetFilterDrawer - фасетные фильтры

3. **Обработка:**
   - Изменение параметров -> обновление провайдера -> вызов _loadFirstPage() -> загрузка отфильтрованных данных

### Оффлайн режим
1. **Проверка подключения** через NetworkService
2. **При наличии интернета:**
   - Запрос к API
   - Сохранение в локальную базу
   - Отображение данных
3. **При отсутствии интернета:**
   - Данные из локальной базы
   - Фильтрация через SQL запросы
   - Отображение данных

### Пагинация
1. **HomeScreen:**
   - _currentPage - текущая страница
   - _hasMore - есть ли ещё данные
   - _scrollListener() - слушатель скролла
   - _loadMore() - подгрузка следующей страницы

### Rich Text редактор
1. **flutter_quill** для редактирования
2. **flutter_widget_from_html** для отображения
3. Формат Delta для хранения форматированного текста

## Архитектурные решения

### MVVM
- **Model:** lib/models/ - модели данных
- **View:** lib/screens/, lib/widgets/ - UI компоненты
- **ViewModel:** lib/controllers/, lib/services/ - бизнес-логика

### Управление состоянием
- **Riverpod:** Мощная система управления состоянием
- **StateNotifierProvider:** Для изменяемого состояния (фильтры)
- **FutureProvider:** Для асинхронных данных (списки чаёв)

### Многоуровневая архитектура
- **Presentation Layer:** Виджеты и экраны
- **Business Logic Layer:** Контроллеры и сервисы
- **Data Layer:** API клиенты и локальная база данных