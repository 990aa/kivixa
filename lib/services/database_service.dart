import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/page.dart';
import '../models/stroke.dart';

class DatabaseService {
  static const String _notesBox = 'notes';
  
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(NotePageAdapter());
    Hive.registerAdapter(DrawingStrokeAdapter());
    Hive.registerAdapter(ImageDataAdapter());
    
    await Hive.openBox<Note>(_notesBox);
  }

  Box<Note> get notesBox => Hive.box<Note>(_notesBox);

  Future<void> saveNote(Note note) async {
    note.modifiedAt = DateTime.now();
    await notesBox.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await notesBox.delete(id);
  }

  List<Note> getAllNotes() {
    return notesBox.values.toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
  }

  Note? getNote(String id) {
    return notesBox.get(id);
  }
}