import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/screens/notes_settings_screen.dart';
import 'package:kivixa/features/notes/widgets/notes_grid_view.dart';
import 'package:kivixa/features/notes/widgets/notes_list_view.dart';
import 'package:kivixa/features/notes/screens/a4_drawing_page.dart';
import 'package:kivixa/features/notes/screens/a3_drawing_page.dart';
import 'package:kivixa/features/notes/screens/square_drawing_page.dart';
import 'package:kivixa/features/notes/models/note_document.dart';

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentFolder != null) _buildBreadcrumb(_currentFolder!),
            Text(_currentFolder?.name ?? 'Notes'),
          ],
        ),
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
  Widget _buildBreadcrumb(Folder folder) {
    List<Folder> path = [];
    Folder? current = folder;
    while (current != null) {
      path.insert(0, current);
      current = _findFolder(_getDummyFolders(), current.parentId ?? '');
      if (current?.parentId == null) break;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < path.length; i++) ...[
            GestureDetector(
              onTap: () {
                if (i == path.length - 1) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => NotesHomeScreen(folderId: path[i].id),
                  ),
                );
              },
              child: Text(
                path[i].name,
                style: TextStyle(
                  color: i == path.length - 1
                      ? Colors.white
                      : Colors.white70,
                  fontWeight: i == path.length - 1
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (i < path.length - 1)
              const Icon(Icons.chevron_right, size: 16, color: Colors.white70),
          ],
        ],
      ),
    );
  }
        onRefresh: _refreshFolders,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isGridView
              ? Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: NotesGridView(
                        key: const ValueKey('grid'),
                        folders: _folders,
                        isLoading: _isLoading,
                      ),
                    ),
                    if (_currentFolder != null && _currentFolder!.notes.isNotEmpty)
                      Expanded(
                        flex: 3,
                        child: ListView.builder(
                          itemCount: _currentFolder!.notes.length,
                          itemBuilder: (context, index) {
                            final note = _currentFolder!.notes[index];
                            return ListTile(
                              leading: const Icon(Icons.note),
                              title: Text(note.title),
                              subtitle: Text('Created: \\${note.createdAt}'),
                            );
                          },
                        ),
                      ),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: NotesListView(key: const ValueKey('list'), folders: _folders),
                    ),
                    if (_currentFolder != null && _currentFolder!.notes.isNotEmpty)
                      Expanded(
                        flex: 3,
                        child: ListView.builder(
                          itemCount: _currentFolder!.notes.length,
                          itemBuilder: (context, index) {
                            final note = _currentFolder!.notes[index];
                            return ListTile(
                              leading: const Icon(Icons.note),
                              title: Text(note.title),
                              subtitle: Text('Created: \\${note.createdAt}'),
                            );
                          },
                        ),
                      ),
                  ],
                ),
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
                final folder = _currentFolder;
                if (folder != null) {
                  final newNote = NoteDocument(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: noteName,
                    pages: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    folderId: folder.id,
                  );
                  setState(() {
                    folder.notes.add(newNote);
                  });
                }
                final folderId = folder?.id;
                Widget page;
                if (pageType == 'A4') {
                  page = A4DrawingPage(noteName: noteName, folderId: folderId);
                } else if (pageType == 'A3') {
                  page = A3DrawingPage(noteName: noteName, folderId: folderId);
                } else {
                  page = SquareDrawingPage(
                    noteName: noteName,
                    folderId: folderId,
                  );
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
