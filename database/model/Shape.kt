package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "shapes",
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
data class Shape(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val layerId: Long,
    val type: String, // e.g., "rectangle", "circle", "triangle"
    val properties: String, // JSON for shape properties like color, stroke, etc.
    val x: Float,
    val y: Float,
    val width: Float,
    val height: Float,
    val rotation: Float,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)
