package com.kivixa.longpress

import androidx.room.withTransaction
import com.kivixa.database.KivixaDatabase
import com.kivixa.database.dao.DocumentDao
import com.kivixa.database.dao.OutlineDao
import com.kivixa.database.model.Document
import com.kivixa.database.model.Outline
import javax.inject.Inject

class LongPressActions @Inject constructor(
    private val db: KivixaDatabase,
    private val documentDao: DocumentDao,
    private val outlineDao: OutlineDao
) {

    // --- Re-edit Actions ---
    // These would typically open a UI for editing, so the backend handler
    // might just return the object to be edited.
    suspend fun reEditText(textBlockId: Long) { /* TODO */ }
    suspend fun reEditImage(imageId: Long) { /* TODO */ }
    suspend fun reEditShape(shapeId: Long) { /* TODO */ }

    // --- Paste Action ---
    suspend fun paste(documentId: Long, pageId: Long, clipboardContent: String) { /* TODO */ }

    // --- Document Actions ---
    suspend fun reorderDocument(documentId: Long, newOrder: Int): List<Document> = db.withTransaction {
        // Placeholder implementation
        val doc = documentDao.getDocumentById(documentId)
        if (doc != null) {
            // documentDao.update(doc.copy(order = newOrder)) // Assuming an 'order' field
        }
        return@withTransaction documentDao.getDocumentsForNotebook(doc!!.notebookId)
    }

    suspend fun moveDocumentToFolder(documentId: Long, newNotebookId: Long): Document = db.withTransaction {
        val doc = documentDao.getDocumentById(documentId)
        val updatedDoc = doc!!.copy(notebookId = newNotebookId)
        documentDao.update(updatedDoc)
        return@withTransaction updatedDoc
    }

    // --- Outline Actions ---
    suspend fun nestOutline(outlineId: Long, newParentId: Long?): Outline = db.withTransaction {
        val outline = outlineDao.getOutlineById(outlineId)
        val updatedOutline = outline!!.copy(parentId = newParentId)
        outlineDao.update(updatedOutline)
        return@withTransaction updatedOutline
    }
}
