package com.kivixa.domain

data class Job(
    val id: Long,
    val jobType: String,
    val payload: String,
    val status: String,
    val priority: Int,
    val createdAt: Long,
    val updatedAt: Long
)
