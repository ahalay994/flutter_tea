import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tea/models/tea.dart';
import 'package:tea/screens/details/details_screen.dart';
import 'package:tea/widgets/info_chip.dart';

class TeaCard extends StatelessWidget {
  final TeaModel tea;

  const TeaCard({super.key, required this.tea});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
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

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Галерея
            AbsorbPointer(
              child: CarouselSlider(
                options: CarouselOptions(height: 220.0, viewportFraction: 1.0, autoPlay: tea.images.length > 1),
                items: tea.images.map((path) {
                  return SizedBox(
                    width: double.infinity,
                    child: path.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: path,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          )
                        : Image.asset(path, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Название на всю ширину
                  Text(
                    tea.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 8),

                  // 3. Chips: Тип и Страна
                  Wrap(
                    spacing: 8,
                    children: [
                      if (tea.type != null)
                        InfoChip(label: tea.type!, backgroundColor: Colors.green[100], textColor: Colors.green[900]),
                      if (tea.country != null)
                        InfoChip(label: tea.country!, backgroundColor: Colors.blue[50], textColor: Colors.blue[900]),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4. Внешний вид (курсив)
                  if (tea.appearance != null)
                    Text(
                      tea.appearance!,
                      style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                    ),

                  const Divider(height: 24),

                  // 5. Вес и Вкусы
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center, // Выравнивание по центру по вертикали
                    children: [
                      // Вкусы слева (ограничиваем ширину для предотвращения сжатия)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Показываем первые 3 вкусы и, если их больше, добавляем "+N"
                            final allFlavors = tea.flavors;
                            final displayedFlavors = allFlavors.take(3).toList();
                            final extraCount = allFlavors.length - displayedFlavors.length;

                            return Wrap(
                              spacing: 4,
                              runSpacing: 0,
                              children: [
                                ...displayedFlavors
                                    .map((f) => Text("#$f", style: TextStyle(color: Colors.orange[800], fontSize: 12)))
                                    .toList(),
                                if (extraCount > 0)
                                  Text(
                                    "+$extraCount",
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Вес справа (иконка и текст в одной строке)
                      if (tea.weight != null && tea.weight!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "${tea.weight}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}