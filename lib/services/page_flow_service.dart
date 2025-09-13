// PageFlowService: Manages page flow modes and page addition helpers.

enum PageFlowMode { autoAddOnWrite, swipeUpToAdd }

class PageFlowService {
  // Stores the active mode per document (docId -> mode)
  final Map<String, PageFlowMode> _docModes = {};

  // Set mode for a document
  void setMode(String docId, PageFlowMode mode) {
    _docModes[docId] = mode;
  }

  // Get mode for a document
  PageFlowMode getMode(String docId) {
    return _docModes[docId] ?? PageFlowMode.autoAddOnWrite;
  }

  // Add a page with a template, return metadata for quick thumbnail update
  Map<String, dynamic> addPageWithTemplate(String docId, String templateId) {
    // Simulate adding a page and returning metadata
    final pageId = DateTime.now().millisecondsSinceEpoch.toString();
    final metadata = {
      'pageId': pageId,
      'templateId': templateId,
      'thumbnailUrl': '/thumbnails/$pageId.png',
      'createdAt': DateTime.now().toIso8601String(),
    };
    // ... Add page to document logic ...
    return metadata;
  }

  // Helper: Should auto-add page on last-page write?
  bool shouldAutoAddOnWrite(String docId) {
    return getMode(docId) == PageFlowMode.autoAddOnWrite;
  }

  // Helper: Should add page on swipe up?
  bool shouldAddOnSwipeUp(String docId) {
    return getMode(docId) == PageFlowMode.swipeUpToAdd;
  }
}
