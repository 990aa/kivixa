import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/overlay/assistant_window.dart';
import 'package:kivixa/components/overlay/floating_hub.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

class _FakeInferenceGateway implements ChatInferenceGateway {
  _FakeInferenceGateway();

  final String response;
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

Widget _buildFloatingAssistantHarness(AIChatController chatController) {
  return MaterialApp(
    home: Scaffold(
      body: FloatingHubOverlay(
        child: Stack(
          fit: StackFit.expand,
          children: [AssistantWindow(chatController: chatController)],
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    OverlayController.testMode = true;
  });

  tearDownAll(() {
    OverlayController.testMode = false;
  });

  setUp(() {
    final overlayController = OverlayController.instance;
    overlayController.collapseHubMenu();
    overlayController.closeAssistant();
  });

  testWidgets(
    'model switch dropdown opens in floating assistant and lists downloaded models',
    (tester) async {
      final primaryModel = ModelManager.getModelById('phi4-mini-q4km')!;
      final secondaryModel = ModelManager.getModelById('qwen25-3b-q4km')!;

      final fakeInference = _FakeInferenceGateway();
      final fakeModelGateway = _FakeModelGateway(
        models: [primaryModel, secondaryModel],
        modelPaths: {
          primaryModel.id: '/models/phi4.gguf',
          secondaryModel.id: '/models/qwen25.gguf',
        },
      );

      final chatController = AIChatController(
        inferenceGateway: fakeInference,
        modelGateway: fakeModelGateway,
        autoInitialize: false,
      );

      final switched = await chatController.switchModel(primaryModel);
      expect(switched, isTrue);

      OverlayController.instance.openAssistant();

      await tester.pumpWidget(_buildFloatingAssistantHarness(chatController));
      await tester.pumpAndSettle();

      expect(find.text(primaryModel.name), findsOneWidget);

      await tester.tap(find.text(primaryModel.name));
      await tester.pumpAndSettle();

      expect(find.text('Switch Model'), findsOneWidget);
      expect(find.text(primaryModel.name), findsAtLeastNWidgets(2));
      expect(find.text(secondaryModel.name), findsOneWidget);

      chatController.dispose();
    },
  );

  testWidgets(
    'selecting model in floating assistant routes to selected model and chat inference still works',
    (tester) async {
      final primaryModel = ModelManager.getModelById('phi4-mini-q4km')!;
      final secondaryModel = ModelManager.getModelById('qwen25-3b-q4km')!;

      final fakeInference = _FakeInferenceGateway();
      final fakeModelGateway = _FakeModelGateway(
        models: [primaryModel, secondaryModel],
        modelPaths: {
          primaryModel.id: '/models/phi4.gguf',
          secondaryModel.id: '/models/qwen25.gguf',
        },
      );

      final chatController = AIChatController(
        inferenceGateway: fakeInference,
        modelGateway: fakeModelGateway,
        autoInitialize: false,
      );

      final switched = await chatController.switchModel(primaryModel);
      expect(switched, isTrue);

      OverlayController.instance.openAssistant();

      await tester.pumpWidget(_buildFloatingAssistantHarness(chatController));
      await tester.pumpAndSettle();

      await tester.tap(find.text(primaryModel.name));
      await tester.pumpAndSettle();

      await tester.tap(find.text(secondaryModel.name));
      await tester.pumpAndSettle();

      expect(chatController.loadedModelId, secondaryModel.id);
      expect(fakeModelGateway.lastSetModelId, secondaryModel.id);
      expect(fakeInference.loadedModelPaths.last, '/models/qwen25.gguf');

      await chatController.sendMessage('Ping from floating assistant');

      expect(fakeInference.chatRequests, isNotEmpty);
      expect(
        fakeInference.chatRequests.last.any(
          (message) =>
              message.role == 'user' &&
              message.content == 'Ping from floating assistant',
        ),
        isTrue,
      );
      expect(chatController.messages.last.content, 'stubbed-response');

      chatController.dispose();
    },
  );
}
