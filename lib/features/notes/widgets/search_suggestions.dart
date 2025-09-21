import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/search_bloc.dart';

class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final List<String> history;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (history.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'History',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Wrap(
            spacing: 8.0,
            children: history
                .map(
                  (item) => Chip(
                    label: Text(item),
                    onDeleted: () {
                      // TODO: Implement delete history item
                    },
                  ),
                )
                .toList(),
          ),
          TextButton(
            onPressed: () {
              context.read<SearchBloc>().add(ClearSearchHistory());
            },
            child: const Text('Clear History'),
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Suggestions',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ...suggestions.map(
            (suggestion) => ListTile(
              title: Text(
                suggestion,
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                context.read<SearchBloc>().add(SearchSubmitted(suggestion));
              },
            ),
          ),
        ],
      ],
    );
  }
}
