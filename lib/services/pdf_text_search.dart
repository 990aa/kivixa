import 'package:pdfx/pdfx.dart';
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
    final doc = await PdfDocument.openFile(pdfPath);
    final results = <PdfSearchResult>[];

    for (var i = 1; i <= doc.pagesCount; i++) {
      final page = await doc.getPage(i);
      // Try to extract text using pdfx's PdfPageImageText if available
      String? pageText;
      try {
        final textContent = await page.getText();
        pageText = textContent?.text;
      } catch (_) {
        pageText = null;
      }
      if (pageText != null && pageText.contains(query)) {
        results.add(
          PdfSearchResult(pageIndex: i, text: pageText, bounds: Rect.zero),
        );
      }
    }
    return results;
  }
}
