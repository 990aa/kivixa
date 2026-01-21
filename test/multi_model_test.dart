// Multi-Model Support Tests
//
// Tests for the multi-model feature that allows users to download,
// switch between, and use different AI models.

import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/model_manager.dart';

void main() {
  group('ModelCategory', () {
    test('should have all expected categories', () {
      expect(ModelCategory.values.length, 5);
      expect(ModelCategory.values, contains(ModelCategory.general));
      expect(ModelCategory.values, contains(ModelCategory.agent));
      expect(ModelCategory.values, contains(ModelCategory.writing));
      expect(ModelCategory.values, contains(ModelCategory.math));
      expect(ModelCategory.values, contains(ModelCategory.code));
    });

    test('each category should have displayName and description', () {
      for (final category in ModelCategory.values) {
        expect(category.displayName, isNotEmpty);
        expect(category.description, isNotEmpty);
      }
    });

    test('displayNames should be human readable', () {
      expect(ModelCategory.general.displayName, 'General Purpose');
      expect(ModelCategory.agent.displayName, 'MCP / Agent Brain');
      expect(ModelCategory.writing.displayName, 'Writing / Notes');
      expect(ModelCategory.math.displayName, 'Math / LaTeX');
      expect(ModelCategory.code.displayName, 'Code Generation');
    });
  });

  group('AIModel with categories', () {
    test('model should support category checking', () {
      const model = AIModel(
        id: 'test',
        name: 'Test',
        description: 'Test model',
        url: 'https://example.com/model.gguf',
        fileName: 'model.gguf',
        sizeBytes: 1000000,
        categories: [ModelCategory.writing, ModelCategory.code],
      );

      expect(model.supportsCategory(ModelCategory.writing), true);
      expect(model.supportsCategory(ModelCategory.code), true);
      expect(model.supportsCategory(ModelCategory.math), false);
      expect(model.supportsCategory(ModelCategory.agent), false);
    });

    test('model with default categories should support general', () {
      const model = AIModel(
        id: 'test',
        name: 'Test',
        description: 'Test model',
        url: 'https://example.com/model.gguf',
        fileName: 'model.gguf',
        sizeBytes: 1000000,
        // categories defaults to [ModelCategory.general]
      );

      expect(model.supportsCategory(ModelCategory.general), true);
    });

    test('model isDefault flag works correctly', () {
      const defaultModel = AIModel(
        id: 'default',
        name: 'Default',
        description: 'Default model',
        url: 'https://example.com/model.gguf',
        fileName: 'model.gguf',
        sizeBytes: 1000000,
        isDefault: true,
      );

      const otherModel = AIModel(
        id: 'other',
        name: 'Other',
        description: 'Other model',
        url: 'https://example.com/other.gguf',
        fileName: 'other.gguf',
        sizeBytes: 1000000,
      );

      expect(defaultModel.isDefault, true);
      expect(otherModel.isDefault, false);
    });
  });

  group('Available Models', () {
    test('should have at least 4 models', () {
      expect(ModelManager.availableModels.length, greaterThanOrEqualTo(4));
    });

    test('should have exactly one default model', () {
      final defaultModels = ModelManager.availableModels
          .where((m) => m.isDefault)
          .toList();
      expect(defaultModels.length, 1);
    });

    test('default model should be Phi-4 Mini', () {
      final defaultModel = ModelManager.defaultModel;
      expect(defaultModel.id, 'phi4-mini-q4km');
      expect(defaultModel.name, 'Phi-4 Mini');
      expect(defaultModel.isDefault, true);
    });

    test('Phi-4 Mini should support general, writing, and math', () {
      final phi4 = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'phi4-mini-q4km',
      );

      expect(phi4.supportsCategory(ModelCategory.general), true);
      expect(phi4.supportsCategory(ModelCategory.writing), true);
      expect(phi4.supportsCategory(ModelCategory.math), true);
      expect(phi4.supportsCategory(ModelCategory.agent), false);
    });

    test('Qwen2.5-3B should support writing and code', () {
      final qwen = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'qwen25-3b-q4km',
      );

      expect(qwen.supportsCategory(ModelCategory.writing), true);
      expect(qwen.supportsCategory(ModelCategory.code), true);
      expect(qwen.supportsCategory(ModelCategory.general), true);
    });

    test('Function Gemma 270M should support agent only', () {
      final funcGemma = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'function-gemma-270m',
      );

      expect(funcGemma.supportsCategory(ModelCategory.agent), true);
      expect(funcGemma.supportsCategory(ModelCategory.code), false);
      expect(funcGemma.supportsCategory(ModelCategory.writing), false);
    });

    test('Gemma 2B should support general and code', () {
      final gemma2b = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-2b',
      );

      expect(gemma2b.supportsCategory(ModelCategory.general), true);
      expect(gemma2b.supportsCategory(ModelCategory.code), true);
      expect(gemma2b.supportsCategory(ModelCategory.agent), false);
    });

    test('Gemma 7B should support general, code, and writing', () {
      final gemma7b = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-7b',
      );

      expect(gemma7b.supportsCategory(ModelCategory.general), true);
      expect(gemma7b.supportsCategory(ModelCategory.code), true);
      expect(gemma7b.supportsCategory(ModelCategory.writing), true);
    });

    test('all models should have valid URLs', () {
      for (final model in ModelManager.availableModels) {
        expect(model.url, startsWith('https://huggingface.co/'));
        expect(model.url, contains('/resolve/main/'));
        expect(model.url, endsWith('.gguf'));
      }
    });

    test('all models should have reasonable sizes', () {
      const oneHundredMB = 100 * 1024 * 1024;
      const tenGB = 10 * 1024 * 1024 * 1024;

      for (final model in ModelManager.availableModels) {
        expect(model.sizeBytes, greaterThan(oneHundredMB)); // At least 100MB
        expect(model.sizeBytes, lessThan(tenGB)); // Less than 10GB
      }
    });

    test('model filenames should end with .gguf', () {
      for (final model in ModelManager.availableModels) {
        expect(model.fileName, endsWith('.gguf'));
      }
    });

    test('model URLs should end with their filenames', () {
      for (final model in ModelManager.availableModels) {
        expect(model.url, endsWith(model.fileName));
      }
    });

    test('all models should have unique IDs', () {
      final ids = ModelManager.availableModels.map((m) => m.id).toSet();
      expect(ids.length, ModelManager.availableModels.length);
    });
  });

  group('Model Category Filtering', () {
    test('getModelsForCategory should return models for general', () {
      final generalModels = ModelManager.getModelsForCategory(
        ModelCategory.general,
      );
      expect(generalModels, isNotEmpty);

      // Phi-4 and Qwen should be in general
      expect(generalModels.any((m) => m.id == 'phi4-mini-q4km'), true);
      expect(generalModels.any((m) => m.id == 'qwen25-3b-q4km'), true);
    });

    test('getModelsForCategory should return models for agent', () {
      final agentModels = ModelManager.getModelsForCategory(
        ModelCategory.agent,
      );
      expect(agentModels, isNotEmpty);

      // Function Gemma should be in agent
      expect(agentModels.any((m) => m.id == 'function-gemma-270m'), true);

      // Phi-4 should NOT be in agent
      expect(agentModels.any((m) => m.id == 'phi4-mini-q4km'), false);
    });

    test('getModelsForCategory should return models for writing', () {
      final writingModels = ModelManager.getModelsForCategory(
        ModelCategory.writing,
      );
      expect(writingModels, isNotEmpty);

      // Phi-4 and Qwen should be in writing
      expect(writingModels.any((m) => m.id == 'phi4-mini-q4km'), true);
      expect(writingModels.any((m) => m.id == 'qwen25-3b-q4km'), true);
    });

    test('getModelsForCategory should return models for math', () {
      final mathModels = ModelManager.getModelsForCategory(ModelCategory.math);
      expect(mathModels, isNotEmpty);

      // Phi-4 should be in math
      expect(mathModels.any((m) => m.id == 'phi4-mini-q4km'), true);
    });

    test('getModelsForCategory should return models for code', () {
      final codeModels = ModelManager.getModelsForCategory(ModelCategory.code);
      expect(codeModels, isNotEmpty);

      // Qwen and Gemma models should be in code
      expect(codeModels.any((m) => m.id == 'qwen25-3b-q4km'), true);
      expect(codeModels.any((m) => m.id == 'gemma-2b'), true);
      expect(codeModels.any((m) => m.id == 'gemma-7b'), true);
    });

    test('getRecommendedModel should return first matching model', () {
      final agentRecommended = ModelManager.getRecommendedModel(
        ModelCategory.agent,
      );
      expect(agentRecommended.supportsCategory(ModelCategory.agent), true);

      final writingRecommended = ModelManager.getRecommendedModel(
        ModelCategory.writing,
      );
      expect(writingRecommended.supportsCategory(ModelCategory.writing), true);
    });
  });

  group('ModelManager Static Methods', () {
    test('getModelById should return correct model', () {
      final phi4 = ModelManager.getModelById('phi4-mini-q4km');
      expect(phi4, isNotNull);
      expect(phi4!.name, 'Phi-4 Mini');

      final qwen = ModelManager.getModelById('qwen25-3b-q4km');
      expect(qwen, isNotNull);
      expect(qwen!.name, 'Qwen2.5 3B');
    });

    test('getModelById should return null for invalid ID', () {
      final invalid = ModelManager.getModelById('nonexistent-model');
      expect(invalid, isNull);
    });

    test('defaultModel getter should return Phi-4 Mini', () {
      final defaultModel = ModelManager.defaultModel;
      expect(defaultModel.id, 'phi4-mini-q4km');
    });
  });

  group('ModelManager Instance', () {
    test('should be a singleton', () {
      final instance1 = ModelManager();
      final instance2 = ModelManager();
      expect(identical(instance1, instance2), true);
    });

    test('currentlyLoadedModel should be null initially', () {
      final manager = ModelManager();
      // Reset state
      manager.setCurrentlyLoadedModel(null);
      expect(manager.currentlyLoadedModel, isNull);
    });

    test('setCurrentlyLoadedModel should update currentlyLoadedModel', () {
      final manager = ModelManager();
      manager.setCurrentlyLoadedModel('phi4-mini-q4km');
      expect(manager.currentlyLoadedModel, isNotNull);
      expect(manager.currentlyLoadedModel!.id, 'phi4-mini-q4km');

      // Reset for other tests
      manager.setCurrentlyLoadedModel(null);
    });

    test('progressStream should be a broadcast stream', () {
      final manager = ModelManager();
      // Should not throw when listening multiple times
      manager.progressStream.listen((_) {});
      manager.progressStream.listen((_) {});
    });
  });

  group('Model Size Formatting', () {
    test('Phi-4 Mini size should be around 2.5 GB', () {
      final phi4 = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'phi4-mini-q4km',
      );
      expect(phi4.sizeText, contains('GB'));
      // Should be between 2 and 3 GB
      expect(phi4.sizeBytes, greaterThan(2 * 1024 * 1024 * 1024));
      expect(phi4.sizeBytes, lessThan(3 * 1024 * 1024 * 1024));
    });

    test('Qwen2.5-3B size should be around 1.9 GB', () {
      final qwen = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'qwen25-3b-q4km',
      );
      expect(qwen.sizeText, contains('GB'));
      // Should be between 1.5 and 2.5 GB
      expect(qwen.sizeBytes, greaterThan(1.5 * 1024 * 1024 * 1024));
      expect(qwen.sizeBytes, lessThan(2.5 * 1024 * 1024 * 1024));
    });

    test('Function Gemma 270M size should be around 180 MB', () {
      final funcGemma = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'function-gemma-270m',
      );
      expect(funcGemma.sizeText, contains('MB'));
      // Should be between 100 and 300 MB
      expect(funcGemma.sizeBytes, greaterThan(100 * 1024 * 1024));
      expect(funcGemma.sizeBytes, lessThan(300 * 1024 * 1024));
    });

    test('Gemma 2B size should be around 1.5 GB', () {
      final gemma2b = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-2b',
      );
      expect(gemma2b.sizeText, contains('GB'));
      // Should be between 1 and 2 GB
      expect(gemma2b.sizeBytes, greaterThan(1 * 1024 * 1024 * 1024));
      expect(gemma2b.sizeBytes, lessThan(2 * 1024 * 1024 * 1024));
    });

    test('Gemma 7B size should be around 4.7 GB', () {
      final gemma7b = ModelManager.availableModels.firstWhere(
        (m) => m.id == 'gemma-7b',
      );
      expect(gemma7b.sizeText, contains('GB'));
      // Should be between 4 and 6 GB
      expect(gemma7b.sizeBytes, greaterThan(4 * 1024 * 1024 * 1024));
      expect(gemma7b.sizeBytes, lessThan(6 * 1024 * 1024 * 1024));
    });
  });

  group('Use Case Recommendations', () {
    test('Writing tasks should recommend Phi-4 or Qwen', () {
      final recommended = ModelManager.getRecommendedModel(
        ModelCategory.writing,
      );
      expect(
        recommended.id == 'phi4-mini-q4km' ||
            recommended.id == 'qwen25-3b-q4km',
        true,
      );
    });

    test('Math/LaTeX tasks should recommend Phi-4', () {
      final recommended = ModelManager.getRecommendedModel(ModelCategory.math);
      expect(recommended.id, 'phi4-mini-q4km');
    });

    test('Agent/MCP tasks should recommend Function Gemma', () {
      final recommended = ModelManager.getRecommendedModel(ModelCategory.agent);
      expect(recommended.id, 'function-gemma-270m');
    });

    test('Code generation should recommend Qwen or Gemma', () {
      final recommended = ModelManager.getRecommendedModel(ModelCategory.code);
      expect(recommended.supportsCategory(ModelCategory.code), true);
    });
  });
}
