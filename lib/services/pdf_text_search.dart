import 'dart:ui';

class PdfSearchResult {
  final int pageIndex;
  final String text;
  final Rect bounds;

  PdfSearchResult({
    required this.pageIndex,
    required this.text,
    required this.bounds,
  });
}

class PdfTextSearch {
  Future<List<PdfSearchResult>> search(String pdfPath, String query) async {
    // pdfrx does not support text extraction as of 2025-09-14.
    // This is a stub implementation. When/if pdfrx adds text extraction, implement it here.
    return <PdfSearchResult>[];
  }
}
