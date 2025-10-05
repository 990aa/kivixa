import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../services/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return NotesNotifier(dbService);
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final DatabaseService _dbService;

  NotesNotifier(this._dbService) : super([]) {
    loadNotes();
  }

  void loadNotes() {
    state = _dbService.getAllNotes();
  }

  Future<void> createNote(Note note) async {
    await _dbService.saveNote(note);
    loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _dbService.saveNote(note);
    loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _dbService.deleteNote(id);
    loadNotes();
  }
}