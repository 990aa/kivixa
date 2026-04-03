import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';
import 'package:kivixa/pages/home/ai_chat.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/mcp_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';

class _FakeInferenceGateway implements ChatInferenceGateway {
  final response = 'stubbed-response';
  final loadedModelPaths = <String>[];
  final chatRequests = <List<ChatMessage>>[];
  var _modelLoaded = false;

  @override
  bool get isModelLoaded => _modelLoaded;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadModel(String modelPath) async {
    loadedModelPaths.add(modelPath);
    _modelLoaded = true;
  }

  @override
  void unloadModel() {
    _modelLoaded = false;
  }

  @override
  Future<String> chat(List<ChatMessage> messages) async {
    chatRequests.add(List<ChatMessage>.from(messages));
    return response;
  }
}

class _FakeModelGateway implements ChatModelGateway {
  _FakeModelGateway({
    required this.models,
    required this.modelPaths,
    String? initiallyLoadedModelId,
  }) : _currentModel = initiallyLoadedModelId == null
           ? null
           : models.firstWhere((model) => model.id == initiallyLoadedModelId);

  final List<AIModel> models;
  final Map<String, String> modelPaths;
  AIModel? _currentModel;
  String? lastSetModelId;

  @override
  AIModel? get currentlyLoadedModel => _currentModel;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isModelDownloaded([AIModel? model]) async {
    final requestedModel = model ?? ModelManager.defaultModel;
    return modelPaths.containsKey(requestedModel.id);
  }

  @override
  Future<String> getModelPath([AIModel? model]) async {
    final requestedModel = model ?? ModelManager.defaultModel;
    final modelPath = modelPaths[requestedModel.id];
    if (modelPath == null) {
      throw StateError('No path configured for ${requestedModel.id}');
    }
    return modelPath;
  }

  @override
  Future<List<AIModel>> getDownloadedModels() async {
    return models.where((model) => modelPaths.containsKey(model.id)).toList();
  }

  @override
  void setCurrentlyLoadedModel(String? modelId) {
    lastSetModelId = modelId;
    _currentModel = modelId == null
        ? null
        : models.firstWhere((model) => model.id == modelId);
  }
}

class _FakeMcpInferenceService extends Fake implements InferenceService {
  final chatRequests = <List<ChatMessage>>[];

  @override
  bool get isModelLoaded => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> chat(List<ChatMessage> messages, {int? maxTokens}) async {
    chatRequests.add(List<ChatMessage>.from(messages));
    return 'stubbed-mcp-response';
  }
}

void _emitPrefill(ValueNotifier<String?> notifier, String prompt) {
  notifier.value = null;
  notifier.value = prompt;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prompt template coverage', () {
    test('main quick-action prompts cover all visible options', () {
      expect(mainAiQuickActionPrompts.keys, contains('Smart Search'));
      expect(mainAiQuickActionPrompts.keys, contains('Summarize'));
      expect(mainAiQuickActionPrompts.keys, contains('Discover'));

      for (final prompt in mainAiQuickActionPrompts.values) {
        expect(prompt.trim().isNotEmpty, isTrue);
      }
    });

    test('MCP prompt templates cover every displayed tool option', () {
      final toolNames = MCPService.instance.getAvailableTools().map(
        (t) => t.name,
      );

      for (final toolName in toolNames) {
        expect(
          promptForMcpTool(toolName).trim().isNotEmpty,
          isTrue,
          reason: 'Missing prompt for tool: $toolName',
        );
      }
    });
  });

  group('Composer autofill behavior', () {
    testWidgets('main AI options auto-fill textbox and can be sent', (
      tester,
    ) async {
      final primaryModel = ModelManager.getModelById('phi4-mini-q4km')!;
      final fakeInference = _FakeInferenceGateway();
      final fakeModelGateway = _FakeModelGateway(
        models: [primaryModel],
        modelPaths: {primaryModel.id: '/models/phi4.gguf'},
      );

      final controller = AIChatController(
        inferenceGateway: fakeInference,
        modelGateway: fakeModelGateway,
        autoInitialize: false,
      );
      await controller.switchModel(primaryModel);

      final promptPrefill = ValueNotifier<String?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Wrap(
                  children: mainAiQuickActionPrompts.entries
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.all(4),
                          child: ActionChip(
                            label: Text(entry.key),
                            onPressed: () =>
                                _emitPrefill(promptPrefill, entry.value),
                          ),
                        ),
                      )
                      .toList(),
                ),
                Expanded(
                  child: AIChatInterface(
                    controller: controller,
                    showHeader: false,
                    promptPrefillListenable: promptPrefill,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final entry in mainAiQuickActionPrompts.entries) {
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();

        final field = tester.widget<TextField>(find.byType(TextField).first);
        expect(field.controller?.text, entry.value);
      }

      final summarizePrompt = mainAiQuickActionPrompts['Summarize']!;
      _emitPrefill(promptPrefill, summarizePrompt);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send).first);
      await tester.pumpAndSettle();

      final sentUserMessages = controller.messages
          .where((message) => message.role == 'user')
          .map((message) => message.content)
          .toList();

      expect(sentUserMessages, contains(summarizePrompt));
      expect(fakeInference.chatRequests, isNotEmpty);

      controller.dispose();
      promptPrefill.dispose();
    });

    testWidgets('MCP tool options auto-fill textbox with tool prompts', (
      tester,
    ) async {
      final sandboxDir = await Directory.systemTemp.createTemp(
        'kivixa_mcp_autofill_',
      );

      final mcpService = MCPService.instance;
      mcpService.resetForTests();
      await mcpService.initialize(sandboxDir.path);

      final fakeMcpInference = _FakeMcpInferenceService();
      final controller = MCPChatController(
        inferenceService: fakeMcpInference,
        browseDirectory: sandboxDir.path,
      );

      final promptPrefill = ValueNotifier<String?>(null);
      final tools = mcpService.getAvailableTools();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: MCPChatInterface(
                  controller: controller,
                  context: context,
                  promptPrefillListenable: promptPrefill,
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      for (final tool in tools) {
        _emitPrefill(promptPrefill, promptForMcpTool(tool.name));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final field = tester.widget<TextField>(find.byType(TextField).first);
        expect(field.controller?.text, promptForMcpTool(tool.name));
      }

      controller.dispose();
      promptPrefill.dispose();
      mcpService.resetForTests();
      if (sandboxDir.existsSync()) {
        await sandboxDir.delete(recursive: true);
      }
    });
  });

  group('Sandboxed qwen prompt run', () {
    test(
      'runs prompts with qwen 0.8b and sandboxed dummy file operations',
      () async {
        final qwenModel = ModelManager.getModelById(
          'qwen35-08b-claude46-distilled-q5km',
        );
        expect(qwenModel, isNotNull);

        final fakeInference = _FakeInferenceGateway();
        final fakeModelGateway = _FakeModelGateway(
          models: [qwenModel!],
          modelPaths: {qwenModel.id: '/sandbox/models/qwen35-0.8b.gguf'},
        );

        final aiController = AIChatController(
          inferenceGateway: fakeInference,
          modelGateway: fakeModelGateway,
          autoInitialize: false,
        );

        final switched = await aiController.switchModel(qwenModel);
        expect(switched, isTrue);
        expect(aiController.loadedModelId, qwenModel.id);

        final sandboxDir = await Directory.systemTemp.createTemp(
          'kivixa_prompt_sandbox_',
        );
        final mcpService = MCPService.instance;
        mcpService.resetForTests();
        await mcpService.initialize(sandboxDir.path);

        final createResult = await mcpService.executeDirectly(
          const PendingToolCall(
            tool: 'create_folder',
            parameters: {'path': 'dummy'},
            description: 'create dummy folder',
          ),
        );
        expect(createResult.success, isTrue);

        final writeResult = await mcpService.executeDirectly(
          const PendingToolCall(
            tool: 'write_file',
            parameters: {
              'path': 'dummy/demo.md',
              'content': '# Dummy\nSandbox file for MCP prompt run.',
            },
            description: 'write dummy markdown file',
          ),
        );
        expect(writeResult.success, isTrue);

        final listResult = await mcpService.executeDirectly(
          const PendingToolCall(
            tool: 'list_files',
            parameters: {'path': 'dummy', 'recursive': true},
            description: 'list dummy files',
          ),
        );
        expect(listResult.success, isTrue);
        expect(listResult.result, matches(RegExp(r'dummy[\\/]demo\.md')));

        final readResult = await mcpService.executeDirectly(
          const PendingToolCall(
            tool: 'read_file',
            parameters: {'path': 'dummy/demo.md'},
            description: 'read dummy file',
          ),
        );
        expect(readResult.success, isTrue);
        expect(readResult.result, contains('Sandbox file for MCP prompt run.'));

        final deleteResult = await mcpService.executeDirectly(
          const PendingToolCall(
            tool: 'delete_file',
            parameters: {'path': 'dummy/demo.md'},
            description: 'delete dummy file',
          ),
        );
        expect(deleteResult.success, isTrue);

        final prompts = <String>[
          ...mainAiQuickActionPrompts.values,
          ...mcpToolPromptTemplates.values,
        ].map((prompt) => prompt.trim()).toList();

        for (final prompt in prompts) {
          await aiController.sendMessage(prompt);
        }

        final sentUserMessages = aiController.messages
            .where((message) => message.role == 'user')
            .map((message) => message.content)
            .toList();

        for (final prompt in prompts) {
          expect(sentUserMessages, contains(prompt));
        }

        expect(
          fakeInference.loadedModelPaths,
          contains('/sandbox/models/qwen35-0.8b.gguf'),
        );

        aiController.dispose();
        mcpService.resetForTests();
        if (sandboxDir.existsSync()) {
          await sandboxDir.delete(recursive: true);
        }
        expect(sandboxDir.existsSync(), isFalse);
      },
    );
  });
}
