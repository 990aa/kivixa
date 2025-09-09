package com.kivixa.domain

data class Page(
    val id: Long,
    val documentId: Long,
    val pageNumber: Int,
    val createdAt: Long,
    val updatedAt: Long
)
