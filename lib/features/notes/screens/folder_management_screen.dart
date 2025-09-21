import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/folder_tree_sidebar.dart';
import 'package:kivixa/features/notes/widgets/notes_grid_view.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  late List<Folder> currentFolders;
  List<Folder> breadcrumbs = [];

  @override
  void initState() {
    super.initState();
    currentFolders = widget.folder.subFolders;
    breadcrumbs.add(widget.folder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildBreadcrumbs(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2c3e50), Color(0xFF4ca1af)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: FolderTreeSidebar(rootFolder: widget.folder),
          ),
        ),
      ),
      body: Hero(
        tag: 'folder_${widget.folder.id}',
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2c3e50), Color(0xFF4ca1af)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: NotesGridView(folders: currentFolders),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Row(
      children: breadcrumbs.map((folder) {
        return Row(
          children: [
            GestureDetector(
              onTap: () {
                // Handle breadcrumb tap
              },
              child: Text(
                folder.name,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            if (folder != breadcrumbs.last)
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
          ],
        );
      }).toList(),
    );
  }
}