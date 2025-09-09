package com.kivixa.domain

data class Document(
    val id: Long,
    val notebookId: Long,
    val name: String,
    val createdAt: Long,
    val updatedAt: Long
)
