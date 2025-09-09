package com.kivixa.repository

import com.kivixa.database.dao.*
import com.kivixa.domain.Comment
import com.kivixa.domain.Document
import com.kivixa.domain.Outline
import com.kivixa.domain.Result
import com.kivixa.domain.SplitLayoutState
import com.kivixa.domain.TextBlock
import com.kivixa.filestore.FileStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.io.ByteArrayInputStream

class Repository(
    private val assetDao: AssetDao,
    private val commentDao: CommentDao,
    private val documentDao: DocumentDao,
    private val imageDao: ImageDao,
    private val layerDao: LayerDao,
    private val linkDao: LinkDao,
    private val notebookDao: NotebookDao,
    private val outlineDao: OutlineDao,
    private val pageDao: PageDao,
    private val shapeDao: ShapeDao,
    private val strokeChunkDao: StrokeChunkDao,
    private val templateDao: TemplateDao,
    private val textBlockDao: TextBlockDao,
    private val minimapTileDao: MinimapTileDao,
    private val userSettingDao: UserSettingDao,
    private val splitLayoutStateDao: SplitLayoutStateDao,
    private val pageThumbnailDao: PageThumbnailDao,
    private val fileStore: FileStore
) {

    private val LAST_OPENED_DOC_ID_KEY = "last_opened_document_id"

    // --- Document CRUD ---

    suspend fun createDocument(name: String, notebookId: Long): Long = withContext(Dispatchers.IO) {
        val newDocument = com.kivixa.database.model.Document(
            name = name,
            notebookId = notebookId
        )
        documentDao.insert(newDocument)
    }

    fun getDocument(id: Long): Flow<Document> {
        return documentDao.getDocument(id).map { it.toDomain() }
    }

    fun getDocumentsForNotebook(notebookId: Long): Flow<List<Document>> {
        return documentDao.getDocumentsForNotebook(notebookId).map { list -> list.map { it.toDomain() } }
    }

    suspend fun updateDocument(document: Document) = withContext(Dispatchers.IO) {
        documentDao.update(document.toEntity())
    }

    suspend fun deleteDocument(document: Document) = withContext(Dispatchers.IO) {
        // Clean up split layout state
        val splitState = splitLayoutStateDao.getSplitLayoutState().firstOrNull()
        if (splitState != null) {
            var changed = false
            var newSplitState = splitState
            if (splitState.pane1_docId == document.id) {
                newSplitState = newSplitState.copy(pane1_docId = null, pane1_pageId = null)
                changed = true
            }
            if (splitState.pane2_docId == document.id) {
                newSplitState = newSplitState.copy(pane2_docId = null, pane2_pageId = null)
                changed = true
            }
            if (changed) {
                splitLayoutStateDao.insert(newSplitState)
            }
        }

        documentDao.delete(document.toEntity())
    }

    suspend fun getDocumentsForNotebookPaginated(notebookId: Long, page: Int, pageSize: Int): Result<List<Document>> {
        return withContext(Dispatchers.IO) {
            try {
                val offset = page * pageSize
                val documents = documentDao.getDocumentsForNotebookPaginated(notebookId, pageSize, offset)
                Result.Success(documents.map { it.toDomain() })
            } catch (e: Exception) {
                Result.Error(e)
            }
        }
    }

    suspend fun moveDocument(documentId: Long, newNotebookId: Long): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val document = documentDao.getDocumentById(documentId)
                if (document != null) {
                    documentDao.update(document.copy(notebookId = newNotebookId))
                    Result.Success(Unit)
                } else {
                    Result.Error(Exception("Document not found"))
                }
            } catch (e: Exception) {
                Result.Error(e)
            }
        }
    }

    suspend fun setLastOpenedDocument(documentId: Long) {
        withContext(Dispatchers.IO) {
            val setting = com.kivixa.database.model.UserSetting(LAST_OPENED_DOC_ID_KEY, documentId.toString())
            userSettingDao.insert(setting) // BaseDao's insert with OnConflictStrategy.REPLACE
        }
    }

    suspend fun getLastOpenedDocument(): Result<Document?> {
        return withContext(Dispatchers.IO) {
            try {
                val setting = userSettingDao.getSetting(LAST_OPENED_DOC_ID_KEY)
                if (setting != null) {
                    val docId = setting.value.toLongOrNull()
                    if (docId != null) {
                        Result.Success(documentDao.getDocumentById(docId)?.toDomain())
                    } else {
                        Result.Success(null)
                    }
                } else {
                    Result.Success(null)
                }
            } catch (e: Exception) {
                Result.Error(e)
            }
        }
    }

    // --- Split Layout State ---

    fun getSplitLayoutState(): Flow<SplitLayoutState?> {
        return splitLayoutStateDao.getSplitLayoutState().map { it?.toDomain() }
    }

    suspend fun saveSplitLayoutState(state: SplitLayoutState) {
        withContext(Dispatchers.IO) {
            splitLayoutStateDao.insert(state.toEntity())
        }
    }

    // --- Outline Service ---
    fun getOutlinesForDocumentDesc(documentId: Long): Flow<List<Outline>> {
        return outlineDao.getOutlinesForDocumentDesc(documentId).map { list -> list.map { it.toDomain() } }
    }

    suspend fun insertAllOutlines(outlines: List<Outline>) = withContext(Dispatchers.IO) {
        outlineDao.insertAll(outlines.map { it.toEntity() })
    }

    import com.kivixa.domain.Result
import com.kivixa.domain.SplitLayoutState
import com.kivixa.domain.StrokeChunk
import com.kivixa.domain.TextBlock
import com.kivixa.filestore.FileStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.io.ByteArrayInputStream

data class CanvasContent(
    val strokeChunks: List<StrokeChunk>,
    val textBlocks: List<TextBlock>
)

class Repository(
    private val assetDao: AssetDao,
    private val commentDao: CommentDao,
    private val documentDao: DocumentDao,
    private val imageDao: ImageDao,
    private val layerDao: LayerDao,
    private val linkDao: LinkDao,
    private val notebookDao: NotebookDao,
    private val outlineDao: OutlineDao,
    private val pageDao: PageDao,
    private val shapeDao: ShapeDao,
    private val strokeChunkDao: StrokeChunkDao,
    private val templateDao: TemplateDao,
    private val textBlockDao: TextBlockDao,
    private val minimapTileDao: MinimapTileDao,
    private val userSettingDao: UserSettingDao,
    private val splitLayoutStateDao: SplitLayoutStateDao,
    private val pageThumbnailDao: PageThumbnailDao,
    private val fileStore: FileStore
) {

    private val LAST_OPENED_DOC_ID_KEY = "last_opened_document_id"
    private val TILE_SIZE = 256 // Or whatever tile size is appropriate

    // --- Document CRUD ---

    suspend fun createDocument(name: String, notebookId: Long): Long = withContext(Dispatchers.IO) {
        val newDocument = com.kivixa.database.model.Document(
            name = name,
            notebookId = notebookId
        )
        documentDao.insert(newDocument)
    }

    fun getDocument(id: Long): Flow<Document> {
        return documentDao.getDocument(id).map { it.toDomain() }
    }

    fun getDocumentsForNotebook(notebookId: Long): Flow<List<Document>> {
        return documentDao.getDocumentsForNotebook(notebookId).map { list -> list.map { it.toDomain() } }
    }

    suspend fun updateDocument(document: Document) = withContext(Dispatchers.IO) {
        documentDao.update(document.toEntity())
    }

    suspend fun deleteDocument(document: Document) = withContext(Dispatchers.IO) {
        // Clean up split layout state
        val splitState = splitLayoutStateDao.getSplitLayoutState().firstOrNull()
        if (splitState != null) {
            var changed = false
            var newSplitState = splitState
            if (splitState.pane1_docId == document.id) {
                newSplitState = newSplitState.copy(pane1_docId = null, pane1_pageId = null)
                changed = true
            }
            if (splitState.pane2_docId == document.id) {
                newSplitState = newSplitState.copy(pane2_docId = null, pane2_pageId = null)
                changed = true
            }
            if (changed) {
                splitLayoutStateDao.insert(newSplitState)
            }
        }

        documentDao.delete(document.toEntity())
    }

    suspend fun getDocumentsForNotebookPaginated(notebookId: Long, page: Int, pageSize: Int): Result<List<Document>> {
        return withContext(Dispatchers.IO) {
            try {
                val offset = page * pageSize
                val documents = documentDao.getDocumentsForNotebookPaginated(notebookId, pageSize, offset)
                Result.Success(documents.map { it.toDomain() })
            } catch (e: Exception) {
                Result.Error(e)
            }
        }
    }

    suspend fun moveDocument(documentId: Long, newNotebookId: Long): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val document = documentDao.getDocumentById(documentId)
                if (document != null) {
                    documentDao.update(document.copy(notebookId = newNotebookId))
                    Result.Success(Unit)
                } else {
                    Result.Error(Exception("Document not found"))
                }
            } catch (e: Exception) {
                Result.Error(e)
            }
        }
    }

    suspend fun setLastOpenedDocument(documentId: Long) {
        withContext(Dispatchers.IO) {
            val setting = com.kivixa.database.model.UserSetting(LAST_OPENED_DOC_ID_KEY, documentId.toString())
            userSettingDao.insert(setting) // BaseDao's insert with OnConflictStrategy.REPLACE
        }
    }

    suspend fun getLastOpenedDocument(): Result<Document?> {
        return withContext(Dispatchers.IO) {
            try {
                val setting = userSettingDao.getSetting(LAST_OPENED_DOC_ID_KEY)
                if (setting != null) {
                    val docId = setting.value.toLongOrNull()
                    if (docId != null) {
                        Result.Success(documentDao.getDocumentById(docId)?.toDomain())
                    } else {
                        Result.Success(null)
                    }
                } else {
                    Result.Success(null)
                }
            } catch (e: Exception) {
                Result.Error(e)
            }
        }
    }

    // --- Split Layout State ---

    fun getSplitLayoutState(): Flow<SplitLayoutState?> {
        return splitLayoutStateDao.getSplitLayoutState().map { it?.toDomain() }
    }

    suspend fun saveSplitLayoutState(state: SplitLayoutState) {
        withContext(Dispatchers.IO) {
            splitLayoutStateDao.insert(state.toEntity())
        }
    }

    // --- Outline Service ---
    fun getOutlinesForDocumentDesc(documentId: Long): Flow<List<Outline>> {
        return outlineDao.getOutlinesForDocumentDesc(documentId).map { list -> list.map { it.toDomain() } }
    }

    suspend fun insertAllOutlines(outlines: List<Outline>) = withContext(Dispatchers.IO) {
        outlineDao.insertAll(outlines.map { it.toEntity() })
    }

    suspend fun deleteAllOutlines(outlines: List<Outline>) = withContext(Dispatchers.IO) {
        outlineDao.deleteAll(outlines.map { it.toEntity() })
    }

    // --- Comment Service ---
    fun getCommentsForPageDesc(pageId: Long): Flow<List<Comment>> {
        return commentDao.getCommentsForPageDesc(pageId).map { list -> list.map { it.toDomain() } }
    }

    suspend fun searchComments(query: String): List<Comment> = withContext(Dispatchers.IO) {
        commentDao.searchComments(query).map { it.toDomain() }
    }

    suspend fun insertAllComments(comments: List<Comment>) = withContext(Dispatchers.IO) {
        commentDao.insertAll(comments.map { it.toEntity() })
    }

    suspend fun deleteAllComments(comments: List<Comment>) = withContext(Dispatchers.IO) {
        commentDao.deleteAll(comments.map { it.toEntity() })
    }

    // --- TextBlock Service ---
    suspend fun searchTextBlocks(query: String): List<TextBlock> = withContext(Dispatchers.IO) {
        textBlockDao.searchTextBlocks(query).map { it.toDomain() }
    }

    // --- TiledThumbnails Backend ---

    suspend fun generateThumbnail(pageId: Long): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            // 1. Invalidate old thumbnail
            invalidateThumbnail(pageId)

            // 2. Simulate thumbnail generation
            val dummyThumbnailData = "dummy thumbnail for page $pageId".toByteArray()
            val inputStream = ByteArrayInputStream(dummyThumbnailData)

            // 3. Save to FileStore
            val result = fileStore.saveFile(inputStream, FileStore.Subfolder.THUMBNAILS)

            if (result is FileStore.FileStoreResult.Success) {
                // 4. Save metadata to database
                val thumbnail = com.kivixa.database.model.PageThumbnail(
                    pageId = pageId,
                    filePath = result.data.absolutePath,
                    hash = result.data.name // Hash is the filename in our FileStore
                )
                pageThumbnailDao.insert(thumbnail)
                Result.Success(Unit)
            } else {
                Result.Error(Exception("Failed to save thumbnail file."))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    suspend fun invalidateThumbnail(pageId: Long) = withContext(Dispatchers.IO) {
        val thumbnail = pageThumbnailDao.getThumbnailForPage(pageId)
        if (thumbnail != null) {
            fileStore.deleteFile(thumbnail.hash, FileStore.Subfolder.THUMBNAILS)
            pageThumbnailDao.delete(thumbnail)
        }
    }

    suspend fun updatePageContent(pageId: Long) = withContext(Dispatchers.IO) {
        // This is a placeholder for when page content is updated.
        // For example, after adding a stroke or a text block.
        invalidateThumbnail(pageId)
    }

    suspend fun deletePage(pageId: Long) = withContext(Dispatchers.IO) {
        invalidateThumbnail(pageId)
        pageDao.deletePageById(pageId) // Assuming this method exists
    }

    // --- Infinite Canvas ---

    suspend fun getContentForViewport(layerId: Long, viewport: com.kivixa.domain.Rect): CanvasContent = withContext(Dispatchers.IO) {
        val minTileX = (viewport.left / TILE_SIZE).toInt()
        val maxTileX = (viewport.right / TILE_SIZE).toInt()
        val minTileY = (viewport.top / TILE_SIZE).toInt()
        val maxTileY = (viewport.bottom / TILE_SIZE).toInt()

        val tileXs = (minTileX..maxTileX).toList()
        val tileYs = (minTileY..maxTileY).toList()

        val strokeChunks = strokeChunkDao.getStrokeChunksForTiles(layerId, tileXs, tileYs).map { it.toDomain() }
        val textBlocks = textBlockDao.getTextBlocksForTiles(layerId, tileXs, tileYs).map { it.toDomain() }

        CanvasContent(strokeChunks, textBlocks)
    }

    suspend fun addStrokeChunk(chunk: StrokeChunk) = withContext(Dispatchers.IO) {
        strokeChunkDao.insert(chunk.toEntity())
    }

    suspend fun addTextBlock(textBlock: TextBlock) = withContext(Dispatchers.IO) {
        textBlockDao.insert(textBlock.toEntity())
    }

    // Other use cases will be implemented here
}


    // --- Comment Service ---
    fun getCommentsForPageDesc(pageId: Long): Flow<List<Comment>> {
        return commentDao.getCommentsForPageDesc(pageId).map { list -> list.map { it.toDomain() } }
    }

    suspend fun searchComments(query: String): List<Comment> = withContext(Dispatchers.IO) {
        commentDao.searchComments(query).map { it.toDomain() }
    }

    suspend fun insertAllComments(comments: List<Comment>) = withContext(Dispatchers.IO) {
        commentDao.insertAll(comments.map { it.toEntity() })
    }

    suspend fun deleteAllComments(comments: List<Comment>) = withContext(Dispatchers.IO) {
        commentDao.deleteAll(comments.map { it.toEntity() })
    }

    // --- TextBlock Service ---
    suspend fun searchTextBlocks(query: String): List<TextBlock> = withContext(Dispatchers.IO) {
        textBlockDao.searchTextBlocks(query).map { it.toDomain() }
    }

    // --- TiledThumbnails Backend ---

    suspend fun generateThumbnail(pageId: Long): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            // 1. Invalidate old thumbnail
            invalidateThumbnail(pageId)

            // 2. Simulate thumbnail generation
            val dummyThumbnailData = "dummy thumbnail for page $pageId".toByteArray()
            val inputStream = ByteArrayInputStream(dummyThumbnailData)

            // 3. Save to FileStore
            val result = fileStore.saveFile(inputStream, FileStore.Subfolder.THUMBNAILS)

            if (result is FileStore.FileStoreResult.Success) {
                // 4. Save metadata to database
                val thumbnail = com.kivixa.database.model.PageThumbnail(
                    pageId = pageId,
                    filePath = result.data.absolutePath,
                    hash = result.data.name // Hash is the filename in our FileStore
                )
                pageThumbnailDao.insert(thumbnail)
                Result.Success(Unit)
            } else {
                Result.Error(Exception("Failed to save thumbnail file."))
            }
        } catch (e: Exception) {
            Result.Error(e)
        }
    }

    suspend fun invalidateThumbnail(pageId: Long) = withContext(Dispatchers.IO) {
        val thumbnail = pageThumbnailDao.getThumbnailForPage(pageId)
        if (thumbnail != null) {
            fileStore.deleteFile(thumbnail.hash, FileStore.Subfolder.THUMBNAILS)
            pageThumbnailDao.delete(thumbnail)
        }
    }

    suspend fun updatePageContent(pageId: Long) = withContext(Dispatchers.IO) {
        // This is a placeholder for when page content is updated.
        // For example, after adding a stroke or a text block.
        invalidateThumbnail(pageId)
    }

    suspend fun deletePage(pageId: Long) = withContext(Dispatchers.IO) {
        invalidateThumbnail(pageId)
        pageDao.deletePageById(pageId) // Assuming this method exists
    }

    // Other use cases will be implemented here
}
