import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repository.dart';

class LongPressActionsService {
  final Repository _repository;

  LongPressActionsService(this._repository);

  /// Re-edits a text element.
  Future<void> reEditText(int textId) async {
    final textBlock = await _repository.getTextBlock(textId);
    if (textBlock != null) {
      // In a real app, you would open an editor with the text block data.
      // For now, we just simulate an update.
      await _repository.updateTextBlock(textId, {
        'styled_json': textBlock['styled_json'],
        'plain_text': textBlock['plain_text'],
      });
    }
  }

  /// Re-edits an image element.
  Future<void> reEditImage(int imageId) async {
    final image = await _repository.getImage(imageId);
    if (image != null) {
      // In a real app, you would open an editor with the image data.
      // For now, we just simulate an update.
      await _repository.updateImage(imageId, {
        'asset_path': image['asset_path'],
        'transform': image['transform'],
      });
    }
  }

  /// Re-edits a shape element.
  Future<void> reEditShape(int shapeId) async {
    final shape = await _repository.getShape(shapeId);
    if (shape != null) {
      // In a real app, you would open an editor with the shape data.
      // For now, we just simulate an update.
      await _repository.updateShape(shapeId, {
        'svg': shape['svg'],
        'transform': shape['transform'],
      });
    }
  }

  /// Pastes content at the given coordinates.
  Future<void> pasteAtCoordinates(int pageId, int layerId, Offset coordinates) async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      await _repository.createTextBlock({
        'page_id': pageId,
        'layer_id': layerId,
        'plain_text': clipboardData.text,
        'x': coordinates.dx,
        'y': coordinates.dy,
      });
    }
  }

  /// Reorders documents.
  Future<void> reorderDocuments(int documentId, int newIndex) async {
    final documents = await _repository.listDocuments(orderBy: 'display_order ASC');
    final docIndex = documents.indexWhere((d) => d['id'] == documentId);

    if (docIndex == -1) {
      throw Exception('Document not found');
    }

    final doc = documents.removeAt(docIndex);
    documents.insert(newIndex, doc);

    await _repository.batchWrite([
      for (var i = 0; i < documents.length; i++)
        () => _repository.updateDocument(documents[i]['id'], {'display_order': i})
    ]);
  }

  /// Moves a document to a folder.
  Future<void> moveToFolder(int documentId, int folderId) async {
    await _repository.updateDocument(documentId, {'parent_id': folderId});
  }

  /// Creates a nested outline item.
  Future<void> createNestedOutlineItem(int documentId, int parentItemId) async {
    await _repository.createOutline({
      'document_id': documentId,
      'parent_id': parentItemId,
      'title': 'New Item',
    });
  }
}