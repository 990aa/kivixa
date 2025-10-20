import 'package:flutter/material.dart';
import '../database/database.dart';
import '../services/database_service.dart';

/// Search delegate for searching notes
class NotesSearchDelegate extends SearchDelegate<Note?> {
  final DatabaseService databaseService;
  final bool useFullTextSearch;

  NotesSearchDelegate({
    required this.databaseService,
    this.useFullTextSearch = true,
  }) : super(
         searchFieldLabel: 'Search notes...',
         keyboardType: TextInputType.text,
         textInputAction: TextInputAction.search,
       );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Enter a search term',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<List<Note>>(
      future: _performSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No results found for "$query"',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final note = results[index];
            return _buildNoteListTile(context, note);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return FutureBuilder<List<Note>>(
        future: databaseService.getAllNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentNotes = snapshot.data?.take(5).toList() ?? [];

          if (recentNotes.isEmpty) {
            return const Center(
              child: Text(
                'No notes yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Recent Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...recentNotes.map((note) => _buildNoteListTile(context, note)),
            ],
          );
        },
      );
    }

    return buildResults(context);
  }

  Widget _buildNoteListTile(BuildContext context, Note note) {
    final contentPreview = note.content ?? '';
    final highlightedTitle = _highlightText(note.title, query);
    final highlightedContent = _highlightText(
      contentPreview.length > 100
          ? '${contentPreview.substring(0, 100)}...'
          : contentPreview,
      query,
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        child: Icon(Icons.note, color: Theme.of(context).primaryColor),
      ),
      title: highlightedTitle,
      subtitle: highlightedContent,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatDate(note.modifiedAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (note.isSynced)
            const Icon(Icons.cloud_done, size: 16, color: Colors.green),
        ],
      ),
      onTap: () => close(context, note),
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text);
    }

    final matches = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        matches.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (index > start) {
        matches.add(TextSpan(text: text.substring(start, index)));
      }

      matches.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
            backgroundColor: Colors.yellow,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(text: TextSpan(children: matches));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<List<Note>> _performSearch(String query) async {
    try {
      if (useFullTextSearch) {
        return await databaseService.searchNotesFullText(query);
      } else {
        return await databaseService.searchNotes(query);
      }
    } catch (e) {
      // Fallback to basic search if FTS5 fails
      return await databaseService.searchNotes(query);
    }
  }
}

/// Extension method to show search
extension SearchExtension on BuildContext {
  Future<Note?> showNotesSearch({
    required DatabaseService databaseService,
    bool useFullTextSearch = true,
  }) {
    return showSearch<Note?>(
      context: this,
      delegate: NotesSearchDelegate(
        databaseService: databaseService,
        useFullTextSearch: useFullTextSearch,
      ),
    );
  }
}
