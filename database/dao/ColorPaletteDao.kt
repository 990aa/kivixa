package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.ColorPalette

@Dao
interface ColorPaletteDao : BaseDao<ColorPalette> {

    @Query("SELECT * FROM color_palettes WHERE toolId = :toolId")
    suspend fun getPalettesForTool(toolId: String): List<ColorPalette>

    @Query("SELECT * FROM color_palettes WHERE toolId IS NULL")
    suspend fun getGlobalPalettes(): List<ColorPalette>

    @Query("SELECT * FROM color_palettes WHERE isFavorite = 1")
    suspend fun getFavoritePalettes(): List<ColorPalette>

    @Query("UPDATE color_palettes SET isFavorite = :isFavorite WHERE id = :paletteId")
    suspend fun setFavorite(paletteId: Long, isFavorite: Boolean)
}
