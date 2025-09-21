import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card.dart';

class FolderGridView extends StatelessWidget {
  const FolderGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyFolders = [
      Folder(name: 'Personal', color: Colors.blue, noteCount: 12),
      Folder(name: 'Work', color: Colors.green, noteCount: 8),
      Folder(name: 'Ideas', color: Colors.purple, noteCount: 23),
      Folder(name: 'Travel', color: Colors.orange, noteCount: 5),
      Folder(name: 'Recipes', color: Colors.red, noteCount: 16),
      Folder(name: 'Projects', color: Colors.teal, noteCount: 9),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: dummyFolders.length,
      itemBuilder: (context, index) {
        final folder = dummyFolders[index];
        return ModernFolderCard(
          folder: folder,
          onTap: () {
            // TODO: Handle folder tap
            print('${folder.name} tapped');
          },
          onDelete: () {
            // TODO: Handle folder delete
            print('${folder.name} deleted');
          },
          onMove: () {
            // TODO: Handle folder move
            print('${folder.name} moved');
          },
        );
      },
    );
  }
}
