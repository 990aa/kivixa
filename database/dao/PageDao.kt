package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Page
import kotlinx.coroutines.flow.Flow

@Dao
interface PageDao : BaseDao<Page> {

    @Query("SELECT * FROM pages WHERE id = :id")
    fun getPage(id: Long): Flow<Page>

    @Query("SELECT * FROM pages WHERE documentId = :documentId ORDER BY pageNumber ASC")
    fun getPagesForDocument(documentId: Long): Flow<List<Page>>

    @Query("DELETE FROM pages WHERE id = :pageId")
    suspend fun deletePageById(pageId: Long)
}
