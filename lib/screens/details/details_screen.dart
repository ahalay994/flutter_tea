import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/screens/edit/edit_screen.dart';
import 'package:tea/utils/ui_helpers.dart';
import 'package:tea/widgets/image_gallery_view.dart';
import 'package:tea/widgets/info_chip.dart';

import 'widgets/feature_row.dart';
import 'widgets/flavor_tag.dart';
import 'widgets/section_title.dart';

class TeaDetailScreen extends ConsumerStatefulWidget {
  final TeaModel tea;

  const TeaDetailScreen({super.key, required this.tea});

  @override
  ConsumerState<TeaDetailScreen> createState() => _TeaDetailScreenState();
}

class _TeaDetailScreenState extends ConsumerState<TeaDetailScreen> {
  TeaModel _currentTea = TeaModel(
    id: 0,
    name: '',
    flavors: [],
    images: [],
  );
  bool _isExpanded = true; // Флаг: развернута ли шапка

  @override
  void initState() {
    super.initState();
    // Инициализируем текущий чай данными из widget
    _currentTea = widget.tea;
  }

  @override
  Widget build(BuildContext context) {
    // Сначала дожидаемся результата первой проверки подключения
    final initialConnectionStatus = ref.watch(initialConnectionStatusProvider);
    
    return initialConnectionStatus.when(
      data: (initialConnected) {
        // После получения результата первой проверки подключения
        // продолжаем с основной логикой TeaDetailScreen
        return _buildMainContent(context, initialConnected);
      },
      loading: () {
        // Показываем индикатор загрузки до завершения первой проверки подключения
        return Scaffold(
          appBar: AppBar(
            title: const Text('Загрузка...'),
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
        // В случае ошибки проверки подключения, используем false как значение
        return _buildMainContent(context, false);
      },
    );
  }
  
  // Отдельный метод для основного содержимого экрана
  Widget _buildMainContent(BuildContext context, bool initialConnected) {
    final connectionStatus = ref.watch(connectionStatusProvider);
    final isConnected = connectionStatus.when(
      data: (isConnected) => isConnected,
      loading: () => initialConnected, // Используем результат первой проверки
      error: (error, stack) => initialConnected, // Используем результат первой проверки
    );

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Вычисляем, насколько прокручен список
          // 350 - это expandedHeight нашего SliverAppBar
          if (notification.metrics.pixels > 150 && _isExpanded) {
            setState(() => _isExpanded = false);
          } else if (notification.metrics.pixels <= 150 && !_isExpanded) {
            setState(() => _isExpanded = true);
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            // 1. Красивая шапка с галереей и фиолетово-розовым градиентом
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              automaticallyImplyLeading: true, // Показывает кнопку назад
              backgroundColor: const Color(0xFF9B59B6), // Фиолетовый фон
              actions: [
                if (isConnected) // Показываем меню только при наличии интернета
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      if (isConnected) // Показываем кнопку удаления только при наличии интернета
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Удалить', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _showDeleteConfirmationDialog(context);
                      } else if (value == 'edit') {
                        // Навигация к экрану редактирования и получение обновленного чая
                        final updatedTea = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditScreen(tea: _currentTea),
                          ),
                        );
                        
                        // Если получен обновленный чай, обновляем локальное состояние
                        if (updatedTea != null) {
                          setState(() {
                            _currentTea = updatedTea;
                          });
                        }
                      }
                    },
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: !_isExpanded ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFFF69B4).withOpacity(0.7), // Розовый полупрозрачный фон
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    _currentTea.name, // Показываем название чая только при закреплении
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ) : null,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CarouselSlider.builder(
                      itemCount: _currentTea.images.length,
                      itemBuilder: (context, index, realIndex) {
                        final path = _currentTea.images[index]; // Получаем путь по индексу
                        return AbsorbPointer(
                          absorbing: !_isExpanded, // Если шапка свернута, клики ПОГЛОЩАЮТСЯ
                          child: GestureDetector(
                            onTap: () => path.startsWith('http') ? _openGalleryModal(index) : () => {},
                            child: path.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: path,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    ),
                                  )
                                : Image.asset(path, fit: BoxFit.cover),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 400,
                        viewportFraction: 1.0,
                        autoPlay: _currentTea.images.length > 1,
                        enableInfiniteScroll: _currentTea.images.length > 1,
                        autoPlayCurve: Curves.easeInOut,
                        autoPlayAnimationDuration: const Duration(seconds: 3),
                      ),
                    ),
                    // Градиент снизу, чтобы текст имени был читаем
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF9B59B6).withOpacity(0.8), // Фиолетовый полупрозрачный
                          ],
                          stops: [0.7, 1.0],
                        ),
                      ),
                    ),
                    // Эффект блёсток
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withOpacity(0.8),
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Контентная часть
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFF8F6FF), // Светло-фиолетовый оттенок
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Индикатор оффлайн режима
                      if (!isConnected)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          margin: const EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Оффлайн режим - редактирование и удаление недоступны',
                                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Название и Вес
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _currentTea.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_currentTea.weight != null && _currentTea.weight!.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF69B4).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF69B4),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                "${_currentTea.weight}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.pink[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Чипсы: Тип и Страна с новым дизайном
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_currentTea.country != null)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6C5CE7), // Фиолетовый
                                    const Color(0xFFA29BFE),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  _currentTea.country!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          if (_currentTea.type != null)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFD79A8), // Розовый
                                    const Color(0xFFFFDDF4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Text(
                                  _currentTea.type!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const Divider(height: 40),

                      // 3. Секция характеристик (Appearance & Temperature)
                      // Показываем только если есть данные для отображения
                      if (_currentTea.appearance != null || (_currentTea.temperature != null && _currentTea.temperature!.trim().isNotEmpty)) ...[
                        const SectionTitle("Характеристики"),
                        const SizedBox(height: 8),
                        if (_currentTea.appearance != null)
                          FeatureRow(icon: Icons.visibility_outlined, label: "Внешний вид", value: _currentTea.appearance!),
                        if (_currentTea.temperature != null && _currentTea.temperature!.trim().isNotEmpty)
                          FeatureRow(
                            icon: Icons.thermostat_outlined,
                            label: "Температура заваривания",
                            value: _currentTea.temperature!,
                          ),
                        const SizedBox(height: 40),
                      ],

                      const SizedBox(height: 40),

                      // 4. Вкусовой профиль
                      if (_currentTea.flavors.isNotEmpty) ...[
                        const SectionTitle("Вкусовой профиль"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _currentTea.flavors.map((f) => Container(
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF9B59B6).withOpacity(0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // 6. Инструкция по завариванию
                      if (isHtmlContentNotEmpty(_currentTea.brewingGuide)) ...[
                        Container(
                          margin: const EdgeInsets.only(top: 24), // Отступ сверху, чтобы не прилипало
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEDCF5).withOpacity(0.5), // Фиолетовый легкий фон
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF9B59B6).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_cafe_outlined,
                                    color: Color(0xFF9B59B6),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const SectionTitle("Как заваривать"),
                                ],
                              ),
                              const SizedBox(height: 8),
                              HtmlWidget(
                                _currentTea.brewingGuide!,
                                textStyle: const TextStyle(fontSize: 15, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // 5. Описание
                      if (isHtmlContentNotEmpty(_currentTea.description)) ...[
                        const SectionTitle("О чае"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5F9).withOpacity(0.7), // Розовый легкий фон
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF69B4).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: HtmlWidget(
                            _currentTea.description!,
                            textStyle: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGalleryModal(int index) {
    if (mounted) {
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (context) => ImageGalleryView(images: _currentTea.images, initialIndex: index),
      );
    }
  }
  
  void _showDeleteConfirmationDialog(BuildContext context) {
    if (!mounted) return;
    
    showDialog(
      context: this.context, // используем контекст State
      builder: (context) => AlertDialog(
        title: const Text("Подтверждение удаления"),
        content: Text("Вы действительно хотите удалить чай \"${_currentTea.name}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Нет"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Закрываем диалог подтверждения
              
              // Показываем индикатор загрузки
              this.context.showLoadingDialog(); // используем контекст State
              
              bool success = false;
              String? errorMessage;
              
              try {
                // Получаем контроллер и вызываем удаление
                final controller = ref.read(teaControllerProvider);
                
                success = await controller.deleteTea(
                  _currentTea.id,
                  onSuccess: () => ref.read(refreshTeaListProvider.notifier).triggerRefresh(), // Обновляем список через флаг
                );
                
                if (!success) {
                  errorMessage = "Не удалось удалить чай";
                }
              } catch (e) {
                errorMessage = e.toString();
              }
              
              // Скрываем индикатор загрузки с проверкой mounted
              if (mounted) {
                this.context.hideLoading(); // используем контекст State
                
                // Откладываем навигацию до следующего кадра, чтобы избежать коллизий
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    if (success) {
                      // Показываем сообщение об успешном удалении
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text("Чай \"${_currentTea.name}\" успешно удалён"), backgroundColor: Colors.green),
                      );
                      
                      // Возвращаемся на главный экран при успешном удалении
                      Navigator.of(this.context).pop(); // Закрываем экран деталей
                    } else {
                      // Показываем ошибку, если удаление не удалось
                      if (mounted) {
                        this.context.showErrorDialog(errorMessage ?? "Не удалось удалить чай");
                      }
                    }
                  }
                });
              }
            },
            child: const Text("Да", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}