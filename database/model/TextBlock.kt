package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "text_blocks",
    foreignKeys = [
        ForeignKey(
            entity = Layer::class,
            parentColumns = ["id"],
            childColumns = ["layerId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["layerId"])]
)
data class TextBlock(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val layerId: Long,
    val styledJson: String,
    val plainText: String,
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)
