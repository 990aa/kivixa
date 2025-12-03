// Model Manager URL Tests
//
// Tests that the model download URLs are correctly configured
// and point to valid HuggingFace model repositories.

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/model_manager.dart';

void main() {
  group('Model Manager Configuration', () {
    test('availableModels is not empty', () {
      expect(ModelManager.availableModels, isNotEmpty);
    });

    test('defaultModel is the first available model', () {
      expect(ModelManager.defaultModel, ModelManager.availableModels.first);
    });

    test('Phi-4 Mini model is correctly configured', () {
      final phi4Model = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'phi4-mini-q4km',
      );

      expect(phi4Model.name, 'Phi-4 Mini');
      expect(
        phi4Model.url,
        contains('bartowski/microsoft_Phi-4-mini-instruct-GGUF'),
      );
      expect(phi4Model.url, contains('Q4_K_M.gguf'));
      expect(phi4Model.fileName, 'microsoft_Phi-4-mini-instruct-Q4_K_M.gguf');
    });

    test('model URL uses correct HuggingFace resolve format', () {
      final model = ModelManager.defaultModel;

      // HuggingFace direct download URLs should use /resolve/main/ format
      expect(model.url, contains('/resolve/main/'));
      expect(model.url, startsWith('https://huggingface.co/'));
    });

    test('model filename matches URL', () {
      final model = ModelManager.defaultModel;

      // The filename in the URL should match the fileName property
      expect(model.url, endsWith(model.fileName));
    });

    test('model size is reasonable for Q4_K_M quantization', () {
      final phi4Model = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'phi4-mini-q4km',
      );

      // Q4_K_M should be around 2-3 GB
      const oneGB = 1024 * 1024 * 1024;
      expect(phi4Model.sizeBytes, greaterThan(2 * oneGB));
      expect(phi4Model.sizeBytes, lessThan(4 * oneGB));
    });

    test('model sizeText is formatted correctly', () {
      final model = ModelManager.defaultModel;
      final sizeText = model.sizeText;

      // Should display in GB format
      expect(sizeText, contains('GB'));
    });

    test('model has required fields', () {
      for (final model in ModelManager.availableModels) {
        expect(model.id, isNotEmpty);
        expect(model.name, isNotEmpty);
        expect(model.description, isNotEmpty);
        expect(model.url, isNotEmpty);
        expect(model.fileName, isNotEmpty);
        expect(model.sizeBytes, greaterThan(0));
      }
    });
  });

  group('AIModel', () {
    test('AIModel can be created with all fields', () {
      const model = AIModel(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model for unit testing',
        url: 'https://example.com/model.gguf',
        fileName: 'model.gguf',
        sizeBytes: 1000000,
        sha256Hash: 'abc123',
      );

      expect(model.id, 'test-model');
      expect(model.name, 'Test Model');
      expect(model.sha256Hash, 'abc123');
    });

    test('AIModel sizeText formats KB correctly', () {
      const model = AIModel(
        id: 'small',
        name: 'Small Model',
        description: 'Small',
        url: 'https://example.com/small.gguf',
        fileName: 'small.gguf',
        sizeBytes: 512 * 1024, // 512 KB
      );

      expect(model.sizeText, contains('KB'));
    });

    test('AIModel sizeText formats MB correctly', () {
      const model = AIModel(
        id: 'medium',
        name: 'Medium Model',
        description: 'Medium',
        url: 'https://example.com/medium.gguf',
        fileName: 'medium.gguf',
        sizeBytes: 512 * 1024 * 1024, // 512 MB
      );

      expect(model.sizeText, contains('MB'));
    });

    test('AIModel sizeText formats GB correctly', () {
      const model = AIModel(
        id: 'large',
        name: 'Large Model',
        description: 'Large',
        url: 'https://example.com/large.gguf',
        fileName: 'large.gguf',
        sizeBytes: 2 * 1024 * 1024 * 1024, // 2 GB
      );

      expect(model.sizeText, contains('GB'));
    });
  });

  group('ModelDownloadProgress', () {
    test('progressText shows preparing when totalBytes is 0', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
      );

      expect(progress.progressText, 'Preparing...');
    });

    test('progressText shows MB format for download progress', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: 0.5,
        downloadedBytes: 512 * 1024 * 1024,
        totalBytes: 1024 * 1024 * 1024,
      );

      expect(progress.progressText, contains('MB'));
    });

    test('speedText formats bytes per second', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: 500,
      );

      expect(progress.speedText, contains('B/s'));
    });

    test('speedText formats KB per second', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: 5000,
      );

      expect(progress.speedText, contains('KB/s'));
    });

    test('speedText formats MB per second', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: 5000000,
      );

      expect(progress.speedText, contains('MB/s'));
    });

    test('estimatedSecondsRemaining calculates correctly', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        downloadedBytes: 500,
        totalBytes: 1000,
        networkSpeed: 100,
      );

      expect(progress.estimatedSecondsRemaining, 5);
    });

    test('etaText shows seconds for short times', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        downloadedBytes: 950,
        totalBytes: 1000,
        networkSpeed: 10,
      );

      expect(progress.etaText, contains('s remaining'));
    });

    test('etaText shows minutes for medium times', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        downloadedBytes: 0,
        totalBytes: 6000,
        networkSpeed: 100,
      );

      expect(progress.etaText, contains('m remaining'));
    });

    test('copyWith creates new instance with updated values', () {
      const original = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: 0.5,
      );

      final updated = original.copyWith(
        state: ModelDownloadState.paused,
        progress: 0.6,
      );

      expect(updated.state, ModelDownloadState.paused);
      expect(updated.progress, 0.6);
      expect(original.state, ModelDownloadState.downloading);
      expect(original.progress, 0.5);
    });
  });

  group('ModelDownloadState', () {
    test('all states are defined', () {
      expect(
        ModelDownloadState.values,
        contains(ModelDownloadState.notDownloaded),
      );
      expect(ModelDownloadState.values, contains(ModelDownloadState.queued));
      expect(
        ModelDownloadState.values,
        contains(ModelDownloadState.downloading),
      );
      expect(ModelDownloadState.values, contains(ModelDownloadState.paused));
      expect(ModelDownloadState.values, contains(ModelDownloadState.completed));
      expect(ModelDownloadState.values, contains(ModelDownloadState.failed));
    });
  });
}
