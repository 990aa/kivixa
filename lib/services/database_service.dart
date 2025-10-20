import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/stroke.dart' as stroke_model;
import '../models/canvas_element.dart' as element_model;
import '../utils/serialization_utils.dart';

/// Service for managing database operations
class DatabaseService {
  final AppDatabase _db = AppDatabase();

  AppDatabase get database => _db;

  // ============ Note Operations ============

  /// Create a new note
  Future<int> createNote({required String title, String? content}) async {
    final now = DateTime.now();
    return await _db.createNote(
      NotesCompanion.insert(
        title: title,
        content: Value(content),
        createdAt: now,
        modifiedAt: now,
      ),
    );
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() => _db.getAllNotes();

  /// Watch all notes (reactive)
  Stream<List<Note>> watchAllNotes() => _db.watchAllNotes();

  /// Get note by ID
  Future<Note?> getNoteById(int id) => _db.getNoteById(id);

  /// Update note
  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(modifiedAt: DateTime.now());
    await _db.updateNote(updatedNote);
  }

  /// Delete note
  Future<void> deleteNote(int id) => _db.deleteNoteCompletely(id);

  /// Search notes
  Future<List<Note>> searchNotes(String query) => _db.searchNotes(query);

  // ============ Stroke Operations ============

  /// Save strokes for a note
  Future<void> saveStrokesForNote(int noteId, List<stroke_model.Stroke> strokes) async {
    // Delete existing strokes
    await _db.deleteStrokesForNote(noteId);

    // Save new strokes
    final strokeCompanions = strokes.asMap().entries.map((entry) {
      final index = entry.key;
      final stroke = entry.value;

      return StrokesCompanion.insert(
        noteId: noteId,
        pointsJson: SerializationUtils.serializePoints(stroke.points),
        color: SerializationUtils.colorToHex(stroke.color),
        strokeWidth: stroke.strokeWidth,
        isHighlighter: stroke.isHighlighter,
        layerIndex: index,
      );
    }).toList();

    if (strokeCompanions.isNotEmpty) {
      await _db.saveStrokes(strokeCompanions);
    }
  }

  /// Load strokes for a note
  Future<List<stroke_model.Stroke>> loadStrokesForNote(int noteId) async {
    final dbStrokes = await _db.getStrokesForNote(noteId);

    return dbStrokes.map((dbStroke) {
      return stroke_model.Stroke(
        points: SerializationUtils.deserializePoints(dbStroke.pointsJson),
        color: SerializationUtils.hexToColor(dbStroke.color),
        strokeWidth: dbStroke.strokeWidth,
        isHighlighter: dbStroke.isHighlighter,
      );
    }).toList();
  }

  // ============ Canvas Element Operations ============

  /// Save canvas elements for a note
  Future<void> saveElementsForNote(
    int noteId,
    List<element_model.CanvasElement> elements,
  ) async {
    // Delete existing elements
    await _db.deleteElementsForNote(noteId);

    // Save new elements
    final elementCompanions = elements.asMap().entries.map((entry) {
      final index = entry.key;
      final element = entry.value;
      final serialized = SerializationUtils.serializeCanvasElement(element);

      return CanvasElementsCompanion.insert(
        noteId: noteId,
        type: serialized['type'] as String,
        dataJson: serialized['dataJson'] as String,
        posX: serialized['posX'] as double,
        posY: serialized['posY'] as double,
        rotation: serialized['rotation'] as double,
        scale: serialized['scale'] as double,
        layerIndex: index,
      );
    }).toList();

    if (elementCompanions.isNotEmpty) {
      await _db.saveElements(elementCompanions);
    }
  }

  /// Load canvas elements for a note
  Future<List<element_model.CanvasElement>> loadElementsForNote(int noteId) async {
    final dbElements = await _db.getElementsForNote(noteId);

    return dbElements.map((dbElement) {
      return SerializationUtils.deserializeCanvasElement(
        dbElement.type,
        dbElement.dataJson,
        dbElement.posX,
        dbElement.posY,
        dbElement.rotation,
        dbElement.scale,
      );
    }).toList();
  }

  // ============ Combined Operations ============

  /// Save complete note with strokes and elements
  Future<void> saveCompleteNote({
    required int noteId,
    required String title,
    String? content,
    required List<stroke_model.Stroke> strokes,
    required List<element_model.CanvasElement> elements,
  }) async {
    await _db.transaction(() async {
      // Update note
      final note = await _db.getNoteById(noteId);
      if (note != null) {
        await updateNote(note.copyWith(title: title, content: Value(content)));
      }

      // Save strokes and elements
      await saveStrokesForNote(noteId, strokes);
      await saveElementsForNote(noteId, elements);
    });
  }

  /// Load complete note with strokes and elements
  Future<Map<String, dynamic>?> loadCompleteNote(int noteId) async {
    final note = await getNoteById(noteId);
    if (note == null) return null;

    final strokes = await loadStrokesForNote(noteId);
    final elements = await loadElementsForNote(noteId);

    return {'note': note, 'strokes': strokes, 'elements': elements};
  }

  /// Get statistics
  Future<Map<String, int>> getStatistics() async {
    final notesCount = await _db.getNotesCount();
    return {'notesCount': notesCount};
  }

  /// Close database
  Future<void> close() => _db.close();
}
