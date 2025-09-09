package com.kivixa.domain

data class StrokeChunk(
    val id: Long,
    val layerId: Long,
    val chunkIndex: Int,
    val strokeData: ByteArray,
    val startTime: Long,
    val endTime: Long
)
