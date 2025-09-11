import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';

class PageFlowManager {
  final DatabaseProvider _provider = DatabaseProvider();

  Future<void> setMode(int documentId, String mode) async {
    final db = await _provider.database;
    await db.insert('user_settings', {
      'key': 'pageflow_mode_$documentId',
      'value': mode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getMode(int documentId) async {
    final db = await _provider.database;
    final result = await db.query(
      'user_settings',
      where: 'key = ?',
      whereArgs: ['pageflow_mode_$documentId'],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  Future<Map<String, dynamic>> insertPage(
    int documentId,
    int pageNumber,
  ) async {
    final db = await _provider.database;
    final id = await db.insert('pages', {
      'document_id': documentId,
      'page_number': pageNumber,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    });
    final page = await db.query('pages', where: 'id = ?', whereArgs: [id]);
    return page.first;
  }
}
