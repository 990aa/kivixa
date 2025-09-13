import 'dart:convert';

import '../data/repository.dart';
import 'outline_comments_service.dart';

class ScannedPageOutline {
  final int? id;
  final int documentId;
  final int pageNumber;
  final String comment;

  ScannedPageOutline({
    this.id,
    required this.documentId,
    required this.pageNumber,
    required this.comment,
  });
}

class ScannedPagesOutlineService {
  final Repository _repo;
  final OutlineService _outlineService;
  final CommentsService _commentsService;

  ScannedPagesOutlineService(this._repo, this._outlineService, this._commentsService);

  Future<void> addOutline(ScannedPageOutline outline) async {
    final outlineData = {
      'documentId': outline.documentId,
      'pageNumber': outline.pageNumber,
      'text': outline.comment,
      'type': 'scanned_page_outline',
    };
    final outlineId = await _outlineService.addOutline(outline.documentId, jsonEncode(outlineData));

    // I'm assuming pageId can be retrieved from documentId and pageNumber
    final pages = await _repo.listPages(documentId: outline.documentId, limit: 1, offset: outline.pageNumber - 1);
    if (pages.isNotEmpty) {
      final pageId = pages.first['id'];
      final commentId = await _commentsService.addComment(pageId, outline.comment);

      // Now, let's store a reference in the thumbnail metadata.
      // This assumes the thumbnail entry already exists.
      final metadata = {
        'outlineId': outlineId,
        'commentId': commentId,
      };
      await _repo.updatePageThumbnailMetadata(pageId, metadata);
    }
  }

  // Deleting would require a way to find the associated outline/comment from the page number.
  // This is a simplified implementation.
}