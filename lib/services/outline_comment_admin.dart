import 'dart:async';

import '../data/repository.dart';

class OutlineCommentAdmin {
  final Repository _repo;

  OutlineCommentAdmin(this._repo);

  Future<void> clearAll(int documentId) async {
    await _repo.batchWrite([
      () async {
        final outlines = await _repo.listOutlines(documentId: documentId);
        for (final outline in outlines) {
          await _repo.deleteOutline(outline['id']);
        }
      },
      () async {
        final pages = await _repo.listPages(documentId: documentId);
        for (final page in pages) {
          final comments = await _repo.listComments(pageId: page['id']);
          for (final comment in comments) {
            await _repo.deleteComment(comment['id']);
          }
        }
      },
    ]);
  }

  Future<void> reverseChronology(int documentId) async {
    // This is a complex operation. For now, we'll just reorder the comments for each page.
    // A full implementation would require more details on how to handle outlines.
    await _repo.batchWrite([
      () async {
        final pages = await _repo.listPages(documentId: documentId);
        for (final page in pages) {
          final comments = await _repo.listComments(pageId: page['id']);
          final sortedComments = List.from(comments);
          sortedComments.sort((a, b) => b['created_at'].compareTo(a['created_at']));
          // The repository doesn't have a way to reorder comments, so this is a conceptual implementation.
          // A real implementation would need to update the order of comments in the database.
        }
      },
    ]);
  }

  Future<int> saveCommentsPagesAsNewDoc(int documentId, List<int> pageIds) async {
    final newDocId = await _repo.createDocument({'name': 'New Document with Comments'});
    await _repo.batchWrite([
      () async {
        for (final pageId in pageIds) {
          final page = await _repo.getPage(pageId);
          if (page != null) {
            final newPage = Map<String, dynamic>.from(page);
            newPage.remove('id');
            newPage['document_id'] = newDocId;
            await _repo.createPage(newPage);
          }
        }
      },
    ]);
    return newDocId;
  }

  Future<void> copyToOtherDoc(int fromDocumentId, int toDocumentId, List<int> pageIds) async {
    await _repo.batchWrite([
      () async {
        for (final pageId in pageIds) {
          final page = await _repo.getPage(pageId);
          if (page != null) {
            final newPage = Map<String, dynamic>.from(page);
            newPage.remove('id');
            newPage['document_id'] = toDocumentId;
            await _repo.createPage(newPage);
          }
        }
      },
    ]);
  }

  Future<String> export(int documentId, List<int> pageIds) async {
    final buffer = StringBuffer();
    for (final pageId in pageIds) {
      final comments = await _repo.listComments(pageId: pageId);
      for (final comment in comments) {
        buffer.writeln('Page $pageId: ${comment['content']}');
      }
    }
    return buffer.toString();
  }

  Future<void> move(int fromDocumentId, int toDocumentId, List<int> pageIds) async {
    await _repo.batchWrite([
      () async {
        for (final pageId in pageIds) {
          await _repo.updatePage(pageId, {'document_id': toDocumentId});
        }
      },
    ]);
  }
}