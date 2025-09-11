import 'notebook_model.dart';
import '../database/database_provider.dart';

class NotebookRepository {
  final DatabaseProvider _provider = DatabaseProvider();

  Future<int> insertNotebook(Notebook notebook) async {
    final db = await _provider.database;
    return await db.insert('notebooks', notebook.toJson());
  }

  Future<List<Notebook>> getAllNotebooks() async {
    final db = await _provider.database;
    final result = await db.query('notebooks');
    return result.map((json) => Notebook.fromJson(json)).toList();
  }

  Future<int> updateNotebook(Notebook notebook) async {
    final db = await _provider.database;
    return await db.update(
      'notebooks',
      notebook.toJson(),
      where: 'id = ?',
      whereArgs: [notebook.id],
    );
  }

  Future<int> deleteNotebook(int id) async {
    final db = await _provider.database;
    return await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
  }

  // Performance-critical bulk operation example
  Future<void> bulkInsertNotebooks(List<Notebook> notebooks) async {
    final db = await _provider.database;
    final batch = db.batch();
    for (final notebook in notebooks) {
      batch.insert('notebooks', notebook.toJson());
    }
    await batch.commit(noResult: true);
  }

  // Raw SQL for custom queries
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await _provider.database;
    return await db.rawQuery(sql, args);
  }
}
