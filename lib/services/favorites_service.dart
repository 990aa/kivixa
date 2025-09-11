import 'package:sqflite/sqflite.dart';

class FavoritesService {
  final Database db;
  FavoritesService(this.db);

  Future<void> addFavorite(
    Map<String, dynamic> config, {
    String? hotkey,
  }) async {
    await db.insert('favorites', {
      'config': config.toString(),
      'hotkey': hotkey,
    });
  }

  Future<void> removeFavorite(int id) async {
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    return await db.query('favorites', limit: 20);
  }

  Future<void> setHotkey(int id, String hotkey) async {
    await db.update(
      'favorites',
      {'hotkey': hotkey},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> batchLoadFavorites(List<int> ids) async {
    final idsStr = ids.join(',');
    return await db.rawQuery('SELECT * FROM favorites WHERE id IN ($idsStr)');
  }
}
