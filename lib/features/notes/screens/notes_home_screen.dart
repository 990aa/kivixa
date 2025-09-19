import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/notes_bloc.dart';
import 'package:kivixa/features/notes/blocs/notes_event.dart';
import 'package:kivixa/features/notes/blocs/notes_state.dart';
import 'package:kivixa/features/notes/models/note_document.dart';
import 'package:kivixa/features/notes/services/export_service.dart';
import 'package:kivixa/features/notes/services/favorite_documents_service.dart';
import 'package:kivixa/features/notes/services/recent_documents_service.dart';

import 'package:kivixa/features/notes/screens/notes_settings_screen.dart';

enum FilterType { all, recents, favorites }

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  final ExportService _exportService = ExportService();
  final RecentDocumentsService _recentDocumentsService = RecentDocumentsService();
  final FavoriteDocumentsService _favoriteDocumentsService = FavoriteDocumentsService();
  bool _isSearching = false;
  String _searchQuery = '';
  List<NoteDocument> _filteredNotes = [];
  FilterType _filterType = FilterType.all;
  List<String> _recentDocumentIds = [];
  List<String> _favoriteDocumentIds = [];

  @override
  void initState() {
    super.initState();
    context.read<NotesBloc>().add(NotesLoaded());
    _getRecentDocuments();
    _getFavoriteDocuments();
  }

  void _getRecentDocuments() async {
    _recentDocumentIds = await _recentDocumentsService.getRecentDocuments();
    setState(() {});
  }

  void _getFavoriteDocuments() async {
    _favoriteDocumentIds = await _favoriteDocumentsService.getFavoriteDocuments();
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
            icon: Icon(_getFilterIcon()),
            onPressed: () {
              setState(() {
                _filterType = FilterType.values[(_filterType.index + 1) % FilterType.values.length];
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
            switch (_filterType) {
              case FilterType.recents:
                notes = state.notes
                    .where((note) => _recentDocumentIds.contains(note.id))
                    .toList();
                break;
              case FilterType.favorites:
                notes = state.notes
                    .where((note) => _favoriteDocumentIds.contains(note.id))
                    .toList();
                break;
              case FilterType.all:
              default:
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
                        .then((_) {
                      _getRecentDocuments();
                      _getFavoriteDocuments();
                    });
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

  IconData _getFilterIcon() {
    switch (_filterType) {
      case FilterType.recents:
        return Icons.history;
      case FilterType.favorites:
        return Icons.star;
      case FilterType.all:
      default:
        return Icons.list;
    }
  }
}
