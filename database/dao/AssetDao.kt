package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Asset
import kotlinx.coroutines.flow.Flow

@Dao
interface AssetDao : BaseDao<Asset> {
    @Query("SELECT * FROM assets WHERE documentId = :documentId")
    fun getAssetsForDocument(documentId: Long): Flow<List<Asset>>
}
