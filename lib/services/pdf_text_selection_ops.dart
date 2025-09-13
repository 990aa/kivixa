import 'dart:ui';

import '../data/repository.dart';
import 'pdf_annotation_service.dart';

class PdfSelection {
  final int documentId;
  final int pageNumber;
  final List<Rect> rects;
  final String text;
  final List<String> provenance;

  PdfSelection({
    required this.documentId,
    required this.pageNumber,
    required this.rects,
    required this.text,
    this.provenance = const [],
  });
}

class PdfTextSelectionOps {
  final Repository _repo;
  final PdfAnnotationService _annotationService;

  PdfTextSelectionOps(this._repo, this._annotationService);

  Future<int> createAnnotationFromSelection(PdfSelection selection, AnnotationType type, {String? comment}) {
    final newProvenance = List<String>.from(selection.provenance);
    newProvenance.add('Created annotation from selection at ${DateTime.now()}');

    final annotation = PdfAnnotation(
      documentId: selection.documentId,
      pageNumber: selection.pageNumber,
      rects: selection.rects,
      type: type,
      text: selection.text,
      provenance: newProvenance,
    );

    return _annotationService.addAnnotation(annotation, comment: comment);
  }

  Future<void> moveSelectionToDocument(PdfSelection selection, int targetDocumentId) async {
    final newProvenance = List<String>.from(selection.provenance);
    newProvenance.add('Moved from document ${selection.documentId} to $targetDocumentId at ${DateTime.now()}');

    final newAnnotation = PdfAnnotation(
      documentId: targetDocumentId,
      pageNumber: 1, // Or some other default page number
      rects: [], // Rects might not be meaningful in the new document
      type: AnnotationType.highlight, // Or some other default type
      text: selection.text,
      provenance: newProvenance,
    );

    await _repo.batchWrite([
      () async {
        // In a real implementation, we would also delete the original annotation if it exists.
        // For now, we just create a new one.
        await _annotationService.addAnnotation(newAnnotation);
      }
    ]);
  }
}