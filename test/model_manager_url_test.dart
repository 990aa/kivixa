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

    test('should have at least 4 models available', () {
      expect(ModelManager.availableModels.length, greaterThanOrEqualTo(4));
    });

    test('defaultModel is Phi-4 Mini', () {
      expect(ModelManager.defaultModel.id, 'phi4-mini-q4km');
      expect(ModelManager.defaultModel.isDefault, true);
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
      expect(phi4Model.isDefault, true);
    });

    test('Qwen2.5-3B model is correctly configured', () {
      final qwenModel = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'qwen25-3b-q4km',
      );

      expect(qwenModel.name, 'Qwen2.5 3B');
      expect(qwenModel.url, contains('Qwen/Qwen2.5-3B-Instruct-GGUF'));
      expect(qwenModel.url, contains('q4_k_m.gguf'));
      expect(qwenModel.fileName, 'qwen2.5-3b-instruct-q4_k_m.gguf');
      expect(qwenModel.isDefault, false);
    });

    test('Function Gemma 270M model is correctly configured', () {
      final funcGemmaModel = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'function-gemma-270m',
      );

      expect(funcGemmaModel.name, 'Function Gemma 270M');
      expect(funcGemmaModel.url, contains('unsloth/functiongemma-270m'));
      expect(funcGemmaModel.url, contains('Q4_K_M.gguf'));
      expect(funcGemmaModel.isDefault, false);
    });

    test('Gemma 2B model is correctly configured', () {
      final gemma2bModel = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-2b',
      );

      expect(gemma2bModel.name, 'Gemma 2B');
      expect(gemma2bModel.url, contains('tensorblock/gemma-2b-GGUF'));
      expect(gemma2bModel.url, contains('Q4_K_M.gguf'));
      expect(gemma2bModel.isDefault, false);
    });

    test('Gemma 7B model is correctly configured', () {
      final gemma7bModel = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-7b',
      );

      expect(gemma7bModel.name, 'Gemma 7B');
      expect(gemma7bModel.url, contains('tensorblock/gemma-7b-GGUF'));
      expect(gemma7bModel.url, contains('Q4_K_M.gguf'));
      expect(gemma7bModel.isDefault, false);
    });

    test('all model URLs use correct HuggingFace resolve format', () {
      for (final model in ModelManager.availableModels) {
        // HuggingFace direct download URLs should use /resolve/main/ format
        expect(model.url, contains('/resolve/main/'));
        expect(model.url, startsWith('https://huggingface.co/'));
      }
    });

    test('all model filenames match their URLs', () {
      for (final model in ModelManager.availableModels) {
        // The filename in the URL should match the fileName property
        expect(model.url, endsWith(model.fileName));
      }
    });

    test('model sizes are reasonable for Q4_K_M quantization', () {
      const oneGB = 1024 * 1024 * 1024;

      // Phi-4 Mini should be around 2.5 GB
      final phi4Model = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'phi4-mini-q4km',
      );
      expect(phi4Model.sizeBytes, greaterThan(2 * oneGB));
      expect(phi4Model.sizeBytes, lessThan(3 * oneGB));

      // Qwen 3B should be around 1.9 GB
      final qwenModel = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'qwen25-3b-q4km',
      );
      expect(qwenModel.sizeBytes, greaterThan(1.5 * oneGB));
      expect(qwenModel.sizeBytes, lessThan(2.5 * oneGB));

      // Function Gemma 270M should be around 180 MB
      final funcGemma = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'function-gemma-270m',
      );
      expect(funcGemma.sizeBytes, greaterThan(100 * 1024 * 1024));
      expect(funcGemma.sizeBytes, lessThan(300 * 1024 * 1024));

      // Gemma 2B should be around 1.5 GB
      final gemma2b = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-2b',
      );
      expect(gemma2b.sizeBytes, greaterThan(1 * oneGB));
      expect(gemma2b.sizeBytes, lessThan(2 * oneGB));

      // Gemma 7B should be around 4.7 GB
      final gemma7b = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-7b',
      );
      expect(gemma7b.sizeBytes, greaterThan(4 * oneGB));
      expect(gemma7b.sizeBytes, lessThan(6 * oneGB));
    });

    test('all model sizeText is formatted correctly', () {
      for (final model in ModelManager.availableModels) {
        final sizeText = model.sizeText;
        // Most models should display in MB or GB format
        expect(sizeText, anyOf(contains('MB'), contains('GB')));
      }
    });

    test('all models have required fields', () {
      for (final model in ModelManager.availableModels) {
        expect(model.id, isNotEmpty);
        expect(model.name, isNotEmpty);
        expect(model.description, isNotEmpty);
        expect(model.url, isNotEmpty);
        expect(model.fileName, isNotEmpty);
        expect(model.sizeBytes, greaterThan(0));
        expect(model.categories, isNotEmpty);
      }
    });

    test('all models have unique IDs', () {
      final ids = ModelManager.availableModels.map((m) => m.id).toSet();
      expect(ids.length, ModelManager.availableModels.length);
    });

    test('all models have unique filenames', () {
      final fileNames = ModelManager.availableModels
          .map((m) => m.fileName)
          .toSet();
      expect(fileNames.length, ModelManager.availableModels.length);
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
