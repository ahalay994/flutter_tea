import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:tea/models/tea.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Галерея
          AbsorbPointer(
            child: CarouselSlider(
              options: CarouselOptions(height: 220.0, viewportFraction: 1.0, autoPlay: true),
              items: tea.images.map((path) {
                return SizedBox(
                  width: double.infinity,
                  child: path.startsWith('http')
                      ? Image.network(path, fit: BoxFit.cover)
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
                Text(tea.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
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
                  children: [
                    // Вкусы слева
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        children: tea.flavors
                            .take(3)
                            .map((f) => Text("#$f", style: TextStyle(color: Colors.orange[800], fontSize: 12)))
                            .toList(),
                      ),
                    ),
                    // Вес справа
                    if (tea.weight != null)
                      Row(
                        children: [
                          Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text("${tea.weight}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color textColor, Color bgColor) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
      backgroundColor: bgColor,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
