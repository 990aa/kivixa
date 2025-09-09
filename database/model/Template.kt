package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "templates")
data class Template(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val description: String,
    val previewImagePath: String?,
    val orientation: String = "PORTRAIT", // PORTRAIT, LANDSCAPE
    val pageSize: String = "A4", // A4, LETTER, etc.
    val backgroundColor: String = "#FFFFFF",
    val gridType: String = "NONE", // NONE, DOT, LINE
    val gridColor: String = "#E0E0E0",
    val spacing: Float = 10f,
    val columns: Int = 1,
    val templateType: String = "NOTE", // NOTE, STUDY, PROFESSIONAL, PLAN
    val isCover: Boolean = false,
    val isQuickNote: Boolean = false,
    val isDefault: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)
