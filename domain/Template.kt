package com.kivixa.domain

data class Template(
    val id: Long,
    val name: String,
    val description: String,
    val previewImagePath: String?,
    val isDefault: Boolean,
    val createdAt: Long
)
