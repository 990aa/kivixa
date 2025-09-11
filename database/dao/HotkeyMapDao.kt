package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.HotkeyMap

@Dao
interface HotkeyMapDao : BaseDao<HotkeyMap> {

    @Query("SELECT * FROM hotkey_map")
    suspend fun getAllHotkeys(): List<HotkeyMap>
}
