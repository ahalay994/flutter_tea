import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:tea/models/tea.dart';

class TeaCard extends StatelessWidget {
  final TeaModel tea;

  const TeaCard({super.key, required this.tea});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Изображение
          AbsorbPointer(
            // Отключаем ручное управление
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
              ),
              items: tea.images.map((path) {
                final bool isNetwork = path.startsWith('http');
                return SizedBox(
                  width: double.infinity,
                  child: isNetwork
                      ? Image.network(
                          path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/default.png', fit: BoxFit.cover),
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
                // 2. Название и Тип
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(tea.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    if (tea.type != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                        child: Text(tea.type!, style: TextStyle(color: Colors.green[800], fontSize: 12)),
                      ),
                  ],
                ),

                // 3. Страна
                const SizedBox(height: 4),
                Text(tea.country ?? 'Происхождение не указано', style: TextStyle(color: Colors.grey[600])),

                const SizedBox(height: 12),

                // 4. Вкусы (Chips)
                if (tea.flavors.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tea.flavors
                        .map(
                          (flavor) => Chip(
                            label: Text(flavor, style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.orange[50],
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 12),

                /*// 5. Описание
                if (tea.description != null && tea.description!.isNotEmpty)
                  HtmlWidget(
                    tea.description!,
                    textStyle: const TextStyle(fontSize: 14, color: Colors.black87),
                    renderMode: RenderMode.column,
                  ),*/
              ],
            ),
          ),
        ],
      ),
    );
  }
}
