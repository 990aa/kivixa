package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Transaction
import com.kivixa.database.model.Comment
import kotlinx.coroutines.flow.Flow

@Dao
interface CommentDao : BaseDao<Comment> {
    @Query("SELECT * FROM comments WHERE pageId = :pageId ORDER BY createdAt ASC")
    fun getCommentsForPage(pageId: Long): Flow<List<Comment>>

    @Query("SELECT * FROM comments WHERE pageId = :pageId ORDER BY createdAt DESC")
    fun getCommentsForPageDesc(pageId: Long): Flow<List<Comment>>

    @Query("SELECT * FROM comments, comments_fts WHERE comments_fts.rowid = comments.id AND comments_fts.content MATCH :query")
    suspend fun searchComments(query: String): List<Comment>

    @Transaction
    suspend fun insertAll(comments: List<Comment>) {
        comments.forEach { insert(it) }
    }

    @Transaction
    suspend fun deleteAll(comments: List<Comment>) {
        comments.forEach { delete(it) }
    }
}
