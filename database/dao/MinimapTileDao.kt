package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Transaction
import com.kivixa.database.KivixaDatabase
import com.kivixa.database.model.MinimapTile
import kotlinx.coroutines.Dispatchers

/**
 * Data Access Object for Minimap Tiles.
 *
 * This DAO handles operations for [MinimapTile] entities. For high-throughput
 * write operations, it uses raw SQLite statements.
 *
 * Note: All write operations like [insertAll] must be executed on [Dispatchers.IO]
 * to avoid blocking the main thread.
 */
@Dao
abstract class MinimapTileDao(private val db: KivixaDatabase) {

    /**
     * Retrieves all minimap tiles for a given page.
     * This is a suspendable function and is safe to call from a coroutine.
     *
     * @param pageId The ID of the page.
     * @return A list of [MinimapTile]s.
     */
    @Query("SELECT * FROM minimap_tiles WHERE pageId = :pageId")
    abstract suspend fun getTilesForPage(pageId: Long): List<MinimapTile>

    /**
     * Inserts a list of minimap tiles in a single transaction for high performance.
     * This operation must be called from a coroutine running on [Dispatchers.IO].
     *
     * @param tiles The list of [MinimapTile]s to insert.
     */
    @Transaction
    open fun insertAll(tiles: List<MinimapTile>) {
        val sql = "INSERT INTO minimap_tiles (pageId, zoomLevel, x, y, tileData, createdAt) VALUES (?, ?, ?, ?, ?, ?)"
        val statement = db.openHelper.writableDatabase.compileStatement(sql)
        db.runInTransaction {
            tiles.forEach { tile ->
                statement.bindLong(1, tile.pageId)
                statement.bindLong(2, tile.zoomLevel.toLong())
                statement.bindLong(3, tile.x.toLong())
                statement.bindLong(4, tile.y.toLong())
                statement.bindBlob(5, tile.tileData)
                statement.bindLong(6, tile.createdAt)
                statement.executeInsert()
                statement.clearBindings()
            }
        }
    }
}
