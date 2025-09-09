package com.kivixa.domain

data class Comment(
    val id: Long,
    val pageId: Long,
    val userId: Long,
    val content: String,
    val x: Float,
    val y: Float,
    val createdAt: Long,
    val updatedAt: Long
)
