
import 'dart:async';

import 'package:kivixa/ai/providers.dart';

class AIActionsService {
  final AIProvider _provider;

  AIActionsService(this._provider);

  Stream<String> summarizeSelection(String text) {
    return _executeWithRetries(() => _provider.summarize(text));
  }

  Stream<String> outlinePage(String text) {
    final prompt = 'Create an outline for the following text:\n$text';
    return _provider.streamCompletion(prompt);
  }

  Stream<String> translate(String text, String targetLanguage) {
    return _executeWithRetries(() => _provider.translate(text, targetLanguage));
  }

  Stream<String> handwritingToText(List<int> imageData) {
    return _executeWithRetries(() => _provider.ocrHandwriting(imageData));
  }

  Stream<T> _executeWithRetries<T>(
    Stream<T> Function() execution, {
    int retries = 3,
  }) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    var attempt = 0;

    void start() {
      attempt++;
      subscription = execution().listen(
        controller.add,
        onError: (e) {
          if (attempt >= retries) {
            controller.addError(e);
            controller.close();
          } else {
            // In a real-world scenario, you would implement exponential backoff here.
            Future.delayed(const Duration(seconds: 1), start);
          }
        },
        onDone: controller.close,
      );
    }

    controller = StreamController<T>(
      onListen: start,
      onCancel: () => subscription?.cancel(),
    );

    return controller.stream;
  }
}
