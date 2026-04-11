class LiveTranscriptionEdit {
  const LiveTranscriptionEdit({
    required this.startOffset,
    required this.replacedLength,
    required this.replacementText,
  });

  final int startOffset;
  final int replacedLength;
  final String replacementText;

  int get endOffset => startOffset + replacedLength;

  int get caretOffset => startOffset + replacementText.length;
}

/// Tracks partial speech dictation so interim updates replace in-place.
class LiveTranscriptionBuffer {
  int? _anchorOffset;
  int _previewLength = 0;
  String? _lastFinalText;

  void startSession({required int anchorOffset}) {
    _anchorOffset = anchorOffset;
    _previewLength = 0;
    _lastFinalText = null;
  }

  void reset() {
    _anchorOffset = null;
    _previewLength = 0;
    _lastFinalText = null;
  }

  LiveTranscriptionEdit? buildEdit({
    required String text,
    required bool isFinal,
    required int currentTextLength,
    int? fallbackAnchorOffset,
  }) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return null;
    }

    final safeLength = currentTextLength < 0 ? 0 : currentTextLength;
    final anchor = _resolveAnchor(safeLength, fallbackAnchorOffset);
    final safePreviewLength = _clamp(
      _previewLength,
      0,
      safeLength - anchor,
    );

    if (isFinal && _lastFinalText == normalizedText && safePreviewLength == 0) {
      return null;
    }

    final replacementText = isFinal ? '$normalizedText ' : normalizedText;
    final edit = LiveTranscriptionEdit(
      startOffset: anchor,
      replacedLength: safePreviewLength,
      replacementText: replacementText,
    );

    if (isFinal) {
      _lastFinalText = normalizedText;
      _anchorOffset = edit.caretOffset;
      _previewLength = 0;
    } else {
      _anchorOffset = anchor;
      _previewLength = replacementText.length;
    }

    return edit;
  }

  int _resolveAnchor(int currentTextLength, int? fallbackAnchorOffset) {
    final fallback = fallbackAnchorOffset ?? currentTextLength;
    final requested = _anchorOffset ?? fallback;
    return _clamp(requested, 0, currentTextLength);
  }

  int _clamp(int value, int minValue, int maxValue) {
    if (value < minValue) {
      return minValue;
    }
    if (value > maxValue) {
      return maxValue;
    }
    return value;
  }
}
