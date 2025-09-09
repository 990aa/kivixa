package com.kivixa.repository

import com.kivixa.database.model.Comment as CommentEntity
import com.kivixa.database.model.Document as DocumentEntity
import com.kivixa.database.model.Outline as OutlineEntity
import com.kivixa.database.model.SplitLayoutState as SplitLayoutStateEntity
import com.kivixa.database.model.StrokeChunk as StrokeChunkEntity
import com.kivixa.database.model.TextBlock as TextBlockEntity
import com.kivixa.domain.Comment as CommentDomain
import com.kivixa.domain.Document as DocumentDomain
import com.kivixa.domain.Orientation
import com.kivixa.domain.Outline as OutlineDomain
import com.kivixa.domain.PageFlowMode
import com.kivixa.domain.PaneState
import com.kivixa.domain.SplitLayoutState as SplitLayoutStateDomain
import com.kivixa.domain.StrokeChunk as StrokeChunkDomain
import com.kivixa.domain.TextBlock as TextBlockDomain

fun DocumentEntity.toDomain() = DocumentDomain(
    id = id,
    notebookId = notebookId,
    name = name,
    pageFlowMode = PageFlowMode.valueOf(pageFlowMode),
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun DocumentDomain.toEntity() = DocumentEntity(
    id = id,
    notebookId = notebookId,
    name = name,
    pageFlowMode = pageFlowMode.name,
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

fun OutlineEntity.toDomain() = OutlineDomain(
    id = id,
    documentId = documentId,
    title = title,
    pageId = pageId,
    parentId = parentId,
    displayOrder = displayOrder,
    createdAt = createdAt
)

fun OutlineDomain.toEntity() = OutlineEntity(
    id = id,
    documentId = documentId,
    title = title,
    pageId = pageId,
    parentId = parentId,
    displayOrder = displayOrder,
    createdAt = createdAt
)

fun CommentEntity.toDomain() = CommentDomain(
    id = id,
    pageId = pageId,
    userId = userId,
    content = content,
    x = x,
    y = y,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun CommentDomain.toEntity() = CommentEntity(
    id = id,
    pageId = pageId,
    userId = userId,
    content = content,
    x = x,
    y = y,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun TextBlockEntity.toDomain() = TextBlockDomain(
    id = id,
    layerId = layerId,
    tileX = tileX,
    tileY = tileY,
    styledJson = styledJson,
    plainText = plainText,
    x = x,
    y = y,
    width = width,
    height = height,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun TextBlockDomain.toEntity() = TextBlockEntity(
    id = id,
    layerId = layerId,
    tileX = tileX,
    tileY = tileY,
    styledJson = styledJson,
    plainText = plainText,
    x = x,
    y = y,
    width = width,
    height = height,
    createdAt = createdAt,
    updatedAt = updatedAt
)

fun StrokeChunkEntity.toDomain() = StrokeChunkDomain(
    id = id,
    layerId = layerId,
    tileX = tileX,
    tileY = tileY,
    chunkIndex = chunkIndex,
    strokeData = strokeData,
    startTime = startTime,
    endTime = endTime
)

fun StrokeChunkDomain.toEntity() = StrokeChunkEntity(
    id = id,
    layerId = layerId,
    tileX = tileX,
    tileY = tileY,
    chunkIndex = chunkIndex,
    strokeData = strokeData,
    startTime = startTime,
    endTime = endTime
)
