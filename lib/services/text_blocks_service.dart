
import 'package:flutter/material.dart';

import '../data/repository.dart';

class TextBlocksService {
  final Repository _repository;

  TextBlocksService(this._repository);

  /// Updates a text block.
  Future<void> updateTextBlock(int textBlockId, String styledJson, String plainText) async {
    await _repository.updateTextBlock(textBlockId, {
      'styled_json': styledJson,
      'plain_text': plainText,
    });
  }

  /// Gets a text block.
  Future<TextBlock?> getTextBlock(int textBlockId) async {
    final data = await _repository.getTextBlock(textBlockId);
    if (data != null) {
      return TextBlock(data['styled_json'], data['plain_text']);
    }
    return null;
  }

  /// Gets the selection range for a text block.
  Future<TextSelection?> getSelectionRange(int textBlockId) async {
    final data = await _repository.getTextBlock(textBlockId);
    if (data != null && data['selection_base'] != null && data['selection_extent'] != null) {
      return TextSelection(
        baseOffset: data['selection_base'],
        extentOffset: data['selection_extent'],
      );
    }
    return null;
  }

  /// Saves the selection range for a text block.
  Future<void> saveSelectionRange(int textBlockId, TextSelection selection) async {
    await _repository.updateTextBlock(textBlockId, {
      'selection_base': selection.baseOffset,
      'selection_extent': selection.extentOffset,
    });
  }
}

class TextBlock {
  final String styledJson;
  final String plainText;

  TextBlock(this.styledJson, this.plainText);
}

