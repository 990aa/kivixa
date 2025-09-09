package com.kivixa.domain

data class EditorState(
    val toolbarMode: String = "default",
    val sidebarVisible: Boolean = true,
    val lastOpenedDocId: Long? = null,
    val lastOpenedPageId: Long? = null,
    val lastViewport: Viewport? = null
)
