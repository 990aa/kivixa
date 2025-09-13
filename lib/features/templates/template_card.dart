import 'package:flutter/material.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.name,
    required this.color,
    this.onTap,
  });

  final String name;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        child: Center(
          child: Text(name),
        ),
      ),
    );
  }
}