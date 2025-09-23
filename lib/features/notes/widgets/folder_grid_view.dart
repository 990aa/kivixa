import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/folders_bloc.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/modern_folder_card.dart';
import 'package:kivixa/features/notes/widgets/neumorphic_folder_card.dart';

class FolderGridView extends StatefulWidget {
  const FolderGridView({
    super.key,
    this.isNeumorphic = false,
    required this.folders,
    required this.allFolders,
  });

  final bool isNeumorphic;
  final List<Folder> folders;
  final List<Folder> allFolders;

  @override
  State<FolderGridView> createState() => _FolderGridViewState();
}

class _FolderGridViewState extends State<FolderGridView> {
  String? _selectedFolderId;

  void _showMoveFolderDialog(BuildContext context, Folder folderToMove) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Move "${folderToMove.name}" to...'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.allFolders.length,
              itemBuilder: (context, index) {
                final destinationFolder = widget.allFolders[index];
                if (destinationFolder.id == folderToMove.id) {
                  return const SizedBox.shrink(); // Can't move a folder into itself
                }
                return ListTile(
                  title: Text(destinationFolder.name),
                  onTap: () {
                    BlocProvider.of<FoldersBloc>(context).add(
                      MoveFolder(folderToMove.id, destinationFolder.id),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

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
            setState(() {
              widget.folders.removeAt(index);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${folder.name} deleted')),
            );
          },
          onMove: () {
            _showMoveFolderDialog(context, folder);
          },
        );
      },
    );
  }
}
