import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:kivixa/data/database.dart';

// --- Interface Definition ---
abstract class Repository {
  /// Returns a list of assets, optionally filtered by hash.
  Future<List<Map<String, dynamic>>> listAssets({String? hash});

  /// Creates a new asset and returns its id.
  Future<int> createAsset(Map<String, dynamic> assetData);
  // Layer methods
  Future<int> createLayer(Map<String, dynamic> data);
  Future<void> updateLayer(int layerId, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getLayer(int layerId);
  Future<List<Map<String, dynamic>>> listLayers({
    required int pageId,
    String? orderBy,
  });

  // Shape methods
  Future<void> updateShape(int shapeId, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getShape(int shapeId);
  // Document methods
  Future<int> createDocument(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getDocument(int id);
  Future<List<Map<String, dynamic>>> listDocuments({
    int? notebookId,
    int? parentId,
    String? orderBy,
    int? limit,
    int? offset,
  });
  Future<void> updateDocument(int id, Map<String, dynamic> data);
  Future<void> deleteDocument(int id);

  // Page methods
  Future<List<Map<String, dynamic>>> listPages({
    required int documentId,
    int? limit,
    int? offset,
  });
  Future<Map<String, dynamic>?> getPage(int pageId);
  Future<int> createPage(Map<String, dynamic> data);
  Future<void> updatePage(int pageId, Map<String, dynamic> data);

  // Outline methods
  Future<List<Map<String, dynamic>>> listOutlines({required int documentId});
  Future<int> createOutline(Map<String, dynamic> data); // Added
  Future<void> deleteOutline(int outlineId);

  // Comment methods
  Future<int> createComment(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> listComments({required int pageId});
  Future<void> deleteComment(int commentId);

  // PDF Annotation methods
  Future<int> createPdfAnnotation(Map<String, dynamic> annotationData);
  Future<Map<String, dynamic>?> getPdfAnnotation(int annotationId);
  Future<List<Map<String, dynamic>>> listPdfAnnotations({
    required int documentId,
    required int pageNumber,
  });
  Future<void> deletePdfAnnotation(int annotationId);

  // Image methods
  Future<Map<String, dynamic>?> getImage(int imageId);
  Future<void> updateImage(int imageId, Map<String, dynamic> data);

  // TextBlock methods
  Future<int> createTextBlock(Map<String, dynamic> data); // Added
  Future<Map<String, dynamic>?> getTextBlock(int textBlockId);
  Future<void> updateTextBlock(int textBlockId, Map<String, dynamic> data);

  // Generic/Utility methods
  /// Returns a lock object for a document, or null if not locked. Stub for multi_instance_guard.
  Future<dynamic> getDocumentLock(int documentId);
  Future<void> batchWrite(List<Future<void> Function()> operations);

  // TODO: Review if the following methods are still needed in this generic interface
  Future<int> createNotebook(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getNotebook(int id);
  Future<List<Map<String, dynamic>>> listNotebooks({int? limit, int? offset});
  Future<void> updateNotebook(int id, Map<String, dynamic> data);
  Future<void> deleteNotebook(int id);

  Future<void> updateUserSetting(
    String userId,
    String key,
    Map<String, dynamic> data,
  );
  Future<List<Map<String, dynamic>>> listUserSettings({
    String? userId,
    int? limit,
    int? offset,
  });

  Future<void> updatePageThumbnailMetadata(
    int pageId,
    Map<String, dynamic> metadata,
  );
  Future<Map<String, dynamic>?> getPageThumbnail(int pageId);
  Future<Map<String, dynamic>?> getAsset(int assetId);
}

// --- Drift Implementation of the Repository ---
class DocumentRepository implements Repository {
  @override
  Future<List<Map<String, dynamic>>> listAssets({String? hash}) async {
    // Example implementation: query assets table, filter by hash if provided
    final query = _db.select(_db.assets);
    if (hash != null) {
      query.where((tbl) => tbl.hash.equals(hash));
    }
    final results = await query.get();
    return results
        .map(
          (row) => {
            'id': row.id,
            'path': row.path,
            'size': row.size,
            'hash': row.hash,
            'mime': row.mime,
            'created_at': row.createdAt.millisecondsSinceEpoch,
          },
        )
        .toList();
  }

  @override
  Future<int> createAsset(Map<String, dynamic> assetData) async {
    // Example implementation: insert into assets table
    final companion = AssetsCompanion.insert(
      path: assetData['path'] as String,
      size: assetData['size'] as int,
      hash: assetData['hash'] as String,
      mime: assetData['mime'] as String? ?? '',
      createdAt: drift.Value(
        DateTime.fromMillisecondsSinceEpoch(
          assetData['created_at'] as int? ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    );
    final row = await _db.into(_db.assets).insertReturning(companion);
    return row.id;
  }

  // --- Layer Methods ---
  @override
  Future<int> createLayer(Map<String, dynamic> data) async {
    throw UnimplementedError(
      'createLayer not implemented in DocumentRepository',
    );
  }

  @override
  Future<void> updateLayer(int layerId, Map<String, dynamic> data) async {
    throw UnimplementedError(
      'updateLayer not implemented in DocumentRepository',
    );
  }

  @override
  Future<Map<String, dynamic>?> getLayer(int layerId) async {
    throw UnimplementedError('getLayer not implemented in DocumentRepository');
  }

  @override
  Future<List<Map<String, dynamic>>> listLayers({
    required int pageId,
    String? orderBy,
  }) async {
    throw UnimplementedError(
      'listLayers not implemented in DocumentRepository',
    );
  }

  // --- Shape Methods ---
  @override
  Future<void> updateShape(int shapeId, Map<String, dynamic> data) async {
    throw UnimplementedError(
      'updateShape not implemented in DocumentRepository',
    );
  }

  @override
  Future<Map<String, dynamic>?> getShape(int shapeId) async {
    throw UnimplementedError('getShape not implemented in DocumentRepository');
  }

  // --- DB getter for compatibility (returns underlying Drift database instance) ---
  AppDatabase get db => _db;
  @override
  Future<dynamic> getDocumentLock(int documentId) async {
    // TODO: Implement actual locking logic if needed
    return null;
  }

  DocumentRepository(this._db);

  final AppDatabase _db;

  // --- Document Methods ---
  @override
  Future<int> createDocument(Map<String, dynamic> data) async {
    final title =
        data['name'] as String? ??
        data['title'] as String? ??
        'Untitled Document';
    final companion = DocumentsCompanion.insert(title: title);
    final docData = await _db.into(_db.documents).insertReturning(companion);
    return docData.id;
  }

  @override
  Future<Map<String, dynamic>?> getDocument(int id) async {
    final docData = await (_db.select(
      _db.documents,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (docData != null) {
      return {'id': docData.id, 'name': docData.title};
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments({
    int? notebookId,
    int? parentId,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final documentsData = await _db.select(_db.documents).get();
    return documentsData
        .map((doc) => {'id': doc.id, 'name': doc.title})
        .toList();
  }

  @override
  Future<void> updateDocument(int id, Map<String, dynamic> data) async {
    final title = data['name'] as String? ?? data['title'] as String?;
    if (title != null) {
      final companion = DocumentsCompanion(title: drift.Value(title));
      await (_db.update(
        _db.documents,
      )..where((tbl) => tbl.id.equals(id))).write(companion);
    }
  }

  @override
  Future<void> deleteDocument(int id) async {
    await (_db.delete(_db.documents)..where((tbl) => tbl.id.equals(id))).go();
  }

  // --- Page Methods ---
  @override
  Future<List<Map<String, dynamic>>> listPages({
    required int documentId,
    int? limit,
    int? offset,
  }) async {
    final query = _db.select(_db.pages)
      ..where((tbl) => tbl.documentId.equals(documentId));
    final pageEntries = await query.get();
    return pageEntries.map((entry) {
      return {'id': entry.id, 'document_id': entry.documentId};
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getPage(int pageId) async {
    final pageData = await (_db.select(
      _db.pages,
    )..where((tbl) => tbl.id.equals(pageId))).getSingleOrNull();
    if (pageData != null) {
      return {'id': pageData.id, 'document_id': pageData.documentId};
    }
    return null;
  }

  @override
  Future<int> createPage(Map<String, dynamic> data) async {
    final documentId = data['document_id'] as int;
    final companion = PagesCompanion.insert(documentId: documentId);
    final pageData = await _db.into(_db.pages).insertReturning(companion);
    return pageData.id;
  }

  @override
  Future<void> updatePage(int pageId, Map<String, dynamic> data) async {
    final documentId = data['document_id'] as int?;
    final companion = PagesCompanion(
      documentId: documentId != null
          ? drift.Value(documentId)
          : const drift.Value.absent(),
    );
    await (_db.update(
      _db.pages,
    )..where((tbl) => tbl.id.equals(pageId))).write(companion);
  }

  // --- Outline Methods ---
  @override
  Future<List<Map<String, dynamic>>> listOutlines({
    required int documentId,
  }) async {
    final outlineEntries = await (_db.select(
      _db.outlines,
    )..where((tbl) => tbl.documentId.equals(documentId))).get();
    return outlineEntries.map((entry) {
      return {
        'id': entry.id,
        'documentId': entry.documentId,
        'data': entry.data, // This is a JSON string
      };
    }).toList();
  }

  @override
  Future<int> createOutline(Map<String, dynamic> data) async {
    final outlineJsonData = {
      'title': data['title'],
      'parent_id': data['parent_id'],
    };
    final companion = OutlinesCompanion.insert(
      documentId: data['document_id'] as int,
      data: jsonEncode(outlineJsonData),
    );
    final outline = await _db.into(_db.outlines).insertReturning(companion);
    return outline.id;
  }

  @override
  Future<void> deleteOutline(int outlineId) async {
    await (_db.delete(
      _db.outlines,
    )..where((tbl) => tbl.id.equals(outlineId))).go();
  }

  // --- Comment Methods ---
  @override
  Future<int> createComment(Map<String, dynamic> data) async {
    final companion = CommentsCompanion.insert(
      pageId: data['page_id'] as int,
      content: data['content'] as String,
      createdAt: data['created_at'] != null
          ? drift.Value(
              DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
            )
          : const drift.Value.absent(),
    );
    final comment = await _db.into(_db.comments).insertReturning(companion);
    return comment.id;
  }

  @override
  Future<List<Map<String, dynamic>>> listComments({required int pageId}) async {
    final commentEntries = await (_db.select(
      _db.comments,
    )..where((tbl) => tbl.pageId.equals(pageId))).get();
    return commentEntries.map((entry) {
      return {
        'id': entry.id,
        'pageId': entry.pageId,
        'content': entry.content,
        'created_at': entry.createdAt.toIso8601String(),
      };
    }).toList();
  }

  @override
  Future<void> deleteComment(int commentId) async {
    await (_db.delete(
      _db.comments,
    )..where((tbl) => tbl.id.equals(commentId))).go();
  }

  // --- PDF Annotation Methods ---
  @override
  Future<int> createPdfAnnotation(Map<String, dynamic> annotationData) async {
    throw UnimplementedError(
      'PDF annotation support is not implemented: missing PdfAnnotationsCompanion and pdfAnnotations table.',
    );
  }

  @override
  Future<Map<String, dynamic>?> getPdfAnnotation(int annotationId) async {
    throw UnimplementedError(
      'PDF annotation support is not implemented: missing pdfAnnotations table.',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listPdfAnnotations({
    required int documentId,
    required int pageNumber,
  }) async {
    throw UnimplementedError(
      'PDF annotation support is not implemented: missing pdfAnnotations table.',
    );
  }

  @override
  Future<void> deletePdfAnnotation(int annotationId) async {
    throw UnimplementedError(
      'PDF annotation support is not implemented: missing pdfAnnotations table.',
    );
  }

  // --- Image Methods ---
  @override
  Future<void> updateImage(int imageId, Map<String, dynamic> data) async {
    final companion = ImagesCompanion(
      assetPath: data.containsKey('asset_path')
          ? drift.Value(data['asset_path'] as String)
          : const drift.Value.absent(),
      transform: data.containsKey('transform')
          ? drift.Value(jsonEncode(data['transform']))
          : const drift.Value.absent(),
    );
    await (_db.update(
      _db.images,
    )..where((tbl) => tbl.id.equals(imageId))).write(companion);
  }

  @override
  Future<Map<String, dynamic>?> getImage(int imageId) async {
    final imageData = await (_db.select(
      _db.images,
    )..where((tbl) => tbl.id.equals(imageId))).getSingleOrNull();
    if (imageData != null) {
      return {
        'id': imageData.id,
        'asset_path': imageData.assetPath,
        'thumbnail_path': imageData.thumbnailPath,
        'transform': imageData.transform != null
            ? jsonDecode(imageData.transform!)
            : null,
      };
    }
    return null;
  }

  // --- TextBlock Methods ---
  @override
  Future<int> createTextBlock(Map<String, dynamic> data) async {
    final companion = TextBlocksCompanion.insert(
      layerId: data['layer_id'] as int,
      content: data['plain_text'] as String? ?? '',
    );
    final textBlock = await _db.into(_db.textBlocks).insertReturning(companion);
    return textBlock.id;
  }

  @override
  Future<Map<String, dynamic>?> getTextBlock(int textBlockId) async {
    final block = await (_db.select(
      _db.textBlocks,
    )..where((tbl) => tbl.id.equals(textBlockId))).getSingleOrNull();
    if (block != null) {
      return {
        'id': block.id,
        'layer_id': block.layerId,
        'plain_text': block.content,
        'styled_json': null,
      };
    }
    return null;
  }

  @override
  Future<void> updateTextBlock(
    int textBlockId,
    Map<String, dynamic> data,
  ) async {
    final String? plainText = data['plain_text'] as String?;
    drift.Value<String> contentValue = const drift.Value.absent();
    if (plainText != null) {
      contentValue = drift.Value(plainText);
    }

    if (contentValue != const drift.Value.absent()) {
      final companion = TextBlocksCompanion(content: contentValue);
      await (_db.update(
        _db.textBlocks,
      )..where((tbl) => tbl.id.equals(textBlockId))).write(companion);
    }
  }

  // --- Generic/Utility Methods ---
  @override
  Future<void> batchWrite(List<Future<void> Function()> operations) async {
    await _db.transaction(() async {
      for (final operation in operations) {
        await operation();
      }
    });
  }

  // --- Stubs for other Repository methods ---
  @override
  Future<int> createNotebook(Map<String, dynamic> data) async {
    throw UnimplementedError(
      'createNotebook not implemented in DocumentRepository',
    );
  }

  @override
  Future<Map<String, dynamic>?> getNotebook(int id) async {
    throw UnimplementedError(
      'getNotebook not implemented in DocumentRepository',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listNotebooks({
    int? limit,
    int? offset,
  }) async {
    throw UnimplementedError(
      'listNotebooks not implemented in DocumentRepository',
    );
  }

  @override
  Future<void> updateNotebook(int id, Map<String, dynamic> data) async {
    throw UnimplementedError(
      'updateNotebook not implemented in DocumentRepository',
    );
  }

  @override
  Future<void> deleteNotebook(int id) async {
    throw UnimplementedError(
      'deleteNotebook not implemented in DocumentRepository',
    );
  }

  @override
  Future<void> updateUserSetting(
    String userId,
    String key,
    Map<String, dynamic> data,
  ) async {
    throw UnimplementedError(
      'updateUserSetting not implemented in DocumentRepository',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listUserSettings({
    String? userId,
    int? limit,
    int? offset,
  }) async {
    throw UnimplementedError(
      'listUserSettings not implemented in DocumentRepository',
    );
  }

  @override
  Future<void> updatePageThumbnailMetadata(
    int pageId,
    Map<String, dynamic> metadata,
  ) async {
    throw UnimplementedError(
      'updatePageThumbnailMetadata not implemented in DocumentRepository',
    );
  }

  @override
  Future<Map<String, dynamic>?> getPageThumbnail(int pageId) async {
    throw UnimplementedError(
      'getPageThumbnail not implemented in DocumentRepository',
    );
  }

  @override
  Future<Map<String, dynamic>?> getAsset(int assetId) async {
    throw UnimplementedError('getAsset not implemented in DocumentRepository');
  }

  // --- Methods from original DocumentRepository that are not part of the refined Repository interface ---
  Stream<List<DocumentData>> watchAllDriftDocuments() {
    return _db.select(_db.documents).watch();
  }

  Future<DocumentData> getDriftDocument(int id) {
    return (_db.select(
      _db.documents,
    )..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<DocumentData> createDriftDocument(String title) {
    return _db
        .into(_db.documents)
        .insertReturning(DocumentsCompanion.insert(title: title));
  }

  Future<bool> updateDriftDocument(DocumentData entry) {
    final updates = DocumentsCompanion(title: drift.Value(entry.title));
    final updateStmt = _db.update(_db.documents);
    updateStmt.where((tbl) => tbl.id.equals(entry.id));
    return updateStmt
        .write(updates)
        .then((numberOfAffectedRows) => numberOfAffectedRows > 0);
  }

  Future<int> deleteDriftDocument(int id) {
    return (_db.delete(_db.documents)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<Map<String, dynamic>?> getTemplate(int templateId) async {
    throw UnimplementedError(
      'getTemplate not implemented. Requires Templates table in DB.',
    );
  }

  Future<void> createMinimapTile(Map<String, dynamic> tileData) async {
    final documentId = tileData['document_id'] as int?;
    final x = tileData['x'] as int?;
    final y = tileData['y'] as int?;
    final dynamic rawData = tileData['data'];

    if (documentId == null || x == null || y == null || rawData == null) {
      return;
    }
    final String jsonData = rawData is String ? rawData : jsonEncode(rawData);
    final companion = MinimapTilesCompanion.insert(
      documentId: documentId,
      x: x,
      y: y,
      data: jsonData,
    );
    await _db
        .into(_db.minimapTiles)
        .insert(companion, mode: drift.InsertMode.replace);
  }
}
