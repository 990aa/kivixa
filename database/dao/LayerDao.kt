package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Layer

@Dao
interface LayerDao : BaseDao<Layer> {
    @Query("SELECT * FROM layers WHERE pageId = :pageId ORDER BY zIndex ASC")
    suspend fun getLayersForPage(pageId: Long): List<Layer>
}
