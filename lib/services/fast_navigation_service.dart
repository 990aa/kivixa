import 'dart:async';

import '../data/repository.dart'; // This file provides DocumentRepository

abstract class PageIdentifier {}

class PageNumberIdentifier implements PageIdentifier {
  final int pageNumber;
  PageNumberIdentifier(this.pageNumber);
}

class PageIdIdentifier implements PageIdentifier {
  final int pageId;
  PageIdIdentifier(this.pageId);
}

class FastNavigationService {
  final DocumentRepository _repo; // Changed from Repository to DocumentRepository

  int? _currentDocumentId;
  final Map<int, int> _pageNumberToIdCache = {};

  // This stream would be used to notify the UI to navigate to a page.
  final _navigationController = StreamController<int>.broadcast();
  Stream<int> get navigationStream => _navigationController.stream;

  FastNavigationService(this._repo);

  Future<void> loadDocument(int documentId) async {
    if (_currentDocumentId == documentId) return;

    _currentDocumentId = documentId;
    _pageNumberToIdCache.clear();

    // Note: DocumentRepository does not currently have a listPages method.
    // This will cause an error.
    final pages = await _repo.listPages(documentId: documentId);
    for (var i = 0; i < pages.length; i++) {
      // Assuming pages are ordered by page number.
      _pageNumberToIdCache[i + 1] = pages[i]['id'];
    }
  }

  Future<void> goTo(PageIdentifier pageIdentifier) async {
    final pageId = await _resolvePageId(pageIdentifier);
    if (pageId != null) {
      _navigationController.add(pageId);
    }
  }

  Future<int?> _resolvePageId(PageIdentifier pageIdentifier) async {
    if (pageIdentifier is PageIdIdentifier) {
      return pageIdentifier.pageId;
    }
    if (pageIdentifier is PageNumberIdentifier) {
      if (_pageNumberToIdCache.containsKey(pageIdentifier.pageNumber)) {
        return _pageNumberToIdCache[pageIdentifier.pageNumber];
      }
    }
    return null;
  }

  void dispose() {
    _navigationController.close();
  }
}