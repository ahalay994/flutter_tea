import 'package:flutter/material.dart';

class AnimatedLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AnimatedLoader({
    super.key,
    this.size = 50.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16.0),
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).primaryColor,
        ),
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
            color: Colors.black.withValues(alpha: 0.3), // Полупрозрачный черный фон
            child: const Center(
              child: AnimatedLoader(size: 80),
            ),
          ),
      ],
    );
  }
}