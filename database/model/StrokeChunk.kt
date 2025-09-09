package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "stroke_chunks",
    foreignKeys = [
        ForeignKey(
            entity = Layer::class,
            parentColumns = ["id"],
            childColumns = ["layerId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index(value = ["layerId"])]
)
data class StrokeChunk(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val layerId: Long,
    val chunkIndex: Int,
    val strokeData: ByteArray,
    val startTime: Long,
    val endTime: Long
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as StrokeChunk

        if (id != other.id) return false
        if (layerId != other.layerId) return false
        if (chunkIndex != other.chunkIndex) return false
        if (!strokeData.contentEquals(other.strokeData)) return false
        if (startTime != other.startTime) return false
        if (endTime != other.endTime) return false

        return true
    }

    override fun hashCode(): Int {
        var result = id.hashCode()
        result = 31 * result + layerId.hashCode()
        result = 31 * result + chunkIndex
        result = 31 * result + strokeData.contentHashCode()
        result = 31 * result + startTime.hashCode()
        result = 31 * result + endTime.hashCode()
        return result
    }
}
