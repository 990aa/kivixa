package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "favorites")
data class Favorite(
    @PrimaryKey
    val entityId: String, // Composite key like "notebook-1", "document-5", "page-12"
    val entityType: String, // "notebook", "document", "page"
    val userId: Long, // Assuming a User entity exists or will be added
    val createdAt: Long = System.currentTimeMillis()
)
