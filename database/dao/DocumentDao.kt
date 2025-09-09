package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Document
import kotlinx.coroutines.flow.Flow

@Dao
interface DocumentDao : BaseDao<Document> {

    @Query("SELECT * FROM documents WHERE id = :id")
    fun getDocument(id: Long): Flow<Document>

    @Query("SELECT * FROM documents WHERE notebookId = :notebookId ORDER BY updatedAt DESC")
    fun getDocumentsForNotebook(notebookId: Long): Flow<List<Document>>
}
