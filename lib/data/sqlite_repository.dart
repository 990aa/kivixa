import 'dart:async';
import 'dart:convert'; // For jsonEncode and jsonDecode
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

  @override
  Future<List<Map<String, dynamic>>> listPages({required int documentId, int? limit, int? offset}) async {
    return await db.query(
      'pages', // Assuming the table is named 'pages'
      where: 'document_id = ?', // Assuming the foreign key column is 'document_id'
      whereArgs: [documentId],
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<void> batchWrite(List<Function()> operations) async {
    await db.transaction((txn) async {
      for (final op in operations) {
        await op();
      }
    });
  }

  @override
  Future<void> updatePageThumbnailMetadata(int pageId, Map<String, dynamic> metadata) async {
    final String metadataJson = jsonEncode(metadata);
    await db.update(
      'pages', // Assuming the table is named 'pages'
      {'thumbnail_metadata': metadataJson}, // Assuming the column is 'thumbnail_metadata'
      where: 'id = ?', // Assuming the primary key column for pages is 'id'
      whereArgs: [pageId],
    );
  }

  @override
  Future<Map<String, dynamic>?> getPageThumbnail(int pageId) async {
    final List<Map<String, dynamic>> results = await db.query(
      'pages',
      columns: ['thumbnail_asset_id', 'thumbnail_metadata'], // Specify columns
      where: 'id = ?',
      whereArgs: [pageId],
      limit: 1, // Expecting a single page
    );

    if (results.isNotEmpty) {
      final pageData = results.first;
      final String? metadataJson = pageData['thumbnail_metadata'] as String?;
      Map<String, dynamic>? decodedMetadata;

      if (metadataJson != null && metadataJson.isNotEmpty) {
        try {
          decodedMetadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        } catch (e) {
          // print('Error decoding thumbnail_metadata for pageId $pageId: $e. Setting metadata to null.');
          decodedMetadata = null; // Explicitly set to null on error
        }
      }
      
      return {
        'asset_id': pageData['thumbnail_asset_id'],
        'metadata': decodedMetadata, // This will be null if JSON was null, empty, or invalid
      };
    }
    return null; // No page found
  }

  @override
  Future<Map<String, dynamic>?> getAsset(int assetId) async {
    final List<Map<String, dynamic>> results = await db.query(
      'assets', // Assuming the table is named 'assets'
      where: 'id = ?', // Assuming the primary key column is 'id'
      whereArgs: [assetId],
      limit: 1, // Expecting a single asset
    );

    if (results.isNotEmpty) {
      return results.first; // Return the first (and only) asset found
    }
    return null; // No asset found with the given id
  }

  // TextBlocks
  @override
  Future<Map<String, dynamic>?> getTextBlock(int textBlockId) async {
    final List<Map<String, dynamic>> results = await db.query(
      'text_blocks', // Assuming the table is named 'text_blocks'
      where: 'id = ?', // Assuming the primary key column is 'id'
      whereArgs: [textBlockId],
      limit: 1, // Expecting a single text block
    );

    if (results.isNotEmpty) {
      return results.first; // Return the first (and only) text block found
    }
    return null; // No text block found with the given id
  }

  @override
  Future<void> updateTextBlock(int textBlockId, Map<String, dynamic> data) async {
    await db.update(
      'text_blocks', // Assuming the table is named 'text_blocks'
      data,
      where: 'id = ?', // Assuming the primary key column is 'id'
      whereArgs: [textBlockId],
    );
  }
}
