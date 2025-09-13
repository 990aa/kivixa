// Repository interface for all entities in the normalized schema.
// Provides CRUD and batch APIs for notebooks, documents, pages, layers, strokes, text_blocks, images, shapes, assets, outlines, comments, links, templates, favorites, audio_clips, user_settings, ai_keys, page_thumbnails, redo_log, job_queue, minimap_tiles.

abstract class Repository {
  // Notebooks
  Future<int> createNotebook(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getNotebook(int id);
  Future<List<Map<String, dynamic>>> listNotebooks({int? limit, int? offset});
  Future<void> updateNotebook(int id, Map<String, dynamic> data);
  Future<void> deleteNotebook(int id);

  // Documents
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

  // Pages
  Future<int> createPage(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getPage(int id);
  Future<List<Map<String, dynamic>>> listPages({
    int? documentId,
    int? limit,
    int? offset,
  });
  Future<void> updatePage(int id, Map<String, dynamic> data);
  Future<void> deletePage(int id);

  // Layers
  Future<int> createLayer(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getLayer(int id);
  Future<List<Map<String, dynamic>>> listLayers({
    int? pageId,
    int? limit,
    int? offset,
  });
  Future<void> updateLayer(int id, Map<String, dynamic> data);
  Future<void> deleteLayer(int id);

  // Strokes (chunked)
  Future<int> createStrokeChunk(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getStrokeChunks(String strokeId);
  Future<void> deleteStroke(String strokeId);

  // Text Blocks
  Future<int> createTextBlock(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getTextBlock(int id);
  Future<List<Map<String, dynamic>>> listTextBlocks({
    int? layerId,
    int? limit,
    int? offset,
  });
  Future<void> updateTextBlock(int id, Map<String, dynamic> data);
  Future<void> deleteTextBlock(int id);

  // Images
  Future<int> createImage(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getImage(int id);
  Future<List<Map<String, dynamic>>> listImages({
    int? layerId,
    int? limit,
    int? offset,
  });
  Future<void> updateImage(int id, Map<String, dynamic> data);
  Future<void> deleteImage(int id);

  // Shapes
  Future<int> createShape(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getShape(int id);
  Future<List<Map<String, dynamic>>> listShapes({
    int? layerId,
    int? limit,
    int? offset,
  });
  Future<void> updateShape(int id, Map<String, dynamic> data);
  Future<void> deleteShape(int id);

  // Assets
  Future<int> createAsset(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getAsset(int id);
  Future<List<Map<String, dynamic>>> listAssets({
    String? hash,
    int? limit,
    int? offset,
  });
  Future<void> updateAsset(int id, Map<String, dynamic> data);
  Future<void> deleteAsset(int id);

  // Outlines
  Future<int> createOutline(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getOutline(int id);
  Future<List<Map<String, dynamic>>> listOutlines({
    int? documentId,
    int? limit,
    int? offset,
  });
  Future<void> updateOutline(int id, Map<String, dynamic> data);
  Future<void> deleteOutline(int id);

  // Comments
  Future<int> createComment(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getComment(int id);
  Future<List<Map<String, dynamic>>> listComments({
    int? pageId,
    int? limit,
    int? offset,
  });
  Future<void> updateComment(int id, Map<String, dynamic> data);
  Future<void> deleteComment(int id);

  // Links
  Future<int> createLink(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getLink(int id);
  Future<List<Map<String, dynamic>>> listLinks({
    int? fromPageId,
    int? toPageId,
    int? limit,
    int? offset,
  });
  Future<void> updateLink(int id, Map<String, dynamic> data);
  Future<void> deleteLink(int id);

  // Templates
  Future<int> createTemplate(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getTemplate(int id);
  Future<List<Map<String, dynamic>>> listTemplates({int? limit, int? offset});
  Future<void> updateTemplate(int id, Map<String, dynamic> data);
  Future<void> deleteTemplate(int id);

  // Favorites
  Future<int> createFavorite(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getFavorite(int id);
  Future<List<Map<String, dynamic>>> listFavorites({
    String? userId,
    int? limit,
    int? offset,
  });
  Future<void> deleteFavorite(int id);

  // Audio Clips
  Future<int> createAudioClip(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getAudioClip(int id);
  Future<List<Map<String, dynamic>>> listAudioClips({
    int? pageId,
    int? limit,
    int? offset,
  });
  Future<void> updateAudioClip(int id, Map<String, dynamic> data);
  Future<void> deleteAudioClip(int id);

  // User Settings
  Future<int> createUserSetting(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getUserSetting(int id);
  Future<List<Map<String, dynamic>>> listUserSettings({
    String? userId,
    int? limit,
    int? offset,
  });
  Future<void> updateUserSetting(String userId, String key, Map<String, dynamic> data);
  Future<void> deleteUserSetting(int id);

  // AI Keys
  Future<int> createAIKey(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getAIKey(int id);
  Future<List<Map<String, dynamic>>> listAIKeys({
    int? providerId,
    int? limit,
    int? offset,
  });
  Future<void> updateAIKey(int id, Map<String, dynamic> data);
  Future<void> deleteAIKey(int id);

  // Page Thumbnails
  Future<int> createPageThumbnail(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getPageThumbnail(int id);
  Future<List<Map<String, dynamic>>> listPageThumbnails({
    int? pageId,
    int? limit,
    int? offset,
  });
  Future<void> updatePageThumbnail(int id, Map<String, dynamic> data);
  Future<void> deletePageThumbnail(int id);

  Future<void> updatePageThumbnailMetadata(int pageId, Map<String, dynamic> metadata);

  // Redo Log
  Future<int> createRedoLog(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getRedoLog(int id);
  Future<List<Map<String, dynamic>>> listRedoLogs({
    String? entityType,
    int? entityId,
    int? limit,
    int? offset,
  });
  Future<void> deleteRedoLog(int id);

  // Job Queue
  Future<int> createJob(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getJob(int id);
  Future<List<Map<String, dynamic>>> listJobs({
    String? status,
    int? limit,
    int? offset,
  });
  Future<void> updateJob(int id, Map<String, dynamic> data);
  Future<void> deleteJob(int id);

  // Minimap Tiles
  Future<int> createMinimapTile(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getMinimapTile(int id);
  Future<List<Map<String, dynamic>>> listMinimapTiles({
    int? pageId,
    int? limit,
    int? offset,
  });
  Future<void> updateMinimapTile(int id, Map<String, dynamic> data);
  Future<void> deleteMinimapTile(int id);

  // Pdf Annotations
  Future<int> createPdfAnnotation(Map<String, dynamic> data);
  Future<Map<String, dynamic>?> getPdfAnnotation(int id);
  Future<List<Map<String, dynamic>>> listPdfAnnotations({
    int? documentId,
    int? pageNumber,
    int? limit,
    int? offset,
  });
  Future<void> updatePdfAnnotation(int id, Map<String, dynamic> data);
  Future<void> deletePdfAnnotation(int id);

  // Batch operations
  Future<void> batchWrite(List<Function()> operations);
}
