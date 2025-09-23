import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/screens/notes_home_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.folders.length,
      itemBuilder: (context, index) {
        final folder = widget.folders[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotesHomeScreen(folderId: folder.id),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(folder.icon, size: 48, color: folder.color),
              const SizedBox(height: 8),
              Text(
                folder.name,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
