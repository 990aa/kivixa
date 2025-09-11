package com.kivixa.database.converters

import androidx.room.TypeConverter
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class ListFloatConverter {
    @TypeConverter
    fun fromString(value: String?): List<Float>? {
        if (value == null) {
            return null
        }
        val listType = object : TypeToken<List<Float>>() {}.type
        return Gson().fromJson(value, listType)
    }

    @TypeConverter
    fun fromList(list: List<Float>?): String? {
        if (list == null) {
            return null
        }
        val gson = Gson()
        return gson.toJson(list)
    }
}
