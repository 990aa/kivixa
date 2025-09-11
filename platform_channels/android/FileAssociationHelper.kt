package com.example.kivixa

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import java.io.File

object FileAssociationHelper {
    fun openFile(context: Context, file: File, mimeType: String) {
        val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            FileProvider.getUriForFile(context, context.packageName + ".provider", file)
        } else {
            Uri.fromFile(file)
        }
        val intent = Intent(Intent.ACTION_VIEW)
        intent.setDataAndType(uri, mimeType)
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            // Fallback: show error or use default handler
        }
    }
}
