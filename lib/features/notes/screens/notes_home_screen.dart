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
  List<dynamic> _items = [];

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
        _items = _folders;
      } else {
        _currentFolder = _findFolder(_getDummyFolders(), widget.folderId!);
        _folders = _currentFolder?.subFolders ?? [];
        _items = [..._folders, ..._currentFolder?.notes ?? []];
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
            if (_currentFolder != null)
              _buildBreadcrumb(context, _currentFolder!),
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
        onRefresh: _refreshFolders,
        child: _isGridView
            ? NotesGridView(
                key: const ValueKey('grid'),
                items: _items,
                isLoading: _isLoading,
                onRename: _handleRename,
                onMove: _handleMove,
                onDelete: _handleDelete,
              )
            : NotesListView(
                key: const ValueKey('list'),
                folders: _folders,
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

  Widget _buildBreadcrumb(BuildContext context, Folder folder) {
    List<Folder> path = [];
    Folder? current = folder;
    while (current != null) {
      path.insert(0, current);
      if (current.parentId == null) break;
      current = _findFolder(_getDummyFolders(), current.parentId!);
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
                  color: i == path.length - 1 ? Colors.white : Colors.white70,
                  fontWeight:
                      i == path.length - 1 ? FontWeight.bold : FontWeight.normal,
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

  void _showCreateOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String name = '';
        String type = 'Note'; // 'Note' or 'Folder'
        String pageType = 'A4'; // For notes

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Create New $type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(value: 'Note', child: Text('Note')),
                      DropdownMenuItem(value: 'Folder', child: Text('Folder')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          type = val;
                        });
                      }
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: '$type Name'),
                    onChanged: (val) => name = val,
                  ),
                  if (type == 'Note') ...[
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: pageType,
                      items: const [
                        DropdownMenuItem(value: 'A4', child: Text('A4')),
                        DropdownMenuItem(value: 'A3', child: Text('A3')),
                        DropdownMenuItem(
                            value: 'Square', child: Text('Square')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            pageType = val;
                          });
                        }
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (name.trim().isEmpty) return;
                    Navigator.pop(context);

                    if (type == 'Folder') {
                      final newFolder = Folder(
                        name: name,
                        parentId: _currentFolder?.id,
                      );
                      setState(() {
                        _folders.add(newFolder);
                        _items = [..._folders, ..._currentFolder?.notes ?? []];
                      });
                    } else {
                      final newNote = NoteDocument(
                        title: name,
                        pages: [],
                        folderId: _currentFolder?.id,
                      );
                      setState(() {
                        _currentFolder?.notes.add(newNote);
                        _items = [..._folders, ..._currentFolder?.notes ?? []];
                      });

                      Widget page;
                      if (pageType == 'A4') {
                        page = A4DrawingPage(
                            noteName: name, folderId: _currentFolder?.id);
                      } else if (pageType == 'A3') {
                        page = A3DrawingPage(
                            noteName: name, folderId: _currentFolder?.id);
                      } else {
                        page = SquareDrawingPage(
                          noteName: name,
                          folderId: _currentFolder?.id,
                        );
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => page),
                      );
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleRename(dynamic item) {
    String currentName = item is Folder ? item.name : item.title;
    TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Rename ${item is Folder ? 'Folder' : 'Note'}'),
          content: TextField(
            controller: controller,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                setState(() {
                  if (item is Folder) {
                    item.copyWith(name: controller.text);
                  } else if (item is NoteDocument) {
                    item.copyWith(title: controller.text);
                  }
                  _items = [..._folders, ..._currentFolder?.notes ?? []];
                });
                Navigator.pop(context);
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(dynamic item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${item is Folder ? 'Folder' : 'Note'}?'),
          content: Text(
              'Are you sure you want to delete "${item is Folder ? item.name : item.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (item is Folder) {
                    _folders.remove(item);
                  } else if (item is NoteDocument) {
                    _currentFolder?.notes.remove(item);
                  }
                  _items = [..._folders, ..._currentFolder?.notes ?? []];
                });
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _handleMove(dynamic item) {
    // TODO: Implement move functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Move functionality not implemented yet.')),
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
