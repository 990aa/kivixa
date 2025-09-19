import 'package:shared_preferences/shared_preferences.dart';

class FavoriteDocumentsService {
  static const _key = 'favorite_documents';

  Future<void> addFavoriteDocument(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    if (!favorites.contains(documentId)) {
      favorites.add(documentId);
      await prefs.setStringList(_key, favorites);
    }
  }

  Future<void> removeFavoriteDocument(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    favorites.remove(documentId);
    await prefs.setStringList(_key, favorites);
  }

  Future<List<String>> getFavoriteDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<bool> isFavorite(String documentId) async {
    final favorites = await getFavoriteDocuments();
    return favorites.contains(documentId);
  }
}
