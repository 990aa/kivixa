import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card.dart';
import 'package:kivixa/features/notes/widgets/neumorphic_folder_card.dart';

class FolderGridView extends StatefulWidget {
  const FolderGridView({
    super.key,
    this.isNeumorphic = false,
    required this.folders,
  });

  final bool isNeumorphic;
  final List<Folder> folders;

  @override
  State<FolderGridView> createState() => _FolderGridViewState();
}

class _FolderGridViewState extends State<FolderGridView> {
  String? _selectedFolderId;

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
      itemCount: widget.folders.length,
      itemBuilder: (context, index) {
        final folder = widget.folders[index];
        if (widget.isNeumorphic) {
          return NeumorphicFolderCard(
            folder: folder,
            onTap: () {
              setState(() {
                if (_selectedFolderId == folder.id) {
                  _selectedFolderId = null;
                }
                else {
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
              }
              else {
                _selectedFolderId = folder.id;
              }
            });
          },
          onDelete: () {
            setState(() {
              widget.folders.removeAt(index);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${folder.name} deleted')),
            );
          },
          onMove: () {
            // TODO: Handle folder move
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Move ${folder.name}')),
            );
          },
        );
      },
    );
  }
}
