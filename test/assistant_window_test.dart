import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/overlay/assistant_window.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

class _FakeInferenceGateway implements ChatInferenceGateway {
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
  Future<String> chat(List<ChatMessage> messages) async => 'ok';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    OverlayController.instance.closeAssistant();
  });

  testWidgets('floating assistant exposes attachment composer in AI and MCP', (
    tester,
  ) async {
    final model = ModelManager.getModelById('phi4-mini-q4km')!;
    final chatController = AIChatController(
      inferenceGateway: _FakeInferenceGateway(),
      modelGateway: _FakeModelGateway(model),
      autoInitialize: false,
    );
    await chatController.switchModel(model);

    OverlayController.instance.openAssistant();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AssistantWindow(chatController: chatController)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add attachments'), findsOneWidget);

    await tester.tap(find.byTooltip('Enable MCP Tools'));
    await tester.pumpAndSettle();

    expect(find.text('Kivixa MCP Assistant'), findsOneWidget);
    expect(find.byTooltip('Add attachments'), findsOneWidget);

    chatController.dispose();
  });
}
