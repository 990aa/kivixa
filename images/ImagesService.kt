package com.kivixa.images

import com.kivixa.database.dao.ImageDao
import com.kivixa.database.model.Image
import java.io.File
import javax.inject.Inject

class ImagesService @Inject constructor(
    private val imageDao: ImageDao
) {

    suspend fun addImage(layerId: Long, filePath: String, x: Float, y: Float, width: Float, height: Float): Image {
        // 1. Create thumbnail (placeholder)
        val thumbnailPath = createThumbnail(filePath)

        // 2. Create image metadata
        val image = Image(
            layerId = layerId,
            filePath = filePath,
            x = x,
            y = y,
            width = width,
            height = height,
            rotation = 0f,
            metadata = "{\"thumbnailPath\": \"$thumbnailPath\"}"
        )

        // 3. Insert into database
        val id = imageDao.insert(image)
        return image.copy(id = id)
    }

    suspend fun updateTransform(imageId: Long, transformMatrix: List<Float>) {
        val image = imageDao.getImage(imageId)
        if (image != null) {
            imageDao.update(image.copy(transformMatrix = transformMatrix))
        }
    }

    private fun createThumbnail(filePath: String): String {
        // Placeholder implementation
        val file = File(filePath)
        return "${file.parent}/${file.nameWithoutExtension}_thumb.png"
    }
}
