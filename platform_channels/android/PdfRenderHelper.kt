package com.example.kivixa

import android.content.Context
import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import java.io.File

object PdfRenderHelper {
    fun renderPage(context: Context, pdfFile: File, pageIndex: Int): Bitmap? {
        return try {
            val fileDescriptor = ParcelFileDescriptor.open(pdfFile, ParcelFileDescriptor.MODE_READ_ONLY)
            val renderer = PdfRenderer(fileDescriptor)
            val page = renderer.openPage(pageIndex)
            val bitmap = Bitmap.createBitmap(page.width, page.height, Bitmap.Config.ARGB_8888)
            page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
            page.close()
            renderer.close()
            fileDescriptor.close()
            bitmap
        } catch (e: Exception) {
            null // Fallback: rendering failed
        }
    }
}
