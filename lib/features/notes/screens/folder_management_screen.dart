import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/widgets/folder_grid_view.dart';

class FolderManagementScreen extends StatelessWidget {
  const FolderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder Management'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: const FolderGridView(),
    );
  }
}
