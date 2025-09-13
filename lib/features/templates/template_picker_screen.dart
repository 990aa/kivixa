import 'package:flutter/material.dart';
import 'package:kivixa/features/templates/template_card.dart';

class _Template {
  const _Template({required this.name, required this.color});
  final String name;
  final Color color;
}

class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});

  static const List<_Template> _templates = [
    _Template(name: 'Blank', color: Colors.white),
    _Template(name: 'Lined', color: Colors.blue.shade100),
    _Template(name: 'Grid', color: Colors.green.shade100),
    _Template(name: 'Dotted', color: Colors.purple.shade100),
    _Template(name: 'Cornell', color: Colors.orange.shade100),
    _Template(name: 'Storyboard', color: Colors.red.shade100),
  ];

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'create_document_fab',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Choose a Template'),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.75,
          ),
          itemCount: _templates.length,
          itemBuilder: (context, index) {
            final template = _templates[index];
            return TemplateCard(
              name: template.name,
              color: template.color,
            );
          },
        ),
      ),
    );
  }
}