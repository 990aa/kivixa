package com.kivixa.navigation

import com.kivixa.database.dao.PageDao
import javax.inject.Inject

class FastNavigationService @Inject constructor(
    private val pageDao: PageDao
) {

    suspend fun resolvePageNumberToId(documentId: Long, pageNumber: Int): Long? {
        val page = pageDao.getPageByNumber(documentId, pageNumber)
        return page?.id
    }

    fun goTo(documentId: Long, pageId: Long) {
        // This would typically involve navigating to a new screen or updating a UI component.
        // For now, it's a placeholder.
    }

    fun goTo(documentId: Long, pageNumber: Int) {
        // This would typically involve navigating to a new screen or updating a UI component.
        // For now, it's a placeholder.
    }

    fun unifiedGoTo(documentId: Long, pageIdentifier: Any) {
        when (pageIdentifier) {
            is Long -> goTo(documentId, pageIdentifier) // pageId
            is Int -> goTo(documentId, pageIdentifier) // pageNumber
            else -> { /* Handle error */ }
        }
    }
}
