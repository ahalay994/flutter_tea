import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/screens/add/add_screen.dart';
import 'package:tea/utils/filter_type.dart';
import 'package:tea/utils/ui_helpers.dart';
import 'package:tea/widgets/animated_loader.dart';
import 'package:tea/utils/app_logger.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Загружаем первую страницу при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFirstPage();
    });
  }
  
  Future<void> _loadFirstPage() async {
    AppLogger.debug('Начало загрузки первой страницы');
    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Получаем параметры фильтров из провайдера
      final filterParams = ref.read(filterParamsProvider);
      AppLogger.debug('Получены параметры фильтров: $filterParams');
      
      final teaController = ref.read(teaControllerProvider);
      
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
      
      if (mounted) {
        setState(() {
          _allTeas = List.from(teaData);
          _isLoadingMore = false;
        });
        AppLogger.debug('Обновлен список чаёв: ${_allTeas.length} шт., всего: $_totalCount, isLoadingMore: false');
      }
    } catch (e, stack) {
      AppLogger.error('Ошибка при загрузке данных', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        context.showErrorDialog('Ошибка при загрузке данных');
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
      loading: () => true, // По умолчанию считаем, что подключение есть
      error: (error, stack) => true, // При ошибке считаем, что подключение есть
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(dotenv.env['APP_NAME'] ?? 'Tea App'),
        actions: [
          // Показываем индикатор фильтрации, если фильтры активны
          if (isFiltered)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.filter_alt, color: Colors.blue),
            ),
          // Индикатор статуса подключения
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: connectionStatus.when(
              data: (isConnected) => isConnected 
                  ? Icon(Icons.signal_cellular_alt, color: Colors.green)
                  : Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: Colors.red),
              loading: () => Icon(Icons.signal_cellular_alt, color: Colors.orange),
              error: (error, stack) => Icon(Icons.signal_cellular_connected_no_internet_4_bar, color: Colors.red),
            ),
          ),
        ],
      ),
      drawer: const TeaFacetFilterDrawer(),
      body: Column(
        children: [
          // Индикатор оффлайн режима - над шапкой списка
          if (connectionStatus.asData?.value == false)
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
                  Text(
                    _totalCount > 0 
                      ? 'Фильтры активны: $_totalCount позиций'
                      : 'Фильтры активны',
                    style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w500),
                  ),
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
              ),
            ),
          // Список чаёв
          Expanded(
            child: _allTeas.isEmpty && _isLoadingMore
                ? const Center(child: AnimatedLoader(size: 50))
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_cafe_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  isConnected ? 
                                    (isFiltered ? "Нет чаёв по фильтрам" : "Список чая пока пуст") : 
                                    "Нет данных для отображения в оффлайн-режиме",
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
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
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.add),
            )
          : null, // Не отображаем кнопку добавления в оффлайн-режиме
    );
  }
}