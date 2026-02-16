import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tea/controllers/tea_controller.dart';
import 'package:tea/models/tea.dart';
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
    _currentTea = widget.tea;
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(teaControllerProvider).isConnected;

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
            // 1. Красивая шапка с галереей
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              automaticallyImplyLeading: true, // Показывает кнопку назад
              actions: [
                if (isConnected) // Показываем меню только при наличии интернета
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
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
                                        ),                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        _showDeleteConfirmationDialog(context);
                      } else if (value == 'edit') {
                        // Переход к экрану редактирования
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditScreen(tea: _currentTea),
                          ),
                        );
                      }
                    },
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: !_isExpanded ? Text(
                  _currentTea.name, // Показываем название чая только при закреплении
                  style: const TextStyle(color: Colors.white),
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
                            child: path.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: path,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  )
                                : Image.asset(path, fit: BoxFit.cover),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 400,
                        viewportFraction: 1.0,
                        autoPlay: true,
                        enableInfiniteScroll: _currentTea.images.length > 1,
                      ),
                    ),
                    // Градиент снизу, чтобы текст имени был читаем (если захотите его в AppBar)
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black45],
                            stops: [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Контентная часть
            SliverToBoxAdapter(
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
                                'Оффлайн режим - функции редактирования и удаления недоступны',
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
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_currentTea.weight != null && _currentTea.weight!.isNotEmpty)
                          Text(
                            "${_currentTea.weight}",
                            style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Чипсы: Тип и Страна
                    Wrap(
                      spacing: 8,
                      children: [
                        if (_currentTea.type != null)
                          InfoChip(label: _currentTea.type!, backgroundColor: Colors.green[50]),
                      ],
                    ),

                    const Divider(height: 40),

                    // 3. Секция характеристик (Appearance & Temperature)
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

                    // 4. Вкусовой профиль
                    if (_currentTea.flavors.isNotEmpty) ...[
                      const SectionTitle("Вкусовой профиль"),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: _currentTea.flavors.map((f) => FlavorTag(f)).toList()),
                      const SizedBox(height: 40),
                    ],

                    // 6. Инструкция по завариванию
                    if (isHtmlContentNotEmpty(_currentTea.brewingGuide)) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 24), // Отступ сверху, чтобы не прилипало
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1), // Легкий фон
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle("Как заваривать"),
                            const SizedBox(height: 8),
                            HtmlWidget(_currentTea.brewingGuide!, textStyle: const TextStyle(fontSize: 15, height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // 5. Описание
                    if (isHtmlContentNotEmpty(_currentTea.description)) ...[
                      const SectionTitle("О чае"),
                      const SizedBox(height: 8),
                      HtmlWidget(
                        _currentTea.description!,
                        textStyle: const TextStyle(fontSize: 16, height: 1.5),
                        // Можно настроить отступы или кастомные стили для тегов
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
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
                  onSuccess: () {
                    // Инвалидируем провайдер для страницы 1, чтобы обновить список чаёв
                    ref.invalidate(teaListProvider(1));
                    // Устанавливаем флаг обновления
                    ref.read(refreshTeaListProvider.notifier).state = true;
                  }, // Обновляем список
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
                      
                      // Обновляем список чаёв на главном экране
                      // Инвалидируем провайдер, чтобы данные обновились при возврате на главный экран
                      ref.invalidate(teaListProvider(1));
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