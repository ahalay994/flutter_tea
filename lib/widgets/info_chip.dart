import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final String label;
  final Color? textColor;
  final Color? backgroundColor;

  const InfoChip({super.key, required this.label, this.textColor, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: textColor ?? Colors.green[800], fontSize: 12, fontWeight: FontWeight.w500),
      backgroundColor: backgroundColor ?? Colors.green[50],
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
