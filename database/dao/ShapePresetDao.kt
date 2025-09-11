package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.ShapePreset

@Dao
interface ShapePresetDao : BaseDao<ShapePreset> {

    @Query("SELECT * FROM shape_presets")
    suspend fun getAllShapePresets(): List<ShapePreset>

    @Query("SELECT * FROM shape_presets WHERE type = :type")
    suspend fun getShapePresetsByType(type: String): List<ShapePreset>
}
