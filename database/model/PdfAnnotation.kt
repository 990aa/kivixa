package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "pdf_annotations")
data class PdfAnnotation(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val pageId: Long,
    val type: String, // "highlight", "underline", "strikethrough"
    val rects: List<List<Float>>, // List of rectangles, each defined by [left, top, right, bottom]
    val color: String,
    val comment: String? = null,
    val provenance: String? = null // For cross-document move
)
