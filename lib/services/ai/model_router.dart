/// Model Router Service
///
/// Automatically routes tasks to the appropriate AI model based on task type:
/// - Phi-4: General conversation and reasoning
/// - Functionary: Tool calling and function execution
/// - Qwen: Code generation and programming tasks
///
/// The router analyzes user messages and selects the best model for the task.
library;

import 'package:flutter/foundation.dart';
import 'package:kivixa/services/ai/mcp_service.dart';

/// Model types supported by the router
enum AIModelType {
  phi4,
  qwen,
  functionary;

  /// User-friendly display name
  String get displayName {
    switch (this) {
      case AIModelType.phi4:
        return 'Phi-4 (Reasoning)';
      case AIModelType.qwen:
        return 'Qwen 2.5 (Code)';
      case AIModelType.functionary:
        return 'Functionary (Tools)';
    }
  }

  /// Short name for compact displays
  String get shortName {
    switch (this) {
      case AIModelType.phi4:
        return 'Phi-4';
      case AIModelType.qwen:
        return 'Qwen';
      case AIModelType.functionary:
        return 'Func';
    }
  }
}

/// Information about the selected model
class ModelSelection {
  final AIModelType modelType;
  final MCPTaskCategory taskCategory;
  final String modelName;
  final String? modelPath;
  final bool isAvailable;

  const ModelSelection({
    required this.modelType,
    required this.taskCategory,
    required this.modelName,
    this.modelPath,
    required this.isAvailable,
  });
}

/// Model Router Service
class ModelRouterService {
  static ModelRouterService? _instance;
  static ModelRouterService get instance =>
      _instance ??= ModelRouterService._();

  ModelRouterService._();

  final MCPService _mcpService = MCPService.instance;
  AIModelType? _currentModel;
  String? _currentModelPath;

  /// Get the currently loaded model type
  AIModelType? get currentModel => _currentModel;

  /// Get the currently loaded model path
  String? get currentModelPath => _currentModelPath;

  /// Check if a specific model is currently loaded
  bool isModelLoaded(AIModelType modelType) => _currentModel == modelType;

  /// Analyze a message and determine the best model to use
  ModelSelection analyzeAndSelectModel(String userMessage) {
    // Use MCP's task classification
    final taskCategory = _mcpService.classifyTask(userMessage);
    final recommendedModelName = _mcpService.getModelForTask(taskCategory);

    // Map to model type
    final modelType = _mapModelNameToType(recommendedModelName);

    // For now, assume models are available if we have paths
    // In a full implementation, this would check actual model availability
    const isAvailable = true; // Placeholder - would check actual model files

    return ModelSelection(
      modelType: modelType,
      taskCategory: taskCategory,
      modelName: recommendedModelName,
      modelPath: null, // Would be populated from model manager
      isAvailable: isAvailable,
    );
  }

  /// Switch to the recommended model for a task
  Future<bool> switchToRecommendedModel(String userMessage) async {
    final selection = analyzeAndSelectModel(userMessage);

    if (!selection.isAvailable) {
      debugPrint(
        'Model ${selection.modelName} not available, using current model',
      );
      return false;
    }

    // If already using the right model, no need to switch
    if (_currentModel == selection.modelType) {
      debugPrint('Already using recommended model: ${selection.modelName}');
      return true;
    }

    // In a full implementation, this would load the model
    // For now, just update the tracking
    _currentModel = selection.modelType;
    debugPrint('Would switch to model: ${selection.modelName}');
    return true;
  }

  /// Load a specific model (placeholder for actual implementation)
  Future<bool> loadModel(AIModelType modelType, String? modelPath) async {
    // This would integrate with the actual InferenceService
    // For now, just track the model type
    _currentModel = modelType;
    _currentModelPath = modelPath;
    debugPrint('Model type set to: ${modelType.name}');
    return true;
  }

  /// Generate a system prompt optimized for the current model
  String getOptimizedSystemPrompt(AIModelType modelType) {
    switch (modelType) {
      case AIModelType.phi4:
        return '''
You are a helpful AI assistant. Provide clear, accurate, and thoughtful responses.
Focus on reasoning and explanation. Be conversational and helpful.''';

      case AIModelType.functionary:
        return '''
You are an AI assistant with access to tools. When the user asks you to perform actions, use the available tools.

To call a tool, respond with a JSON object in this format:
{"tool": "tool_name", "parameters": {...}, "description": "what this action does"}

Available tools:
- read_file: Read file contents
- write_file: Write or create a file
- delete_file: Delete a file
- create_folder: Create a folder
- list_files: List directory contents
- calendar_lua: Execute calendar scripts
- timer_lua: Execute timer scripts
- export_markdown: Export as markdown

Only call tools when the user explicitly requests an action. For general questions, respond normally.''';

      case AIModelType.qwen:
        return '''
You are an expert coding assistant. Provide well-structured, documented code.
Follow best practices and include comments explaining complex logic.
When generating Lua scripts, ensure they are compatible with the sandbox environment.''';
    }
  }

  /// Check if model switching is needed for a message
  bool needsModelSwitch(String userMessage) {
    final selection = analyzeAndSelectModel(userMessage);
    return selection.isAvailable && _currentModel != selection.modelType;
  }

  AIModelType _mapModelNameToType(String name) {
    switch (name.toLowerCase()) {
      case 'phi4':
        return AIModelType.phi4;
      case 'qwen':
        return AIModelType.qwen;
      case 'functionary':
        return AIModelType.functionary;
      default:
        return AIModelType.phi4; // Default fallback
    }
  }

  /// Get the best available model for a task category (placeholder)
  Future<String?> getBestModelPath(MCPTaskCategory category) async {
    // This would scan for available models
    // For now, return null to indicate model manager integration needed
    return null;
  }
}
