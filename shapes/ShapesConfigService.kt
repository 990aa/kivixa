package com.kivixa.shapes

import com.google.gson.Gson
import com.kivixa.database.dao.ShapePresetDao
import com.kivixa.database.model.ShapePreset
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ShapesConfigService @Inject constructor(
    private val shapePresetDao: ShapePresetDao,
    private val gson: Gson
) {

    suspend fun saveShapePreset(preset: ShapePreset) {
        shapePresetDao.insert(preset)
    }

    suspend fun getAllShapePresets(): List<ShapePreset> {
        return shapePresetDao.getAllShapePresets()
    }

    suspend fun getShapePresetsByType(type: String): List<ShapePreset> {
        return shapePresetDao.getShapePresetsByType(type)
    }

    suspend fun getShapePreset(presetId: Long): ShapePreset? {
        // This is not efficient, but for the sake of simplicity
        // we will get all presets and filter by id.
        // A proper implementation would have a getById in the DAO.
        return shapePresetDao.getAllShapePresets().find { it.id == presetId }
    }
}
