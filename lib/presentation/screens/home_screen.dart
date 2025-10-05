// lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/note_grid_item.dart';
import '../../application/note_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noteStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('kivixa'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.notes.isEmpty
              ? const _EmptyState()
              : _NoteGrid(notes: state.notes),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateNoteDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateNoteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateNoteDialog(onCreate: (title, template) {
        ref.read(noteStateProvider.notifier).createNote(
          title: title,
          template: template,
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first note to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteGrid extends StatelessWidget {
  final List<Note> notes;

  const _NoteGrid({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: notes.length,
        itemBuilder: (context, index) => NoteGridItem(note: notes[index]),
      ),
    );
  }
}

class CreateNoteDialog extends StatefulWidget {
  final Function(String title, PageTemplate template) onCreate;

  const CreateNoteDialog({super.key, required this.onCreate});

  @override
  State<CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<CreateNoteDialog> {
  final _titleController = TextEditingController();
  PageTemplate _selectedTemplate = PageTemplate.plain;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Note Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Choose template:'),
          const SizedBox(height: 8),
          DropdownButton<PageTemplate>(
            value: _selectedTemplate,
            onChanged: (value) => setState(() => _selectedTemplate = value!),
            items: PageTemplate.values.map((template) {
              return DropdownMenuItem(
                value: template,
                child: Text(_getTemplateName(template)),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onCreate(_titleController.text, _selectedTemplate);
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _getTemplateName(PageTemplate template) {
    switch (template) {
      case PageTemplate.plain:
        return 'Plain White';
      case PageTemplate.ruled:
        return 'Ruled Lines';
      case PageTemplate.grid:
        return 'Grid Paper';
    }
  }
}