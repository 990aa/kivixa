package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.TextBlock
import kotlinx.coroutines.flow.Flow

@Dao
interface TextBlockDao : BaseDao<TextBlock> {
    @Query("SELECT * FROM text_blocks WHERE layerId = :layerId")
    fun getTextBlocksForLayer(layerId: Long): Flow<List<TextBlock>>
}
