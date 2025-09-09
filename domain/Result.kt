package com.kivixa.domain

/**
 * A generic class that holds a value with its loading status.
 * @param <T> The type of the value.
 */
sealed class Result<out T> {
    data class Success<out T>(val data: T) : Result<T>()
    data class Error(val exception: Exception) : Result<Nothing>()
    object Loading : Result<Nothing>()
}
