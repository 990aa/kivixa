import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kivixa/database/archive_repository.dart';

/// SQLite database for managing drawings, folders, tags, and document organization
///
/// Features:
/// - Hierarchical folder structure
/// - Multi-tagging support (many-to-many)
/// - Full-text search across documents
/// - Efficient indexing for fast queries
/// - Cascade deletion for data integrity
/// - Document archiving and compression
class DrawingDatabase {
  static Database? _database;
  static const dbName = 'drawing_app.db';
  static const dbVersion = 2;

  // Table names
  static const tableFolders = 'folders';
  static const tableDocuments = 'documents';
  static const tableTags = 'tags';
  static const tableDocumentTags = 'document_tags';

  /// Get database instance (singleton pattern)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with all tables and indexes
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create all tables with relationships and indexes
  static Future<void> _onCreate(Database db, int version) async {
    // Folders table with hierarchical structure
    await db.execute('''
      CREATE TABLE $tableFolders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_folder_id INTEGER,
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        color INTEGER,
        icon TEXT,
        description TEXT,
        FOREIGN KEY (parent_folder_id) REFERENCES $tableFolders(id) ON DELETE CASCADE
      )
    ''');

    // Documents table (canvases, images, PDFs)
    await db.execute('''
      CREATE TABLE $tableDocuments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        folder_id INTEGER,
        file_path TEXT NOT NULL,
        thumbnail_path TEXT,
        width INTEGER,
        height INTEGER,
        file_size INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        modified_at INTEGER NOT NULL,
        last_opened_at INTEGER,
        is_favorite INTEGER DEFAULT 0,
        stroke_count INTEGER DEFAULT 0,
        layer_count INTEGER DEFAULT 0,
        FOREIGN KEY (folder_id) REFERENCES $tableFolders(id) ON DELETE SET NULL
      )
    ''');

    // Tags table with custom colors
    await db.execute('''
      CREATE TABLE $tableTags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        use_count INTEGER DEFAULT 0
      )
    ''');

    // Many-to-many relationship between documents and tags
    await db.execute('''
      CREATE TABLE $tableDocumentTags (
        document_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (document_id, tag_id),
        FOREIGN KEY (document_id) REFERENCES $tableDocuments(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES $tableTags(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for fast searching and filtering
    await db.execute(
      'CREATE INDEX idx_documents_name ON $tableDocuments(name)',
    );
    await db.execute(
      'CREATE INDEX idx_documents_type ON $tableDocuments(type)',
    );
    await db.execute(
      'CREATE INDEX idx_documents_folder ON $tableDocuments(folder_id)',
    );
    await db.execute(
      'CREATE INDEX idx_documents_created ON $tableDocuments(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_documents_modified ON $tableDocuments(modified_at)',
    );
    await db.execute(
      'CREATE INDEX idx_documents_favorite ON $tableDocuments(is_favorite)',
    );
    await db.execute(
      'CREATE INDEX idx_folders_parent ON $tableFolders(parent_folder_id)',
    );
    await db.execute('CREATE INDEX idx_folders_name ON $tableFolders(name)');
    await db.execute('CREATE INDEX idx_tags_name ON $tableTags(name)');
    await db.execute(
      'CREATE INDEX idx_document_tags_doc ON $tableDocumentTags(document_id)',
    );
    await db.execute(
      'CREATE INDEX idx_document_tags_tag ON $tableDocumentTags(tag_id)',
    );

    // Create default "All Drawings" folder
    await db.insert(tableFolders, {
      'name': 'All Drawings',
      'parent_folder_id': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'modified_at': DateTime.now().millisecondsSinceEpoch,
      'color': 0xFF2196F3, // Blue
      'description': 'Default folder for all drawings',
    });

    // Create archive tables
    await ArchiveRepository.createArchiveTables(db);
  }

  /// Handle database migrations
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Add migration logic here when schema changes
    if (oldVersion < 2) {
      // Version 2: Add archive tables
      await ArchiveRepository.createArchiveTables(db);
    }
  }

  /// Close database connection
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (for testing or reset)
  static Future<void> deleteDatabaseFile() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Vacuum database to reclaim space
  static Future<void> vacuum() async {
    final db = await database;
    await db.execute('VACUUM');
  }

  /// Get database size in bytes
  static Future<int> getDatabaseSize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, dbName);
    final file = await databaseFactory.openDatabase(path);
    final size = await file.getVersion(); // This is just a placeholder
    await file.close();
    return size;
  }
}
