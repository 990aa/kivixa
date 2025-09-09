package com.kivixa.pageflow

import com.kivixa.database.dao.DocumentDao
import com.kivixa.database.dao.PageDao
import com.kivixa.database.model.Page
import com.kivixa.domain.Document
import com.kivixa.domain.PageFlowMode
import com.kivixa.settings.SettingsManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class PageFlowManager(
    private val documentDao: DocumentDao,
    private val pageDao: PageDao,
    private val settingsManager: SettingsManager
) {

    suspend fun getUserDefaultPageFlowMode(): PageFlowMode {
        // Implementation detail: get from SettingsManager
        // For now, return a default
        return PageFlowMode.SWIPE_UP_TO_ADD
    }

    suspend fun setUserDefaultPageFlowMode(mode: PageFlowMode) {
        // Implementation detail: save to SettingsManager
    }

    suspend fun getDocumentPageFlowMode(documentId: Long): PageFlowMode? = withContext(Dispatchers.IO) {
        documentDao.getDocumentById(documentId)?.pageFlowMode?.let { PageFlowMode.valueOf(it) }
    }

    suspend fun setDocumentPageFlowMode(documentId: Long, mode: PageFlowMode) = withContext(Dispatchers.IO) {
        val document = documentDao.getDocumentById(documentId)
        if (document != null) {
            documentDao.update(document.copy(pageFlowMode = mode.name))
        }
    }

    suspend fun addPage(documentId: Long, pageNumber: Int): Page = withContext(Dispatchers.IO) {
        val newPage = Page(
            documentId = documentId,
            pageNumber = pageNumber
        )
        val newPageId = pageDao.insert(newPage)
        return@withContext newPage.copy(id = newPageId)
    }

    suspend fun addPageWithTemplate(documentId: Long, pageNumber: Int, templateId: Long?): Page = withContext(Dispatchers.IO) {
        // 1. Create a new page
        val newPage = Page(
            documentId = documentId,
            pageNumber = pageNumber
        )
        val newPageId = pageDao.insert(newPage)

        // 2. Apply template (placeholder)
        if (templateId != null) {
            // TODO: Get template from TemplatesService and apply it
        }

        return@withContext newPage.copy(id = newPageId)
    }
}
