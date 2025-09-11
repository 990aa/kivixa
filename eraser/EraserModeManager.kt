package com.kivixa.eraser

import com.google.gson.Gson
import com.kivixa.database.dao.RedoLogDao
import com.kivixa.database.dao.StrokeChunkDao
import com.kivixa.database.model.RedoLog
import com.kivixa.database.model.StrokeChunk
import com.kivixa.domain.Stroke
import javax.inject.Inject

class EraserModeManager @Inject constructor(
    private val strokeChunkDao: StrokeChunkDao,
    private val redoLogDao: RedoLogDao,
    private val gson: Gson
) {

    private data class EraseStrokesUndoData(val strokes: List<Stroke>)

    suspend fun eraseStrokes(layerId: Long, strokeIds: List<Long>) {
        // This is a placeholder implementation. A real implementation would need to:
        // 1. Fetch the stroke chunks for the layer.
        // 2. Decode the stroke data to get individual strokes.
        // 3. Filter out the strokes to be deleted.
        // 4. Re-encode the remaining strokes and update the stroke chunks.
        // 5. Log the deleted strokes to the RedoLog for undo.

        // For now, we'll just log a placeholder undo action.
        val deletedStrokes = strokeIds.map { Stroke(id = it, points = emptyList()) } // Placeholder
        val undoData = EraseStrokesUndoData(deletedStrokes)
        logUndoAction("ADD_STROKES", undoData)
    }

    private suspend fun logUndoAction(operation: String, data: Any) {
        val jsonData = gson.toJson(data)
        val redoLog = RedoLog(operation = operation, data = jsonData.toByteArray())
        redoLogDao.insert(redoLog)
    }
}
