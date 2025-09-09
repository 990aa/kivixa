package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Outline
import kotlinx.coroutines.flow.Flow

@Dao
interface OutlineDao : BaseDao<Outline> {
    @Query("SELECT * FROM outlines WHERE documentId = :documentId ORDER BY displayOrder ASC")
    fun getOutlinesForDocument(documentId: Long): Flow<List<Outline>>
}
