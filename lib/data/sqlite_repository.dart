import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'repository.dart';

class SQLiteRepository implements Repository {
  final Database db;
  SQLiteRepository(this.db);

  // Notebooks
  @override
  Future<int> createNotebook(Map<String, dynamic> data) async {
    return await db.insert('notebooks', data);
  }

  @override
  Future<Map<String, dynamic>?> getNotebook(int id) async {
    final res = await db.query('notebooks', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> listNotebooks({
    int? limit,
    int? offset,
  }) async {
    return await db.query('notebooks', limit: limit, offset: offset);
  }

  @override
  Future<void> updateNotebook(int id, Map<String, dynamic> data) async {
    await db.update('notebooks', data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteNotebook(int id) async {
    await db.delete('notebooks', where: 'id = ?', whereArgs: [id]);
  }

  // Documents (example)
  @override
  Future<int> createDocument(Map<String, dynamic> data) async {
    return await db.insert('documents', data);
  }

  @override
  Future<Map<String, dynamic>?> getDocument(int id) async {
    final res = await db.query('documents', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments({
    int? notebookId,
    int? parentId,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    String? where;
    List<dynamic>? whereArgs;

    if (notebookId != null && parentId != null) {
      where = 'notebook_id = ? AND parent_id = ?';
      whereArgs = [notebookId, parentId];
    } else if (notebookId != null) {
      where = 'notebook_id = ?';
      whereArgs = [notebookId];
    } else if (parentId != null) {
      where = 'parent_id = ?';
      whereArgs = [parentId];
    }

    return await db.query(
      'documents',
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<void> updateDocument(int id, Map<String, dynamic> data) async {
    await db.update('documents', data, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteDocument(int id) async {
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // User Settings
  @override
  Future<void> updateUserSetting(String userId, String key, Map<String, dynamic> data) async {
    await db.update('user_settings', data, where: 'user_id = ? AND key = ?', whereArgs: [userId, key]);
  }

  @override
  Future<List<Map<String, dynamic>>> listUserSettings({
    String? userId,
    int? limit,
    int? offset,
  }) async {
    return await db.query(
      'user_settings',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      limit: limit,
      offset: offset,
    );
  }


  // ... Implement all other methods similarly ...

  @override
  Future<void> batchWrite(List<Function()> operations) async {
    await db.transaction((txn) async {
      for (final op in operations) {
        await op();
      }
    });
  }
}
