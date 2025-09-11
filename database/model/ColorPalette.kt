package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "color_palettes")
data class ColorPalette(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val colors: List<String>, // List of 10 color hex codes
    val toolId: String? = null, // Null if global
    val isFavorite: Boolean = false
)
