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
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/loader.gif',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}