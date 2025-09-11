import 'package:sqflite/sqflite.dart';

class PdfAnnotationService {
  final Database db;
  PdfAnnotationService(this.db);

  Future<void> saveAnnotation(
    int pageId,
    String type,
    Map<String, dynamic> coords,
    String text,
  ) async {
    await db.insert('pdf_annotations', {
      'page_id': pageId,
      'type': type,
      'coords': coords.toString(),
      'text': text,
    });
  }

  // Platform-specific PDF text selection and annotation APIs to be implemented
}
