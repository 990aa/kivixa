package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.UserSetting

@Dao
interface UserSettingDao : BaseDao<UserSetting> {
    @Query("SELECT * FROM user_settings WHERE key = :key")
    suspend fun getSetting(key: String): UserSetting?

    @Query("SELECT * FROM user_settings")
    suspend fun getAllSettings(): List<UserSetting>
}
