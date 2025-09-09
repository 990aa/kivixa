package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "split_layout_state")
data class SplitLayoutState(
    @PrimaryKey
    val id: Int = 1, // Singleton
    val orientation: String, // "horizontal" or "vertical"
    val ratio: Float,
    val pane1_docId: Long?,
    val pane1_pageId: Long?,
    val pane2_docId: Long?,
    val pane2_pageId: Long?
)
