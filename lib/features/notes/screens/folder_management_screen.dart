import 'package:flutter/material.dart';
import 'package:kivixa/features/notes/models/folder_model.dart';
import 'package:kivixa/features/notes/screens/note_editor_screen.dart';
import 'package:kivixa/features/notes/widgets/folder_grid_view.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:uuid/uuid.dart';
import 'package:kivixa/features/notes/models/note_document.dart';
import 'package:kivixa/features/notes/models/note_page.dart';
import 'package:kivixa/features/notes/models/paper_settings.dart';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  State<FolderManagementScreen> createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  bool _isNeumorphic = false;
  final List<Folder> _folders = [
    Folder(name: 'Personal', color: Colors.blue, noteCount: 12),
    Folder(name: 'Work', color: Colors.green, noteCount: 8),
    Folder(name: 'Ideas', color: Colors.purple, noteCount: 23),
    Folder(name: 'Travel', color: Colors.orange, noteCount: 5),
    Folder(name: 'Recipes', color: Colors.red, noteCount: 16),
    Folder(name: 'Projects', color: Colors.teal, noteCount: 9),
  ];

  void _showCreateFolderDialog() {
    final TextEditingController folderNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: const InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (folderNameController.text.isNotEmpty) {
                  final newFolder = Folder(
                    name: folderNameController.text,
                    color: Colors.primaries[
                        _folders.length % Colors.primaries.length],
                    noteCount: 0,
                  );
                  setState(() {
                    _folders.add(newFolder);
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuTheme(
      data: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.transparent,
        elevation: 0,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: Icon(_isNeumorphic ? Icons.view_quilt : Icons.view_agenda),
              onPressed: () {
                setState(() {
                  _isNeumorphic = !_isNeumorphic;
                });
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: FolderGridView(
          isNeumorphic: _isNeumorphic,
          folders: _folders,
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          overlayColor: Colors.black,
          overlayOpacity: 0.5,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.create_new_folder),
              label: 'Create Folder',
              onTap: _showCreateFolderDialog,
            ),
            SpeedDialChild(
              child: const Icon(Icons.note_add),
              label: 'Create Note',
              onTap: () {
                final newDocument = NoteDocument(
                  id: const Uuid().v4(),
                  title: 'Untitled Note',
                  pages: [
                    NotePage(
                      pageNumber: 0,
                      strokes: [],
                      paperSettings: PaperSettings(
                        paperType: PaperType.plain,
                        paperSize: PaperSize.a4,
                        options: PlainPaperOptions(backgroundColor: Colors.white),
                      ),
                    ),
                  ],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(
                      documentId: newDocument.id,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
