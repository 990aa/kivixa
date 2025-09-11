package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "viewport_states")
data class ViewportState(
    @PrimaryKey
    val pageId: Long,
    val scrollX: Float,
    val scrollY: Float,
    val zoom: Float
)
