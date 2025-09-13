
import 'dart:async';

import '../data/repository.dart';

// Defines sorting options for library items.
enum SortBy { date, name }

// Manages library operations like listing, moving, and organizing.
class LibraryService {
  final Repository _repo;

  LibraryService(this._repo);

  String _orderBy(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.name:
        return 'title ASC';
      case SortBy.date:
      default:
        return 'updated_at DESC';
    }
  }

  // Lists notebooks with pagination and sorting.
  Future<List<Map<String, dynamic>>> listNotebooks({
    int page = 1,
    int limit = 20,
    SortBy sortBy = SortBy.date,
  }) async {
    final offset = (page - 1) * limit;
    // TODO: Add sorting to the repository layer for notebooks.
    return await _repo.listNotebooks(limit: limit, offset: offset);
  }

  // Lists documents and folders within a given parent.
  Future<List<Map<String, dynamic>>> listDocuments({
    int? parentId,
    int page = 1,
    int limit = 20,
    SortBy sortBy = SortBy.date,
  }) async {
    final offset = (page - 1) * limit;
    return await _repo.listDocuments(
      parentId: parentId,
      orderBy: _orderBy(sortBy),
      limit: limit,
      offset: offset,
    );
  }

  // Moves a document to a new parent folder.
  Future<void> moveDocument(int documentId, int? newParentId) async {
    await _repo.batchWrite([
      () => _repo.updateDocument(documentId, {'parent_id': newParentId})
    ]);
  }
}
