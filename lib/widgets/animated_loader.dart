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

// Виджет для полноэкранного лоадера с прозрачным фоном
class FullScreenLoader extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const FullScreenLoader({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.white.withOpacity(0.8), // Прозрачный белый фон
            child: const Center(
              child: AnimatedLoader(size: 100),
            ),
          ),
      ],
    );
  }
}