import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/page.dart';
import '../providers/notes_provider.dart';
import 'editor_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kivixa Notes'),
        elevation: 0,
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first note',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return _NoteCard(note: note);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Page Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TemplateOption(
              title: 'Plain White',
              template: PageTemplate.plain,
              onTap: () => _createNote(context, ref, PageTemplate.plain),
            ),
            _TemplateOption(
              title: 'Ruled Lines',
              template: PageTemplate.ruled,
              onTap: () => _createNote(context, ref, PageTemplate.ruled),
            ),
            _TemplateOption(
              title: 'Grid Paper',
              template: PageTemplate.grid,
              onTap: () => _createNote(context, ref, PageTemplate.grid),
            ),
          ],
        ),
      ),
    );
  }

  void _createNote(BuildContext context, WidgetRef ref, PageTemplate template) {
    final uuid = const Uuid();
    final now = DateTime.now();
    
    final newNote = Note(
      id: uuid.v4(),
      title: 'Untitled Note',
      pages: [
        NotePage(
          id: uuid.v4(),
          strokes: [],
          template: template,
          images: [],
        ),
      ],
      defaultTemplate: template,
      createdAt: now,
      modifiedAt: now,
    );

    ref.read(notesProvider.notifier).createNote(newNote);
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(noteId: newNote.id),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditorScreen(noteId: note.id),
          ),
        );
      },
      onLongPress: () => _showContextMenu(context, ref),
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(
                    Icons.note,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${note.pages.length} page${note.pages.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              ref.read(notesProvider.notifier).deleteNote(note.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: note.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Note title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              note.title = controller.text;
              ref.read(notesProvider.notifier).updateNote(note);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
  final String title;
  final PageTemplate template;
  final VoidCallback onTap;

  const _TemplateOption({
    required this.title,
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: Icon(_getIcon()),
      onTap: onTap,
    );
  }

  IconData _getIcon() {
    switch (template) {
      case PageTemplate.plain:
        return Icons.insert_drive_file;
      case PageTemplate.ruled:
        return Icons.subject;
      case PageTemplate.grid:
        return Icons.grid_on;
    }
  }
}
