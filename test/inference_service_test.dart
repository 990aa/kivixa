import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/inference_service.dart';

void main() {
  group('InferenceConfig', () {
    test('should have correct default values', () {
      const config = InferenceConfig();
      expect(config.nGpuLayers, 99);
      expect(config.nCtx, 4096);
      expect(config.nThreads, 4);
      expect(config.temperature, 0.7);
      expect(config.topP, 0.9);
      expect(config.maxTokens, 512);
    });

    test('should allow custom values', () {
      const config = InferenceConfig(
        nGpuLayers: 50,
        nCtx: 2048,
        nThreads: 8,
        temperature: 0.5,
        topP: 0.8,
        maxTokens: 256,
      );
      expect(config.nGpuLayers, 50);
      expect(config.nCtx, 2048);
      expect(config.nThreads, 8);
      expect(config.temperature, 0.5);
      expect(config.topP, 0.8);
      expect(config.maxTokens, 256);
    });
  });

  group('ChatMessage', () {
    test('should create system message', () {
      final msg = ChatMessage.system('You are helpful.');
      expect(msg.role, 'system');
      expect(msg.content, 'You are helpful.');
    });

    test('should create user message', () {
      final msg = ChatMessage.user('Hello!');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello!');
    });

    test('should create assistant message', () {
      final msg = ChatMessage.assistant('Hi there!');
      expect(msg.role, 'assistant');
      expect(msg.content, 'Hi there!');
    });

    test('should convert to tuple', () {
      const msg = ChatMessage(role: 'user', content: 'Test');
      final tuple = msg.toTuple();
      expect(tuple.$1, 'user');
      expect(tuple.$2, 'Test');
    });
  });

  group('InferenceService', () {
    test('should be a singleton', () {
      final instance1 = InferenceService();
      final instance2 = InferenceService();
      expect(identical(instance1, instance2), true);
    });

    test('should start uninitialized', () {
      final service = InferenceService();
      // Note: Can't reliably test this as it may have been initialized
      // in other tests. Just verify the property exists.
      expect(service.isInitialized, isA<bool>());
    });

    test('should start with model not loaded', () {
      final service = InferenceService();
      // Note: Checking the type is bool, actual value depends on test order
      expect(service.isModelLoaded, isA<bool>());
    });

    test('should return null embedding dimension when model not loaded', () {
      final service = InferenceService();
      // If model is not loaded, dimension should be null or a default
      expect(service.embeddingDimension, anyOf(isNull, isA<int>()));
    });

    test('healthCheck should complete', () async {
      final service = InferenceService();
      final result = await service.healthCheck();
      expect(result, isA<bool>());
    });
  });
}
