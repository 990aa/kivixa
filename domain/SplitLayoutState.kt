package com.kivixa.domain

data class SplitLayoutState(
    val orientation: Orientation,
    val ratio: Float,
    val pane1: PaneState,
    val pane2: PaneState
)

enum class Orientation {
    HORIZONTAL, VERTICAL
}

data class PaneState(
    val documentId: Long?,
    val pageId: Long?
)
