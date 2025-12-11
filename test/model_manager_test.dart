import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/model_manager.dart';

void main() {
  group('AIModel', () {
    test('should have correct default model', () {
      final defaultModel = ModelManager.defaultModel;
      expect(defaultModel.id, 'phi4-mini-q4km');
      expect(defaultModel.name, 'Phi-4 Mini');
      expect(
        defaultModel.fileName,
        'microsoft_Phi-4-mini-instruct-Q4_K_M.gguf',
      );
    });

    test('should calculate size text correctly for GB', () {
      const model = AIModel(
        id: 'test',
        name: 'Test',
        description: 'Test model',
        url: 'https://example.com/model.gguf',
        fileName: 'model.gguf',
        sizeBytes: 2576980378, // ~2.4 GB
      );
      expect(model.sizeText, '2.40 GB');
    });

    test('should calculate size text correctly for MB', () {
      const model = AIModel(
        id: 'test',
        name: 'Test',
        description: 'Test model',
        url: 'https://example.com/model.gguf',
        fileName: 'model.gguf',
        sizeBytes: 524288000, // 500 MB
      );
      expect(model.sizeText, '500.0 MB');
    });

    test('should calculate size text correctly for KB', () {
      const model = AIModel(
        id: 'test',
        name: 'Test',
        description: 'Test model',
        url: 'https://example.com/model.gguf',
        fileName: 'model.gguf',
        sizeBytes: 512000, // 500 KB
      );
      expect(model.sizeText, '500.0 KB');
    });
  });

  group('ModelDownloadProgress', () {
    test('should have correct initial state', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.notDownloaded,
      );
      expect(progress.state, ModelDownloadState.notDownloaded);
      expect(progress.progress, 0.0);
      expect(progress.downloadedBytes, 0);
      expect(progress.totalBytes, 0);
      expect(progress.errorMessage, null);
      expect(progress.networkSpeed, null);
    });

    test('should calculate progress text correctly', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: 0.5,
        downloadedBytes: 1288490189, // ~1.2 GB
        totalBytes: 2576980378, // ~2.4 GB
      );
      // Check format is correct (X.X MB / Y.Y MB)
      expect(
        progress.progressText,
        matches(RegExp(r'\d+\.\d MB / \d+\.\d MB')),
      );
      expect(progress.progressText.contains('1228.8 MB'), true);
    });

    test('should return preparing text when total is 0', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
      );
      expect(progress.progressText, 'Preparing...');
    });

    test('should calculate speed text in B/s', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: 500,
      );
      expect(progress.speedText, '500 B/s');
    });

    test('should calculate speed text in KB/s', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: 512000, // 500 KB/s
      );
      expect(progress.speedText, '500.0 KB/s');
    });

    test('should calculate speed text in MB/s', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: 10485760, // 10 MB/s
      );
      expect(progress.speedText, '10.0 MB/s');
    });

    test('should return empty speed text when speed is null', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: null,
      );
      expect(progress.speedText, '');
    });

    test('should return empty speed text when speed is 0', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        networkSpeed: 0,
      );
      expect(progress.speedText, '');
    });

    test('should calculate ETA in seconds', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        downloadedBytes: 0,
        totalBytes: 1000,
        networkSpeed: 100,
      );
      expect(progress.estimatedSecondsRemaining, 10);
      expect(progress.etaText, '10s remaining');
    });

    test('should calculate ETA in minutes', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        downloadedBytes: 0,
        totalBytes: 6000,
        networkSpeed: 100,
      );
      expect(progress.estimatedSecondsRemaining, 60);
      expect(progress.etaText, '1m remaining');
    });

    test('should calculate ETA in hours', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        downloadedBytes: 0,
        totalBytes: 360000,
        networkSpeed: 100,
      );
      expect(progress.estimatedSecondsRemaining, 3600);
      expect(progress.etaText, '1h 0m remaining');
    });

    test('should return empty ETA when speed is null', () {
      const progress = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        downloadedBytes: 0,
        totalBytes: 1000,
        networkSpeed: null,
      );
      expect(progress.estimatedSecondsRemaining, null);
      expect(progress.etaText, '');
    });

    test('copyWith should preserve unchanged values', () {
      const original = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: 0.5,
        downloadedBytes: 100,
        totalBytes: 200,
        errorMessage: 'test',
        networkSpeed: 50.0,
      );

      final copied = original.copyWith(progress: 0.7);

      expect(copied.state, ModelDownloadState.downloading);
      expect(copied.progress, 0.7);
      expect(copied.downloadedBytes, 100);
      expect(copied.totalBytes, 200);
      expect(copied.errorMessage, 'test');
      expect(copied.networkSpeed, 50.0);
    });

    test('copyWith should update multiple values', () {
      const original = ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: 0.5,
      );

      final copied = original.copyWith(
        state: ModelDownloadState.completed,
        progress: 1.0,
      );

      expect(copied.state, ModelDownloadState.completed);
      expect(copied.progress, 1.0);
    });
  });

  group('ModelDownloadState', () {
    test('should have all expected states', () {
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

  group('ModelManager', () {
    test('should be a singleton', () {
      final instance1 = ModelManager();
      final instance2 = ModelManager();
      expect(identical(instance1, instance2), true);
    });

    test('should have available models', () {
      expect(ModelManager.availableModels.isNotEmpty, true);
    });

    test('should have default model matching first available model', () {
      expect(ModelManager.defaultModel, ModelManager.availableModels.first);
    });

    test('currentProgress should start as notDownloaded', () {
      final manager = ModelManager();
      expect(manager.currentProgress.state, ModelDownloadState.notDownloaded);
    });

    test('progressStream should be a broadcast stream', () {
      final manager = ModelManager();
      // Should not throw when listening multiple times
      manager.progressStream.listen((_) {});
      manager.progressStream.listen((_) {});
    });
  });
}
