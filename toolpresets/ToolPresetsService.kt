package com.kivixa.toolpresets

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.kivixa.database.dao.ToolPresetDao
import com.kivixa.database.model.ToolPreset
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ToolPresetsService @Inject constructor(
    private val toolPresetDao: ToolPresetDao,
    private val gson: Gson
) {

    suspend fun saveToolPreset(preset: ToolPreset) {
        toolPresetDao.insert(preset)
    }

    suspend fun loadToolPresets(toolId: String): List<ToolPreset> {
        return toolPresetDao.getPresetsForTool(toolId)
    }

    suspend fun setLastUsedPreset(toolId: String, presetId: Long) {
        toolPresetDao.setLastUsedPreset(toolId, presetId)
    }

    suspend fun getLastUsedPreset(toolId: String): ToolPreset? {
        return toolPresetDao.getLastUsedPreset(toolId)
    }

    suspend fun getEffectiveToolPreset(toolId: String, liveAdjustments: ToolPreset?): ToolPreset? {
        val lastUsedPreset = getLastUsedPreset(toolId)
        // Start with the last used preset as the base
        var effectivePreset = lastUsedPreset

        // If there are live adjustments, merge them
        if (liveAdjustments != null) {
            effectivePreset = effectivePreset?.copy(
                pressureSensitivity = liveAdjustments.pressureSensitivity ?: effectivePreset.pressureSensitivity,
                inkFlow = liveAdjustments.inkFlow ?: effectivePreset.inkFlow,
                opacity = liveAdjustments.opacity ?: effectivePreset.opacity,
                widthPresets = liveAdjustments.widthPresets ?: effectivePreset.widthPresets,
                eraserMode = liveAdjustments.eraserMode ?: effectivePreset.eraserMode,
                eraserPressure = liveAdjustments.eraserPressure ?: effectivePreset.eraserPressure
            ) ?: liveAdjustments
        }

        return effectivePreset
    }

    suspend fun exportPresets(): String {
        val presets = toolPresetDao.getAllPresets()
        return gson.toJson(presets)
    }

    suspend fun importPresets(json: String) {
        val type = object : TypeToken<List<ToolPreset>>() {}.type
        val presets: List<ToolPreset> = gson.fromJson(json, type)
        toolPresetDao.deleteAllPresets()
        presets.forEach { toolPresetDao.insert(it) }
    }
}
