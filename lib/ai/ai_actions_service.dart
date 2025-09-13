import 'dart:async';
import 'providers.dart';

class AIActionsService {
  final AIProvider _provider;

  AIActionsService(this._provider);

  Stream<String> summarizeSelection(String text) {
    final controller = StreamController<String>();
    _summarizeWithRetries(text, controller, 0);
    return controller.stream;
  }

  Stream<String> outlinePage(String text) {
    final prompt = 'Create an outline for the following text:\n$text';
    return _streamCompletionWithRetries(prompt, 0);
  }

  Stream<String> translate(String text, String targetLanguage) {
    final controller = StreamController<String>();
    _translateWithRetries(text, targetLanguage, controller, 0);
    return controller.stream;
  }

  Stream<String> handwritingToText(List<int> imageData) {
    final controller = StreamController<String>();
    _ocrWithRetries(imageData, controller, 0);
    return controller.stream;
  }

  Stream<String> _streamCompletionWithRetries(String prompt, int attempt) {
    // This is a simplified example. A real implementation would use a specific model.
    final model = AIModel(id: 'default', name: 'default', provider: 'default');
    return _provider.streamCompletion(prompt, model).handleError((error) {
      if (_shouldRetry(error) && attempt < 5) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        return Stream.fromFuture(Future.delayed(delay))
            .asyncExpand((_) => _streamCompletionWithRetries(prompt, attempt + 1));
      } else {
        throw error;
      }
    });
  }

  void _summarizeWithRetries(String text, StreamController<String> controller, int attempt) async {
    try {
      final summary = await _provider.summarize(text);
      controller.add(summary);
      await controller.close();
    } catch (e) {
      if (_shouldRetry(e) && attempt < 5) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        Future.delayed(delay, () => _summarizeWithRetries(text, controller, attempt + 1));
      } else {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  void _translateWithRetries(String text, String targetLanguage, StreamController<String> controller, int attempt) async {
    try {
      final translation = await _provider.translate(text, targetLanguage);
      controller.add(translation);
      await controller.close();
    } catch (e) {
      if (_shouldRetry(e) && attempt < 5) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        Future.delayed(delay, () => _translateWithRetries(text, targetLanguage, controller, attempt + 1));
      } else {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  void _ocrWithRetries(List<int> imageData, StreamController<String> controller, int attempt) async {
    try {
      final text = await _provider.ocrHandwriting(imageData);
      controller.add(text);
      await controller.close();
    } catch (e) {
      if (_shouldRetry(e) && attempt < 5) {
        final delay = Duration(seconds: 2 * (attempt + 1));
        Future.delayed(delay, () => _ocrWithRetries(imageData, controller, attempt + 1));
      } else {
        controller.addError(e);
        await controller.close();
      }
    }
  }

  bool _shouldRetry(Object error) {
    // In a real app, inspect the error to see if it's a rate limit error
    return true;
  }
}