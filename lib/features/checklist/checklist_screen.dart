import 'package:flutter/material.dart';
import 'package:kivixa/widgets/checklist_interactive.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Checklist')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: ChecklistInteractive(),
      ),
    );
  }
}
