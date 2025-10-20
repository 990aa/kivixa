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
  IntColumn get noteId => integer().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get pointsJson => text()(); // Serialized points
  TextColumn get color => text()();
  RealColumn get strokeWidth => real()();
  BoolColumn get isHighlighter => boolean()();
  IntColumn get layerIndex => integer()();
}

/// Canvas elements table for images, text, and shapes
class CanvasElements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().references(Notes, #id, onDelete: KeyAction.cascade)();
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
    return (select(notes)
          ..orderBy([
            (n) => OrderingTerm(expression: n.modifiedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Get all notes (one-time)
  Future<List<Note>> getAllNotes() {
    return (select(notes)
          ..orderBy([
            (n) => OrderingTerm(expression: n.modifiedAt, mode: OrderingMode.desc)
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
          ..orderBy([
            (s) => OrderingTerm(expression: s.layerIndex)
          ]))
        .get();
  }

  /// Save a stroke
  Future<int> saveStroke(StrokesCompanion stroke) => into(strokes).insert(stroke);

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
          ..orderBy([
            (e) => OrderingTerm(expression: e.layerIndex)
          ]))
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

  /// Search notes by title
  Future<List<Note>> searchNotes(String query) {
    return (select(notes)
          ..where((n) => n.title.like('%$query%'))
          ..orderBy([
            (n) => OrderingTerm(expression: n.modifiedAt, mode: OrderingMode.desc)
          ]))
        .get();
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
