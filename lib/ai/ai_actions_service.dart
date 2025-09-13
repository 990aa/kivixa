
import 'dart:async';

import 'package:kivixa/ai/providers.dart';

class AIActionsService {
  final AIProvider _provider;

  AIActionsService(this._provider);

  Stream<String> summarizeSelection(String text) {
    final controller = StreamController<String>();
    _executeWithRetries(() => _provider.summarize(text), controller);
    return controller.stream;
  }

  Stream<String> outlinePage(String text) {
    final prompt = 'Create an outline for the following text:\n$text';
    return _provider.streamCompletion(prompt);
  }

  Stream<String> translate(String text, String targetLanguage) {
    final controller = StreamController<String>();
    _executeWithRetries(() => _provider.translate(text, targetLanguage), controller);
    return controller.stream;
  }

  Stream<String> handwritingToText(List<int> imageData) {
    final controller = StreamController<String>();
    _executeWithRetries(() => _provider.ocrHandwriting(imageData), controller);
    return controller.stream;
  }

  void _executeWithRetries<T>(
    Future<T> Function() execution,
    StreamController<T> controller,
  ) async {
    for (var i = 0; i < retries; i++) {
      try {
        final result = await execution();
        controller.add(result);
        await controller.close();
        return;
      } catch (e) {
        if (i == retries - 1) {
          controller.addError(e);
          await controller.close();
        }
        // In a real-world scenario, you would implement exponential backoff here.
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
