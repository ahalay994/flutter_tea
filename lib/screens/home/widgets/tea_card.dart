import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/screens/details/details_screen.dart';

class TeaCard extends StatelessWidget {
  final TeaModel tea;

  const TeaCard({super.key, required this.tea});

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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.5), // Цвет текущей темы
          width: 2,
        ),
      ),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Theme.of(context).primaryColor.withOpacity(0.05)],
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TeaDetailScreen(tea: tea),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                  return SlideTransition(position: animation.drive(tween), child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с градиентным фоном и эффектом блёсток
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Theme.of(context).primaryColor, // Цвет текущей темы
                      Theme.of(context).colorScheme.secondaryContainer, // Вторичный цвет
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Значок единорога
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    // Название чая
                    Expanded(
                      child: Text(
                        tea.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(offset: Offset(1, 1), blurRadius: 3, color: Colors.black45)],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Значок блёсток
                    Icon(Icons.star, color: Colors.white, size: 20),
                  ],
                ),
              ),
              // 1. Галерея
              AbsorbPointer(
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 200.0,
                    viewportFraction: 1.0,
                    autoPlay: tea.images.length > 1,
                    autoPlayCurve: Curves.easeInOut,
                    autoPlayAnimationDuration: const Duration(seconds: 2),
                  ),
                  items: tea.images.map((path) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: path.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: path,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) =>
                                    Container(color: Colors.grey[300], child: const Icon(Icons.error)),
                              )
                            : Image.asset(path, fit: BoxFit.cover),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3. Chips: Тип и Страна
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (tea.type != null)
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary, // Насыщенный вторичный цвет без прозрачности
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                tea.type!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [Shadow(offset: Offset(1, 1), blurRadius: 1, color: Colors.black54)],
                                ),
                              ),
                            ),
                          ),
                        if (tea.country != null)
                          Container(
                            decoration: BoxDecoration(
                              color: _getModifiedSecondaryColor(Theme.of(context).colorScheme.secondary, 0.1).withOpacity(0.9), // Изменённый вторичный цвет с 90% непрозрачностью
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                tea.country!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  shadows: [Shadow(offset: Offset(1, 1), blurRadius: 1, color: Colors.black54)],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 4. Внешний вид (курсив)
                    if (tea.appearance != null)
                      Text(
                        tea.appearance!,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // 5. Вес и Вкусы
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Вкусы слева
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Показываем первые 3 вкусы и, если их больше, добавляем "+N"
                              final allFlavors = tea.flavors;
                              final displayedFlavors = allFlavors.take(3).toList();
                              final extraCount = allFlavors.length - displayedFlavors.length;

                              return Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  ...List<Widget>.from(
                                    displayedFlavors.map(
                                      (f) => Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Text(
                                            "#$f",
                                            style: TextStyle(
                                              color: Theme.of(context).primaryColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (extraCount > 0)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Text(
                                          "+$extraCount",
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Вес справа
                        if (tea.weight != null && tea.weight!.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.scale, size: 14, color: Colors.grey[700]),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${tea.weight}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
