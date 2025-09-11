package com.kivixa.pdf

import com.kivixa.database.dao.PdfAnnotationDao
import com.kivixa.database.model.PdfAnnotation
import javax.inject.Inject

class PdfAnnotationService @Inject constructor(
    private val pdfAnnotationDao: PdfAnnotationDao
) {

    suspend fun addHighlight(pageId: Long, rects: List<List<Float>>, color: String): PdfAnnotation {
        val annotation = PdfAnnotation(pageId = pageId, type = "highlight", rects = rects, color = color)
        val id = pdfAnnotationDao.insert(annotation)
        return annotation.copy(id = id)
    }

    suspend fun addUnderline(pageId: Long, rects: List<List<Float>>, color: String): PdfAnnotation {
        val annotation = PdfAnnotation(pageId = pageId, type = "underline", rects = rects, color = color)
        val id = pdfAnnotationDao.insert(annotation)
        return annotation.copy(id = id)
    }

    suspend fun addStrikethrough(pageId: Long, rects: List<List<Float>>, color: String): PdfAnnotation {
        val annotation = PdfAnnotation(pageId = pageId, type = "strikethrough", rects = rects, color = color)
        val id = pdfAnnotationDao.insert(annotation)
        return annotation.copy(id = id)
    }

    suspend fun addComment(annotationId: Long, comment: String) {
        val annotation = pdfAnnotationDao.getAnnotation(annotationId)
        if (annotation != null) {
            pdfAnnotationDao.update(annotation.copy(comment = comment))
        }
    }

    suspend fun copyAnnotation(annotationId: Long, newPageId: Long): PdfAnnotation? {
        val annotation = pdfAnnotationDao.getAnnotation(annotationId)
        if (annotation != null) {
            val newAnnotation = annotation.copy(id = 0, pageId = newPageId, provenance = "copied_from_${annotation.id}")
            val newId = pdfAnnotationDao.insert(newAnnotation)
            return newAnnotation.copy(id = newId)
        }
        return null
    }

    suspend fun moveAnnotation(annotationId: Long, newPageId: Long) {
        val annotation = pdfAnnotationDao.getAnnotation(annotationId)
        if (annotation != null) {
            pdfAnnotationDao.update(annotation.copy(pageId = newPageId, provenance = "moved_from_${annotation.pageId}"))
        }
    }
}
