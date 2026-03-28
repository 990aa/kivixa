import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/services/ai/model_manager.dart';

void main() {
  group('Model catalog metadata', () {
    test('default model remains Phi-4 Mini', () {
      expect(ModelManager.defaultModel.id, 'phi4-mini-q4km');
      expect(ModelManager.defaultModel.name, 'Phi-4 Mini');
      expect(ModelManager.defaultModel.isDefault, true);
    });

    test('Gemma 7B is removed from available models', () {
      expect(ModelManager.getModelById('gemma-7b'), isNull);
      expect(
        ModelManager.availableModels.any((m) => m.name == 'Gemma 7B'),
        false,
      );
    });

    test('includes all requested Qwen3.5 distilled models', () {
      expect(
        ModelManager.getModelById('qwen35-4b-claude46-distilled-v2-q4km'),
        isNotNull,
      );
      expect(
        ModelManager.getModelById('qwen35-2b-claude46-distilled-q5km'),
        isNotNull,
      );
      expect(
        ModelManager.getModelById('qwen35-08b-claude46-distilled-q5km'),
        isNotNull,
      );
    });

    test('includes the four newly requested compact models', () {
      expect(ModelManager.getModelById('phi4-mini-reasoning-q4km'), isNotNull);
      expect(ModelManager.getModelById('gemma-3-4b-it-q4km'), isNotNull);
      expect(
        ModelManager.getModelById('deepseek-r1-distill-qwen-15b-q4km'),
        isNotNull,
      );
      expect(ModelManager.getModelById('smollm2-17b-instruct-q4km'), isNotNull);
    });

    test('requested Qwen3.5 links and filenames are exact', () {
      final qwen4b = ModelManager.getModelById(
        'qwen35-4b-claude46-distilled-v2-q4km',
      )!;
      final qwen2b = ModelManager.getModelById(
        'qwen35-2b-claude46-distilled-q5km',
      )!;
      final qwen08b = ModelManager.getModelById(
        'qwen35-08b-claude46-distilled-q5km',
      )!;

      expect(
        qwen4b.url,
        'https://huggingface.co/Jackrong/Qwen3.5-4B-Claude-4.6-Opus-Reasoning-Distilled-v2-GGUF/resolve/main/Qwen3.5-4B.Q4_K_M.gguf',
      );
      expect(qwen4b.fileName, 'Qwen3.5-4B.Q4_K_M.gguf');

      expect(
        qwen2b.url,
        'https://huggingface.co/Jackrong/Qwen3.5-2B-Claude-4.6-Opus-Reasoning-Distilled-GGUF/resolve/main/Qwen3.5-2B.Q5_K_M.gguf',
      );
      expect(qwen2b.fileName, 'Qwen3.5-2B.Q5_K_M.gguf');

      expect(
        qwen08b.url,
        'https://huggingface.co/Jackrong/Qwen3.5-0.8B-Claude-4.6-Opus-Reasoning-Distilled-GGUF/resolve/main/Qwen3.5-0.8B.Q5_K_M.gguf',
      );
      expect(qwen08b.fileName, 'Qwen3.5-0.8B.Q5_K_M.gguf');
    });

    test('newly requested model links and filenames are exact', () {
      final phiReasoning = ModelManager.getModelById(
        'phi4-mini-reasoning-q4km',
      )!;
      final gemma3 = ModelManager.getModelById('gemma-3-4b-it-q4km')!;
      final deepseek = ModelManager.getModelById(
        'deepseek-r1-distill-qwen-15b-q4km',
      )!;
      final smollm = ModelManager.getModelById('smollm2-17b-instruct-q4km')!;

      expect(
        phiReasoning.url,
        'https://huggingface.co/unsloth/Phi-4-mini-reasoning-GGUF/resolve/main/Phi-4-mini-reasoning-Q4_K_M.gguf',
      );
      expect(phiReasoning.fileName, 'Phi-4-mini-reasoning-Q4_K_M.gguf');

      expect(
        gemma3.url,
        'https://huggingface.co/bartowski/google_gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf',
      );
      expect(gemma3.fileName, 'gemma-3-4b-it-Q4_K_M.gguf');

      expect(
        deepseek.url,
        'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
      );
      expect(deepseek.fileName, 'DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf');

      expect(
        smollm.url,
        'https://huggingface.co/bartowski/SmolLM2-1.7B-Instruct-GGUF/resolve/main/SmolLM2-1.7B-Instruct-Q4_K_M.gguf',
      );
      expect(smollm.fileName, 'SmolLM2-1.7B-Instruct-Q4_K_M.gguf');
    });

    test('all models provide short description and suggestion text', () {
      for (final model in ModelManager.availableModels) {
        expect(model.displayDescription, isNotEmpty);
        expect(model.suggestionText, isNotEmpty);
      }
    });

    test('all model URLs are direct HuggingFace resolve links', () {
      for (final model in ModelManager.availableModels) {
        expect(model.url, startsWith('https://huggingface.co/'));
        expect(model.url, contains('/resolve/main/'));
        expect(model.url, endsWith(model.fileName));
      }
    });

    test('IDs and filenames are unique', () {
      final ids = ModelManager.availableModels.map((m) => m.id).toSet();
      final fileNames = ModelManager.availableModels
          .map((m) => m.fileName)
          .toSet();

      expect(ids.length, ModelManager.availableModels.length);
      expect(fileNames.length, ModelManager.availableModels.length);
    });
  });

  group('Categories and recommendations', () {
    test(
      'Qwen Claude-distilled models expose canonical and alternate filenames',
      () {
        final manager = ModelManager();

        final qwen4b = ModelManager.getModelById(
          'qwen35-4b-claude46-distilled-v2-q4km',
        )!;
        final qwen2b = ModelManager.getModelById(
          'qwen35-2b-claude46-distilled-q5km',
        )!;
        final qwen08b = ModelManager.getModelById(
          'qwen35-08b-claude46-distilled-q5km',
        )!;

        final qwen4bCandidates = manager.candidateFileNames(qwen4b);
        final qwen2bCandidates = manager.candidateFileNames(qwen2b);
        final qwen08bCandidates = manager.candidateFileNames(qwen08b);

        expect(qwen4bCandidates, contains('Qwen3.5-4B.Q4_K_M.gguf'));
        expect(
          qwen4bCandidates,
          contains(
            'Qwen3.5-4B-Claude-4.6-Opus-Reasoning-Distilled-v2.Q4_K_M.gguf',
          ),
        );

        expect(qwen2bCandidates, contains('Qwen3.5-2B.Q5_K_M.gguf'));
        expect(
          qwen2bCandidates,
          contains('Qwen3.5-2B-Claude-4.6-Opus-Reasoning-Distilled.Q5_K_M.gguf'),
        );

        expect(qwen08bCandidates, contains('Qwen3.5-0.8B.Q5_K_M.gguf'));
        expect(
          qwen08bCandidates,
          contains(
            'Qwen3.5-0.8B-Claude-4.6-Opus-Reasoning-Distilled.Q5_K_M.gguf',
          ),
        );
      },
    );

    test(
      'Strongest category contains Qwen Claude-distilled trio and Phi reasoning',
      () {
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
      },
    );

    test('requested reasoning models are flagged as reasoning-capable', () {
      final qwen4b = ModelManager.getModelById(
        'qwen35-4b-claude46-distilled-v2-q4km',
      )!;
      final qwen2b = ModelManager.getModelById(
        'qwen35-2b-claude46-distilled-q5km',
      )!;
      final qwen08b = ModelManager.getModelById(
        'qwen35-08b-claude46-distilled-q5km',
      )!;
      final phiReasoning = ModelManager.getModelById(
        'phi4-mini-reasoning-q4km',
      )!;

      expect(qwen4b.isReasoningModel, true);
      expect(qwen2b.isReasoningModel, true);
      expect(qwen08b.isReasoningModel, true);
      expect(phiReasoning.isReasoningModel, true);
    });

    test(
      'Qwen model names include Claude 4.6 Opus Reasoning Distilled branding',
      () {
        final qwen4b = ModelManager.getModelById(
          'qwen35-4b-claude46-distilled-v2-q4km',
        )!;
        final qwen2b = ModelManager.getModelById(
          'qwen35-2b-claude46-distilled-q5km',
        )!;
        final qwen08b = ModelManager.getModelById(
          'qwen35-08b-claude46-distilled-q5km',
        )!;

        expect(qwen4b.name, contains('Claude 4.6 Opus Reasoning Distilled'));
        expect(qwen2b.name, contains('Claude 4.6 Opus Reasoning Distilled'));
        expect(qwen08b.name, contains('Claude 4.6 Opus Reasoning Distilled'));
      },
    );

    test('Qwen3.5 4B supports general, writing, code, and math', () {
      final model = ModelManager.getModelById(
        'qwen35-4b-claude46-distilled-v2-q4km',
      )!;

      expect(model.supportsCategory(ModelCategory.general), true);
      expect(model.supportsCategory(ModelCategory.writing), true);
      expect(model.supportsCategory(ModelCategory.code), true);
      expect(model.supportsCategory(ModelCategory.math), true);
    });

    test('Qwen3.5 0.8B appears in code filter', () {
      final codeModels = ModelManager.getModelsForCategory(ModelCategory.code);
      expect(
        codeModels.any((m) => m.id == 'qwen35-08b-claude46-distilled-q5km'),
        true,
      );
    });

    test('agent recommendation remains Function Gemma', () {
      final recommended = ModelManager.getRecommendedModel(ModelCategory.agent);
      expect(recommended.id, 'function-gemma-270m');
    });
  });

  group('Download task construction (no network)', () {
    test(
      'createDownloadTask carries URL, file, and metadata for Qwen3.5 4B',
      () {
        final manager = ModelManager();
        final model = ModelManager.getModelById(
          'qwen35-4b-claude46-distilled-v2-q4km',
        )!;

        final task = manager.createDownloadTask(model);

        expect(task, isA<DownloadTask>());
        expect(task.url, model.url);
        expect(task.filename, model.fileName);
        expect(task.metaData, model.id);
        expect(task.directory, 'models');
        expect(task.baseDirectory, BaseDirectory.applicationSupport);
        expect(task.allowPause, true);
        expect(task.retries, 3);
        expect(task.updates, Updates.statusAndProgress);
      },
    );

    test('every model creates a valid task from its direct link', () {
      final manager = ModelManager();

      for (final model in ModelManager.availableModels) {
        final task = manager.createDownloadTask(model);
        expect(task.url, model.url);
        expect(task.filename, model.fileName);
        expect(task.metaData, model.id);
        expect(task.url, contains('/resolve/main/'));
      }
    });
  });
}
