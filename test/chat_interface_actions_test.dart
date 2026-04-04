import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/services/ai/chat_attachment_service.dart';
import 'package:kivixa/services/ai/chat_context_service.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';

class _FakeInferenceGateway implements ChatInferenceGateway {
  final chatRequests = <List<ChatMessage>>[];
  String Function(List<ChatMessage>)? responseBuilder;
  var _isModelLoaded = false;

  @override
  bool get isModelLoaded => _isModelLoaded;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadModel(String modelPath) async {
    _isModelLoaded = true;
  }

  @override
  void unloadModel() {
    _isModelLoaded = false;
  }

  @override
  Future<String> chat(List<ChatMessage> messages) async {
    chatRequests.add(List<ChatMessage>.from(messages));
    return responseBuilder?.call(messages) ?? 'Assistant response';
  }
}

class _FakeModelGateway implements ChatModelGateway {
  _FakeModelGateway(this.model);

  final AIModel model;

  @override
  AIModel? get currentlyLoadedModel => model;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isModelDownloaded([AIModel? model]) async => true;

  @override
  Future<String> getModelPath([AIModel? model]) async => '/tmp/model.gguf';

  @override
  Future<List<AIModel>> getDownloadedModels() async => [model];

  @override
  void setCurrentlyLoadedModel(String? modelId) {}
}

class _FakeContextGateway implements ChatContextGateway {
  const _FakeContextGateway(this.snapshot);

  final String snapshot;

  @override
  Future<String> buildContextSnapshot() async => snapshot;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AIChatController includes context snapshot in chat request', () async {
    final model = ModelManager.getModelById('phi4-mini-q4km')!;
    final inference = _FakeInferenceGateway();
    final controller = AIChatController(
      inferenceGateway: inference,
      modelGateway: _FakeModelGateway(model),
      contextGateway: const _FakeContextGateway('CTX: notes and activities'),
      autoInitialize: false,
    );
    await controller.switchModel(model);
    await controller.sendMessage('Summarize recent notes');

    expect(inference.chatRequests, isNotEmpty);
    final request = inference.chatRequests.last;
    expect(
      request.any(
        (msg) => msg.role == 'system' && msg.content.contains('CTX:'),
      ),
      isTrue,
    );
    expect(controller.messages.last.modelName, model.name);
    expect(controller.messages.last.modelId, model.id);

    controller.dispose();
  });

  test(
    'AIChatController injects attachment context into chat request',
    () async {
      final model = ModelManager.getModelById('phi4-mini-q4km')!;
      final inference = _FakeInferenceGateway();
      final controller = AIChatController(
        inferenceGateway: inference,
        modelGateway: _FakeModelGateway(model),
        contextGateway: const _FakeContextGateway(''),
        autoInitialize: false,
      );
      await controller.switchModel(model);

      const attachment = ChatAttachment(
        id: 'a1',
        filePath: '/tmp/plan.txt',
        fileName: 'plan.txt',
        sizeBytes: 20,
        mediaType: 'text/plain',
        extractedText: 'Attachment context marker',
      );

      await controller.sendMessage(
        'Use the attachment',
        attachments: const [attachment],
      );

      expect(inference.chatRequests, isNotEmpty);
      final userMessage = inference.chatRequests.last.lastWhere(
        (message) => message.role == 'user',
      );
      expect(userMessage.content, contains('[Attached files]'));
      expect(userMessage.content, contains('Attachment context marker'));

      controller.dispose();
    },
  );

  group('AI chat interface actions', () {
    testWidgets('shows copy controls for user and assistant messages', (
      tester,
    ) async {
      final model = ModelManager.getModelById('phi4-mini-q4km')!;
      final inference = _FakeInferenceGateway()
        ..responseBuilder = (_) => '# Assistant Markdown\n\n- item';
      final controller = AIChatController(
        inferenceGateway: inference,
        modelGateway: _FakeModelGateway(model),
        contextGateway: const _FakeContextGateway(''),
        autoInitialize: false,
      );
      await controller.switchModel(model);
      await controller.sendMessage('Hello there');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIChatInterface(controller: controller, showHeader: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Copy'), findsNWidgets(2));
      expect(find.byTooltip('Retry'), findsOneWidget);
      expect(find.byType(MarkdownBody), findsWidgets);

      controller.dispose();
    });

    testWidgets('exports chat payload through provided callback', (
      tester,
    ) async {
      final model = ModelManager.getModelById('phi4-mini-q4km')!;
      final controller = AIChatController(
        inferenceGateway: _FakeInferenceGateway(),
        modelGateway: _FakeModelGateway(model),
        contextGateway: const _FakeContextGateway(''),
        autoInitialize: false,
      );
      await controller.switchModel(model);
      await controller.sendMessage('Export this');

      String? exportedPayload;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIChatInterface(
              controller: controller,
              onExportChat: (payload) async {
                exportedPayload = payload;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Export chat as JSON'));
      await tester.pumpAndSettle();

      expect(exportedPayload, isNotNull);
      final decoded = jsonDecode(exportedPayload!) as Map<String, dynamic>;
      expect(decoded['sessionType'], 'ai-chat');
      expect(decoded['messageCount'], 2);

      controller.dispose();
    });

    testWidgets('supports composer attachment add/remove and send wiring', (
      tester,
    ) async {
      final model = ModelManager.getModelById('phi4-mini-q4km')!;
      final inference = _FakeInferenceGateway();
      final controller = AIChatController(
        inferenceGateway: inference,
        modelGateway: _FakeModelGateway(model),
        contextGateway: const _FakeContextGateway(''),
        autoInitialize: false,
      );
      await controller.switchModel(model);

      const attachment = ChatAttachment(
        id: 'att-1',
        filePath: '/tmp/spec.md',
        fileName: 'spec.md',
        sizeBytes: 128,
        mediaType: 'text/plain',
        extractedText: 'Attachment body',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIChatInterface(
              controller: controller,
              showHeader: false,
              onPickAttachments: () async => const [attachment],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add attachments'));
      await tester.pumpAndSettle();

      expect(find.text('spec.md'), findsOneWidget);

      await tester.tap(find.byTooltip('Remove attachment'));
      await tester.pumpAndSettle();
      expect(find.text('spec.md'), findsNothing);

      await tester.tap(find.byTooltip('Add attachments'));
      await tester.pumpAndSettle();
      expect(find.text('spec.md'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Use this file');
      await tester.tap(find.byIcon(Icons.send).first);
      await tester.pumpAndSettle();

      expect(inference.chatRequests, isNotEmpty);
      final sentUserMessage = inference.chatRequests.last.lastWhere(
        (message) => message.role == 'user',
      );
      expect(sentUserMessage.content, contains('spec.md'));
      expect(sentUserMessage.content, contains('Attachment body'));

      expect(find.text('spec.md'), findsNothing);

      controller.dispose();
    });

    testWidgets('navigates user prompt history with up and down arrows', (
      tester,
    ) async {
      final model = ModelManager.getModelById('phi4-mini-q4km')!;
      final controller = AIChatController(
        inferenceGateway: _FakeInferenceGateway(),
        modelGateway: _FakeModelGateway(model),
        contextGateway: const _FakeContextGateway(''),
        autoInitialize: false,
      );
      await controller.switchModel(model);
      await controller.sendMessage('first prompt');
      await controller.sendMessage('second prompt');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIChatInterface(controller: controller, showHeader: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'draft text');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      var field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, 'second prompt');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, 'first prompt');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, 'second prompt');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, 'draft text');

      controller.dispose();
    });
  });
}
