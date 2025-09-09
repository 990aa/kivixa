package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Image
import kotlinx.coroutines.flow.Flow

@Dao
interface ImageDao : BaseDao<Image> {
    @Query("SELECT * FROM images WHERE layerId = :layerId")
    fun getImagesForLayer(layerId: Long): Flow<List<Image>>
}
