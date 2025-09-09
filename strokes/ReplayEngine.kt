package com.kivixa.strokes

import com.kivixa.database.dao.StrokeChunkDao
import com.kivixa.domain.DecodedStrokeData
import com.kivixa.domain.PointF
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn

class ReplayEngine(private val strokeChunkDao: StrokeChunkDao) {

    fun replay(
        layerId: Long,
        startIndex: Int = 0,
        endIndex: Int = Int.MAX_VALUE
    ): Flow<DecodedStrokeData> = flow {
        val pageSize = 100
        var offset = startIndex
        var hasMore = true

        while (hasMore) {
            val chunks = strokeChunkDao.getStrokeChunksForLayerPaginated(layerId, pageSize, offset)
            if (chunks.isEmpty()) {
                hasMore = false
            } else {
                chunks.forEach { chunk ->
                    if (chunk.chunkIndex <= endIndex) {
                        // Simulate decoding
                        val decodedData = decodeStrokeData(chunk.id, chunk.chunkIndex, chunk.strokeData)
                        emit(decodedData)
                    } else {
                        hasMore = false
                        return@forEach
                    }
                }
                offset += pageSize
            }
        }
    }.flowOn(Dispatchers.Default) // Use Default dispatcher for CPU-bound decoding work

    private fun decodeStrokeData(strokeId: Long, chunkIndex: Int, data: ByteArray): DecodedStrokeData {
        // Dummy decoding implementation.
        // In a real app, this would parse the binary blob into vector points.
        val points = mutableListOf<PointF>()
        for (i in 0 until data.size / 8) {
            points.add(PointF(i.toFloat(), i.toFloat()))
        }
        return DecodedStrokeData(strokeId, chunkIndex, points)
    }
}
