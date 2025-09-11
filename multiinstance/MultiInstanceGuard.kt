package com.kivixa.multiinstance

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.concurrent.ConcurrentHashMap

class MultiInstanceGuard {

    private val documentLocks = ConcurrentHashMap<String, Mutex>()

    suspend fun <T> withDocumentLock(documentId: String, block: suspend () -> T): Result<T> {
        val mutex = documentLocks.computeIfAbsent(documentId) { Mutex() }
        if (mutex.isLocked) {
            return Result.failure(DocumentLockedException("Document is currently being modified by another instance."))
        }
        return try {
            mutex.withLock {
                Result.success(block())
            }
        } catch (e: Exception) {
            Result.failure(e)
        } finally {
            // Clean up the mutex if no other operations are waiting for it
            if (!mutex.hasQueuedThreads()) {
                documentLocks.remove(documentId)
            }
        }
    }
}

class DocumentLockedException(message: String) : Exception(message)
