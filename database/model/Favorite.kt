package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "favorites")
data class Favorite(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val userId: Long,
    val type: String, // "preset", "color"
    val value: String, // presetId or color hex
    val sortOrder: Int
)