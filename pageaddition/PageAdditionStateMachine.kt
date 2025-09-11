package com.kivixa.pageaddition

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class PageAdditionStateMachine {

    private val _state = MutableStateFlow<State>(State.Idle)
    val state: StateFlow<State> = _state

    fun onDragStart() {
        _state.value = State.Dragging(0f)
    }

    fun onDrag(delta: Float) {
        if (_state.value is State.Dragging) {
            val currentProgress = (_state.value as State.Dragging).progress
            val newProgress = (currentProgress + delta).coerceIn(0f, 1f)
            if (newProgress >= THRESHOLD) {
                _state.value = State.ReadyToAdd
            } else {
                _state.value = State.Dragging(newProgress)
            }
        }
    }

    fun onDragEnd() {
        if (_state.value == State.ReadyToAdd) {
            // Action to add page should be triggered here by the observer
            _state.value = State.Idle
        } else {
            _state.value = State.Idle
        }
    }

    fun onDragCancel() {
        _state.value = State.Idle
    }

    sealed class State {
        object Idle : State()
        data class Dragging(val progress: Float) : State()
        object ReadyToAdd : State()
    }

    companion object {
        private const val THRESHOLD = 0.8f
    }
}
