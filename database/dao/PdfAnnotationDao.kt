package com.kivixa.database.dao

import androidx.room.Dao
import androidx.room.Query
import com.kivixa.database.model.PdfAnnotation

@Dao
interface PdfAnnotationDao : BaseDao<PdfAnnotation> {

    @Query("SELECT * FROM pdf_annotations WHERE id = :id")
    suspend fun getAnnotation(id: Long): PdfAnnotation?

    @Query("SELECT * FROM pdf_annotations WHERE pageId = :pageId")
    suspend fun getAnnotationsForPage(pageId: Long): List<PdfAnnotation>
}
