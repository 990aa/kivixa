import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';
import '../domain/entities.dart';

class LibraryService {
  final DatabaseProvider _provider = DatabaseProvider();

  Future<List<Document>> getDocuments({
    int limit = 20,
    int offset = 0,
    String? search,
  }) async {
    final db = await _provider.database;
    final where = search != null ? 'title LIKE ?' : null;
    final whereArgs = search != null ? ['%$search%'] : null;
    final result = await db.query(
      'documents',
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'updated_at DESC',
    );
    return result
        .map(
          (json) => Document(
            id: json['id'] as int,
            title: json['title'] as String,
            createdAt: json['created_at'] as int,
            updatedAt: json['updated_at'] as int,
          ),
        )
        .toList();
  }

  Future<void> runInTransaction(
    Future<void> Function(Transaction txn) action,
  ) async {
    final db = await _provider.database;
    await db.transaction(action);
  }

  Future<void> moveDocumentToNotebook(int documentId, int notebookId) async {
    final db = await _provider.database;
    await db.update(
      'documents',
      {'notebook_id': notebookId},
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  // Add more folder/document operations as needed
}
