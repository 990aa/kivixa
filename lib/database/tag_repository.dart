import 'package:sqflite/sqflite.dart';
import '../database/drawing_database.dart';
import '../models/tag.dart';

/// Repository for tag operations
///
/// Handles all CRUD operations for tags and document-tag relationships
class TagRepository {
  /// Create tag
  Future<int> createTag(Tag tag) async {
    return await insert(tag);
  }

  /// Insert a new tag
  Future<int> insert(Tag tag) async {
    final db = await DrawingDatabase.database;
    return await db.insert(
      DrawingDatabase.tableTags,
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing tag
  Future<int> update(Tag tag) async {
    final db = await DrawingDatabase.database;
    return await db.update(
      DrawingDatabase.tableTags,
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  /// Delete a tag
  Future<int> delete(int id) async {
    final db = await DrawingDatabase.database;
    return await db.delete(
      DrawingDatabase.tableTags,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get tag by ID
  Future<Tag?> getById(int id) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableTags,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  /// Get tag by name
  Future<Tag?> getByName(String name) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableTags,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  /// Get all tags
  Future<List<Tag>> getAll() async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(DrawingDatabase.tableTags, orderBy: 'name ASC');

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// Get tags sorted by usage count
  Future<List<Tag>> getByPopularity() async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableTags,
      orderBy: 'use_count DESC, name ASC',
    );

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// Search tags by name
  Future<List<Tag>> searchByName(String query) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.tableTags,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// Add tag to document
  Future<void> addToDocument(int tagId, int documentId) async {
    final db = await DrawingDatabase.database;

    // Insert relationship
    await db.insert(
      DrawingDatabase.tableDocumentTags,
      {
        'document_id': documentId,
        'tag_id': tagId,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Increment use count
    await _incrementUseCount(tagId);
  }

  /// Remove tag from document
  Future<void> removeFromDocument(int tagId, int documentId) async {
    final db = await DrawingDatabase.database;

    await db.delete(
      DrawingDatabase.tableDocumentTags,
      where: 'document_id = ? AND tag_id = ?',
      whereArgs: [documentId, tagId],
    );

    // Decrement use count
    await _decrementUseCount(tagId);
  }

  /// Get tags for a specific document
  Future<List<Tag>> getDocumentTags(int documentId) async {
    final db = await DrawingDatabase.database;

    final maps = await db.rawQuery(
      '''
      SELECT t.* FROM ${DrawingDatabase.tableTags} t
      INNER JOIN ${DrawingDatabase.tableDocumentTags} dt ON t.id = dt.tag_id
      WHERE dt.document_id = ?
      ORDER BY t.name ASC
    ''',
      [documentId],
    );

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// Set tags for a document (replaces existing tags)
  Future<void> setDocumentTags(int documentId, List<int> tagIds) async {
    // Get current tags
    final currentTags = await getDocumentTags(documentId);
    final currentTagIds = currentTags.map((t) => t.id!).toSet();

    // Remove old tags
    for (final tagId in currentTagIds) {
      if (!tagIds.contains(tagId)) {
        await removeFromDocument(tagId, documentId);
      }
    }

    // Add new tags
    for (final tagId in tagIds) {
      if (!currentTagIds.contains(tagId)) {
        await addToDocument(tagId, documentId);
      }
    }
  }

  /// Get document count for a tag
  Future<int> getDocumentCount(int tagId) async {
    final db = await DrawingDatabase.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM ${DrawingDatabase.tableDocumentTags}
      WHERE tag_id = ?
    ''',
      [tagId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Increment tag use count
  Future<void> _incrementUseCount(int tagId) async {
    final db = await DrawingDatabase.database;
    await db.rawUpdate(
      '''
      UPDATE ${DrawingDatabase.tableTags}
      SET use_count = use_count + 1
      WHERE id = ?
    ''',
      [tagId],
    );
  }

  /// Decrement tag use count
  Future<void> _decrementUseCount(int tagId) async {
    final db = await DrawingDatabase.database;
    await db.rawUpdate(
      '''
      UPDATE ${DrawingDatabase.tableTags}
      SET use_count = MAX(0, use_count - 1)
      WHERE id = ?
    ''',
      [tagId],
    );
  }

  /// Get unused tags (no documents)
  Future<List<Tag>> getUnused() async {
    final db = await DrawingDatabase.database;

    final maps = await db.rawQuery('''
      SELECT t.* FROM ${DrawingDatabase.tableTags} t
      LEFT JOIN ${DrawingDatabase.tableDocumentTags} dt ON t.id = dt.tag_id
      WHERE dt.tag_id IS NULL
      ORDER BY t.name ASC
    ''');

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// Delete unused tags
  Future<int> deleteUnused() async {
    final db = await DrawingDatabase.database;

    return await db.rawDelete('''
      DELETE FROM ${DrawingDatabase.tableTags}
      WHERE id NOT IN (
        SELECT DISTINCT tag_id FROM ${DrawingDatabase.tableDocumentTags}
      )
    ''');
  }
}
