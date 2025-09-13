import 'package:kivixa/data/database.dart';

class SearchResult {
  final String title;
  final String snippet;
  final String documentId;
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
    // This is a placeholder for the search logic.
    // A real implementation would query the database.
    return [];
  }
}
