import 'dart:async';
import 'package:kivixa/data/database.dart';

class DocumentRepository {
  DocumentRepository(this._db);

  final AppDatabase _db;

  Stream<List<DocumentData>> watchDocuments() {
    return _db.select(_db.documents).watch();
  }

  Future<DocumentData> getDocument(int id) {
    return (_db.select(_db.documents)..where((tbl) => tbl.id.equals(id))).getSingle();
  }

  Future<DocumentData> createDocument(String title) {
    return _db.into(_db.documents).insertReturning(DocumentsCompanion.insert(title: title));
  }

  Future<bool> updateDocument(DocumentData entry) {
    // TODO: Consider if this should take specific fields or a Companion for more targeted updates.
    // If DocumentData can have an 'is_infinite' field, this is where it could be set.
    // Example: await _db.update(_db.documents).replace(entry.copyWith(isInfinite: true));
    return _db.update(_db.documents).replace(entry);
  }

  Future<int> deleteDocument(int id) {
    return (_db.delete(_db.documents)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<Map<String, dynamic>>> listPages({required int documentId}) async {
    // TODO: Implement database query to fetch pages for the documentId
    // Example (assuming you have a 'pages' table and a PageData class in your AppDatabase):
    // final pageEntries = await (_db.select(_db.pages)..where((tbl) => tbl.documentId.equals(documentId))).get();
    // return pageEntries.map((entry) => {
    //   'id': entry.id,
    //   // Add other relevant page properties here, e.g., 'pageNumber': entry.pageNumber
    // }).toList();
    print('DocumentRepository.listPages called with documentId: $documentId - Needs actual implementation!');
    return []; // Placeholder: Returns an empty list until implemented
  }

  Future<void> updateImage(int imageId, Map<String, dynamic> data) async {
    // TODO: Implement database logic to update image metadata (e.g., asset_path, transform)
    // This might involve updating a specific table for images or a field in your documents/pages table.
    // Example (assuming an 'images' table):
    // final companion = ImagesCompanion(
    //   assetPath: data.containsKey('asset_path') ? Value(data['asset_path']) : const Value.absent(),
    //   transform: data.containsKey('transform') ? Value(jsonEncode(data['transform'])) : const Value.absent(),
    // );
    // await (_db.update(_db.images)..where((tbl) => tbl.id.equals(imageId))).write(companion);
    print('DocumentRepository.updateImage called for imageId: $imageId with data: $data - Needs actual implementation!');
  }

  Future<Map<String, dynamic>?> getImage(int imageId) async {
    // TODO: Implement database logic to fetch image metadata.
    // This should return a map containing details like 'thumbnail_path', 'asset_path', etc.
    // Example (assuming an 'images' table):
    // final imageData = await (_db.select(_db.images)..where((tbl) => tbl.id.equals(imageId))).getSingleOrNull();
    // if (imageData != null) {
    //   return {
    //     'id': imageData.id,
    //     'asset_path': imageData.assetPath,
    //     'thumbnail_path': imageData.thumbnailPath,
    //     // 'transform': imageData.transform != null ? jsonDecode(imageData.transform) : null,
    //   };
    // }
    print('DocumentRepository.getImage called for imageId: $imageId - Needs actual implementation!');
    return null; // Placeholder: Returns null until implemented
  }

  Future<Map<String, dynamic>?> getTemplate(int templateId) async {
    // TODO: Implement database logic to fetch template data by templateId.
    // This should return a map, often containing the template content or structure.
    // Example (assuming a 'templates' table):
    // final templateData = await (_db.select(_db.templates)..where((tbl) => tbl.id.equals(templateId))).getSingleOrNull();
    // if (templateData != null) {
    //   return {
    //     'id': templateData.id,
    //     'name': templateData.name,
    //     'content': templateData.content, // Assuming content is stored (e.g., as JSON string)
    //   };
    // }
    print('DocumentRepository.getTemplate called for templateId: $templateId - Needs actual implementation!');
    return null; // Placeholder
  }

  Future<void> createMinimapTile(Map<String, dynamic> tileData) async {
    // TODO: Implement database logic to create/update a minimap tile.
    // tileData might contain { 'document_id': ..., 'x': ..., 'y': ..., 'data': ... }
    // Example (assuming a 'minimap_tiles' table):
    // final companion = MinimapTilesCompanion.insert(
    //   documentId: tileData['document_id'],
    //   x: tileData['x'],
    //   y: tileData['y'],
    //   data: jsonEncode(tileData['data']), // Assuming data is stored as JSON
    // );
    // await _db.into(_db.minimapTiles).insert(companion);
    print('DocumentRepository.createMinimapTile called with data: $tileData - Needs actual implementation!');
  }
}

// Added Repository interface based on SQLiteRepository methods
abstract class Repository {
  Future<int> createNotebook(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getNotebook(int id);
  Future<List<Map<String, dynamic>>> listNotebooks({
    int? limit,
    int? offset,
  });
  Future<void> updateNotebook(int id, Map<String, dynamic> data);
  Future<void> deleteNotebook(int id);

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

  Future<void> updateUserSetting(String userId, String key, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> listUserSettings({
    String? userId,
    int? limit,
    int? offset,
  });

  Future<void> batchWrite(List<Function()> operations);

  Future<void> updatePageThumbnailMetadata(int pageId, Map<String, dynamic> metadata);

  Future<List<Map<String, dynamic>>> listPages({required int documentId, int? limit, int? offset}); // Added this line
}
