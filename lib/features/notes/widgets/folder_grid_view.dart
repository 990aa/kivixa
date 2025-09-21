import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card.dart';
import 'package:kivixa/features/notes/widgets/neumorphic_folder_card.dart';

class FolderGridView extends StatefulWidget {
  const FolderGridView({super.key, this.isNeumorphic = false});

  final bool isNeumorphic;

  @override
  State<FolderGridView> createState() => _FolderGridViewState();
}

class _FolderGridViewState extends State<FolderGridView> {
  String? _selectedFolderId;

  final dummyFolders = [
    Folder(name: 'Personal', color: Colors.blue, noteCount: 12),
    Folder(name: 'Work', color: Colors.green, noteCount: 8),
    Folder(name: 'Ideas', color: Colors.purple, noteCount: 23),
    Folder(name: 'Travel', color: Colors.orange, noteCount: 5),
    Folder(name: 'Recipes', color: Colors.red, noteCount: 16),
    Folder(name: 'Projects', color: Colors.teal, noteCount: 9),
  ];

  @override
  Widget build(BuildContext context) {
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
        if (widget.isNeumorphic) {
          return NeumorphicFolderCard(
            folder: folder,
            onTap: () {
              setState(() {
                if (_selectedFolderId == folder.id) {
                  _selectedFolderId = null;
                } else {
                  _selectedFolderId = folder.id;
                }
              });
            },
          );
        }
        return ModernFolderCard(
          folder: folder,
          isSelected: _selectedFolderId == folder.id,
          onTap: () {
            setState(() {
              if (_selectedFolderId == folder.id) {
                _selectedFolderId = null;
              } else {
                _selectedFolderId = folder.id;
              }
            });
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
