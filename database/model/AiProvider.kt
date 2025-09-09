package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "ai_providers")
data class AiProvider(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val apiKey: String,
    val apiEndpoint: String,
    val isEnabled: Boolean = true,
    val createdAt: Long = System.currentTimeMillis()
)
