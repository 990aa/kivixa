import 'package:hive/hive.dart';
import '../domain/models/note.dart';

class NoteRepository {
  static const _notesBox = 'notes';

  Future<Box<Note>> _openNotesBox() async {
    return await Hive.openBox<Note>(_notesBox);
  }

  Future<List<Note>> getAllNotes() async {
    final box = await _openNotesBox();
    return box.values.toList();
  }

  Future<void> saveNote(Note note) async {
    final box = await _openNotesBox();
    await box.put(note.id, note);
  }

  Future<void> deleteNote(String noteId) async {
    final box = await _openNotesBox();
    await box.delete(noteId);
  }

  Future<Note?> getNote(String noteId) async {
    final box = await _openNotesBox();
    return box.get(noteId);
  }
}