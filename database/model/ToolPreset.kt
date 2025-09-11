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
    val isLastUsed: Boolean = false
)
