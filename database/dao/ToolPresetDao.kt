package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Transaction
import com.kivixa.database.model.ToolPreset

@Dao
interface ToolPresetDao : BaseDao<ToolPreset> {

    @Query("SELECT * FROM tool_presets WHERE toolId = :toolId")
    suspend fun getPresetsForTool(toolId: String): List<ToolPreset>

    @Query("SELECT * FROM tool_presets WHERE toolId = :toolId AND isLastUsed = 1")
    suspend fun getLastUsedPreset(toolId: String): ToolPreset?

    @Transaction
    suspend fun setLastUsedPreset(toolId: String, presetId: Long) {
        // Clear the last used flag for the given tool
        clearLastUsed(toolId)
        // Set the new last used preset
        setLastUsed(presetId)
    }

    @Query("UPDATE tool_presets SET isLastUsed = 0 WHERE toolId = :toolId")
    suspend fun clearLastUsed(toolId: String)

    @Query("UPDATE tool_presets SET isLastUsed = 1 WHERE id = :presetId")
    suspend fun setLastUsed(presetId: Long)

    @Query("SELECT * FROM tool_presets")
    suspend fun getAllPresets(): List<ToolPreset>

    @Query("DELETE FROM tool_presets")
    suspend fun deleteAllPresets()
}
