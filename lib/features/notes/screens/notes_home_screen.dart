import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/screens/note_editor_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/document_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:kivixa/features/notes/services/notes_database_service.dart';
import 'package:kivixa/features/notes/screens/notes_settings_screen.dart';
import 'package:kivixa/features/notes/widgets/notes_grid_view.dart';
import 'package:kivixa/features/notes/widgets/notes_list_view.dart';
import 'package:kivixa/features/notes/screens/a4_drawing_page.dart';
import 'package:kivixa/features/notes/screens/a3_drawing_page.dart';
import 'package:kivixa/features/notes/screens/square_drawing_page.dart';

class NotesHomeScreen extends StatefulWidget {
  final String? folderId;
  const NotesHomeScreen({super.key, this.folderId});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  bool _isGridView = true;
  bool _isLoading = true;
  List<Folder> _folders = [];
  Folder? _currentFolder;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      if (widget.folderId == null) {
        _folders = _getDummyFolders();
      } else {
        _currentFolder = _findFolder(_getDummyFolders(), widget.folderId!);
        _folders = _currentFolder?.subFolders ?? [];
      }
      _isLoading = false;
    });
  }

  Folder? _findFolder(List<Folder> folders, String folderId) {
    for (var folder in folders) {
      if (folder.id == folderId) {
        return folder;
      }
      if (folder.subFolders.isNotEmpty) {
        final subFolder = _findFolder(folder.subFolders, folderId);
        if (subFolder != null) {
          return subFolder;
        }
      }
    }
    return null;
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
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentFolder?.parentId != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            NotesHomeScreen(folderId: _currentFolder!.parentId),
                      ),
                    );
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              )
            : null,
        title: Text(_currentFolder?.name ?? 'Notes'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.grid_view : Icons.list),
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
                MaterialPageRoute(
                  builder: (context) => const NotesSettingsScreen(),
                ),
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
              : NotesListView(key: const ValueKey('list'), folders: _folders),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateOptions(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String noteName = '';
        String pageType = 'A4';
        return AlertDialog(
          title: const Text('Create New Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Note Name'),
                onChanged: (val) => noteName = val,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: pageType,
                items: const [
                  DropdownMenuItem(value: 'A4', child: Text('A4')),
                  DropdownMenuItem(value: 'A3', child: Text('A3')),
                  DropdownMenuItem(value: 'Square', child: Text('Square')),
                ],
                onChanged: (val) {
                  if (val != null) pageType = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (noteName.trim().isEmpty) return;
                Navigator.pop(context);
                final folderId = _currentFolder?.id;
                Widget page;
                if (pageType == 'A4') {
                  page = A4DrawingPage(noteName: noteName, folderId: folderId);
                } else if (pageType == 'A3') {
                  page = A3DrawingPage(noteName: noteName, folderId: folderId);
                } else {
                  page = SquareDrawingPage(noteName: noteName, folderId: folderId);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => page),
                );
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _folders.add(
                      Folder(
                        id: DateTime.now().toString(),
                        name: controller.text,
                        color: Colors.grey,
                        icon: Icons.folder,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
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
