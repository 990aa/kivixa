package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "shape_presets")
data class ShapePreset(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val type: String, // e.g., "line", "arrow", "dashed", "wave", "axis", "cube"
    val parameters: String // JSON string for shape-specific parameters
)
