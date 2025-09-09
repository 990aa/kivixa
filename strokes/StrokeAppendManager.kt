package com.kivixa.strokes

import com.kivixa.database.dao.StrokeChunkDao
import com.kivixa.database.model.StrokeChunk
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.debounce

class StrokeAppendManager(
    private val strokeChunkDao: StrokeChunkDao,
    private val scope: CoroutineScope,
    private val batchSize: Int = 100,
    private val batchTimeoutMs: Long = 500
) {
    private val chunkBuffer = mutableListOf<StrokeChunk>()
    private val flushChannel = MutableSharedFlow<Unit>(replay = 1, onBufferOverflow = BufferOverflow.DROP_OLDEST)

    init {
        scope.launch {
            flushChannel.debounce(batchTimeoutMs).collect {
                flush()
            }
        }
    }

    fun append(chunk: StrokeChunk) {
        chunkBuffer.add(chunk)
        if (chunkBuffer.size >= batchSize) {
            scope.launch { flush() }
        } else {
            flushChannel.tryEmit(Unit)
        }
    }

    suspend fun flush() = withContext(Dispatchers.IO) {
        if (chunkBuffer.isNotEmpty()) {
            val batch = chunkBuffer.toList()
            chunkBuffer.clear()
            strokeChunkDao.insertAll(batch)
        }
    }
}
