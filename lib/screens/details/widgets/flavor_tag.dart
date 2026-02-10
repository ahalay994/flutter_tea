import 'package:flutter/material.dart';

class FlavorTag extends StatelessWidget {
  final String flavor;
  const FlavorTag(this.flavor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Text(flavor, style: TextStyle(color: Colors.orange[900], fontSize: 13)),
    );
  }
}
