import 'package:flutter/material.dart';

class FlavorTag extends StatelessWidget {
  final String flavor;
  const FlavorTag(this.flavor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        flavor, 
        style: TextStyle(
          color: Color.alphaBlend(
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
            Colors.black,
          ),
          fontSize: 13,
        ),
      ),
    );
  }
}
