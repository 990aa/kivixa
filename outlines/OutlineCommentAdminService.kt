package com.kivixa.outlines

import androidx.room.withTransaction
import com.kivixa.database.KivixaDatabase
import com.kivixa.database.dao.DocumentDao
import com.kivixa.database.dao.OutlineDao
import com.kivixa.database.model.Outline
import javax.inject.Inject

class OutlineCommentAdminService @Inject constructor(
    private val db: KivixaDatabase,
    private val outlineDao: OutlineDao,
    private val documentDao: DocumentDao
) {

    suspend fun clearAll(documentId: Long) {
        outlineDao.deleteOutlinesForDocument(documentId)
    }

    suspend fun getCommentsReverseChronological(documentId: Long): List<Outline> {
        return outlineDao.getOutlinesForDocumentDesc(documentId)
    }

    suspend fun saveCommentsAsNewDoc(documentId: Long, newDocName: String) = db.withTransaction {
        // Placeholder implementation
    }

    suspend fun copyComments(fromDocumentId: Long, toDocumentId: Long) = db.withTransaction {
        // Placeholder implementation
    }

    suspend fun exportComments(documentId: Long, format: String) = db.withTransaction {
        // Placeholder implementation
    }

    suspend fun moveComments(fromDocumentId: Long, toDocumentId: Long) = db.withTransaction {
        // Placeholder implementation
    }
}
