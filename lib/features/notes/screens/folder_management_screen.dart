import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/widgets/folder_tree_sidebar.dart';
import 'package:kivixa/features/notes/widgets/notes_grid_view.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  late final Folder rootFolder;
  late List<Folder> currentFolders;
  List<Folder> breadcrumbs = [];

  @override
  void initState() {
    super.initState();
    _generateMockData();
    currentFolders = rootFolder.subFolders;
    breadcrumbs.add(rootFolder);
  }

  void _generateMockData() {
    rootFolder = Folder(
      id: 'root',
      name: 'Home',
      subFolders: [
        Folder(
          name: 'Personal',
          color: Colors.blue,
          icon: Icons.person,
          subFolders: [
            Folder(name: 'Health', color: Colors.green),
            Folder(name: 'Finance', color: Colors.yellow),
          ],
        ),
        Folder(
          name: 'Work',
          color: Colors.red,
          icon: Icons.work,
          subFolders: [
            Folder(name: 'Projects', color: Colors.purple),
            Folder(name: 'Meetings', color: Colors.orange),
          ],
        ),
        Folder(name: 'Ideas', color: Colors.indigo),
      ],
    );
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
            child: FolderTreeSidebar(rootFolder: rootFolder),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2c3e50), Color(0xFF4ca1af)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: NotesGridView(folders: currentFolders),
      ),
      floatingActionButton: ShadcnButton.primary(
        onPressed: () {},
        text: const Text('Add'),
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