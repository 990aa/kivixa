package com.kivixa.database.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "encrypted_keys")
data class EncryptedKey(
    @PrimaryKey
    val keyAlias: String,
    val encryptedKey: ByteArray,
    val iv: ByteArray,
    val createdAt: Long = System.currentTimeMillis()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as EncryptedKey

        if (keyAlias != other.keyAlias) return false
        if (!encryptedKey.contentEquals(other.encryptedKey)) return false
        if (!iv.contentEquals(other.iv)) return false
        if (createdAt != other.createdAt) return false

        return true
    }

    override fun hashCode(): Int {
        var result = keyAlias.hashCode()
        result = 31 * result + encryptedKey.contentHashCode()
        result = 31 * result + iv.contentHashCode()
        result = 31 * result + createdAt.hashCode()
        return result
    }
}
