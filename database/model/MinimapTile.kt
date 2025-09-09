package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "minimap_tiles",
    foreignKeys = [
        ForeignKey(
            entity = Page::class,
            parentColumns = ["id"],
            childColumns = ["pageId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["pageId", "zoomLevel", "x", "y"], unique = true)]
)
data class MinimapTile(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val pageId: Long,
    val zoomLevel: Int,
    val x: Int,
    val y: Int,
    val tileData: ByteArray,
    val createdAt: Long = System.currentTimeMillis()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as MinimapTile

        if (id != other.id) return false
        if (pageId != other.pageId) return false
        if (zoomLevel != other.zoomLevel) return false
        if (x != other.x) return false
        if (y != other.y) return false
        if (!tileData.contentEquals(other.tileData)) return false
        if (createdAt != other.createdAt) return false

        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + pageId.hashCode()
        result = 31 * result + zoomLevel
        result = 31 * result + x
        result = 31 * result + y
        result = 31 * result + tileData.contentHashCode()
        result = 31 * result + createdAt.hashCode()
        return result
    }
}
