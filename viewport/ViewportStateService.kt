package com.kivixa.viewport

import com.kivixa.database.dao.ViewportStateDao
import com.kivixa.database.model.ViewportState
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ViewportStateService @Inject constructor(
    private val viewportStateDao: ViewportStateDao
) {

    suspend fun saveViewportState(pageId: Long, scrollX: Float, scrollY: Float, zoom: Float) {
        val state = ViewportState(pageId, scrollX, scrollY, zoom)
        viewportStateDao.insert(state)
    }

    suspend fun getViewportState(pageId: Long): ViewportState? {
        val savedState = viewportStateDao.getViewportState(pageId)
        // TODO: Add validation logic to check if the saved state is valid
        // after edits. For now, just return the saved state.
        return savedState ?: getDefaultViewportState(pageId)
    }

    private fun getDefaultViewportState(pageId: Long): ViewportState {
        return ViewportState(pageId, 0f, 0f, 1f)
    }

    fun getInertialScrollParameters(): Map<String, Any> {
        // These parameters should be consistent across devices.
        return mapOf(
            "decelerationRate" to 0.95f,
            "flingFriction" to 0.05f
        )
    }
}
