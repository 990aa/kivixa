package com.kivixa.ui

import com.google.gson.Gson
import com.kivixa.database.dao.JobQueueDao
import com.kivixa.database.dao.LayerDao
import com.kivixa.database.dao.RedoLogDao
import com.kivixa.database.dao.TemplateDao
import com.kivixa.database.model.JobQueue
import com.kivixa.database.model.Layer
import com.kivixa.database.model.RedoLog
import com.kivixa.database.model.Template
import com.kivixa.pageflow.PageFlowManager
import com.kivixa.pageflow.PageMetadata
import javax.inject.Inject

class TitleBarActions @Inject constructor(
    private val pageFlowManager: PageFlowManager,
    private val templateDao: TemplateDao,
    private val layerDao: LayerDao,
    private val jobQueueDao: JobQueueDao,
    private val redoLogDao: RedoLogDao,
    private val gson: Gson
) {

    // --- Undo/Redo Data Structures ---
    private data class DeletePageUndoData(val pageId: Long)
    private data class ModifyTemplateUndoData(val template: Template)
    private data class ExportUndoData(val jobId: Long)
    private data class CaptureScreenUndoData(val imageId: Long)

    suspend fun insertPage(documentId: Long, pageNumber: Int, templateId: Long?): PageMetadata {
        val pageMetadata = pageFlowManager.addPageWithTemplate(documentId, pageNumber, templateId)
        val undoData = DeletePageUndoData(pageMetadata.id)
        logUndoAction("DELETE_PAGE", undoData)
        return pageMetadata
    }

    suspend fun modifyTemplate(template: Template) {
        val originalTemplate = templateDao.getTemplate(template.id)
        if (originalTemplate != null) {
            val undoData = ModifyTemplateUndoData(originalTemplate)
            logUndoAction("MODIFY_TEMPLATE", undoData)
            templateDao.update(template)
        }
    }

    suspend fun exportDocument(documentId: Long, format: String): Long {
        val payload = gson.toJson(mapOf("documentId" to documentId, "format" to format))
        val job = JobQueue(jobType = "export", payload = payload, status = "pending")
        val jobId = jobQueueDao.insert(job)
        val undoData = ExportUndoData(jobId)
        logUndoAction("CANCEL_EXPORT", undoData)
        return jobId
    }

    suspend fun getLayers(pageId: Long): List<Layer> {
        return layerDao.getLayersForPage(pageId)
    }

    suspend fun captureScreen(pageId: Long, imageData: ByteArray): Long {
        // This is a placeholder for actually saving the image and getting an ID
        val imageId = System.currentTimeMillis()
        val undoData = CaptureScreenUndoData(imageId)
        logUndoAction("DELETE_IMAGE", undoData)
        return imageId
    }

    private suspend fun logUndoAction(operation: String, data: Any) {
        val jsonData = gson.toJson(data)
        val redoLog = RedoLog(operation = operation, data = jsonData.toByteArray())
        redoLogDao.insert(redoLog)
    }
}
