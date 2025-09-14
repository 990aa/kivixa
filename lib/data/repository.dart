import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:kivixa/data/database.dart';

// --- Interface Definition ---
abstract class Repository {
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
  Future<List<Map<String, dynamic>>> listPages({required int documentId, int? limit, int? offset});
  Future<Map<String, dynamic>?> getPage(int pageId);
  Future<int> createPage(Map<String, dynamic> data);
  Future<void> updatePage(int pageId, Map<String, dynamic> data);

  // Outline methods
  Future<List<Map<String, dynamic>>> listOutlines({required int documentId});
  Future<void> deleteOutline(int outlineId);

  // Comment methods
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

  // Generic/Utility methods
  Future<void> batchWrite(List<Future<void> Function()> operations);

  // TODO: Review if the following methods are still needed in this generic interface
  // or should be part of more specific repository interfaces if they are used elsewhere.
  Future<int> createNotebook(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getNotebook(int id);
  Future<List<Map<String, dynamic>>> listNotebooks({
    int? limit,
    int? offset,
  });
  Future<void> updateNotebook(int id, Map<String, dynamic> data);
  Future<void> deleteNotebook(int id);

  Future<void> updateUserSetting(String userId, String key, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> listUserSettings({
    String? userId,
    int? limit,
    int? offset,
  });

  Future<void> updatePageThumbnailMetadata(int pageId, Map<String, dynamic> metadata);
  Future<Map<String, dynamic>?> getPageThumbnail(int pageId);
  Future<Map<String, dynamic>?> getAsset(int assetId);
  Future<void> updateTextBlock(int textBlockId, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getTextBlock(int textBlockId);
}

// --- Drift Implementation of the Repository ---
class DocumentRepository implements Repository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  // --- Document Methods ---
  @override
  Future<int> createDocument(Map<String, dynamic> data) async {
    final title = data['name'] as String? ?? data['title'] as String? ?? 'Untitled Document';
    final companion = DocumentsCompanion.insert(title: title);
    final docData = await _db.into(_db.documents).insertReturning(companion);
    return docData.id;
  }

  @override
  Future<Map<String, dynamic>?> getDocument(int id) async {
    final docData = await (_db.select(_db.documents)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (docData != null) {
      return {'id': docData.id, 'name': docData.title}; // Assuming 'title' is the field name
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> listDocuments({
    int? notebookId, // TODO: Implement filtering if needed
    int? parentId,   // TODO: Implement filtering if needed
    String? orderBy,  // TODO: Implement ordering if needed
    int? limit,      // TODO: Implement limit if needed
    int? offset,     // TODO: Implement offset if needed
  }) async {
    final documentsData = await _db.select(_db.documents).get();
    return documentsData.map((doc) => {'id': doc.id, 'name': doc.title}).toList();
  }

  @override
  Future<void> updateDocument(int id, Map<String, dynamic> data) async {
    final title = data['name'] as String? ?? data['title'] as String?;
    if (title != null) {
      final companion = DocumentsCompanion(title: drift.Value(title));
      await (_db.update(_db.documents)..where((tbl) => tbl.id.equals(id))).write(companion);
    }
  }

  @override
  Future<void> deleteDocument(int id) async {
    await (_db.delete(_db.documents)..where((tbl) => tbl.id.equals(id))).go();
  }

  // --- Page Methods ---
  @override
  Future<List<Map<String, dynamic>>> listPages({required int documentId, int? limit, int? offset}) async {
    final query = _db.select(_db.pages)..where((tbl) => tbl.documentId.equals(documentId));
    // TODO: Add limit and offset if provided
    final pageEntries = await query.get();
    return pageEntries.map((entry) {
      return {
        'id': entry.id,
        'document_id': entry.documentId,
        // Add other relevant page properties from your PageData structure
      };
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getPage(int pageId) async {
    final pageData = await (_db.select(_db.pages)..where((tbl) => tbl.id.equals(pageId))).getSingleOrNull();
    if (pageData != null) {
      return {
        'id': pageData.id,
        'document_id': pageData.documentId,
        // ... other fields from your PageData
      };
    }
    return null;
  }

  @override
  Future<int> createPage(Map<String, dynamic> data) async {
    final documentId = data['document_id'] as int;
    final companion = PagesCompanion.insert(documentId: documentId /*, ... other fields */);
    final pageData = await _db.into(_db.pages).insertReturning(companion);
    return pageData.id;
  }

  @override
  Future<void> updatePage(int pageId, Map<String, dynamic> data) async {
    final documentId = data['document_id'] as int?;
    final companion = PagesCompanion(
      documentId: documentId != null ? drift.Value(documentId) : const drift.Value.absent(),
    );
    await (_db.update(_db.pages)..where((tbl) => tbl.id.equals(pageId))).write(companion);
  }

  // --- Outline Methods ---
  @override
  Future<List<Map<String, dynamic>>> listOutlines({required int documentId}) async {
    final outlineEntries = await (_db.select(_db.outlines)..where((tbl) => tbl.documentId.equals(documentId))).get();
    return outlineEntries.map((entry) {
      return {
        'id': entry.id,
        'documentId': entry.documentId,
        'data': entry.data,
      };
    }).toList();
  }

  @override
  Future<void> deleteOutline(int outlineId) async {
    await (_db.delete(_db.outlines)..where((tbl) => tbl.id.equals(outlineId))).go();
  }

  // --- Comment Methods ---
  @override
  Future<List<Map<String, dynamic>>> listComments({required int pageId}) async {
    final commentEntries = await (_db.select(_db.comments)..where((tbl) => tbl.pageId.equals(pageId))).get();
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
    await (_db.delete(_db.comments)..where((tbl) => tbl.id.equals(commentId))).go();
  }

  // --- PDF Annotation Methods ---
  @override
  Future<int> createPdfAnnotation(Map<String, dynamic> annotationData) async {
    // Assuming PdfAnnotationsCompanion is generated from a PdfAnnotations table
    // and that annotationData fields match the PdfAnnotation.toMap() structure.
    final companion = PdfAnnotationsCompanion.insert(
      documentId: annotationData['document_id'] as int,
      pageNumber: annotationData['page_number'] as int,
      rects: annotationData['rects'] as String, // This is a JSON string from PdfAnnotation.toMap
      type: annotationData['type'] as int, // This is an enum index from PdfAnnotation.toMap
      text: annotationData['text'] as String,
      provenance: annotationData['provenance'] as String, // JSON string from PdfAnnotation.toMap
    );
    final inserted = await _db.into(_db.pdfAnnotations).insertReturning(companion);
    return inserted.id;
  }

  @override
  Future<Map<String, dynamic>?> getPdfAnnotation(int annotationId) async {
    final data = await (_db.select(_db.pdfAnnotations)..where((tbl) => tbl.id.equals(annotationId))).getSingleOrNull();
    if (data != null) {
      // This map must match the structure expected by PdfAnnotation.fromMap
      return {
        'id': data.id,
        'document_id': data.documentId,
        'page_number': data.pageNumber,
        'rects': data.rects, // Should be a JSON string
        'type': data.type,   // Should be an int (enum index)
        'text': data.text,
        'provenance': data.provenance, // Should be a JSON string
      };
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> listPdfAnnotations({
    required int documentId,
    required int pageNumber,
  }) async {
    final query = _db.select(_db.pdfAnnotations)
      ..where((tbl) => tbl.documentId.equals(documentId) & tbl.pageNumber.equals(pageNumber));
    final results = await query.get();
    return results.map((data) {
      return {
        'id': data.id,
        'document_id': data.documentId,
        'page_number': data.pageNumber,
        'rects': data.rects,
        'type': data.type,
        'text': data.text,
        'provenance': data.provenance,
      };
    }).toList();
  }

  @override
  Future<void> deletePdfAnnotation(int annotationId) async {
    await (_db.delete(_db.pdfAnnotations)..where((tbl) => tbl.id.equals(annotationId))).go();
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
  
  // --- Stubs for other Repository methods (ensure these are implemented or removed if not needed) ---
  @override
  Future<int> createNotebook(Map<String, dynamic> data) async {
    throw UnimplementedError('createNotebook not implemented in DocumentRepository');
  }

  @override
  Future<Map<String, dynamic>?> getNotebook(int id) async {
    throw UnimplementedError('getNotebook not implemented in DocumentRepository');
  }

  @override
  Future<List<Map<String, dynamic>>> listNotebooks({int? limit, int? offset}) async {
    throw UnimplementedError('listNotebooks not implemented in DocumentRepository');
  }

  @override
  Future<void> updateNotebook(int id, Map<String, dynamic> data) async {
    throw UnimplementedError('updateNotebook not implemented in DocumentRepository');
  }

  @override
  Future<void> deleteNotebook(int id) async {
    throw UnimplementedError('deleteNotebook not implemented in DocumentRepository');
  }

  @override
  Future<void> updateUserSetting(String userId, String key, Map<String, dynamic> data) async {
    throw UnimplementedError('updateUserSetting not implemented in DocumentRepository');
  }

  @override
  Future<List<Map<String, dynamic>>> listUserSettings({String? userId, int? limit, int? offset}) async {
    throw UnimplementedError('listUserSettings not implemented in DocumentRepository');
  }

  @override
  Future<void> updatePageThumbnailMetadata(int pageId, Map<String, dynamic> metadata) async {
    throw UnimplementedError('updatePageThumbnailMetadata not implemented in DocumentRepository');
  }

  @override
  Future<Map<String, dynamic>?> getPageThumbnail(int pageId) async {
    throw UnimplementedError('getPageThumbnail not implemented in DocumentRepository');
  }

  @override
  Future<Map<String, dynamic>?> getAsset(int assetId) async {
    throw UnimplementedError('getAsset not implemented in DocumentRepository');
  }

  @override
  Future<void> updateTextBlock(int textBlockId, Map<String, dynamic> data) async {
    throw UnimplementedError('updateTextBlock not implemented in DocumentRepository');
  }

  @override
  Future<Map<String, dynamic>?> getTextBlock(int textBlockId) async {
    throw UnimplementedError('getTextBlock not implemented in DocumentRepository');
  }
  
  // --- Methods from original DocumentRepository that are not part of the refined Repository interface ---
  // Review if these are needed and how they should be exposed if so.

  Stream<List<DocumentData>> watchAllDriftDocuments() {
    return _db.select(_db.documents).watch();
  }

  Future<DocumentData> getDriftDocument(int id) {
    return (_db.select(_db.documents)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<DocumentData> createDriftDocument(String title) {
    return _db.into(_db.documents).insertReturning(DocumentsCompanion.insert(title: title));
  }

  Future<bool> updateDriftDocument(DocumentData entry) {
    final updates = DocumentsCompanion(
      title: drift.Value(entry.title),
    );
    return _db.update(_db.documents)
        .where((tbl) => tbl.id.equals(entry.id))
        .write(updates)
        .then((numberOfAffectedRows) => numberOfAffectedRows > 0);
  }

  Future<int> deleteDriftDocument(int id) {
    return (_db.delete(_db.documents)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateImage(int imageId, Map<String, dynamic> data) async {
    final companion = ImagesCompanion(
      assetPath: data.containsKey('asset_path') 
          ? drift.Value(data['asset_path'] as String)
          : const drift.Value.absent(),
      transform: data.containsKey('transform') 
          ? drift.Value(jsonEncode(data['transform'])) 
          : const drift.Value.absent(),
    );
    await (_db.update(_db.images)..where((tbl) => tbl.id.equals(imageId))).write(companion);
  }

  Future<Map<String, dynamic>?> getImage(int imageId) async {
    final imageData = await (_db.select(_db.images)..where((tbl) => tbl.id.equals(imageId))).getSingleOrNull();
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

  Future<Map<String, dynamic>?> getTemplate(int templateId) async {
    final templateData = await (_db.select(_db.templates)..where((tbl) => tbl.id.equals(templateId))).getSingleOrNull();
    if (templateData != null) {
      return {
        'id': templateData.id,
        'name': templateData.name,
        'content': templateData.content,
      };
    }
    return null;
  }

  Future<void> createMinimapTile(Map<String, dynamic> tileData) async {
    final documentId = tileData['document_id'] as int?;
    final x = tileData['x'] as int?;
    final y = tileData['y'] as int?;
    final dynamic rawData = tileData['data'];

    if (documentId == null || x == null || y == null || rawData == null) {
      // print('DocumentRepository.createMinimapTile: Missing required fields. $tileData');
      return;
    }
    final String jsonData = rawData is String ? rawData : jsonEncode(rawData);
    final companion = MinimapTilesCompanion.insert(
      documentId: documentId,
      x: x,
      y: y,
      data: jsonData,
    );
    await _db.into(_db.minimapTiles).insert(companion, mode: drift.InsertMode.replace);
  }
}
