import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/model_manager.dart';

void main() {
  group('Model categories', () {
    test('all categories remain available for filtering', () {
      expect(ModelCategory.values.length, 6);
      expect(ModelCategory.values, contains(ModelCategory.general));
      expect(ModelCategory.values, contains(ModelCategory.agent));
      expect(ModelCategory.values, contains(ModelCategory.writing));
      expect(ModelCategory.values, contains(ModelCategory.math));
      expect(ModelCategory.values, contains(ModelCategory.code));
      expect(ModelCategory.values, contains(ModelCategory.strongest));
    });

    test('category labels are user-friendly', () {
      expect(ModelCategory.general.displayName, 'General Purpose');
      expect(ModelCategory.agent.displayName, 'MCP / Agent Brain');
      expect(ModelCategory.writing.displayName, 'Writing / Notes');
      expect(ModelCategory.math.displayName, 'Math / LaTeX');
      expect(ModelCategory.code.displayName, 'Code Generation');
      expect(ModelCategory.strongest.displayName, 'Strongest');
    });
  });

  group('Available model set', () {
    test('has one default model and it is Phi-4 Mini', () {
      final defaults = ModelManager.availableModels
          .where((m) => m.isDefault)
          .toList();
      expect(defaults.length, 1);
      expect(defaults.single.id, 'phi4-mini-q4km');
      expect(defaults.single.name, 'Phi-4 Mini');
    });

    test('includes requested Qwen3.5 distilled variants', () {
      expect(
        ModelManager.availableModels.any(
          (m) => m.id == 'qwen35-4b-claude46-distilled-v2-q4km',
        ),
        true,
      );
      expect(
        ModelManager.availableModels.any(
          (m) => m.id == 'qwen35-2b-claude46-distilled-q5km',
        ),
        true,
      );
      expect(
        ModelManager.availableModels.any(
          (m) => m.id == 'qwen35-08b-claude46-distilled-q5km',
        ),
        true,
      );
    });

    test('includes newly requested reasoning and compact variants', () {
      expect(
        ModelManager.availableModels.any(
          (m) => m.id == 'phi4-mini-reasoning-q4km',
        ),
        true,
      );
      expect(
        ModelManager.availableModels.any((m) => m.id == 'gemma-3-4b-it-q4km'),
        true,
      );
      expect(
        ModelManager.availableModels.any(
          (m) => m.id == 'deepseek-r1-distill-qwen-15b-q4km',
        ),
        true,
      );
      expect(
        ModelManager.availableModels.any(
          (m) => m.id == 'smollm2-17b-instruct-q4km',
        ),
        true,
      );
    });

    test('Gemma 7B is not available anymore', () {
      expect(
        ModelManager.availableModels.any((m) => m.id == 'gemma-7b'),
        false,
      );
      expect(ModelManager.getModelById('gemma-7b'), isNull);
    });

    test('all models have core user-facing metadata', () {
      for (final model in ModelManager.availableModels) {
        expect(model.id, isNotEmpty);
        expect(model.name, isNotEmpty);
        expect(model.displayDescription, isNotEmpty);
        expect(model.suggestionText, isNotEmpty);
        expect(model.categories, isNotEmpty);
      }
    });
  });

  group('Category filtering behavior', () {
    test('general category contains Phi-4 and Qwen3.5 2B', () {
      final models = ModelManager.getModelsForCategory(ModelCategory.general);

      expect(models.any((m) => m.id == 'phi4-mini-q4km'), true);
      expect(
        models.any((m) => m.id == 'qwen35-2b-claude46-distilled-q5km'),
        true,
      );
    });

    test('agent category still routes to Function Gemma only', () {
      final models = ModelManager.getModelsForCategory(ModelCategory.agent);

      expect(models.any((m) => m.id == 'function-gemma-270m'), true);
      expect(models.any((m) => m.id == 'phi4-mini-q4km'), false);
      expect(
        models.any((m) => m.id == 'qwen35-4b-claude46-distilled-v2-q4km'),
        false,
      );
    });

    test('math category includes Phi-4 and Qwen3.5 4B', () {
      final models = ModelManager.getModelsForCategory(ModelCategory.math);

      expect(models.any((m) => m.id == 'phi4-mini-q4km'), true);
      expect(models.any((m) => m.id == 'phi4-mini-reasoning-q4km'), true);
      expect(
        models.any((m) => m.id == 'qwen35-4b-claude46-distilled-v2-q4km'),
        true,
      );
      expect(
        models.any((m) => m.id == 'deepseek-r1-distill-qwen-15b-q4km'),
        true,
      );
    });

    test(
      'code category includes Qwen family, Gemma, and compact additions',
      () {
        final models = ModelManager.getModelsForCategory(ModelCategory.code);

        expect(models.any((m) => m.id == 'qwen25-3b-q4km'), true);
        expect(
          models.any((m) => m.id == 'qwen35-08b-claude46-distilled-q5km'),
          true,
        );
        expect(models.any((m) => m.id == 'gemma-2b'), true);
        expect(models.any((m) => m.id == 'gemma-3-4b-it-q4km'), true);
        expect(
          models.any((m) => m.id == 'deepseek-r1-distill-qwen-15b-q4km'),
          true,
        );
        expect(models.any((m) => m.id == 'smollm2-17b-instruct-q4km'), true);
      },
    );

    test('Strongest category contains requested four reasoning models', () {
      final strongest = ModelManager.getModelsForCategory(
        ModelCategory.strongest,
      );

      expect(
        strongest.any((m) => m.id == 'qwen35-4b-claude46-distilled-v2-q4km'),
        true,
      );
      expect(
        strongest.any((m) => m.id == 'qwen35-2b-claude46-distilled-q5km'),
        true,
      );
      expect(
        strongest.any((m) => m.id == 'qwen35-08b-claude46-distilled-q5km'),
        true,
      );
      expect(strongest.any((m) => m.id == 'phi4-mini-reasoning-q4km'), true);
    });
  });

  group('Recommendations and lookup', () {
    test('agent recommendation is still Function Gemma', () {
      final recommended = ModelManager.getRecommendedModel(ModelCategory.agent);
      expect(recommended.id, 'function-gemma-270m');
    });

    test('math recommendation is still Phi-4 by ordering', () {
      final recommended = ModelManager.getRecommendedModel(ModelCategory.math);
      expect(recommended.id, 'phi4-mini-q4km');
    });

    test('getModelById resolves new Qwen3.5 IDs with full branding', () {
      final qwen4b = ModelManager.getModelById(
        'qwen35-4b-claude46-distilled-v2-q4km',
      );
      final qwen2b = ModelManager.getModelById(
        'qwen35-2b-claude46-distilled-q5km',
      );

      expect(qwen4b, isNotNull);
      expect(qwen4b!.name, 'Qwen3.5 4B Claude 4.6 Opus Reasoning Distilled');
      expect(qwen2b, isNotNull);
      expect(qwen2b!.name, 'Qwen3.5 2B Claude 4.6 Opus Reasoning Distilled');
    });

    test('all model IDs and filenames are unique', () {
      final ids = ModelManager.availableModels.map((m) => m.id).toSet();
      final files = ModelManager.availableModels.map((m) => m.fileName).toSet();

      expect(ids.length, ModelManager.availableModels.length);
      expect(files.length, ModelManager.availableModels.length);
    });
  });

  group('ModelManager singleton state', () {
    test('ModelManager is a singleton', () {
      expect(identical(ModelManager(), ModelManager()), true);
    });

    test('currentlyLoadedModel follows setCurrentlyLoadedModel', () {
      final manager = ModelManager();
      manager.setCurrentlyLoadedModel('qwen35-2b-claude46-distilled-q5km');

      expect(manager.currentlyLoadedModel, isNotNull);
      expect(
        manager.currentlyLoadedModel!.id,
        'qwen35-2b-claude46-distilled-q5km',
      );

      manager.setCurrentlyLoadedModel(null);
      expect(manager.currentlyLoadedModel, isNull);
    });
  });
}
