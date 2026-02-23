import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea_multitenant/controllers/tea_controller.dart';
import 'package:tea_multitenant/models/tea.dart';
import 'package:tea_multitenant/screens/add/add_screen.dart';
import 'package:tea_multitenant/screens/chat/chat_screen.dart';
import 'package:tea_multitenant/utils/ui_helpers.dart';
import 'package:tea_multitenant/utils/app_config.dart';
import 'package:tea_multitenant/widgets/animated_loader.dart';
import 'package:tea_multitenant/utils/app_logger.dart';
import 'package:tea_multitenant/providers/connection_status_provider.dart';
import 'package:tea_multitenant/widgets/theme_selector_modal.dart';
import '../chat/chat_screen.dart';

import 'widgets/tea_card.dart';
import 'widgets/tea_facet_filter_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0; // Добавляем общее количество чаёв
  List<TeaModel> _allTeas = [];
  final ScrollController _scrollController = ScrollController();
  
  String _getAppName() {
    try {
      // Пытаемся получить из dotenv, если доступно
      String? envAppName = dotenv.env['APP_NAME'];
      return envAppName ?? AppConfig.appName;
    } catch (e) {
      // Если возникла ошибка доступа к dotenv (например, в вебе), используем AppConfig
      return AppConfig.appName;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    AppLogger.debug('HomeScreen initState вызван');
    
    // Загружаем первую страницу при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.debug('Загружаем первую страницу');
      // Запускаем загрузку данных в фоне, чтобы не блокировать отображение интерфейса
      Future.microtask(() => _loadFirstPage());
    });
  }
  
  Future<void> _loadFirstPage() async {
    AppLogger.debug('Начало загрузки первой страницы');
    AppLogger.debug('Проверяем подключение...');
    
    // Проверяем подключение
    final connectionStatus = ref.read(connectionStatusProvider);
    final isConnected = connectionStatus.when(
      data: (isConnected) => isConnected,
      loading: () => true, // По умолчанию считаем, что подключение есть
      error: (error, stack) => true, // При ошибке считаем, что подключение есть
    );
    
    AppLogger.debug('Статус подключения: $isConnected');
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Получаем параметры фильтров из провайдера
      final filterParams = ref.read(filterParamsProvider);
      AppLogger.debug('Получены параметры фильтров: $filterParams');
      
      final teaController = ref.read(teaControllerProvider);
      AppLogger.debug('Получен teaController');
      
      List<TeaModel> teaData;
      if (filterParams.isNotEmpty) {
        AppLogger.debug('Применяем фильтры: $filterParams');
        // Используем фильтрованные данные
        final result = await teaController.fetchFilteredTeas(filterParams);
        AppLogger.debug('Получено ${result.data.length} фильтрованных чаёв, всего: ${result.totalCount}, страниц: ${result.totalPages}, hasMore: ${result.hasMore}');
        teaData = result.data;
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _totalCount = result.totalCount; // Сохраняем общее количество
      } else {
        AppLogger.debug('Фильтры не применены, загружаем все чаи');
        // Используем обычные данные
        final result = await teaController.fetchFullTeas(page: 1);
        AppLogger.debug('Получено ${result.data.length} чаёв, всего: ${result.totalCount}, страниц: ${result.totalPages}, hasMore: ${result.hasMore}');
        teaData = result.data;
        _currentPage = result.currentPage;
        _hasMore = result.hasMore;
        _totalCount = result.totalCount; // Сохраняем общее количество
      }
      
      AppLogger.debug('Обновляем состояние с ${teaData.length} чаём(ями)');
      
      if (mounted) {
        setState(() {
          _allTeas = List.from(teaData);
          _isLoadingMore = false;
        });
        AppLogger.debug('Обновлен список чаёв: ${_allTeas.length} шт., всего: $_totalCount, isLoadingMore: false');
        AppLogger.debug('Список чаёв: $_allTeas');
      }
    } catch (e, stack) {
      AppLogger.error('Ошибка при загрузке данных', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        context.showErrorDialog('Ошибка при загрузке данных: $e');
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < 500 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    AppLogger.debug('Начало загрузки дополнительных данных, текущая страница: $_currentPage, hasMore: $_hasMore');
    if (_isLoadingMore || !_hasMore) {
      AppLogger.debug('Загрузка пропущена: isLoadingMore=$_isLoadingMore, hasMore=$_hasMore');
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Получаем параметры фильтров из провайдера
      final filterParams = ref.read(filterParamsProvider);
      AppLogger.debug('Получены параметры фильтров для подгрузки: $filterParams');
      
      final teaController = ref.read(teaControllerProvider);
      
      List<TeaModel> teaData;
      if (filterParams.isNotEmpty) {
        AppLogger.debug('Применяем фильтры для подгрузки: $filterParams, страница: ${_currentPage + 1}');
        // Используем фильтрованные данные
        final result = await teaController.fetchFilteredTeas({
          ...filterParams,
          'page': _currentPage + 1,
        });
        AppLogger.debug('Получено ${result.data.length} дополнительных фильтрованных чаёв, всего: ${result.totalCount}, страниц: ${result.totalPages}, hasMore: ${result.hasMore}');
        teaData = result.data;
        _currentPage = result.currentPage;
        _hasMore = result.hasMore; // Обновляем _hasMore из результата
        _totalCount = result.totalCount; // Обновляем общее количество
      } else {
        AppLogger.debug('Фильтры не применены, подгружаем чаи, страница: ${_currentPage + 1}');
        // Используем обычные данные
        final result = await teaController.fetchFullTeas(page: _currentPage + 1);
        AppLogger.debug('Получено ${result.data.length} дополнительных чаёв, всего: ${result.totalCount}, страниц: ${result.totalPages}, hasMore: ${result.hasMore}');
        teaData = result.data;
        _currentPage = result.currentPage;
        _hasMore = result.hasMore; // Обновляем _hasMore из результата
        _totalCount = result.totalCount; // Обновляем общее количество
      }
      
      if (mounted) {
        setState(() {
          // Добавляем новые данные к уже существующим
          _allTeas.addAll(teaData);
          _hasMore = _hasMore; // Обновляем _hasMore из результата
          _isLoadingMore = false;
        });
        AppLogger.debug('Обновлен список чаёв после подгрузки: ${_allTeas.length} шт., всего: $_totalCount, isLoadingMore: false');
      }
    } catch (e, stack) {
      AppLogger.error('Ошибка при загрузке дополнительных данных', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        context.showErrorDialog('Ошибка при загрузке дополнительных данных');
      }
    }
  }

  // Метод для сброса фильтров
  void _resetFilters() {
    AppLogger.debug('Сброс фильтров начался');
    // Обновляем провайдер параметров фильтрации
    ref.read(filterParamsProvider.notifier).clear();
    AppLogger.debug('Провайдер фильтров очищен');
    
    setState(() {
      _currentPage = 1;
      _totalCount = 0; // Сбрасываем общее количество
      _allTeas = [];
      AppLogger.debug('Сброшена пагинация: currentPage=1, очищен список чаёв');
    });
    
    _loadFirstPage();
    AppLogger.debug('Вызвано обновление первой страницы после сброса фильтров');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Сначала дожидаемся результата первой проверки подключения
    final initialConnectionStatus = ref.watch(initialConnectionStatusProvider);
    
    return initialConnectionStatus.when(
      data: (initialConnected) {
        // После получения результата первой проверки подключения
        // продолжаем с основной логикой HomeScreen
        return _buildMainContent(context);
      },
      loading: () {
        // Показываем индикатор загрузки до завершения первой проверки подключения
        return Scaffold(
          appBar: AppBar(
            title: Text(_getAppName()),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Проверка подключения...'),
              ],
            ),
          ),
        );
      },
      error: (error, stack) {
        // В случае ошибки проверки подключения, считаем, что соединения нет
        return _buildMainContent(context);
      },
    );
  }
  
  // Отдельный метод для основного содержимого экрана
  Widget _buildMainContent(BuildContext context) {
    // Отслеживаем изменения параметров фильтрации и перезагружаем данные при их изменении
    ref.listen(filterParamsProvider, (previous, next) {
      if (previous != next) {
        AppLogger.debug('Параметры фильтрации изменились: $previous -> $next');
        // Перезагружаем список при изменении параметров фильтрации
        if (mounted) {
          setState(() {
            _currentPage = 1;
            _allTeas = [];
          });
          _loadFirstPage();
        }
      }
    });
    
    // Отслеживаем изменения флага обновления списка чаёв
    ref.listen(refreshTeaListProvider, (previous, next) {
      if (previous == false && next == true) {
        AppLogger.debug('Получен сигнал об обновлении списка чаёв');
        // Перезагружаем список при получении сигнала обновления
        if (mounted) {
          setState(() {
            _currentPage = 1;
            _allTeas = [];
          });
          _loadFirstPage();
        }
        // Сбрасываем флаг обновления после обработки
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(refreshTeaListProvider.notifier).reset();
          }
        });
      }
    });
    
    // Слушаем провайдер параметров фильтрации
    final filterParams = ref.watch(filterParamsProvider);
    // Проверяем, есть ли активные фильтры (не пустые значения)
    final isFiltered = filterParams.isNotEmpty && 
        (filterParams['search']?.toString().isNotEmpty == true ||
         filterParams['countries']?.toString().isNotEmpty == true ||
         filterParams['types']?.toString().isNotEmpty == true ||
         filterParams['appearances']?.toString().isNotEmpty == true ||
         filterParams['flavors']?.toString().isNotEmpty == true);
    
    // Слушаем провайдер статуса подключения
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.when(
      data: (isConnected) => isConnected,
      loading: () => false, // Если поток еще не готов, используем предыдущее значение
      error: (error, stack) => false, // При ошибке используем предыдущее значение
    );
    return Scaffold(
              appBar: AppBar(
              title: Text(_getAppName()),
              backgroundColor: Theme.of(context).primaryColor, // Используем текущую тему
              actions: [
                  // Показываем кнопку чата только если есть подключение к интернету
                  ref.watch(connectionStatusProvider).when(
                    data: (isConnected) => isConnected 
                        ? IconButton(
                            icon: const Icon(Icons.chat, color: Colors.white),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const ChatScreen()),
                              );
                            },
                          )
                        : const SizedBox(), // Скрываем кнопку, если нет подключения
                    loading: () => const SizedBox(), // Скрываем кнопку во время проверки подключения
                    error: (error, stack) => const SizedBox(), // Скрываем кнопку при ошибке проверки
                  ),
                  // Кнопка выбора темы
                  IconButton(
                    icon: const Icon(Icons.color_lens, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return const ThemeSelectorModal();
                        },
                      );
                    },
                  ),
                  // Индикатор статуса подключения
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ref.watch(connectionStatusProvider).when(
                      data: (isConnected) => isConnected 
                          ? Icon(Icons.signal_cellular_alt, color: Colors.white)
                          : Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: Colors.white),
                      loading: () => Icon(Icons.hourglass_empty, color: Colors.white),
                      error: (error, stack) => Icon(Icons.error, color: Colors.white),
                    ),
                  ),
                ],
              ), // Закрытие AppBar
            drawer: const TeaFacetFilterDrawer(),
            body: Column(
              children: [
          // Индикатор оффлайн режима - над шапкой списка
          if (!isConnected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: Colors.orange.shade100,
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Оффлайн режим',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          // Индикатор активных фильтров
          if (isFiltered)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _totalCount > 0 
                        ? 'Фильтры активны: $_totalCount позиций'
                        : 'Фильтры активны',
                      style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis, // Добавляем усечение текста
                    ),
                  ),
                  const SizedBox(width: 8), // Небольшой отступ между текстом и кнопкой
                  TextButton(
                    onPressed: _resetFilters,
                    child: Text('Сбросить', style: TextStyle(color: Colors.blue[800])),
                  ),
                ],
              ),
            )
          // Индикатор общего количества чаёв, когда фильтры не активны
          else if (_totalCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              color: Colors.grey.shade50,
              child: Text(
                'Всего чаёв: $_totalCount',
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis, // Добавляем усечение текста
              ),
            ),
          // Список чаёв
          Expanded(
            child: _allTeas.isEmpty && _isLoadingMore
                ? const Center(
                    child: AnimatedLoader(size: 100),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _currentPage = 1;
                      _allTeas = []; // Очищаем список
                      await _loadFirstPage();
                    },
                    child: Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _allTeas.length + (_hasMore && _allTeas.isNotEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _allTeas.length) {
                              return TeaCard(tea: _allTeas[index]);
                            } else {
                              // Индикатор загрузки для "подгрузки" - используем стандартный
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        ),
                        if (_allTeas.isEmpty && !_isLoadingMore)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_cafe_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  if (isFiltered)
                                    Column(
                                      children: [
                                        Text(
                                          "По вашим критериям фильтра ничего не найдено",
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _resetFilters,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text("Сбросить фильтры"),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      isConnected ? 
                                        "Список чая пока пуст" : 
                                        "Нет данных для отображения в оффлайн-режиме",
                                      style: TextStyle(color: Colors.grey.shade600),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: isConnected
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const AddScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.add),
            )
          : null, // Не отображаем кнопку добавления в оффлайн-режиме
    );
  }
}