package com.kivixa.palettes

import com.kivixa.database.dao.ColorPaletteDao
import com.kivixa.database.dao.ToolPresetDao
import com.kivixa.database.model.ColorPalette
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ColorPalettesService @Inject constructor(
    private val colorPaletteDao: ColorPaletteDao,
    private val toolPresetDao: ToolPresetDao
) {

    suspend fun savePalette(palette: ColorPalette) {
        colorPaletteDao.insert(palette)
    }

    suspend fun deletePalette(paletteId: Long) {
        // TODO: Implement fallback logic for presets
        colorPaletteDao.delete(ColorPalette(id = paletteId, name = "", colors = emptyList()))
    }

    suspend fun getPalettesForTool(toolId: String): List<ColorPalette> {
        return colorPaletteDao.getPalettesForTool(toolId)
    }

    suspend fun getGlobalPalettes(): List<ColorPalette> {
        return colorPaletteDao.getGlobalPalettes()
    }

    suspend fun getFavoritePalettes(): List<ColorPalette> {
        return colorPaletteDao.getFavoritePalettes()
    }

    suspend fun setFavorite(paletteId: Long, isFavorite: Boolean) {
        colorPaletteDao.setFavorite(paletteId, isFavorite)
    }
}
