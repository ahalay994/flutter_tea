import 'package:flutter/material.dart';

class InputBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;

  const InputBlock({super.key, required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Легкий фон блока
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок блока с иконкой
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Само поле ввода
          child,
        ],
      ),
    );
  }
}