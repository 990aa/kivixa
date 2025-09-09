package com.kivixa.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
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
    version = 7,
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
    abstract fun pageThumbnailDao(): PageThumbnailDao

    companion object {
        @Volatile
        private var INSTANCE: KivixaDatabase? = null

        private val MIGRATION_4_5 = object : Migration(4, 5) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("ALTER TABLE stroke_chunks ADD COLUMN tileX INTEGER NOT NULL DEFAULT 0")
                database.execSQL("ALTER TABLE stroke_chunks ADD COLUMN tileY INTEGER NOT NULL DEFAULT 0")
                database.execSQL("ALTER TABLE text_blocks ADD COLUMN tileX INTEGER NOT NULL DEFAULT 0")
                database.execSQL("ALTER TABLE text_blocks ADD COLUMN tileY INTEGER NOT NULL DEFAULT 0")
            }
        }

        private val MIGRATION_5_6 = object : Migration(5, 6) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("ALTER TABLE documents ADD COLUMN pageFlowMode TEXT NOT NULL DEFAULT 'SWIPE_UP_TO_ADD'")
            }
        }

        private val MIGRATION_6_7 = object : Migration(6, 7) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("ALTER TABLE templates ADD COLUMN orientation TEXT NOT NULL DEFAULT 'PORTRAIT'")
                database.execSQL("ALTER TABLE templates ADD COLUMN pageSize TEXT NOT NULL DEFAULT 'A4'")
                database.execSQL("ALTER TABLE templates ADD COLUMN backgroundColor TEXT NOT NULL DEFAULT '#FFFFFF'")
                database.execSQL("ALTER TABLE templates ADD COLUMN gridType TEXT NOT NULL DEFAULT 'NONE'")
                database.execSQL("ALTER TABLE templates ADD COLUMN gridColor TEXT NOT NULL DEFAULT '#E0E0E0'")
                database.execSQL("ALTER TABLE templates ADD COLUMN spacing REAL NOT NULL DEFAULT 10.0")
                database.execSQL("ALTER TABLE templates ADD COLUMN columns INTEGER NOT NULL DEFAULT 1")
                database.execSQL("ALTER TABLE templates ADD COLUMN templateType TEXT NOT NULL DEFAULT 'NOTE'")
                database.execSQL("ALTER TABLE templates ADD COLUMN isCover INTEGER NOT NULL DEFAULT 0")
                database.execSQL("ALTER TABLE templates ADD COLUMN isQuickNote INTEGER NOT NULL DEFAULT 0")
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
                ).addMigrations(MIGRATION_4_5, MIGRATION_5_6, MIGRATION_6_7).addCallback(FTS_CALLBACK).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
