import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/screens/add/add_screen.dart';
import 'package:tea/utils/ui_helpers.dart';
import 'package:tea/widgets/animated_loader.dart';

import 'widgets/tea_card.dart';
import 'widgets/tea_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
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
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final teaController = ref.read(teaControllerProvider);
      
      final result = await teaController.fetchFullTeas(page: 1);
      if (mounted) {
        setState(() {
          _allTeas = List.from(result.data);
          _currentPage = result.currentPage;
          _hasMore = result.hasMore;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
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
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Используем контекстный реф для вызова метода
      final teaController = ref.read(teaControllerProvider);
      
      final result = await teaController.fetchFullTeas(page: _currentPage + 1);
      if (mounted) {
        setState(() {
          // Добавляем новые данные к уже существующим
          _allTeas.addAll(result.data);
          _currentPage = result.currentPage;
          _hasMore = result.hasMore; // Обновляем _hasMore из результата
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        context.showErrorDialog('Ошибка при загрузке дополнительных данных');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      drawer: const TeaFilterDrawer(),
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
                                  isConnected ? "Список чая пока пуст" : "Нет данных для отображения в оффлайн-режиме",
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
