package com.kivixa.templates

import android.util.LruCache
import com.kivixa.database.dao.TemplateDao
import com.kivixa.database.model.Template
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TemplatesService @Inject constructor(
    private val templateDao: TemplateDao
) {
    private val templateCache = LruCache<Long, Template>(CACHE_SIZE)

    suspend fun getTemplate(templateId: Long): Template? {
        val cachedTemplate = templateCache.get(templateId)
        if (cachedTemplate != null) {
            return cachedTemplate
        }

        val template = templateDao.getTemplate(templateId)
        if (template != null) {
            templateCache.put(templateId, template)
        }
        return template
    }

    suspend fun getCoverTemplates(): List<Template> {
        return templateDao.getCoverTemplates()
    }

    suspend fun getQuickNoteTemplates(): List<Template> {
        return templateDao.getQuickNoteTemplates()
    }

    suspend fun getTopTemplates(): List<Template> {
        // This is a placeholder. A real implementation would need to track
        // template usage to determine the "top" templates.
        return templateDao.getAllTemplates().take(10)
    }

    companion object {
        private const val CACHE_SIZE = 50
    }
}
