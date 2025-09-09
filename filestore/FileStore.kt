package com.kivixa.filestore

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.io.InputStream
import java.security.MessageDigest

class FileStore(private val context: Context) {

    enum class Subfolder(val folderName: String) {
        ORIGINALS("originals"),
        THUMBNAILS("thumbnails"),
        EXPORTS("exports"),
        BACKUPS("backups"),
        TEMP("temp")
    }

    sealed class FileStoreResult<out T> {
        data class Success<out T>(val data: T) : FileStoreResult<T>()
        data class Error(val exception: Exception) : FileStoreResult<Nothing>()
    }

    private fun getSubfolder(subfolder: Subfolder): File {
        val folder = File(context.filesDir, subfolder.folderName)
        if (!folder.exists()) {
            folder.mkdirs()
        }
        return folder
    }

    private fun calculateSha256(inputStream: InputStream): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val buffer = ByteArray(8192)
        var bytesRead: Int
        while (inputStream.read(buffer).also { bytesRead = it } != -1) {
            digest.update(buffer, 0, bytesRead)
        }
        return digest.digest().fold("") { str, it -> str + "%02x".format(it) }
    }

    suspend fun saveFile(
        inputStream: InputStream,
        subfolder: Subfolder
    ): FileStoreResult<File> = withContext(Dispatchers.IO) {
        try {
            val tempFile = File.createTempFile("upload", ".tmp", getSubfolder(Subfolder.TEMP))
            tempFile.outputStream().use { outputStream ->
                inputStream.copyTo(outputStream)
            }

            val hash = tempFile.inputStream().use { calculateSha256(it) }
            val finalFile = File(getSubfolder(subfolder), hash)

            if (finalFile.exists()) {
                tempFile.delete()
                FileStoreResult.Success(finalFile)
            } else {
                if (tempFile.renameTo(finalFile)) {
                    FileStoreResult.Success(finalFile)
                } else {
                    FileStoreResult.Error(Exception("Failed to move file."))
                }
            }
        } catch (e: Exception) {
            FileStoreResult.Error(e)
        }
    }

    suspend fun getFile(hash: String, subfolder: Subfolder): FileStoreResult<File> = withContext(Dispatchers.IO) {
        try {
            val file = File(getSubfolder(subfolder), hash)
            if (file.exists()) {
                FileStoreResult.Success(file)
            } else {
                FileStoreResult.Error(Exception("File not found."))
            }
        } catch (e: Exception) {
            FileStoreResult.Error(e)
        }
    }

    suspend fun deleteFile(hash: String, subfolder: Subfolder): FileStoreResult<Unit> = withContext(Dispatchers.IO) {
        try {
            val file = File(getSubfolder(subfolder), hash)
            if (file.exists()) {
                if (file.delete()) {
                    FileStoreResult.Success(Unit)
                } else {
                    FileStoreResult.Error(Exception("Failed to delete file."))
                }
            } else {
                FileStoreResult.Success(Unit) // Idempotent delete
            }
        } catch (e: Exception) {
            FileStoreResult.Error(e)
        }
    }
}
