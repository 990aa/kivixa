package com.kivixa.layers

import com.kivixa.database.dao.LayerDao
import com.kivixa.database.model.Layer
import javax.inject.Inject

class LayersService @Inject constructor(
    private val layerDao: LayerDao
) {

    suspend fun createLayer(pageId: Long, name: String, zIndex: Int): Layer {
        val layer = Layer(pageId = pageId, name = name, zIndex = zIndex)
        val id = layerDao.insert(layer)
        return layer.copy(id = id)
    }

    suspend fun reorderLayer(layerId: Long, newZIndex: Int) {
        val layer = layerDao.getLayer(layerId)
        if (layer != null) {
            layerDao.update(layer.copy(zIndex = newZIndex))
        }
    }

    suspend fun renameLayer(layerId: Long, newName: String) {
        val layer = layerDao.getLayer(layerId)
        if (layer != null) {
            layerDao.update(layer.copy(name = newName))
        }
    }

    suspend fun toggleLayerVisibility(layerId: Long, isVisible: Boolean) {
        val layer = layerDao.getLayer(layerId)
        if (layer != null) {
            layerDao.update(layer.copy(isVisible = isVisible))
        }
    }

    suspend fun reassignItemToLayer(itemId: Long, itemType: String, newLayerId: Long) {
        // This would require updating the layerId of the item (e.g., TextBlock, Image).
        // This is a placeholder as it requires modifying other DAOs.
    }

    suspend fun getDrawOrder(pageId: Long): List<Layer> {
        return layerDao.getLayersForPageSortedByZIndex(pageId)
    }
}
