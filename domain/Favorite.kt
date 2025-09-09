package com.kivixa.domain

data class Favorite(
    val entityId: String,
    val entityType: String,
    val userId: Long,
    val createdAt: Long
)
