import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/utils/ui_helpers.dart';
import 'package:tea/widgets/image_gallery_view.dart';
import 'package:tea/widgets/info_chip.dart';

import 'widgets/feature_row.dart';
import 'widgets/flavor_tag.dart';
import 'widgets/section_title.dart';

class TeaDetailScreen extends StatefulWidget {
  final TeaModel tea;

  const TeaDetailScreen({super.key, required this.tea});

  @override
  State<TeaDetailScreen> createState() => _TeaDetailScreenState();
}

class _TeaDetailScreenState extends State<TeaDetailScreen> {
  bool _isExpanded = true; // Флаг: развернута ли шапка

  @override
  Widget build(BuildContext context) {
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
              flexibleSpace: FlexibleSpaceBar(
                title: !_isExpanded ? Text(
                  widget.tea.name, // Показываем название чая только при закреплении
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ) : null,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    CarouselSlider.builder(
                      itemCount: widget.tea.images.length,
                      itemBuilder: (context, index, realIndex) {
                        final path = widget.tea.images[index]; // Получаем путь по индексу
                        return AbsorbPointer(
                          absorbing: !_isExpanded, // Если шапка свернута, клики ПОГЛОЩАЮТСЯ
                          child: GestureDetector(
                            onTap: () => path.startsWith('http') ? _openGalleryModal(index) : () => {},
                            child: path.startsWith('http')
                                ? Image.network(path, fit: BoxFit.cover)
                                : Image.asset(path, fit: BoxFit.cover),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 400,
                        viewportFraction: 1.0,
                        autoPlay: true,
                        enableInfiniteScroll: widget.tea.images.length > 1,
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
                    // Название и Вес
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.tea.name,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.tea.weight != null && widget.tea.weight!.isNotEmpty)
                          Text(
                            "${widget.tea.weight}",
                            style: TextStyle(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Чипсы: Тип и Страна
                    Wrap(
                      spacing: 8,
                      children: [
                        if (widget.tea.type != null)
                          InfoChip(label: widget.tea.type!, backgroundColor: Colors.green[50]),
                      ],
                    ),

                    const Divider(height: 40),

                    // 3. Секция характеристик (Appearance & Temperature)
                    const SectionTitle("Характеристики"),
                    const SizedBox(height: 8),
                    if (widget.tea.appearance != null)
                      FeatureRow(icon: Icons.visibility_outlined, label: "Внешний вид", value: widget.tea.appearance!),
                    if (widget.tea.temperature != null && widget.tea.temperature!.trim().isNotEmpty)
                      FeatureRow(
                        icon: Icons.thermostat_outlined,
                        label: "Температура заваривания",
                        value: widget.tea.temperature!,
                      ),

                    const SizedBox(height: 40),

                    // 4. Вкусовой профиль
                    if (widget.tea.flavors.isNotEmpty) ...[
                      const SectionTitle("Вкусовой профиль"),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: widget.tea.flavors.map((f) => FlavorTag(f)).toList()),
                      const SizedBox(height: 40),
                    ],

                    // 6. Инструкция по завариванию
                    if (isHtmlContentNotEmpty(widget.tea.brewingGuide)) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 24), // Отступ сверху, чтобы не прилипало
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1), // Легкий фон
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle("Как заваривать"),
                            const SizedBox(height: 8),
                            HtmlWidget(widget.tea.brewingGuide!, textStyle: const TextStyle(fontSize: 15, height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // 5. Описание
                    if (isHtmlContentNotEmpty(widget.tea.description)) ...[
                      const SectionTitle("О чае"),
                      const SizedBox(height: 8),
                      HtmlWidget(
                        widget.tea.description!,
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
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ImageGalleryView(images: widget.tea.images, initialIndex: index),
    );
  }
}