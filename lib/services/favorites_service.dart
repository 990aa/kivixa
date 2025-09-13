// FavoritesService: Stores up to 20 favorites and action_shortcuts for hotkey binding.
class FavoriteEntry {
  final String id;
  final String type; // tool, preset, color
  final String value;

  FavoriteEntry({required this.id, required this.type, required this.value});
}

class ActionShortcut {
  final String action;
  final String hotkey;

  ActionShortcut({required this.action, required this.hotkey});
}

class FavoritesService {
  final List<FavoriteEntry> _favorites = [];
  final List<ActionShortcut> _actionShortcuts = [];

  // Add a favorite (max 20)
  void addFavorite(FavoriteEntry entry) {
    if (_favorites.length < 20 && !_favorites.any((e) => e.id == entry.id)) {
      _favorites.add(entry);
    }
  }

  // Remove a favorite
  void removeFavorite(String id) {
    _favorites.removeWhere((e) => e.id == id);
  }

  // Get all favorites
  List<FavoriteEntry> getFavorites() => List.unmodifiable(_favorites);

  // Add or update an action shortcut
  void setActionShortcut(ActionShortcut shortcut) {
    _actionShortcuts.removeWhere((s) => s.action == shortcut.action);
    _actionShortcuts.add(shortcut);
  }

  // Get all action shortcuts
  List<ActionShortcut> getActionShortcuts() =>
      List.unmodifiable(_actionShortcuts);

  // Single-query retrieval for UI hydration
  Map<String, dynamic> getAll() => {
    'favorites': getFavorites(),
    'actionShortcuts': getActionShortcuts(),
  };
}
