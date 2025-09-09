package com.kivixa.domain

/**
 * Represents the boundaries and zoom levels of a minimap for a page.
 */
data class MinimapExtents(
    val pageId: Long,
    val minZoom: Int,
    val maxZoom: Int,
    val bounds: Rect
)
