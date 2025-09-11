package com.kivixa.outlines

import com.kivixa.database.dao.OutlineDao
import com.kivixa.database.model.Outline
import javax.inject.Inject

class ScannedPageOutlineService @Inject constructor(
    private val outlineDao: OutlineDao
) {

    suspend fun createPageLevelOutline(documentId: Long, pageId: Long, title: String, displayOrder: Int): Outline {
        val outline = Outline(
            documentId = documentId,
            pageId = pageId,
            title = title,
            parentId = null, // Page-level outlines have no parent
            displayOrder = displayOrder
        )
        val id = outlineDao.insert(outline)
        return outline.copy(id = id)
    }
}
