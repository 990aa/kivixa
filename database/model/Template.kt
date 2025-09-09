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
    val isDefault: Boolean = false,
    val createdAt: Long = System.currentTimeMillis()
)
