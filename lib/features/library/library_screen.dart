import 'package:flutter/material.dart';
import 'package:kivixa/features/templates/template_picker_screen.dart';
import 'package:kivixa/widgets/components/kivixa_button.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: const Center(
        child: Text('Your documents will appear here.'),
      ),
      floatingActionButton: Hero(
        tag: 'create_document_fab',
        child: KivixaButton(
          buttonType: KivixaButtonType.floating,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TemplatePickerScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}