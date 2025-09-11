import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';

class CommentsService {
  final DatabaseProvider _provider = DatabaseProvider();

  Future<List<Map<String, dynamic>>> searchComments(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await _provider.database;
    return await db.rawQuery(
      'SELECT * FROM comments_fts WHERE comments_fts MATCH ? ORDER BY created_at DESC LIMIT ? OFFSET ?',
      [query, limit, offset],
    );
  }

  Future<void> batchInsert(List<Map<String, dynamic>> comments) async {
    final db = await _provider.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final comment in comments) {
        batch.insert(
          'comments',
          comment,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
