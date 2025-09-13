import 'package:flutter/material.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.name,
    required this.color,
    this.onTap,
    this.onSelect,
  });

  final String name;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'template_card_$name',
        child: Card(
          color: color,
          child: Stack(
            children: [
              Center(
                child: Text(name),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: ElevatedButton(
                  onPressed: onSelect,
                  child: const Text('Select'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
