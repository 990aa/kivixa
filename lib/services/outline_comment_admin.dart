import 'package:sqflite/sqflite.dart';

class OutlineCommentAdmin {
  final Database db;
  OutlineCommentAdmin(this.db);

  Future<void> clearAllComments(int documentId) async {
    await db.transaction((txn) async {
      await txn.delete(
        'comments',
        where: 'document_id = ?',
        whereArgs: [documentId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> batchExportComments(
    List<int> commentIds,
  ) async {
    return await db.query('comments', where: 'id IN (${commentIds.join(',')})');
  }

  Future<void> moveComments(List<int> commentIds, int targetDocumentId) async {
    await db.transaction((txn) async {
      for (final id in commentIds) {
        await txn.update(
          'comments',
          {'document_id': targetDocumentId},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getCommentsPaged(
    int documentId,
    int limit,
    int offset,
  ) async {
    return await db.query(
      'comments',
      where: 'document_id = ?',
      whereArgs: [documentId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }
}
