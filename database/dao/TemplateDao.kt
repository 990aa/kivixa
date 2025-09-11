package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Template
import kotlinx.coroutines.flow.Flow

@Dao
interface TemplateDao : BaseDao<Template> {
    @Query("SELECT * FROM templates WHERE id = :templateId")
    suspend fun getTemplate(templateId: Long): Template?

    @Query("SELECT * FROM templates WHERE isCover = 1")
    suspend fun getCoverTemplates(): List<Template>

    @Query("SELECT * FROM templates WHERE isQuickNote = 1")
    suspend fun getQuickNoteTemplates(): List<Template>

    @Query("SELECT * FROM templates")
    suspend fun getAllTemplates(): List<Template>

    @Query("SELECT * FROM templates WHERE isDefault = 1")
    fun getDefaultTemplates(): Flow<List<Template>>
}
