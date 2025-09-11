package com.example.kivixa

import android.app.Activity
import android.os.Build
import android.util.Log

object SplitScreenHelper {
    fun isInSplitScreenMode(activity: Activity): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            activity.isInMultiWindowMode
        } else {
            false // Fallback: not supported
        }
    }
}
