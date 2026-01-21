// AI Inference Service
//
// Provides a high-level Dart API for AI model inference.
// Uses flutter_rust_bridge to call the native Rust engine.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// Flutter Rust Bridge generated imports
import 'package:kivixa/src/rust/api.dart' as native;
import 'package:kivixa/src/rust/frb_generated.dart';

/// Whether Flutter Rust Bridge bindings are available
const kRustBridgeAvailable = true;

/// Configuration for inference operations
class InferenceConfig {
  /// Number of GPU layers to offload (99 = all possible)
  final int nGpuLayers;

  /// Context size (tokens)
  final int nCtx;

  /// Number of CPU threads for processing
  final int nThreads;

  /// Temperature for sampling (0.0 = deterministic, 1.0 = creative)
  final double temperature;

  /// Top-p sampling (nucleus sampling)
  final double topP;

  /// Maximum tokens to generate
  final int maxTokens;

  const InferenceConfig({
    this.nGpuLayers = 99,
    this.nCtx = 4096,
    this.nThreads = 4,
    this.temperature = 0.7,
    this.topP = 0.9,
    this.maxTokens = 512,
  });
}

/// A chat message for conversation history
class ChatMessage {
  final String role; // "system", "user", or "assistant"
  final String content;

  const ChatMessage({required this.role, required this.content});

  ChatMessage.system(String content) : this(role: 'system', content: content);
  ChatMessage.user(String content) : this(role: 'user', content: content);
  ChatMessage.assistant(String content)
    : this(role: 'assistant', content: content);

  (String, String) toTuple() => (role, content);
}

/// AI Inference Service singleton
class InferenceService {
  static final _instance = InferenceService._internal();
  factory InferenceService() => _instance;
  InferenceService._internal();

  var _isInitialized = false;
  var _isModelLoaded = false;
  int? _embeddingDimension;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// Whether the model is loaded and ready
  bool get isModelLoaded => _isModelLoaded;

  /// The embedding dimension of the loaded model
  int? get embeddingDimension => _embeddingDimension;

  /// Initialize the inference service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize flutter_rust_bridge with platform-specific library loading
    await _initializeRustLib();

    _isInitialized = true;
    debugPrint('InferenceService initialized');
  }

  /// Initialize RustLib with proper library path resolution
  Future<void> _initializeRustLib() async {
    ExternalLibrary? externalLibrary;

    if (Platform.isWindows) {
      // On Windows, the DLL should be next to the executable
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final dllPath = '$exeDir/kivixa_native.dll';

      debugPrint('Looking for native library at: $dllPath');

      if (File(dllPath).existsSync()) {
        debugPrint('Found native library, loading...');
        externalLibrary = ExternalLibrary.open(dllPath);
      } else {
        // Fallback: try loading from system PATH (for development)
        debugPrint('DLL not found at expected path, trying system PATH...');
        try {
          externalLibrary = ExternalLibrary.open('kivixa_native.dll');
        } catch (e) {
          debugPrint('Failed to load from PATH: $e');
          // Let FRB try its default paths
        }
      }
    } else if (Platform.isAndroid) {
      // On Android, the .so is loaded from jniLibs automatically
      // FRB handles this with the correct naming convention
      debugPrint('Android: using FRB default library loading');
    } else if (Platform.isLinux) {
      // On Linux, try the executable directory first
      final exePath = Platform.resolvedExecutable;
      final exeDir = File(exePath).parent.path;
      final soPath = '$exeDir/lib/libkivixa_native.so';

      if (File(soPath).existsSync()) {
        externalLibrary = ExternalLibrary.open(soPath);
      }
    } else if (Platform.isMacOS || Platform.isIOS) {
      // On macOS/iOS, the dylib is in the framework
      debugPrint('macOS/iOS: using FRB default library loading');
    }

    // Initialize with custom library if found, otherwise use defaults
    await RustLib.init(externalLibrary: externalLibrary);
  }

  /// Load the AI model from the given path
  Future<void> loadModel(String modelPath, [InferenceConfig? config]) async {
    await initialize();

    // Skip if model is already loaded to prevent BackendAlreadyInitialized error
    if (_isModelLoaded) {
      debugPrint('Model already loaded, skipping initialization');
      return;
    }

    config ??= const InferenceConfig();

    try {
      await native.initModelWithConfig(
        modelPath: modelPath,
        nGpuLayers: config.nGpuLayers,
        nCtx: config.nCtx,
        nThreads: config.nThreads,
        temperature: config.temperature,
        topP: config.topP,
        maxTokens: config.maxTokens,
      );

      _isModelLoaded = true;

      // Get embedding dimension
      final dimension = native.getEmbeddingDimension();
      _embeddingDimension = dimension.toInt();

      debugPrint('Model loaded from: $modelPath');
      debugPrint('Embedding dimension: $_embeddingDimension');
    } catch (e) {
      debugPrint('Failed to load model: $e');
      rethrow;
    }
  }

  /// Unload the model and free resources
  void unloadModel() {
    native.unloadModel();
    _isModelLoaded = false;
    _embeddingDimension = null;
    debugPrint('Model unloaded');
  }

  /// Generate text completion from a prompt
  Future<String> generateText(String prompt, {int? maxTokens}) async {
    _ensureModelLoaded();

    return await native.generateText(prompt: prompt, maxTokens: maxTokens);
  }

  /// Chat completion with conversation history
  Future<String> chat(List<ChatMessage> messages, {int? maxTokens}) async {
    _ensureModelLoaded();

    final tuples = messages.map((m) => m.toTuple()).toList();
    return await native.chatCompletion(messages: tuples, maxTokens: maxTokens);
  }

  /// Get embedding for text (for semantic search)
  Future<List<double>> getEmbedding(String text) async {
    _ensureModelLoaded();

    final floats = await native.getEmbedding(text: text);
    return floats.map((f) => f.toDouble()).toList();
  }

  /// Extract topics from note content
  Future<List<String>> extractTopics(String text, {int numTopics = 3}) async {
    _ensureModelLoaded();

    return await native.extractTopics(text: text, numTopics: numTopics);
  }

  /// Summarize text
  Future<String> summarize(String text, {int maxLength = 200}) async {
    final messages = [
      ChatMessage.system(
        'You are a helpful assistant that creates concise summaries. '
        'Always respond with just the summary, no explanations.',
      ),
      ChatMessage.user(
        'Summarize the following text in about $maxLength characters:\n\n$text',
      ),
    ];

    return await chat(messages, maxTokens: maxLength ~/ 4);
  }

  /// Answer questions about content
  Future<String> askAboutContent(String content, String question) async {
    final messages = [
      ChatMessage.system(
        'You are a helpful assistant. Answer questions based on the provided context. '
        'If the answer is not in the context, say so.',
      ),
      ChatMessage.user('Context:\n$content\n\nQuestion: $question'),
    ];

    return await chat(messages);
  }

  /// Generate title suggestions for content
  Future<List<String>> suggestTitles(String content, {int count = 3}) async {
    final messages = [
      ChatMessage.system(
        'You are a helpful assistant that creates note titles. '
        'Return a JSON array of $count short, descriptive titles.',
      ),
      ChatMessage.user('Suggest $count titles for this note:\n\n$content'),
    ];

    final response = await chat(messages, maxTokens: 100);

    // Parse JSON response
    try {
      // Simple parsing - in production use json.decode
      final cleaned = response.trim();
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        final inner = cleaned.substring(1, cleaned.length - 1);
        return inner
            .split(',')
            .map((s) => s.trim().replaceAll('"', ''))
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to parse titles: $e');
    }

    return ['Untitled Note'];
  }

  void _ensureModelLoaded() {
    if (!_isModelLoaded) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      await initialize();
      final result = native.healthCheck();
      return result == 'Kivixa Native OK';
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Get version info from native library
  String getVersion() {
    return native.getVersion();
  }

  /// Check if model is loaded via native call
  bool checkModelLoaded() {
    return native.isModelLoaded();
  }
}
