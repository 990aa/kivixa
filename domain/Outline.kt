package com.kivixa.domain

data class Outline(
    val id: Long,
    val documentId: Long,
    val title: String,
    val pageId: Long,
    val parentId: Long?,
    val displayOrder: Int,
    val createdAt: Long
)
