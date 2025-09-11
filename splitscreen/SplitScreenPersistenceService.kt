package com.kivixa.splitscreen

import com.kivixa.database.dao.SplitLayoutStateDao
import com.kivixa.database.model.SplitLayoutState
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

class SplitScreenPersistenceService @Inject constructor(
    private val splitLayoutStateDao: SplitLayoutStateDao
) {

    fun getSplitLayoutState(): Flow<SplitLayoutState?> {
        return splitLayoutStateDao.getSplitLayoutState()
    }

    suspend fun saveSplitLayoutState(state: SplitLayoutState) {
        splitLayoutStateDao.insert(state)
    }

    suspend fun swapPanes() {
        val currentState = splitLayoutStateDao.getSplitLayoutStateOnce()
        if (currentState != null) {
            val newState = currentState.copy(
                pane1_docId = currentState.pane2_docId,
                pane1_pageId = currentState.pane2_pageId,
                pane2_docId = currentState.pane1_docId,
                pane2_pageId = currentState.pane1_pageId
            )
            splitLayoutStateDao.insert(newState)
        }
    }

    suspend fun toggleOrientation() {
        val currentState = splitLayoutStateDao.getSplitLayoutStateOnce()
        if (currentState != null) {
            val newOrientation = if (currentState.orientation == "horizontal") "vertical" else "horizontal"
            val newState = currentState.copy(orientation = newOrientation)
            splitLayoutStateDao.insert(newState)
        }
    }

    suspend fun onDocumentRemoved(docId: Long) {
        val currentState = splitLayoutStateDao.getSplitLayoutStateOnce()
        if (currentState != null) {
            var needsUpdate = false
            var newState = currentState
            if (currentState.pane1_docId == docId) {
                newState = newState.copy(pane1_docId = null, pane1_pageId = null)
                needsUpdate = true
            }
            if (currentState.pane2_docId == docId) {
                newState = newState.copy(pane2_docId = null, pane2_pageId = null)
                needsUpdate = true
            }
            if (needsUpdate) {
                splitLayoutStateDao.insert(newState)
            }
        }
    }
}
