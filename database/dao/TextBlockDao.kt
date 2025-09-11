package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.TextBlock
import kotlinx.coroutines.flow.Flow

@Dao
interface TextBlockDao : BaseDao<TextBlock> {
    @Query("SELECT * FROM text_blocks WHERE id = :id")
    suspend fun getTextBlock(id: Long): TextBlock?

    @Query("SELECT * FROM text_blocks WHERE layerId = :layerId")
    fun getTextBlocksForLayer(layerId: Long): Flow<List<TextBlock>>

    @Query("SELECT * FROM text_blocks, text_blocks_fts WHERE text_blocks_fts.rowid = text_blocks.id AND text_blocks_fts.plainText MATCH :query")
    suspend fun searchTextBlocks(query: String): List<TextBlock>

    @Query("SELECT * FROM text_blocks WHERE layerId = :layerId AND tileX IN (:tileXs) AND tileY IN (:tileYs)")
    suspend fun getTextBlocksForTiles(layerId: Long, tileXs: List<Int>, tileYs: List<Int>): List<TextBlock>
}
