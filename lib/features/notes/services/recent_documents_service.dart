import 'package:shared_preferences/shared_preferences.dart';

class RecentDocumentsService {
  static const _key = 'recent_documents';
  static const _maxRecents = 10;

  Future<void> addRecentDocument(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final recents = prefs.getStringList(_key) ?? [];
    recents.remove(documentId);
    recents.insert(0, documentId);
    if (recents.length > _maxRecents) {
      recents.removeLast();
    }
    await prefs.setStringList(_key, recents);
  }

  Future<List<String>> getRecentDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}
