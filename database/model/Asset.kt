package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "assets",
    foreignKeys = [
        ForeignKey(
            entity = Document::class,
            parentColumns = ["id"],
            childColumns = ["documentId"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [Index(value = ["documentId"])]
)
data class Asset(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val documentId: Long?,
    val name: String,
    val type: String, // e.g., "image", "audio", "video"
    val originalFilePath: String,
    val derivativeFilePath: String?,
    val createdAt: Long = System.currentTimeMillis()
)
