package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Favorite

@Dao
interface FavoriteDao : BaseDao<Favorite> {

    @Query("SELECT * FROM favorites WHERE userId = :userId ORDER BY sortOrder ASC")
    suspend fun getFavoritesForUser(userId: Long): List<Favorite>

    @Query("SELECT COUNT(*) FROM favorites WHERE userId = :userId")
    suspend fun getFavoriteCountForUser(userId: Long): Int
}
