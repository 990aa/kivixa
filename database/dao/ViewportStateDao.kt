package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.ViewportState

@Dao
interface ViewportStateDao : BaseDao<ViewportState> {

    @Query("SELECT * FROM viewport_states WHERE pageId = :pageId")
    suspend fun getViewportState(pageId: Long): ViewportState?
}
