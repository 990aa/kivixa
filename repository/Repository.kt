package com.kivixa.repository

import com.kivixa.database.dao.*
import com.kivixa.domain.Document
import com.kivixa.domain.Result
import com.kivixa.filestore.FileStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

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

    // Other use cases will be implemented here
}
