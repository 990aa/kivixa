package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "job_queue")
data class JobQueue(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val jobType: String, // e.g., "export", "sync"
    val payload: String, // JSON for job parameters
    val status: String, // "pending", "running", "completed", "failed"
    val priority: Int = 0,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)
