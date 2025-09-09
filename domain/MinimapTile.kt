package com.kivixa.domain

data class MinimapTile(
    val id: Long,
    val pageId: Long,
    val zoomLevel: Int,
    val x: Int,
    val y: Int,
    val tileData: ByteArray,
    val createdAt: Long
)
