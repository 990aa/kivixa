package com.kivixa.database.converters

import androidx.room.TypeConverter
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class ListOfListsFloatConverter {
    @TypeConverter
    fun fromString(value: String?): List<List<Float>>? {
        if (value == null) {
            return null
        }
        val listType = object : TypeToken<List<List<Float>>>() {}.type
        return Gson().fromJson(value, listType)
    }

    @TypeConverter
    fun fromListOfLists(list: List<List<Float>>?): String? {
        if (list == null) {
            return null
        }
        val gson = Gson()
        return gson.toJson(list)
    }
}
