import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class SearchResultsList extends StatelessWidget {
  final List<dynamic> results;
  final String searchQuery;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: ListTile(
                  title: _buildHighlightedText(
                    results[index].toString(),
                    searchQuery,
                    context,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    BuildContext context,
  ) {
    if (query.isEmpty) {
      return Text(text, style: const TextStyle(color: Colors.white));
    }

    final theme = Theme.of(context);
    final highlightStyle = TextStyle(
      color: theme.colorScheme.secondary,
      fontWeight: FontWeight.bold,
    );
    final normalStyle = const TextStyle(color: Colors.white);

    final spans = <TextSpan>[];
    int start = 0;
    int indexOfQuery;

    while ((indexOfQuery = text.toLowerCase().indexOf(query.toLowerCase(), start)) != -1) {
      if (indexOfQuery > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfQuery),
          style: normalStyle,
        ));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfQuery, indexOfQuery + query.length),
        style: highlightStyle,
      ));
      start = indexOfQuery + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: normalStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
