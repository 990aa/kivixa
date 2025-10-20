import 'package:sqflite/sqflite.dart';
import '../database/drawing_database.dart';
import '../models/drawing_document.dart';
import '../models/tag.dart';

/// Sort options for documents
enum DocumentSortBy {
  nameAsc,
  nameDesc,
  dateCreatedDesc,
  dateCreatedAsc,
  dateModifiedDesc,
  dateModifiedAsc,
  sizeAsc,
  sizeDesc,
}

/// Repository for document operations
/// 
/// Handles all CRUD operations for documents with advanced querying
class DocumentRepository {
  /// Insert a new document
  Future<int> insert(DrawingDocument document) async {
    final db = await DrawingDatabase.database;
    return await db.insert(
      DrawingDatabase.TABLE_DOCUMENTS,
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing document
  Future<int> update(DrawingDocument document) async {
    final db = await DrawingDatabase.database;
    return await db.update(
      DrawingDatabase.TABLE_DOCUMENTS,
      document.copyWith(modifiedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  /// Delete a document
  Future<int> delete(int id) async {
    final db = await DrawingDatabase.database;
    return await db.delete(
      DrawingDatabase.TABLE_DOCUMENTS,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get document by ID with tags
  Future<DrawingDocument?> getById(int id) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.TABLE_DOCUMENTS,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final document = DrawingDocument.fromMap(maps.first);
    document.tags = await _getDocumentTags(id);
    return document;
  }

  /// Get all documents with tags
  Future<List<DrawingDocument>> getAll({DocumentSortBy? sortBy}) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.TABLE_DOCUMENTS,
      orderBy: _getSortOrder(sortBy),
    );

    final documents = maps.map((map) => DrawingDocument.fromMap(map)).toList();

    // Load tags for each document
    for (final doc in documents) {
      doc.tags = await _getDocumentTags(doc.id!);
    }

    return documents;
  }

  /// Get documents in a specific folder
  Future<List<DrawingDocument>> getByFolder(
    int? folderId, {
    DocumentSortBy? sortBy,
  }) async {
    final db = await DrawingDatabase.database;

    final String whereClause;
    final List<dynamic>? whereArgs;

    if (folderId == null) {
      whereClause = 'folder_id IS NULL';
      whereArgs = null;
    } else {
      whereClause = 'folder_id = ?';
      whereArgs = [folderId];
    }

    final maps = await db.query(
      DrawingDatabase.TABLE_DOCUMENTS,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: _getSortOrder(sortBy),
    );

    final documents = maps.map((map) => DrawingDocument.fromMap(map)).toList();

    for (final doc in documents) {
      doc.tags = await _getDocumentTags(doc.id!);
    }

    return documents;
  }

  /// Get favorite documents
  Future<List<DrawingDocument>> getFavorites({DocumentSortBy? sortBy}) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.TABLE_DOCUMENTS,
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: _getSortOrder(sortBy),
    );

    final documents = maps.map((map) => DrawingDocument.fromMap(map)).toList();

    for (final doc in documents) {
      doc.tags = await _getDocumentTags(doc.id!);
    }

    return documents;
  }

  /// Get recent documents
  Future<List<DrawingDocument>> getRecent({int limit = 10}) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.TABLE_DOCUMENTS,
      orderBy: 'last_opened_at DESC',
      limit: limit,
    );

    final documents = maps.map((map) => DrawingDocument.fromMap(map)).toList();

    for (final doc in documents) {
      doc.tags = await _getDocumentTags(doc.id!);
    }

    return documents;
  }

  /// Search documents by name
  Future<List<DrawingDocument>> searchByName(
    String query, {
    DocumentSortBy? sortBy,
  }) async {
    final db = await DrawingDatabase.database;
    final maps = await db.query(
      DrawingDatabase.TABLE_DOCUMENTS,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: _getSortOrder(sortBy),
    );

    final documents = maps.map((map) => DrawingDocument.fromMap(map)).toList();

    for (final doc in documents) {
      doc.tags = await _getDocumentTags(doc.id!);
    }

    return documents;
  }

  /// Get documents by tag
  Future<List<DrawingDocument>> getByTag(
    int tagId, {
    DocumentSortBy? sortBy,
  }) async {
    final db = await DrawingDatabase.database;

    final maps = await db.rawQuery('''
      SELECT d.* FROM ${DrawingDatabase.TABLE_DOCUMENTS} d
      INNER JOIN ${DrawingDatabase.TABLE_DOCUMENT_TAGS} dt ON d.id = dt.document_id
      WHERE dt.tag_id = ?
      ORDER BY ${_getSortOrder(sortBy)}
    ''', [tagId]);

    final documents = maps.map((map) => DrawingDocument.fromMap(map)).toList();

    for (final doc in documents) {
      doc.tags = await _getDocumentTags(doc.id!);
    }

    return documents;
  }

  /// Get documents by multiple tags (AND logic)
  Future<List<DrawingDocument>> getByTags(
    List<int> tagIds, {
    DocumentSortBy? sortBy,
  }) async {
    if (tagIds.isEmpty) return [];

    final db = await DrawingDatabase.database;

    final placeholders = List.filled(tagIds.length, '?').join(',');

    final maps = await db.rawQuery('''
      SELECT d.* FROM ${DrawingDatabase.TABLE_DOCUMENTS} d
      WHERE (
        SELECT COUNT(*) FROM ${DrawingDatabase.TABLE_DOCUMENT_TAGS} dt
        WHERE dt.document_id = d.id AND dt.tag_id IN ($placeholders)
      ) = ?
      ORDER BY ${_getSortOrder(sortBy)}
    ''', [...tagIds, tagIds.length]);

    final documents = maps.map((map) => DrawingDocument.fromMap(map)).toList();

    for (final doc in documents) {
      doc.tags = await _getDocumentTags(doc.id!);
    }

    return documents;
  }

  /// Move document to different folder
  Future<int> moveToFolder(int documentId, int? folderId) async {
    final db = await DrawingDatabase.database;
    return await db.update(
      DrawingDatabase.TABLE_DOCUMENTS,
      {
        'folder_id': folderId,
        'modified_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  /// Toggle favorite status
  Future<int> toggleFavorite(int documentId, bool isFavorite) async {
    final db = await DrawingDatabase.database;
    return await db.update(
      DrawingDatabase.TABLE_DOCUMENTS,
      {
        'is_favorite': isFavorite ? 1 : 0,
        'modified_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  /// Update last opened timestamp
  Future<int> updateLastOpened(int documentId) async {
    final db = await DrawingDatabase.database;
    return await db.update(
      DrawingDatabase.TABLE_DOCUMENTS,
      {
        'last_opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [documentId],
    );
  }

  /// Get document tags
  Future<List<Tag>> _getDocumentTags(int documentId) async {
    final db = await DrawingDatabase.database;

    final maps = await db.rawQuery('''
      SELECT t.* FROM ${DrawingDatabase.TABLE_TAGS} t
      INNER JOIN ${DrawingDatabase.TABLE_DOCUMENT_TAGS} dt ON t.id = dt.tag_id
      WHERE dt.document_id = ?
      ORDER BY t.name ASC
    ''', [documentId]);

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  /// Get sort order SQL clause
  String _getSortOrder(DocumentSortBy? sortBy) {
    switch (sortBy) {
      case DocumentSortBy.nameAsc:
        return 'name ASC';
      case DocumentSortBy.nameDesc:
        return 'name DESC';
      case DocumentSortBy.dateCreatedAsc:
        return 'created_at ASC';
      case DocumentSortBy.dateCreatedDesc:
        return 'created_at DESC';
      case DocumentSortBy.dateModifiedAsc:
        return 'modified_at ASC';
      case DocumentSortBy.dateModifiedDesc:
        return 'modified_at DESC';
      case DocumentSortBy.sizeAsc:
        return 'file_size ASC';
      case DocumentSortBy.sizeDesc:
        return 'file_size DESC';
      case null:
        return 'modified_at DESC'; // Default
    }
  }
}
