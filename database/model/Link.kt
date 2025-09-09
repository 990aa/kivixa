package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "links",
    foreignKeys = [
        ForeignKey(
            entity = Page::class,
            parentColumns = ["id"],
            childColumns = ["fromPageId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Page::class,
            parentColumns = ["id"],
            childColumns = ["toPageId"],
            onDelete = ForeignKey.SET_NULL
        )
    ],
    indices = [Index(value = ["fromPageId"]), Index(value = ["toPageId"])]
)
data class Link(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val fromPageId: Long,
    val toPageId: Long?,
    val externalUrl: String?,
    val linkType: String, // "page" or "external"
    val createdAt: Long = System.currentTimeMillis()
)
