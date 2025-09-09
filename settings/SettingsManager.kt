package com.kivixa.settings

import com.google.gson.Gson
import com.kivixa.database.dao.UserSettingDao
import com.kivixa.database.model.UserSetting
import com.kivixa.domain.EditorState
import com.kivixa.domain.EdgeOffset
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.debounce

class SettingsManager(
    private val userSettingDao: UserSettingDao,
    private val scope: CoroutineScope
) {
    private val gson = Gson()
    private val settingsCache = mutableMapOf<String, String>()
    private val saveRequests = MutableStateFlow<UserSetting?>(null)

    private val _editorState = MutableStateFlow(EditorState())
    val editorState = _editorState.asStateFlow()

    init {
        loadSettings()
        scope.launch {
            saveRequests.debounce(500).collect { setting ->
                setting?.let {
                    withContext(Dispatchers.IO) {
                        userSettingDao.insert(it)
                    }
                }
            }
        }
    }

    private fun loadSettings() {
        scope.launch(Dispatchers.IO) {
            val settings = userSettingDao.getAllSettings()
            settings.forEach { settingsCache[it.key] = it.value }
            loadEditorState()
        }
    }

    private fun loadEditorState() {
        val editorStateJson = settingsCache[EDITOR_STATE_KEY]
        if (editorStateJson != null) {
            _editorState.value = gson.fromJson(editorStateJson, EditorState::class.java)
        }
    }

    fun updateEditorState(newEditorState: EditorState) {
        _editorState.value = newEditorState
        val json = gson.toJson(newEditorState)
        settingsCache[EDITOR_STATE_KEY] = json
        saveRequests.value = UserSetting(EDITOR_STATE_KEY, json)
    }

    fun saveEdgeOffset(pageId: Long, deviceId: String, offset: EdgeOffset) {
        val key = getEdgeOffsetKey(pageId, deviceId)
        val json = gson.toJson(offset)
        settingsCache[key] = json
        saveRequests.value = UserSetting(key, json)
    }

    fun getEdgeOffset(pageId: Long, deviceId: String): EdgeOffset? {
        val key = getEdgeOffsetKey(pageId, deviceId)
        val json = settingsCache[key]
        return if (json != null) {
            gson.fromJson(json, EdgeOffset::class.java)
        } else {
            null
        }
    }

    private fun getEdgeOffsetKey(pageId: Long, deviceId: String): String {
        return "edge_offset_page_${pageId}_device_${deviceId}"
    }

    companion object {
        private const val EDITOR_STATE_KEY = "editor_state"
        private const val SETTINGS_VERSION_KEY = "settings_schema_version"
        private const val CURRENT_SETTINGS_VERSION = "1"
    }
}
