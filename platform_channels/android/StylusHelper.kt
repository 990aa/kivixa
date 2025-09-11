package com.example.kivixa

import android.view.MotionEvent

object StylusHelper {
    fun getPressure(event: MotionEvent): Float {
        return try {
            event.pressure
        } catch (e: Exception) {
            1.0f // Fallback: no pressure info
        }
    }
}
