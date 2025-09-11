package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "tool_presets",
    indices = [Index(value = ["toolId"])]
)
data class ToolPreset(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val toolId: String,
    val name: String,
    val settings: String, // JSON string for tool-specific settings
    val isLastUsed: Boolean = false,

    // Brush-specific parameters
    val pressureSensitivity: Float? = null,
    val inkFlow: Float? = null,
    val opacity: Float? = null,
    val widthPresets: List<Float>? = null, // For the three width presets

    // Eraser-specific parameters
    val eraserMode: String? = null, // "PIXEL" or "STROKE"
    val eraserPressure: Float? = null
)
