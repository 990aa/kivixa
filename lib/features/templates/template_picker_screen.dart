import 'package:flutter/material.dart';
import 'package:kivixa/features/templates/template_card.dart';

class _Template {
  _Template({required this.name, required this.color});
  final String name;
  Color color;
}

class TemplatePickerScreen extends StatefulWidget {
  const TemplatePickerScreen({super.key});

  @override
  State<TemplatePickerScreen> createState() => _TemplatePickerScreenState();
}

class _TemplatePickerScreenState extends State<TemplatePickerScreen> {
  final List<_Template> _templates = [
    _Template(name: 'Blank', color: Colors.white),
    _Template(name: 'Lined', color: Colors.blue.shade100),
    _Template(name: 'Grid', color: Colors.green.shade100),
    _Template(name: 'Dotted', color: Colors.purple.shade100),
    _Template(name: 'Cornell', color: Colors.orange.shade100),
    _Template(name: 'Storyboard', color: Colors.red.shade100),
  ];

  void _showCustomizationSheet(_Template template) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Customize ${template.name}'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    children: Colors.primaries.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            template.color = color.shade100;
                          });
                          setSheetState(() {}); // Rebuild bottom sheet
                        },
                        child: CircleAvatar(
                          backgroundColor: color.shade100,
                          radius: 20,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              onTap: () => _showCustomizationSheet(template),
            );
          },
        ),
      ),
    );
  }
}
