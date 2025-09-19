
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note_document.dart';

class ExportService {
  Future<String> exportToJson(NoteDocument document) async {
    final jsonString = jsonEncode(document.toJson());
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/${document.title}.json';
    final file = File(path);
    await file.writeAsString(jsonString);
    return path;
  }
}
