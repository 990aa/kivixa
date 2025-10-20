import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// Notes table for storing canvas documents
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get content => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

/// Strokes table for storing drawing strokes
class Strokes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId =>
      integer().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get pointsJson => text()(); // Serialized points
  TextColumn get color => text()();
  RealColumn get strokeWidth => real()();
  BoolColumn get isHighlighter => boolean()();
  IntColumn get layerIndex => integer()();
}

/// Canvas elements table for images, text, and shapes
class CanvasElements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId =>
      integer().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // 'image', 'text', 'shape'
  TextColumn get dataJson => text()(); // Element-specific data
  RealColumn get posX => real()();
  RealColumn get posY => real()();
  RealColumn get rotation => real()();
  RealColumn get scale => real()();
  IntColumn get layerIndex => integer()();
}

/// Main database class
@DriftDatabase(tables: [Notes, Strokes, CanvasElements])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ============ Notes CRUD Operations ============

  /// Create a new note
  Future<int> createNote(NotesCompanion note) => into(notes).insert(note);

  /// Watch all notes (reactive stream)
  Stream<List<Note>> watchAllNotes() {
    return (select(notes)..orderBy([
          (n) =>
              OrderingTerm(expression: n.modifiedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Get all notes (one-time)
  Future<List<Note>> getAllNotes() {
    return (select(notes)..orderBy([
          (n) =>
              OrderingTerm(expression: n.modifiedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  /// Get a note by ID
  Future<Note?> getNoteById(int id) {
    return (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();
  }

  /// Update a note
  Future<bool> updateNote(Note note) => update(notes).replace(note);

  /// Delete a note (cascades to strokes and elements)
  Future<int> deleteNote(int id) {
    return (delete(notes)..where((n) => n.id.equals(id))).go();
  }

  // ============ Strokes CRUD Operations ============

  /// Get all strokes for a note
  Future<List<Stroke>> getStrokesForNote(int noteId) {
    return (select(strokes)
          ..where((s) => s.noteId.equals(noteId))
          ..orderBy([(s) => OrderingTerm(expression: s.layerIndex)]))
        .get();
  }

  /// Save a stroke
  Future<int> saveStroke(StrokesCompanion stroke) =>
      into(strokes).insert(stroke);

  /// Save multiple strokes
  Future<void> saveStrokes(List<StrokesCompanion> strokeList) async {
    await batch((batch) {
      batch.insertAll(strokes, strokeList);
    });
  }

  /// Delete all strokes for a note
  Future<int> deleteStrokesForNote(int noteId) {
    return (delete(strokes)..where((s) => s.noteId.equals(noteId))).go();
  }

  /// Update a stroke
  Future<bool> updateStroke(Stroke stroke) => update(strokes).replace(stroke);

  // ============ Canvas Elements CRUD Operations ============

  /// Get all canvas elements for a note
  Future<List<CanvasElement>> getElementsForNote(int noteId) {
    return (select(canvasElements)
          ..where((e) => e.noteId.equals(noteId))
          ..orderBy([(e) => OrderingTerm(expression: e.layerIndex)]))
        .get();
  }

  /// Save a canvas element
  Future<int> saveElement(CanvasElementsCompanion element) {
    return into(canvasElements).insert(element);
  }

  /// Save multiple elements
  Future<void> saveElements(List<CanvasElementsCompanion> elementList) async {
    await batch((batch) {
      batch.insertAll(canvasElements, elementList);
    });
  }

  /// Delete all elements for a note
  Future<int> deleteElementsForNote(int noteId) {
    return (delete(canvasElements)..where((e) => e.noteId.equals(noteId))).go();
  }

  /// Update an element
  Future<bool> updateElement(CanvasElement element) {
    return update(canvasElements).replace(element);
  }

  // ============ Batch Operations ============

  /// Delete all data for a note (note, strokes, elements)
  Future<void> deleteNoteCompletely(int noteId) async {
    await transaction(() async {
      await deleteStrokesForNote(noteId);
      await deleteElementsForNote(noteId);
      await deleteNote(noteId);
    });
  }

  /// Get total count of notes
  Future<int> getNotesCount() async {
    final count = countAll();
    final query = selectOnly(notes)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Search notes by title or content using LIKE (basic search)
  Future<List<Note>> searchNotes(String query) {
    final pattern = '%$query%';
    return (select(notes)
          ..where((n) => n.title.like(pattern) | n.content.like(pattern))
          ..orderBy([
            (n) =>
                OrderingTerm(expression: n.modifiedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Advanced search with FTS5 full-text search
  /// Note: Requires FTS5 virtual table to be created
  Future<List<Note>> searchNotesFullText(String query) async {
    // Escape special FTS5 characters
    final sanitizedQuery = query.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Use FTS5 MATCH query for full-text search
    final ftsQuery = '''
      SELECT n.* FROM notes n
      INNER JOIN notes_fts fts ON n.id = fts.rowid
      WHERE notes_fts MATCH ?
      ORDER BY rank, n.modified_at DESC
    ''';

    final results = await customSelect(
      ftsQuery,
      variables: [Variable.withString(sanitizedQuery)],
      readsFrom: {notes},
    ).get();

    return results.map((row) => notes.map(row.data)).toList();
  }

  /// Create FTS5 virtual table for full-text search
  Future<void> createFTS5Table() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
        title,
        content,
        content='notes',
        content_rowid='id'
      );
    ''');
  }

  /// Populate FTS5 table with existing data
  Future<void> rebuildFTS5Index() async {
    await customStatement('''
      INSERT INTO notes_fts(notes_fts) VALUES('rebuild');
    ''');
  }

  /// Setup FTS5 triggers for automatic indexing
  Future<void> setupFTS5Triggers() async {
    // Trigger for INSERT
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ai AFTER INSERT ON notes BEGIN
        INSERT INTO notes_fts(rowid, title, content)
        VALUES (new.id, new.title, new.content);
      END;
    ''');

    // Trigger for UPDATE
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_au AFTER UPDATE ON notes BEGIN
        UPDATE notes_fts
        SET title = new.title, content = new.content
        WHERE rowid = old.id;
      END;
    ''');

    // Trigger for DELETE
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS notes_ad AFTER DELETE ON notes BEGIN
        DELETE FROM notes_fts WHERE rowid = old.id;
      END;
    ''');
  }

  /// Initialize FTS5 search (call once on app start)
  Future<void> initializeFTS5() async {
    await createFTS5Table();
    await setupFTS5Triggers();
    // Only rebuild if table is empty
    final count = await customSelect(
      'SELECT COUNT(*) as count FROM notes_fts',
    ).getSingle();
    if (count.data['count'] == 0) {
      await rebuildFTS5Index();
    }
  }
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kivixa_notes.db'));
    return NativeDatabase(file);
  });
}
