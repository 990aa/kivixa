package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "audio_clips",
    foreignKeys = [
        ForeignKey(
            entity = Page::class,
            parentColumns = ["id"],
            childColumns = ["pageId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["pageId"])]
)
data class AudioClip(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val pageId: Long,
    val filePath: String,
    val duration: Long,
    val createdAt: Long = System.currentTimeMillis()
)
