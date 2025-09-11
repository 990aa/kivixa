package com.kivixa.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.kivixa.database.converters.ListFloatConverter
import com.kivixa.database.converters.ListStringConverter
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
        SplitLayoutState::class,
        ToolPreset::class,
        ColorPalette::class,
        ShapePreset::class,
        HotkeyMap::class,
        ViewportState::class
    ],
    version = 12,
    exportSchema = false
)
@TypeConverters(ListFloatConverter::class, ListStringConverter::class)
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
    abstract fun pageThumbnailDao(): PageThumbnailDao
    abstract fun toolPresetDao(): ToolPresetDao
    abstract fun colorPaletteDao(): ColorPaletteDao
    abstract fun shapePresetDao(): ShapePresetDao
    abstract fun favoriteDao(): FavoriteDao
    abstract fun hotkeyMapDao(): HotkeyMapDao
    abstract fun viewportStateDao(): ViewportStateDao

    companion object {
        @Volatile
        private var INSTANCE: KivixaDatabase? = null

        private val MIGRATION_11_12 = object : Migration(11, 12) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("CREATE TABLE IF NOT EXISTS `viewport_states` (`pageId` INTEGER NOT NULL, `scrollX` REAL NOT NULL, `scrollY` REAL NOT NULL, `zoom` REAL NOT NULL, PRIMARY KEY(`pageId`))")
            }
        }

        private val FTS_CALLBACK = object : RoomDatabase.Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                db.execSQL("CREATE VIRTUAL TABLE IF NOT EXISTS text_blocks_fts USING fts5(plainText, content='text_blocks', content_rowid='id')")
                db.execSQL("CREATE TRIGGER IF NOT EXISTS text_blocks_ai AFTER INSERT ON text_blocks BEGIN INSERT INTO text_blocks_fts(rowid, plainText) VALUES (new.id, new.plainText); END")
                db.execSQL("CREATE TRIGGER IF NOT EXISTS text_blocks_ad AFTER DELETE ON text_blocks BEGIN INSERT INTO text_blocks_fts(text_blocks_fts, rowid, plainText) VALUES ('delete', old.id, old.plainText); END")
                db.execSQL("CREATE TRIGGER IF NOT EXISTS text_blocks_au AFTER UPDATE ON text_blocks BEGIN INSERT INTO text_blocks_fts(text_blocks_fts, rowid, plainText) VALUES ('delete', old.id, old.plainText); INSERT INTO text_blocks_fts(rowid, plainText) VALUES (new.id, new.plainText); END")

                db.execSQL("CREATE VIRTUAL TABLE IF NOT EXISTS comments_fts USING fts5(content, content='comments', content_rowid='id')")
                db.execSQL("CREATE TRIGGER IF NOT EXISTS comments_ai AFTER INSERT ON comments BEGIN INSERT INTO comments_fts(rowid, content) VALUES (new.id, new.content); END")
                db.execSQL("CREATE TRIGGER IF NOT EXISTS comments_ad AFTER DELETE ON comments BEGIN INSERT INTO comments_fts(comments_fts, rowid, content) VALUES ('delete', old.id, old.content); END")
                db.execSQL("CREATE TRIGGER IF NOT EXISTS comments_au AFTER UPDATE ON comments BEGIN INSERT INTO comments_fts(comments_fts, rowid, content) VALUES ('delete', old.id, old.content); INSERT INTO comments_fts(rowid, content) VALUES (new.id, new.content); END")
            }
        }

        fun getDatabase(context: Context): KivixaDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    KivixaDatabase::class.java,
                    "kivixa_database"
                ).addMigrations(MIGRATION_11_12).addCallback(FTS_CALLBACK).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
