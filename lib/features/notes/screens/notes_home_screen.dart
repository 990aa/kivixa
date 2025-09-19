import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/notes_bloc.dart';
import 'package:kivixa/features/notes/blocs/notes_event.dart';
import 'package:kivixa/features/notes/blocs/notes_state.dart';
import 'package:kivixa/features/notes/models/note_document.dart';
import 'package:kivixa/features/notes/services/export_service.dart';
import 'package:kivixa/features/notes/services/recent_documents_service.dart';

import 'package:kivixa/features/notes/screens/notes_settings_screen.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  final ExportService _exportService = ExportService();
  final RecentDocumentsService _recentDocumentsService = RecentDocumentsService();
  bool _isSearching = false;
  String _searchQuery = '';
  List<NoteDocument> _filteredNotes = [];
  bool _showRecents = false;
  List<String> _recentDocumentIds = [];

  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(NotesLoaded());
    _getRecentDocuments();
  }

  void _getRecentDocuments() async {
    _recentDocumentIds = await _recentDocumentsService.getRecentDocuments();
    setState(() {});
  }

  void _filterNotes(String query, List<NoteDocument> notes) {
    _searchQuery = query;
    _filteredNotes = notes
        .where((note) => note.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  final state = context.read<NotesBloc>().state;
                  if (state is NotesLoadSuccess) {
                    setState(() {
                      _filterNotes(query, state.notes);
                    });
                  }
                },
              )
            : const Text('Notes'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_showRecents ? Icons.list : Icons.history),
            onPressed: () {
              setState(() {
                _showRecents = !_showRecents;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              final note = await _exportService.importFromJson();
              if (note != null) {
                context.read<NotesBloc>().add(NoteAdded(note));
              }
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
      body: BlocBuilder<NotesBloc, NotesState>(
        builder: (context, state) {
          if (state is NotesLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NotesLoadSuccess) {
            List<NoteDocument> notes;
            if (_showRecents) {
              notes = state.notes
                  .where((note) => _recentDocumentIds.contains(note.id))
                  .toList();
            } else {
              notes = _isSearching && _searchQuery.isNotEmpty ? _filteredNotes : state.notes;
            }
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  onTap: () {
                    Navigator.pushNamed(context, '/notes/editor', arguments: note.id)
                        .then((_) => _getRecentDocuments());
                  },
                );
              },
            );
          } else if (state is NotesLoadFailure) {
            return Center(child: Text(state.error));
          } else {
            return const Center(child: Text('No notes found.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/notes/create');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
