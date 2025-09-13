import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({
    super.key,
    required this.templateName,
    required this.templateColor,
  });

  final String templateName;
  final Color templateColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editing $templateName'),
      ),
      body: Hero(
        tag: 'template_card_$templateName', // Unique tag
        child: Container(
          color: templateColor,
          child: Center(
            child: Text(
              'This is the $templateName template.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
      ),
    );
  }
}
