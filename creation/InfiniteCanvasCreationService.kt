package com.kivixa.creation

import com.kivixa.database.model.Document
import com.kivixa.database.model.Page
import com.kivixa.database.model.Template
import com.kivixa.database.model.ViewportState
import com.kivixa.domain.MinimapExtents
import com.kivixa.repository.Repository
import java.util.UUID

class InfiniteCanvasCreationService(private val repository: Repository) {

    suspend fun create(): CreationResult {
        val documentId = UUID.randomUUID().toString()
        val pageId = UUID.randomUUID().toString()

        val document = Document(
            id = documentId,
            name = "Infinite Canvas",
            templateId = Template.INFINITE_TILING_ID
        )

        val initialPage = Page(
            id = pageId,
            documentId = documentId,
            pageNumber = 0
        )

        val viewportState = ViewportState(
            documentId = documentId,
            scale = 1.0f,
            translateX = 0.0f,
            translateY = 0.0f
        )

        val tileExtents = MinimapExtents(
            minX = -INITIAL_EXTENT,
            maxX = INITIAL_EXTENT,
            minY = -INITIAL_EXTENT,
            maxY = INITIAL_EXTENT
        )

        repository.createDocument(document, initialPage, viewportState)

        return CreationResult(
            document = document,
            initialPage = initialPage,
            viewportState = viewportState,
            tileExtents = tileExtents
        )
    }

    data class CreationResult(
        val document: Document,
        val initialPage: Page,
        val viewportState: ViewportState,
        val tileExtents: MinimapExtents
    )

    companion object {
        private const val INITIAL_EXTENT = 1024
    }
}
