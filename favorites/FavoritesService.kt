package com.kivixa.favorites

import com.kivixa.database.dao.FavoriteDao
import com.kivixa.database.dao.HotkeyMapDao
import com.kivixa.database.dao.ToolPresetDao
import com.kivixa.database.model.Favorite
import com.kivixa.database.model.HotkeyMap
import com.kivixa.database.model.ToolPreset
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FavoritesService @Inject constructor(
    private val favoriteDao: FavoriteDao,
    private val hotkeyMapDao: HotkeyMapDao,
    private val toolPresetDao: ToolPresetDao
) {

    suspend fun getFavorites(userId: Long): List<Any> {
        val favorites = favoriteDao.getFavoritesForUser(userId)
        return favorites.mapNotNull { favorite ->
            when (favorite.type) {
                "preset" -> toolPresetDao.getPreset(favorite.value.toLong())
                "color" -> favorite.value // Just return the color hex
                else -> null
            }
        }
    }

    suspend fun addFavorite(userId: Long, type: String, value: String): Favorite? {
        val count = favoriteDao.getFavoriteCountForUser(userId)
        if (count >= 20) {
            return null // Or throw an exception
        }
        val favorite = Favorite(userId = userId, type = type, value = value, sortOrder = count)
        val id = favoriteDao.insert(favorite)
        return favorite.copy(id = id)
    }

    suspend fun removeFavorite(favoriteId: Long) {
        favoriteDao.delete(Favorite(id = favoriteId, userId = 0, type = "", value = "", sortOrder = 0))
    }

    suspend fun mapHotkey(hotkey: String, favoriteId: Long) {
        hotkeyMapDao.insert(HotkeyMap(hotkey, favoriteId))
    }
}
