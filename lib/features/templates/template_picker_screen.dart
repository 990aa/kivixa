import 'package:flutter/material.dart';

class TemplatePickerScreen extends StatelessWidget {
  const TemplatePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Template'),
      ),
      body: const Center(
        child: Text('Template previews will be shown here.'),
      ),
    );
  }
}
