package com.kivixa.pageflow

import androidx.room.withTransaction
import com.kivixa.database.KivixaDatabase
import com.kivixa.database.dao.DocumentDao
import com.kivixa.database.dao.PageDao
import com.kivixa.database.dao.UserSettingDao
import com.kivixa.database.model.Page
import com.kivixa.database.model.UserSetting
import com.kivixa.domain.PageFlowMode
import com.kivixa.templates.TemplatesService
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

data class PageMetadata(
    val id: Long,
    val documentId: Long,
    val pageNumber: Int
)

class PageFlowManager(
    private val db: KivixaDatabase,
    private val pageDao: PageDao,
    private val documentDao: DocumentDao,
    private val userSettingDao: UserSettingDao,
    private val templatesService: TemplatesService
) {

    suspend fun getUserDefaultPageFlowMode(): PageFlowMode = withContext(Dispatchers.IO) {
        val setting = userSettingDao.getSetting(USER_DEFAULT_PAGE_FLOW_MODE_KEY)
        return@withContext if (setting != null) {
            PageFlowMode.valueOf(setting.value)
        } else {
            PageFlowMode.SWIPE_UP_TO_ADD
        }
    }

    suspend fun setUserDefaultPageFlowMode(mode: PageFlowMode) = withContext(Dispatchers.IO) {
        userSettingDao.insert(UserSetting(USER_DEFAULT_PAGE_FLOW_MODE_KEY, mode.name))
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

    suspend fun addPageWithTemplate(documentId: Long, pageNumber: Int, templateId: Long?): PageMetadata = db.withTransaction {
        val template = templateId?.let { templatesService.getTemplate(it) }

        val newPage = Page(
            documentId = documentId,
            pageNumber = pageNumber,
            orientation = template?.orientation,
            pageSize = template?.pageSize,
            hasBorder = template?.hasBorder ?: true,
            backgroundColor = template?.backgroundColor,
            gridType = template?.gridType,
            gridColor = template?.gridColor,
            spacing = template?.spacing,
            columns = template?.columns
        )

        val newPageId = pageDao.insert(newPage)

        PageMetadata(newPageId, documentId, pageNumber)
    }

    companion object {
        const val USER_DEFAULT_PAGE_FLOW_MODE_KEY = "user_default_page_flow_mode"
    }
}
