package com.kivixa.repository

import com.kivixa.database.model.Document as DocumentEntity
import com.kivixa.domain.Document as DocumentDomain

fun DocumentEntity.toDomain() = DocumentDomain(
    id = id,
    notebookId = notebookId,
    name = name,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun DocumentDomain.toEntity() = DocumentEntity(
    id = id,
    notebookId = notebookId,
    name = name,
    createdAt = createdAt,
    updatedAt = updatedAt
)
