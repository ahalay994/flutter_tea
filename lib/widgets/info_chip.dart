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
      labelStyle: TextStyle(
        color: textColor ?? Theme.of(context).primaryColor, 
        fontSize: 12, 
        fontWeight: FontWeight.w500
      ),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor.withValues(alpha: 0.1),
      side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
