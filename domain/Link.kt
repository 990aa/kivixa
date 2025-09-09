package com.kivixa.domain

data class Link(
    val id: Long,
    val fromPageId: Long,
    val toPageId: Long?,
    val externalUrl: String?,
    val linkType: String,
    val createdAt: Long
)
