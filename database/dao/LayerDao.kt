package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Layer
import kotlinx.coroutines.flow.Flow

@Dao
interface LayerDao : BaseDao<Layer> {
    @Query("SELECT * FROM layers WHERE pageId = :pageId ORDER BY zIndex ASC")
    fun getLayersForPage(pageId: Long): Flow<List<Layer>>
}
