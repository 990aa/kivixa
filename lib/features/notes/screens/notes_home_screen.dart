import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/screens/notes_settings_screen.dart';
import 'package:kivixa/features/notes/widgets/notes_grid_view.dart';
import 'package:kivixa/features/notes/widgets/notes_list_view.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  bool _isGridView = true;
  bool _isLoading = true;
  List<Folder> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _folders = _getDummyFolders();
      _isLoading = false;
    });
  }

  Future<void> _refreshFolders() async {
    setState(() {
      _isLoading = true;
    });
    await _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotesSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFolders,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isGridView
              ? NotesGridView(
                  key: const ValueKey('grid'),
                  folders: _folders,
                  isLoading: _isLoading,
                )
              : NotesListView(
                  key: const ValueKey('list'),
                  folders: _folders,
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement create new folder
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Folder> _getDummyFolders() {
    return [
      Folder(
        id: 'personal',
        name: 'Personal',
        color: Colors.blue,
        icon: Icons.person,
        noteCount: 12,
        size: 3,
        capacity: 10,
        subFolders: [
          Folder(id: 'health', name: 'Health', color: Colors.green),
          Folder(id: 'finance', name: 'Finance', color: Colors.yellow),
        ],
      ),
      Folder(
        id: 'work',
        name: 'Work',
        color: Colors.green,
        icon: Icons.work,
        noteCount: 8,
        size: 8,
        capacity: 10,
        subFolders: [
          Folder(id: 'projects', name: 'Projects', color: Colors.purple),
          Folder(id: 'meetings', name: 'Meetings', color: Colors.orange),
        ],
      ),
      Folder(
        id: 'ideas',
        name: 'Ideas',
        color: Colors.purple,
        icon: Icons.lightbulb,
        noteCount: 23,
        size: 5,
        capacity: 10,
      ),
      Folder(
        id: 'travel',
        name: 'Travel',
        color: Colors.orange,
        icon: Icons.airplanemode_active,
        noteCount: 5,
        size: 2,
        capacity: 10,
      ),
      Folder(
        id: 'recipes',
        name: 'Recipes',
        color: Colors.red,
        icon: Icons.restaurant,
        noteCount: 15,
        size: 9,
        capacity: 10,
      ),
      Folder(
        id: 'projects_main',
        name: 'Projects',
        color: Colors.teal,
        icon: Icons.task,
        noteCount: 7,
        size: 7,
        capacity: 10,
      ),
    ];
  }
}