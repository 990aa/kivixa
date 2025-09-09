package com.kivixa.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.kivixa.database.dao.*
import com.kivixa.database.model.*

@Database(
    entities = [
        AiProvider::class,
        Asset::class,
        AudioClip::class,
        Comment::class,
        Document::class,
        EncryptedKey::class,
        Favorite::class,
        Image::class,
        JobQueue::class,
        Layer::class,
        Link::class,
        MinimapTile::class,
        Notebook::class,
        Outline::class,
        Page::class,
        PageThumbnail::class,
        RedoLog::class,
        Shape::class,
        StrokeChunk::class,
        Template::class,
        TextBlock::class,
        UserSetting::class,
        SplitLayoutState::class
    ],
    version = 2,
    exportSchema = false
)
abstract class KivixaDatabase : RoomDatabase() {

    abstract fun assetDao(): AssetDao
    abstract fun commentDao(): CommentDao
    abstract fun documentDao(): DocumentDao
    abstract fun imageDao(): ImageDao
    abstract fun layerDao(): LayerDao
    abstract fun linkDao(): LinkDao
    abstract fun notebookDao(): NotebookDao
    abstract fun outlineDao(): OutlineDao
    abstract fun pageDao(): PageDao
    abstract fun shapeDao(): ShapeDao
    abstract fun strokeChunkDao(): StrokeChunkDao
    abstract fun templateDao(): TemplateDao
    abstract fun textBlockDao(): TextBlockDao
    abstract fun minimapTileDao(): MinimapTileDao
    abstract fun userSettingDao(): UserSettingDao
    abstract fun splitLayoutStateDao(): SplitLayoutStateDao

    companion object {
        @Volatile
        private var INSTANCE: KivixaDatabase? = null

        fun getDatabase(context: Context): KivixaDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    KivixaDatabase::class.java,
                    "kivixa_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
