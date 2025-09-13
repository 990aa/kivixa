import 'package:flutter/material.dart';
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
      floatingActionButton: KivixaButton(
        buttonType: KivixaButtonType.floating,
        onPressed: () {
          // TODO: Implement document creation flow
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
