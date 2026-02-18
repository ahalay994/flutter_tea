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

  // Метод для изменения яркости цвета
  Color _getModifiedSecondaryColor(Color baseColor, double lightnessAdjustment) {
    // Преобразуем цвет в HSL для изменения яркости
    final hslColor = HSLColor.fromColor(baseColor);
    final modifiedHsl = hslColor.withLightness(
      (hslColor.lightness + lightnessAdjustment).clamp(0.0, 1.0),
    );
    return modifiedHsl.toColor();
  }

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
              backgroundColor: Theme.of(context).primaryColor, // Цвет темы
              actions: [
                if (isConnected) // Показываем меню только при наличии интернета
                  PopupMenuButton(
                    tooltip: '',
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.black87),
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
                title: !_isExpanded ? Text(
                  _currentTea.name, // Показываем название чая только при закреплении
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                            child: Container(
                              color: Colors.grey[300], // фон, который будет виден, если изображение не заполняет полностью
                              child: path.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: path,
                                      width: double.infinity, // заполняет всю доступную ширину
                                      height: 400, // фиксированная высота
                                      fit: BoxFit.fitWidth, // заполняет ширину контейнера
                                      alignment: Alignment.center, // центрирует изображение по высоте
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[300],
                                        child: const Center(child: CircularProgressIndicator()),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                    )
                                  : Image(
                                      image: AssetImage(path),
                                      width: double.infinity, // заполняет всю доступную ширину
                                      height: 400, // фиксированная высота
                                      fit: BoxFit.fitWidth, // заполняет ширину контейнера
                                      alignment: Alignment.center, // центрирует изображение по высоте
                                    ),
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 400,
                        viewportFraction: 1.0,
                        enlargeCenterPage: false,
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
                            Theme.of(context).primaryColor.withValues(alpha: 0.8), // Основной цвет темы
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
                        color: Colors.white.withValues(alpha: 0.8),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Theme.of(context).primaryColor.withValues(alpha: 0.05), // Легкий оттенок основного цвета темы
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
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                "${_currentTea.weight}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color.alphaBlend(
                                    Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                    Colors.black,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Чипсы: Тип и Страна с цветами как на главном экране
                      Wrap(
                        spacing: 8,
                        children: [
                          if (_currentTea.type != null)
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 1.0), // Насыщенный вторичный цвет без прозрачности
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
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 1,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_currentTea.country != null)
                            Container(
                              decoration: BoxDecoration(
                                color: _getModifiedSecondaryColor(Theme.of(context).colorScheme.secondary, 0.1).withValues(alpha: 0.9), // Изменённый вторичный цвет с 90% непрозрачностью
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
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 1,
                                        color: Colors.black54,
                                      ),
                                    ],
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
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
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
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1), // Цвет темы с прозрачностью
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_cafe_outlined,
                                    color: Theme.of(context).primaryColor,
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
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1), // Цвет темы с прозрачностью
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
              
              // Показываем полноэкранный индикатор загрузки
              this.context.showFullScreenLoader(); // используем контекст State
              
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
              
              // Обязательно скрываем индикатор загрузки в finally блоке, чтобы он закрылся в любом случае
              if (mounted) {
                this.context.hideFullScreenLoader(); // используем контекст State
              }
              
              // Откладываем навигацию до следующего кадра, чтобы избежать коллизий
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  if (success) {
                    // Показываем сообщение об успешном удалении
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text("Чай \"${_currentTea.name}\" успешно удалён"), backgroundColor: Colors.green),
                    );
                    
                    // Возвращаемся на главный экран при успешном удалении
                    if (mounted) {
                      // Используем более надежный способ возврата
                      Navigator.of(this.context).maybePop(); // Закрываем экран деталей
                    }
                  } else {
                    // Показываем ошибку, если удаление не удалось
                    if (mounted) {
                      this.context.showErrorDialog(errorMessage ?? "Не удалось удалить чай");
                    }
                  }
                }
              });
            },
            child: const Text("Да", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}