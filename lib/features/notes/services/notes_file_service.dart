import 'dart:convert';
import 'dart:io';

import 'package:kivixa/features/notes/models/note_document.dart';
import 'package:path_provider/path_provider.dart';

class NotesFileService {
  Future<String> getNotesDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final notesDir = Directory('${directory.path}/notes');
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir.path;
  }

  Future<void> saveDocument(NoteDocument document) async {
    final dirPath = await getNotesDirectory();
    final file = File('$dirPath/${document.id}.json');
    await file.writeAsString(jsonEncode(document.toJson()));
  }

  Future<NoteDocument?> loadDocument(String documentId) async {
    try {
      final dirPath = await getNotesDirectory();
      final file = File('$dirPath/$documentId.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        return NoteDocument.fromJson(jsonDecode(content));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      final dirPath = await getNotesDirectory();
      final file = File('$dirPath/$documentId.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      //
    }
  }
}
