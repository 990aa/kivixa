import 'package:kivixa/data/database.dart';
import 'package:drift/drift.dart';

class SearchResult {
  final String title;
  final String snippet;
  final int documentId;
  final int pageId;
  final double rank;

  SearchResult({
    required this.title,
    required this.snippet,
    required this.documentId,
    required this.pageId,
    required this.rank,
  });
}

class GlobalSearchService {
  final AppDatabase _db;

  GlobalSearchService(this._db);

  Future<List<SearchResult>> search(String query) async {
    final results = <SearchResult>[];

    // Search titles
    final titleQuery = _db.select(_db.documents)..where((tbl) => tbl.title.like('%$query%'));
    final titleResults = await titleQuery.get();
    for (final doc in titleResults) {
      results.add(SearchResult(
        title: doc.title,
        snippet: '',
        documentId: doc.id,
        pageId: 0, // No page context for title search
        rank: 1.0,
      ));
    }

    // Search outlines
    final outlineQuery = _db.select(_db.outlines)..where((tbl) => tbl.data.like('%$query%'));
    final outlineResults = await outlineQuery.get();
    for (final outline in outlineResults) {
      results.add(SearchResult(
        title: 'Outline',
        snippet: outline.data,
        documentId: outline.documentId,
        pageId: 0, // No page context for outline search
        rank: 0.8,
      ));
    }

    // Search comments
    final commentQuery = _db.select(_db.comments)..where((tbl) => tbl.content.like('%$query%'));
    final commentResults = await commentQuery.get();
    for (final comment in commentResults) {
      results.add(SearchResult(
        title: 'Comment',
        snippet: comment.content,
        documentId: 0, // No document context for comment search
        pageId: comment.pageId,
        rank: 0.5,
      ));
    }

    // Search text blocks
    final textBlockQuery = _db.select(_db.textBlocks)..where((tbl) => tbl.content.like('%$query%'));
    final textBlockResults = await textBlockQuery.get();
    for (final textBlock in textBlockResults) {
      results.add(SearchResult(
        title: 'Text Block',
        snippet: textBlock.content,
        documentId: 0, // No document context for text block search
        pageId: 0, // No page context for text block search
        rank: 0.3,
      ));
    }

    results.sort((a, b) => b.rank.compareTo(a.rank));
    return results;
  }
}
