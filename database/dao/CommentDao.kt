package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Comment
import kotlinx.coroutines.flow.Flow

@Dao
interface CommentDao : BaseDao<Comment> {
    @Query("SELECT * FROM comments WHERE pageId = :pageId ORDER BY createdAt ASC")
    fun getCommentsForPage(pageId: Long): Flow<List<Comment>>
}
