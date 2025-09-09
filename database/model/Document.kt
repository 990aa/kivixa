package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "documents",
    foreignKeys = [
        ForeignKey(
            entity = Notebook::class,
            parentColumns = ["id"],
            childColumns = ["notebookId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["notebookId"])]
)
data class Document(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val notebookId: Long,
    val name: String,
    val pageFlowMode: String = "SWIPE_UP_TO_ADD",
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)
