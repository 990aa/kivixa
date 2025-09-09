package com.kivixa.repository

import com.kivixa.database.model.Document as DocumentEntity
import com.kivixa.database.model.SplitLayoutState as SplitLayoutStateEntity
import com.kivixa.domain.Document as DocumentDomain
import com.kivixa.domain.Orientation
import com.kivixa.domain.PaneState
import com.kivixa.domain.SplitLayoutState as SplitLayoutStateDomain

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

fun SplitLayoutStateEntity.toDomain() = SplitLayoutStateDomain(
    orientation = if (orientation == "HORIZONTAL") Orientation.HORIZONTAL else Orientation.VERTICAL,
    ratio = ratio,
    pane1 = PaneState(pane1_docId, pane1_pageId),
    pane2 = PaneState(pane2_docId, pane2_pageId)
)

fun SplitLayoutStateDomain.toEntity() = SplitLayoutStateEntity(
    orientation = orientation.name,
    ratio = ratio,
    pane1_docId = pane1.documentId,
    pane1_pageId = pane1.pageId,
    pane2_docId = pane2.documentId,
    pane2_pageId = pane2.pageId
)
