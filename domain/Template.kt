package com.kivixa.domain

data class Template(
    val id: Long,
    val name: String,
    val description: String,
    val previewImagePath: String?,
    val orientation: String,
    val pageSize: String,
    val backgroundColor: String,
    val gridType: String,
    val gridColor: String,
    val spacing: Float,
    val columns: Int,
    val templateType: String,
    val isCover: Boolean,
    val isQuickNote: Boolean,
    val isDefault: Boolean,
    val createdAt: Long
)
