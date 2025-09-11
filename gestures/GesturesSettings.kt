package com.kivixa.gestures

import com.kivixa.database.dao.UserSettingDao
import com.kivixa.database.model.UserSetting
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class GesturesSettings @Inject constructor(
    private val userSettingDao: UserSettingDao
) {

    // --- Gesture Keys ---
    companion object {
        const val QUICK_SWIPE_RIGHT_ENABLED = "gesture_quick_swipe_right_enabled"
        const val DOUBLE_TAP_FIT_ENABLED = "gesture_double_tap_fit_enabled"
        const val TWO_FINGER_UNDO_ENABLED = "gesture_two_finger_undo_enabled"
        const val THREE_FINGER_REDO_ENABLED = "gesture_three_finger_redo_enabled"
    }

    suspend fun isQuickSwipeRightEnabled(): Boolean = getSetting(QUICK_SWIPE_RIGHT_ENABLED, true)
    suspend fun setQuickSwipeRightEnabled(enabled: Boolean) = setSetting(QUICK_SWIPE_RIGHT_ENABLED, enabled)

    suspend fun isDoubleTapFitEnabled(): Boolean = getSetting(DOUBLE_TAP_FIT_ENABLED, true)
    suspend fun setDoubleTapFitEnabled(enabled: Boolean) = setSetting(DOUBLE_TAP_FIT_ENABLED, enabled)

    suspend fun isTwoFingerUndoEnabled(): Boolean = getSetting(TWO_FINGER_UNDO_ENABLED, true)
    suspend fun setTwoFingerUndoEnabled(enabled: Boolean) = setSetting(TWO_FINGER_UNDO_ENABLED, enabled)

    suspend fun isThreeFingerRedoEnabled(): Boolean = getSetting(THREE_FINGER_REDO_ENABLED, true)
    suspend fun setThreeFingerRedoEnabled(enabled: Boolean) = setSetting(THREE_FINGER_REDO_ENABLED, enabled)

    // --- Capability Detector ---

    fun isGestureSupported(gestureKey: String): Boolean {
        // Placeholder implementation. A real implementation would check device hardware and software capabilities.
        return true
    }

    // --- Private Helpers ---

    private suspend fun getSetting(key: String, defaultValue: Boolean): Boolean {
        val setting = userSettingDao.getSetting(key)
        return setting?.value?.toBoolean() ?: defaultValue
    }

    private suspend fun setSetting(key: String, value: Boolean) {
        userSettingDao.insert(UserSetting(key, value.toString()))
    }
}
