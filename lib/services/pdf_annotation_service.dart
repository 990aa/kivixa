import 'dart:convert';
import 'dart:ui';

import '../data/repository.dart';
import 'outline_comments_service.dart';

enum AnnotationType { highlight, underline, strike }

class PdfAnnotation {
  final int? id;
  final int documentId;
  final int pageNumber;
  final List<Rect> rects;
  final AnnotationType type;
  final String text;
  final List<String> provenance;

  PdfAnnotation({
    this.id,
    required this.documentId,
    required this.pageNumber,
    required this.rects,
    required this.type,
    required this.text,
    this.provenance = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'page_number': pageNumber,
      'rects': jsonEncode(rects.map((r) => {'left': r.left, 'top': r.top, 'right': r.right, 'bottom': r.bottom}).toList()),
      'type': type.index,
      'text': text,
      'provenance': jsonEncode(provenance),
    };
  }

  static PdfAnnotation fromMap(Map<String, dynamic> map) {
    return PdfAnnotation(
      id: map['id'],
      documentId: map['document_id'],
      pageNumber: map['page_number'],
      rects: (jsonDecode(map['rects']) as List).map((r) => Rect.fromLTRB(r['left'], r['top'], r['right'], r['bottom'])).toList(),
      type: AnnotationType.values[map['type']],
      text: map['text'],
      provenance: map['provenance'] != null ? (jsonDecode(map['provenance']) as List).cast<String>() : [],
    );
  }
}

class PdfAnnotationService {
  final Repository _repo;
  // final OutlineService _outlineService; // Removed unused field
  final CommentsService _commentsService;

  PdfAnnotationService(this._repo, this._commentsService);

  Future<int> addAnnotation(PdfAnnotation annotation, {String? comment}) async {
    final annotationId = await _repo.createPdfAnnotation(annotation.toMap());

    if (comment != null && comment.isNotEmpty) {
        // final outlineData = { // Removed unused local variable
        //   'documentId': annotation.documentId,
        //   'pageNumber': annotation.pageNumber,
        //   'text': annotation.text,
        //   'type': 'pdf_annotation',
        //   'annotationId': annotationId,
        // };
      
      // I'm assuming pageId can be retrieved from documentId and pageNumber
      // This is a simplification. A more robust solution would be needed.
      final pages = await _repo.listPages(documentId: annotation.documentId, limit: 1, offset: annotation.pageNumber -1);
      if (pages.isNotEmpty) {
        final pageId = pages.first['id'];
        await _commentsService.addComment(pageId, comment);
      }
    }

    return annotationId;
  }

  Future<List<PdfAnnotation>> getAnnotationsForPage(int documentId, int pageNumber) async {
    final maps = await _repo.listPdfAnnotations(documentId: documentId, pageNumber: pageNumber);
    return maps.map((map) => PdfAnnotation.fromMap(map)).toList();
  }

  Future<void> deleteAnnotation(int annotationId) async {
    // Also delete associated outline/comment
    final annotationMap = await _repo.getPdfAnnotation(annotationId);
    if (annotationMap != null) {
      // This is a simplification. We would need a way to find the exact outline/comment to delete.
      // For now, we just delete the annotation from the database.
      await _repo.deletePdfAnnotation(annotationId);
    }
  }
}