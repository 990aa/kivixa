package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Link
import kotlinx.coroutines.flow.Flow

@Dao
interface LinkDao : BaseDao<Link> {
    @Query("SELECT * FROM links WHERE fromPageId = :pageId")
    fun getLinksFromPage(pageId: Long): Flow<List<Link>>
}
