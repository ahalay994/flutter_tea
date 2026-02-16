import 'package:flutter/material.dart';

class AnimatedLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AnimatedLoader({
    super.key,
    this.size = 100.0, // Увеличиваем размер по умолчанию
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity, // Занимает всю ширину экрана
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Image.asset(
        'assets/images/loader.gif',
        width: screenWidth, // Изображение занимает всю ширину экрана
        fit: BoxFit.fitWidth, // Растягиваем изображение по ширине, высота автоматически рассчитывается пропорционально
      ),
    );
  }
}