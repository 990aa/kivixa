import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/annotation_data.dart';

class AnnotationPersistence {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _localFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  static Future<void> saveAnnotations(
      String fileName, List<AnnotationData> annotations) async {
    final file = await _localFile(fileName);
    final data = annotations.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  static Future<List<AnnotationData>> loadAnnotations(String fileName) async {
    try {
      final file = await _localFile(fileName);
      String contents = await file.readAsString();
      final data = jsonDecode(contents) as List;
      return data.map((e) => AnnotationData.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
