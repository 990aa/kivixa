package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "hotkey_map")
data class HotkeyMap(
    @PrimaryKey
    val hotkey: String, // e.g., "ctrl+s"
    val favoriteId: Long
)
