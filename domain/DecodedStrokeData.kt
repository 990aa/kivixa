package com.kivixa.domain

// Represents the decoded vector data from a stroke chunk, ready for rendering.
data class DecodedStrokeData(
    val strokeId: Long, // Not in StrokeChunk entity, but good for the domain model
    val chunkIndex: Int,
    val points: List<PointF> // Assuming PointF is a simple data class for x,y coordinates
)
