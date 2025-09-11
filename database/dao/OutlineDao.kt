package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Transaction
import com.kivixa.database.model.Outline
import kotlinx.coroutines.flow.Flow

@Dao
interface OutlineDao : BaseDao<Outline> {
    @Query("SELECT * FROM outlines WHERE id = :id")
    suspend fun getOutlineById(id: Long): Outline?

    @Query("SELECT * FROM outlines WHERE documentId = :documentId ORDER BY displayOrder ASC")
    fun getOutlinesForDocument(documentId: Long): Flow<List<Outline>>

    @Query("SELECT * FROM outlines WHERE documentId = :documentId ORDER BY createdAt DESC")
    suspend fun getOutlinesForDocumentDesc(documentId: Long): List<Outline>

    @Query("DELETE FROM outlines WHERE documentId = :documentId")
    suspend fun deleteOutlinesForDocument(documentId: Long)

    @Transaction
    suspend fun insertAll(outlines: List<Outline>) {
        outlines.forEach { insert(it) }
    }

    @Transaction
    suspend fun deleteAll(outlines: List<Outline>) {
        outlines.forEach { delete(it) }
    }
}
