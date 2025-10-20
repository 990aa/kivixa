import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/annotation_data.dart';

class AnnotationStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  Future<void> saveAnnotations(List<AnnotationData> annotations, String fileName) async {
    final file = await _localFile(fileName);
    final jsonList = annotations.map((a) => a.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }

  Future<List<AnnotationData>> loadAnnotations(String fileName) async {
    try {
      final file = await _localFile(fileName);
      final contents = await file.readAsString();
      final jsonList = json.decode(contents) as List;
      return jsonList.map((json) => AnnotationData.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}
