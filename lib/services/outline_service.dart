import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';

class OutlineService {
  final DatabaseProvider _provider = DatabaseProvider();

  Future<List<Map<String, dynamic>>> searchOutlines(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _provider.database;
    return await db.rawQuery(
      'SELECT * FROM outlines_fts WHERE outlines_fts MATCH ? ORDER BY updated_at DESC LIMIT ? OFFSET ?',
      [query, limit, offset],
    );
  }

  Future<void> batchInsert(List<Map<String, dynamic>> outlines) async {
    final db = await _provider.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final outline in outlines) {
        batch.insert(
          'outlines',
          outline,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
