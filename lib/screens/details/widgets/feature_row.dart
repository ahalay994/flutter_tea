import 'package:flutter/material.dart';

class FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const FeatureRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.brown[300]),
          const SizedBox(width: 12),
          Expanded(
            child: Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(value, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
