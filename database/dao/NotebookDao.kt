package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Notebook
import kotlinx.coroutines.flow.Flow

@Dao
interface NotebookDao : BaseDao<Notebook> {

    @Query("SELECT * FROM notebooks WHERE id = :id")
    fun getNotebook(id: Long): Flow<Notebook>

    @Query("SELECT * FROM notebooks ORDER BY updatedAt DESC")
    fun getAllNotebooks(): Flow<List<Notebook>>
}
