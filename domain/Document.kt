package com.kivixa.domain

data class Document(
    val id: Long,
    val notebookId: Long,
    val name: String,
    val pageFlowMode: PageFlowMode,
    val createdAt: Long,
    val updatedAt: Long
)
