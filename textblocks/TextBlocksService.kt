package com.kivixa.textblocks

import com.google.gson.Gson
import com.kivixa.database.dao.RedoLogDao
import com.kivixa.database.dao.TextBlockDao
import com.kivixa.database.model.RedoLog
import com.kivixa.database.model.TextBlock
import javax.inject.Inject

class TextBlocksService @Inject constructor(
    private val textBlockDao: TextBlockDao,
    private val redoLogDao: RedoLogDao,
    private val gson: Gson
) {

    private data class UpdateTextBlockUndoData(val oldTextBlock: TextBlock)
    private data class DeleteTextBlockUndoData(val textBlock: TextBlock)

    suspend fun createTextBlock(textBlock: TextBlock): Long {
        return textBlockDao.insert(textBlock)
    }

    suspend fun updateTextBlock(textBlock: TextBlock, selectionStart: Int?, selectionEnd: Int?) {
        val oldTextBlock = textBlockDao.getTextBlock(textBlock.id)
        if (oldTextBlock != null) {
            val undoData = UpdateTextBlockUndoData(oldTextBlock)
            logUndoAction("UPDATE_TEXT_BLOCK", undoData)
            textBlockDao.update(textBlock)
        }
    }

    suspend fun deleteTextBlock(textBlockId: Long) {
        val textBlock = textBlockDao.getTextBlock(textBlockId)
        if (textBlock != null) {
            val undoData = DeleteTextBlockUndoData(textBlock)
            logUndoAction("CREATE_TEXT_BLOCK", undoData)
            textBlockDao.delete(textBlock)
        }
    }

    private suspend fun logUndoAction(operation: String, data: Any) {
        val jsonData = gson.toJson(data)
        val redoLog = RedoLog(operation = operation, data = jsonData.toByteArray())
        redoLogDao.insert(redoLog)
    }
}
