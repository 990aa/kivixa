package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.StrokeChunk

@Dao
interface StrokeChunkDao : BaseDao<StrokeChunk> {
    @Query("SELECT * FROM stroke_chunks WHERE layerId = :layerId ORDER BY chunkIndex ASC")
    suspend fun getStrokeChunksForLayer(layerId: Long): List<StrokeChunk>
}
