package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.SplitLayoutState
import kotlinx.coroutines.flow.Flow

@Dao
interface SplitLayoutStateDao : BaseDao<SplitLayoutState> {
    @Query("SELECT * FROM split_layout_state WHERE id = 1")
    fun getSplitLayoutState(): Flow<SplitLayoutState?>
}
