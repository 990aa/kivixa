import '../data/repository.dart';

// Placeholder for a PDF manipulation library
abstract class PdfManipulationLibrary {
  Future<String> mergePages(List<String> pdfPaths, List<int> pageNumbers);
  Future<List<String>> splitPdf(String pdfPath, List<List<int>> pageGroups);
}

class MergeSplitPdf {
  final Repository _repo;
  final PdfManipulationLibrary _pdfLib;

  MergeSplitPdf(this._repo, this._pdfLib);

  Future<int> merge(List<int> pageIds, String newDocumentName) async {
    final pages = <Map<String, dynamic>>[];
    for (final pageId in pageIds) {
      final page = await _repo.getPage(pageId);
      if (page != null) {
        pages.add(page);
      }
    }

    final pdfPaths = pages.map((p) => p['pdf_path'] as String).toSet().toList();
    final pageNumbers = pages.map((p) => p['page_number'] as int).toList();

    final newPdfPath = await _pdfLib.mergePages(pdfPaths, pageNumbers);

    final newDocId = await _repo.createDocument({'name': newDocumentName});

    for (var i = 0; i < pages.length; i++) {
      final originalPage = pages[i];
      final newPageProvenance = {
        'operation': 'merge',
        'source_document_id': originalPage['document_id'],
        'source_page_id': originalPage['id'],
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await _repo.createPage({
        'document_id': newDocId,
        'page_number': i + 1,
        'pdf_path': newPdfPath,
        'provenance': newPageProvenance,
      });
    }

    return newDocId;
  }

  Future<List<int>> split(int documentId, List<List<int>> pageGroups) async {
    final doc = await _repo.getDocument(documentId);
    if (doc == null) {
      throw Exception('Document not found');
    }

    final pdfPath = doc['pdf_path'] as String;
    final newPdfPaths = await _pdfLib.splitPdf(pdfPath, pageGroups);

    final newDocIds = <int>[];
    for (var i = 0; i < newPdfPaths.length; i++) {
      final newDocId = await _repo.createDocument({'name': '${doc['name']}_part_${i + 1}'});
      newDocIds.add(newDocId);

      for (var j = 0; j < pageGroups[i].length; j++) {
        final originalPageNumber = pageGroups[i][j];
        final newPageProvenance = {
          'operation': 'split',
          'source_document_id': documentId,
          'source_page_number': originalPageNumber,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        await _repo.createPage({
          'document_id': newDocId,
          'page_number': j + 1,
          'pdf_path': newPdfPaths[i],
          'provenance': newPageProvenance,
        });
      }
    }

    return newDocIds;
  }
}