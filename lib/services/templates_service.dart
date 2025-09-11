import 'package:sqflite/sqflite.dart';
import '../data/database/database_provider.dart';
import 'dart:convert';

class TemplatesService {
  final DatabaseProvider _provider = DatabaseProvider();
  final Map<int, Map<String, dynamic>> _cache = {};

  Future<void> insertTemplate(Map<String, dynamic> template) async {
    final db = await _provider.database;
    final id = await db.insert(
      'templates',
      template,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _cache[id] = template;
  }

  Future<Map<String, dynamic>?> getTemplate(int id) async {
    if (_cache.containsKey(id)) return _cache[id];
    final db = await _provider.database;
    final result = await db.query(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      _cache[id] = result.first;
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllTemplates() async {
    final db = await _provider.database;
    final result = await db.query('templates');
    for (final row in result) {
      _cache[row['id'] as int] = row;
    }
    return result;
  }

  Future<void> importTemplateFromJson(String jsonStr) async {
    final template = json.decode(jsonStr) as Map<String, dynamic>;
    await insertTemplate(template);
  }

  Future<String> exportTemplateToJson(int id) async {
    final template = await getTemplate(id);
    if (template == null) throw Exception('Template not found');
    return json.encode(template);
  }
}
