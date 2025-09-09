package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Shape
import kotlinx.coroutines.flow.Flow

@Dao
interface ShapeDao : BaseDao<Shape> {
    @Query("SELECT * FROM shapes WHERE layerId = :layerId")
    fun getShapesForLayer(layerId: Long): Flow<List<Shape>>
}
