import 'package:flutter/material.dart';
import 'package:kivixa/features/library/sidebar.dart';
import 'package:kivixa/features/templates/template_picker_screen.dart';
import 'package:kivixa/widgets/components/kivixa_button.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Library'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: const Sidebar(),
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
