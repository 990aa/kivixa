package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.PageThumbnail

@Dao
interface PageThumbnailDao : BaseDao<PageThumbnail> {
    @Query("SELECT * FROM page_thumbnails WHERE pageId = :pageId")
    suspend fun getThumbnailForPage(pageId: Long): PageThumbnail?

    @Query("DELETE FROM page_thumbnails WHERE pageId = :pageId")
    suspend fun deleteThumbnailForPage(pageId: Long)
}
