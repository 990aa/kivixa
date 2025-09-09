package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Transaction
import com.kivixa.database.KivixaDatabase
import com.kivixa.database.model.StrokeChunk
import kotlinx.coroutines.Dispatchers

/**
 * Data Access Object for Stroke Chunks.
 *
 * This DAO handles operations for [StrokeChunk] entities. For high-throughput
 * write operations, it uses raw SQLite statements.
 *
 * Note: All write operations like [insertAll] must be executed on [Dispatchers.IO]
 * to avoid blocking the main thread.
 */
@Dao
abstract class StrokeChunkDao(private val db: KivixaDatabase) {

    /**
     * Retrieves all stroke chunks for a given layer, ordered by their chunk index.
     * This is a suspendable function and is safe to call from a coroutine.
     *
     * @param layerId The ID of the layer.
     * @return A list of [StrokeChunk]s.
     */
    @Query("SELECT * FROM stroke_chunks WHERE layerId = :layerId ORDER BY chunkIndex ASC")
    abstract suspend fun getStrokeChunksForLayer(layerId: Long): List<StrokeChunk>

    /**
     * Inserts a list of stroke chunks in a single transaction for high performance.
     * This operation must be called from a coroutine running on [Dispatchers.IO].
     *
     * @param chunks The list of [StrokeChunk]s to insert.
     */
    @Transaction
    open fun insertAll(chunks: List<StrokeChunk>) {
        val sql = "INSERT INTO stroke_chunks (layerId, chunkIndex, strokeData, startTime, endTime) VALUES (?, ?, ?, ?, ?)"
        val statement = db.openHelper.writableDatabase.compileStatement(sql)
        db.runInTransaction {
            chunks.forEach { chunk ->
                statement.bindLong(1, chunk.layerId)
                statement.bindLong(2, chunk.chunkIndex.toLong())
                statement.bindBlob(3, chunk.strokeData)
                statement.bindLong(4, chunk.startTime)
                statement.bindLong(5, chunk.endTime)
                statement.executeInsert()
                statement.clearBindings()
            }
        }
    }
}
