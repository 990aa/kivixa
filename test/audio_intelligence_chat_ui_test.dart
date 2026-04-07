import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';
import 'package:kivixa/services/ai/chat_attachment_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';

class _FakeInferenceGateway implements ChatInferenceGateway {
  var _loaded = false;

  @override
  bool get isModelLoaded => _loaded;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadModel(String modelPath) async {
    _loaded = true;
  }

  @override
  void unloadModel() {
    _loaded = false;
  }

  @override
  Future<String> chat(List<ChatMessage> messages) async =>
      'Assistant response for audio test.';
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
  Future<List<AIModel>> getDownloadedModels() async => <AIModel>[model];

  @override
  void setCurrentlyLoadedModel(String? modelId) {}
}

class _FakeMcpChatController extends Fake implements MCPChatController {
  _FakeMcpChatController(this._messages);

  final List<MCPChatMessage> _messages;

  @override
  void addListener(VoidCallback listener) {}

  @override
  List<MCPChatMessage> get messages => _messages;

  @override
  bool get isGenerating => false;

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Future<void> sendMessage(
    String content, {
    BuildContext? context,
    List<ChatAttachment> attachments = const <ChatAttachment>[],
  }) async {}

  @override
  void clearMessages() {}

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI chat shows dictation and response read-aloud actions', (
    tester,
  ) async {
    final model = ModelManager.getModelById('phi4-mini-q4km')!;
    final controller = AIChatController(
      inferenceGateway: _FakeInferenceGateway(),
      modelGateway: _FakeModelGateway(model),
      autoInitialize: false,
    );
    await controller.switchModel(model);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AIChatInterface(
            controller: controller,
            showHeader: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Voice dictation'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.tap(find.byIcon(Icons.send).first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Read response aloud'), findsWidgets);

    controller.dispose();
  });

  testWidgets('MCP chat shows dictation and response read-aloud actions', (
    tester,
  ) async {
    final controller = _FakeMcpChatController(<MCPChatMessage>[
      MCPChatMessage(
        role: 'assistant',
        content: 'MCP assistant response',
        isLoading: false,
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: MCPChatInterface(
                controller: controller,
                context: context,
                showHeader: false,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Voice dictation'), findsOneWidget);
    expect(find.byTooltip('Read response aloud'), findsWidgets);

    controller.dispose();
  });
}
