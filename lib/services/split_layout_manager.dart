import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';

class SplitLayoutManager {
  final DatabaseProvider _provider = DatabaseProvider();

  Future<void> saveLayoutState(String layoutId, String state) async {
    final db = await _provider.database;
    await db.insert('user_settings', {
      'key': 'split_layout_$layoutId',
      'value': state,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> loadLayoutState(String layoutId) async {
    final db = await _provider.database;
    final result = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: ['split_layout_$layoutId'],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }
}
