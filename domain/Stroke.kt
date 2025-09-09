package com.kivixa.domain

/**
 * Represents a single continuous stroke, which may be composed of multiple chunks.
 */
data class Stroke(
    val id: Long,
    val layerId: Long,
    val startTime: Long,
    val endTime: Long,
    val chunks: List<StrokeChunk>
)
