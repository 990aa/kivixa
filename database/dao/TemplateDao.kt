package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.Template
import kotlinx.coroutines.flow.Flow

@Dao
interface TemplateDao : BaseDao<Template> {
    @Query("SELECT * FROM templates WHERE isDefault = 1")
    fun getDefaultTemplates(): Flow<List<Template>>
}
