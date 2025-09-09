package com.kivixa.domain

data class Layer(
    val id: Long,
    val pageId: Long,
    val name: String,
    val zIndex: Int,
    val isVisible: Boolean,
    val createdAt: Long,
    val updatedAt: Long
)
