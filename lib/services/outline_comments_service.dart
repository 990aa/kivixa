
import 'dart:async';

import '../data/repository.dart';

// Manages outlines for documents.
class OutlineService {
  final Repository _repo;

  OutlineService(this._repo);

  // Adds a new outline to a document.
  Future<int> addOutline(int documentId, String data) async {
    return await _repo.createOutline({
      'document_id': documentId,
      'data': data,
    });
  }

  // Lists all outlines for a document.
  Future<List<Map<String, dynamic>>> listOutlines(int documentId) async {
    return await _repo.listOutlines(documentId: documentId);
  }

  // Deletes an outline.
  Future<void> deleteOutline(int outlineId) async {
    await _repo.deleteOutline(outlineId);
  }
}

// Manages comments for pages.
class CommentsService {
  final Repository _repo;

  CommentsService(this._repo);

  // Adds a new comment to a page.
  Future<int> addComment(int pageId, String content, {String? author}) async {
    return await _repo.createComment({
      'page_id': pageId,
      'content': content,
      'author': author,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Lists all comments for a page.
  Future<List<Map<String, dynamic>>> listComments(int pageId) async {
    return await _repo.listComments(pageId: pageId);
  }

  // Deletes a comment.
  Future<void> deleteComment(int commentId) async {
    await _repo.deleteComment(commentId);
  }
}
