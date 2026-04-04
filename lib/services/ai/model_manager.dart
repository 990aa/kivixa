import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Enum representing the current state of the model download
enum ModelDownloadState {
  /// Model is not downloaded and no download is in progress
  notDownloaded,

  /// Download is queued but not yet started
  queued,

  /// Download is currently in progress
  downloading,

  /// Download is paused
  paused,

  /// Download completed successfully
  completed,

  /// Download failed
  failed,
}

/// Categories for AI models based on their primary use case
enum ModelCategory {
  /// General purpose assistant - default category
  general('General Purpose', 'Versatile models for everyday tasks'),

  /// MCP/Agent tasks - function calling, tool use
  agent('MCP / Agent Brain', 'Optimized for function calling and tool use'),

  /// Writing, notes, and markdown assistance
  writing('Writing / Notes', 'Optimized for writing and content creation'),

  /// Math and LaTeX help
  math('Math / LaTeX', 'Specialized for mathematical reasoning'),

  /// Code generation, especially Lua
  code('Code Generation', 'Optimized for programming tasks'),

  /// Highest-quality reasoning models for best results
  strongest('Strongest', 'Top-tier reasoning and output quality models');

  final String displayName;
  final String description;

  const ModelCategory(this.displayName, this.description);
}

/// Progress information for model download
class ModelDownloadProgress {
  final ModelDownloadState state;
  final double progress; // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final String? modelId;
  final String? errorMessage;
  final double? networkSpeed; // bytes per second

  const ModelDownloadProgress({
    required this.state,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.modelId,
    this.errorMessage,
    this.networkSpeed,
  });

  /// Returns a human-readable string for the download progress
  String get progressText {
    if (totalBytes == 0) return 'Preparing...';
    final downloadedMB = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    return '$downloadedMB MB / $totalMB MB';
  }

  /// Returns a human-readable string for the network speed
  String get speedText {
    if (networkSpeed == null || networkSpeed == 0) return '';
    if (networkSpeed! < 1024) {
      return '${networkSpeed!.toStringAsFixed(0)} B/s';
    } else if (networkSpeed! < 1024 * 1024) {
      return '${(networkSpeed! / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(networkSpeed! / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Returns estimated time remaining in seconds
  int? get estimatedSecondsRemaining {
    if (networkSpeed == null || networkSpeed == 0) return null;
    final remainingBytes = totalBytes - downloadedBytes;
    return (remainingBytes / networkSpeed!).round();
  }

  /// Returns a human-readable string for the estimated time remaining
  String get etaText {
    final seconds = estimatedSecondsRemaining;
    if (seconds == null) return '';
    if (seconds < 60) {
      return '${seconds}s remaining';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m remaining';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m remaining';
    }
  }

  ModelDownloadProgress copyWith({
    ModelDownloadState? state,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    String? modelId,
    String? errorMessage,
    double? networkSpeed,
  }) {
    return ModelDownloadProgress(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      modelId: modelId ?? this.modelId,
      errorMessage: errorMessage ?? this.errorMessage,
      networkSpeed: networkSpeed ?? this.networkSpeed,
    );
  }
}

/// A downloadable file asset for a model card.
class AIModelAsset {
  final String id;
  final String url;
  final String fileName;
  final int sizeBytes;
  final List<String> alternateFileNames;

  const AIModelAsset({
    required this.id,
    required this.url,
    required this.fileName,
    required this.sizeBytes,
    this.alternateFileNames = const [],
  });
}

/// Information about a downloadable AI model
class AIModel {
  final String id;
  final String name;
  final String shortDescription;
  final String description;
  final String recommendation;
  final String url;
  final String fileName;
  final List<String> alternateFileNames; // Backward/legacy filename support
  final int sizeBytes; // Expected size in bytes
  final List<AIModelAsset> assets; // Optional multi-file model package
  final String? sha256Hash; // Optional hash for verification
  final List<ModelCategory> categories; // Use cases for this model
  final bool isDefault; // Whether this is the default model
  final bool isReasoningModel; // Whether model frequently emits <think> traces
  final bool supportsVision; // Whether this model supports image understanding

  const AIModel({
    required this.id,
    required this.name,
    this.shortDescription = '',
    required this.description,
    this.recommendation = '',
    required this.url,
    required this.fileName,
    this.alternateFileNames = const [],
    required this.sizeBytes,
    this.assets = const [],
    this.sha256Hash,
    this.categories = const [ModelCategory.general],
    this.isDefault = false,
    this.isReasoningModel = false,
    this.supportsVision = false,
  });

  List<AIModelAsset> get downloadAssets {
    if (assets.isNotEmpty) {
      return assets;
    }

    return <AIModelAsset>[
      AIModelAsset(
        id: 'model',
        url: url,
        fileName: fileName,
        sizeBytes: sizeBytes,
        alternateFileNames: alternateFileNames,
      ),
    ];
  }

  AIModelAsset get primaryAsset => downloadAssets.first;

  int get totalSizeBytes =>
      downloadAssets.fold<int>(0, (sum, asset) => sum + asset.sizeBytes);

  bool get hasCompanionAssets => downloadAssets.length > 1;

  /// Human-readable size string
  String get sizeText {
    final bytes = totalSizeBytes;
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Best short description to show in compact UI cards
  String get displayDescription =>
      shortDescription.isNotEmpty ? shortDescription : description;

  /// Optional recommendation text to help users pick a model
  String get suggestionText => recommendation;

  /// Check if model is suitable for a given category
  bool supportsCategory(ModelCategory category) =>
      categories.contains(category);
}

/// Manages AI model downloads with resume support and background downloading
class ModelManager {
  static final _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  /// Available models for download
  static const availableModels = <AIModel>[
    // Default model - Phi-4 Mini (General Purpose, Writing, Math)
    AIModel(
      id: 'phi4-mini-q4km',
      name: 'Phi-4 Mini',
      shortDescription:
          'Balanced assistant for everyday reasoning, writing, and math.',
      description:
          'Microsoft Phi-4 Mini Instruct - Compact and efficient model for on-device AI. '
          'Great for general chat, writing assistance, and math/LaTeX help.',
      recommendation:
          'Start here if you want one reliable all-round model for most tasks.',
      url:
          'https://huggingface.co/bartowski/microsoft_Phi-4-mini-instruct-GGUF/resolve/main/microsoft_Phi-4-mini-instruct-Q4_K_M.gguf',
      fileName: 'microsoft_Phi-4-mini-instruct-Q4_K_M.gguf',
      sizeBytes: 2671771648, // ~2.49 GB
      categories: [
        ModelCategory.general,
        ModelCategory.writing,
        ModelCategory.math,
      ],
      isDefault: true,
    ),

    // Phi-4 Mini Reasoning - stronger math-focused Phi variant
    AIModel(
      id: 'phi4-mini-reasoning-q4km',
      name: 'Phi-4 Mini Reasoning',
      shortDescription:
          'Reasoning-tuned Phi-4 Mini for step-by-step math and logic tasks.',
      description:
          'Microsoft Phi-4 Mini Reasoning (GGUF by Unsloth) - tuned for '
          'multi-step reasoning and analytical tasks while staying compact.',
      recommendation:
          'Use this when you want stronger step-by-step reasoning than baseline Phi-4 Mini.',
      url:
          'https://huggingface.co/unsloth/Phi-4-mini-reasoning-GGUF/resolve/main/Phi-4-mini-reasoning-Q4_K_M.gguf',
      fileName: 'Phi-4-mini-reasoning-Q4_K_M.gguf',
      sizeBytes: 2670000000, // ~2.49 GB
      categories: [
        ModelCategory.general,
        ModelCategory.math,
        ModelCategory.code,
        ModelCategory.strongest,
      ],
      isReasoningModel: true,
    ),

    // Qwen2.5-3B - Writing and Code
    AIModel(
      id: 'qwen25-3b-q4km',
      name: 'Qwen2.5 3B',
      shortDescription:
          'Writer-friendly 3B model with strong coding and drafting quality.',
      description:
          'Alibaba Qwen2.5 3B Instruct - Excellent for writing, notes, and code generation. '
          'Particularly strong at Lua and other scripting languages.',
      recommendation:
          'Pick this when you want strong writing and coding quality in under 2 GB.',
      url:
          'https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf',
      fileName: 'qwen2.5-3b-instruct-q4_k_m.gguf',
      sizeBytes: 2019221504, // ~1.88 GB
      categories: [
        ModelCategory.writing,
        ModelCategory.code,
        ModelCategory.general,
      ],
    ),

    // Qwen3.5 4B Distilled - Strongest quality among distilled Qwen options
    AIModel(
      id: 'qwen35-4b-claude46-distilled-v2-q4km',
      name: 'Qwen3.5 4B Claude 4.6 Opus Reasoning Distilled',
      shortDescription:
          'Best quality in the Qwen3.5 distilled set for deep reasoning and code.',
      description:
          'Qwen3.5 4B Claude 4.6 Opus Reasoning Distilled - High quality '
          'reasoning and coding with a larger distilled model footprint.',
      recommendation:
          'Choose this for highest output quality if your device has enough RAM.',
      url:
          'https://huggingface.co/Jackrong/Qwen3.5-4B-Claude-4.6-Opus-Reasoning-Distilled-v2-GGUF/resolve/main/Qwen3.5-4B.Q4_K_M.gguf',
      fileName: 'Qwen3.5-4B.Q4_K_M.gguf',
      alternateFileNames: [
        'Qwen3.5-4B-Claude-4.6-Opus-Reasoning-Distilled-v2.Q4_K_M.gguf',
      ],
      sizeBytes: 2820000000, // ~2.63 GB
      categories: [
        ModelCategory.general,
        ModelCategory.writing,
        ModelCategory.code,
        ModelCategory.math,
        ModelCategory.strongest,
      ],
      isReasoningModel: true,
    ),

    // Qwen3.5 2B Distilled - Balanced speed and quality
    AIModel(
      id: 'qwen35-2b-claude46-distilled-q5km',
      name: 'Qwen3.5 2B Claude 4.6 Opus Reasoning Distilled',
      shortDescription:
          'Balanced Qwen3.5 distilled model for quality and speed on mid-range devices.',
      description:
          'Qwen3.5 2B Claude 4.6 Opus Reasoning Distilled - Mid-size distilled '
          'model with strong coding and writing performance.',
      recommendation:
          'Best balance if you want strong results without the 4B model size.',
      url:
          'https://huggingface.co/Jackrong/Qwen3.5-2B-Claude-4.6-Opus-Reasoning-Distilled-GGUF/resolve/main/Qwen3.5-2B.Q5_K_M.gguf',
      fileName: 'Qwen3.5-2B.Q5_K_M.gguf',
      alternateFileNames: [
        'Qwen3.5-2B-Claude-4.6-Opus-Reasoning-Distilled.Q5_K_M.gguf',
      ],
      sizeBytes: 1620000000, // ~1.51 GB
      categories: [
        ModelCategory.general,
        ModelCategory.writing,
        ModelCategory.code,
        ModelCategory.strongest,
      ],
      isReasoningModel: true,
    ),

    // Qwen3.5 0.8B Distilled - Smallest Qwen3.5 distilled option
    AIModel(
      id: 'qwen35-08b-claude46-distilled-q5km',
      name: 'Qwen3.5 0.8B Claude 4.6 Opus Reasoning Distilled',
      shortDescription:
          'Small and fast Qwen3.5 distilled model for constrained devices.',
      description:
          'Qwen3.5 0.8B Claude 4.6 Opus Reasoning Distilled - Lightweight '
          'model optimized for fast responses and low resource usage.',
      recommendation:
          'Choose this first when storage or RAM is limited and speed matters most.',
      url:
          'https://huggingface.co/Jackrong/Qwen3.5-0.8B-Claude-4.6-Opus-Reasoning-Distilled-GGUF/resolve/main/Qwen3.5-0.8B.Q5_K_M.gguf',
      fileName: 'Qwen3.5-0.8B.Q5_K_M.gguf',
      alternateFileNames: [
        'Qwen3.5-0.8B-Claude-4.6-Opus-Reasoning-Distilled.Q5_K_M.gguf',
      ],
      sizeBytes: 760000000, // ~725 MB
      categories: [
        ModelCategory.general,
        ModelCategory.writing,
        ModelCategory.code,
        ModelCategory.strongest,
      ],
      isReasoningModel: true,
    ),

    // DeepSeek R1 Distill Qwen 1.5B - compact reasoning model
    AIModel(
      id: 'deepseek-r1-distill-qwen-15b-q4km',
      name: 'DeepSeek R1 Distill Qwen 1.5B',
      shortDescription:
          'Compact reasoning model with visible think traces and strong math/code ability.',
      description:
          'DeepSeek R1 Distill Qwen 1.5B (GGUF) - distilled reasoning model '
          'with strong logical decomposition for coding and problem solving.',
      recommendation:
          'Choose this for lightweight reasoning-heavy tasks and structured problem solving.',
      url:
          'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
      fileName: 'DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
      sizeBytes: 1200000000, // ~1.12 GB
      categories: [
        ModelCategory.general,
        ModelCategory.math,
        ModelCategory.code,
      ],
    ),

    // SmolLM2 1.7B Instruct - fast small instruct model
    AIModel(
      id: 'smollm2-17b-instruct-q4km',
      name: 'SmolLM2 1.7B Instruct',
      shortDescription:
          'Fast small instruct model for writing, lightweight coding, and quick replies.',
      description:
          'SmolLM2 1.7B Instruct (GGUF) - compact and responsive model for '
          'day-to-day writing, chat, and lightweight coding workflows.',
      recommendation:
          'Great pick for lower-memory devices when you still want solid instruct behavior.',
      url:
          'https://huggingface.co/bartowski/SmolLM2-1.7B-Instruct-GGUF/resolve/main/SmolLM2-1.7B-Instruct-Q4_K_M.gguf',
      fileName: 'SmolLM2-1.7B-Instruct-Q4_K_M.gguf',
      sizeBytes: 1140000000, // ~1.06 GB
      categories: [
        ModelCategory.general,
        ModelCategory.writing,
        ModelCategory.code,
      ],
    ),

    // SmolLM3 3B - newer compact general model
    AIModel(
      id: 'smollm3-3b-q4km',
      name: 'SmolLM3 3B',
      shortDescription:
          'New-generation compact model for strong general chat, writing, and code.',
      description:
          'SmolLM3 3B (GGUF by ggml-org) - updated SmolLM family model with '
          'improved multilingual quality and robust day-to-day assistant behavior.',
      recommendation:
          'Choose this for a newer compact all-round model when you want better quality than older small LLMs.',
      url:
          'https://huggingface.co/ggml-org/SmolLM3-3B-GGUF/resolve/main/SmolLM3-Q4_K_M.gguf',
      fileName: 'SmolLM3-Q4_K_M.gguf',
      sizeBytes: 1915305312, // ~1.78 GB
      categories: [
        ModelCategory.general,
        ModelCategory.writing,
        ModelCategory.code,
      ],
      isReasoningModel: true,
    ),

    // SmolVLM2 500M - merged card (text model + mmproj)
    AIModel(
      id: 'smolvlm2-500m-video-instruct-q8',
      name: 'SmolVLM2 500M Video Instruct',
      shortDescription:
          'Compact vision-language model for image-aware chat and multimodal notes.',
      description:
          'SmolVLM2 500M Video Instruct (GGUF + mmproj) delivered as a merged '
          'model card so both required files download together for vision inference.',
      recommendation:
          'Pick this when you want local image understanding directly inside AI and MCP chats.',
      url:
          'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
      fileName: 'SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
      sizeBytes: 436808704, // primary model size; total shown via assets
      assets: [
        AIModelAsset(
          id: 'model',
          url:
              'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
          fileName: 'SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
          sizeBytes: 436808704,
        ),
        AIModelAsset(
          id: 'mmproj',
          url:
              'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/mmproj-SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
          fileName: 'mmproj-SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
          sizeBytes: 108785184,
        ),
      ],
      categories: [ModelCategory.general, ModelCategory.writing],
      supportsVision: true,
    ),

    // Function Gemma 270M - Top choice for MCP/Tool calling
    AIModel(
      id: 'function-gemma-270m',
      name: 'Function Gemma 270M',
      shortDescription:
          'Ultra-light tool-calling specialist for MCP actions and automation.',
      description:
          'Unsloth Function Gemma 270M - Ultra-lightweight model specialized for '
          'function calling and MCP tool use. Best choice for agent tasks.',
      recommendation:
          'Best for file, calendar, and timer actions, especially on low-power devices.',
      url:
          'https://huggingface.co/unsloth/functiongemma-270m-it-GGUF/resolve/main/functiongemma-270m-it-Q4_K_M.gguf',
      fileName: 'functiongemma-270m-it-Q4_K_M.gguf',
      sizeBytes: 188743680, // ~180 MB
      categories: [ModelCategory.agent],
    ),

    // Gemma 2B - General purpose small model
    AIModel(
      id: 'gemma-2b',
      name: 'Gemma 2B',
      shortDescription:
          'General-purpose compact model with steady speed and broad capability.',
      description:
          'Google Gemma 2B - Lightweight general-purpose model. '
          'Good balance of speed and capability for everyday tasks.',
      recommendation:
          'Good fallback for general tasks if you prefer Gemma-family responses.',
      url:
          'https://huggingface.co/tensorblock/gemma-2b-GGUF/resolve/main/gemma-2b-Q4_K_M.gguf',
      fileName: 'gemma-2b-Q4_K_M.gguf',
      sizeBytes: 1678770176, // ~1.56 GB
      categories: [ModelCategory.general, ModelCategory.code],
    ),

    // Gemma 3 4B IT - newer Gemma instruct model
    AIModel(
      id: 'gemma-3-4b-it-q4km',
      name: 'Gemma 3 4B IT',
      shortDescription:
          'Newer Gemma instruct model with strong balanced quality for chat and coding.',
      description:
          'Google Gemma 3 4B IT (GGUF by bartowski) - modern Gemma-family '
          'instruction model with strong multi-purpose quality.',
      recommendation:
          'Use this when you want a larger Gemma-family model for stronger general output quality.',
      url:
          'https://huggingface.co/bartowski/google_gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf',
      fileName: 'gemma-3-4b-it-Q4_K_M.gguf',
      sizeBytes: 2670000000, // ~2.49 GB
      categories: [
        ModelCategory.general,
        ModelCategory.writing,
        ModelCategory.code,
      ],
    ),

    // TranslateGemma 4B IT - translation-focused multilingual model
    AIModel(
      id: 'translategemma-4b-it-q4km',
      name: 'TranslateGemma 4B IT',
      shortDescription:
          'Translation-focused Gemma model for multilingual drafting and localization.',
      description:
          'TranslateGemma 4B IT (GGUF by mradermacher) - instruction-tuned '
          'model optimized for translation, bilingual rewriting, and '
          'cross-language editing workflows.',
      recommendation:
          'Choose this for translating notes, refining multilingual text, and localization tasks.',
      url:
          'https://huggingface.co/mradermacher/translategemma-4b-it-GGUF/resolve/main/translategemma-4b-it.Q4_K_M.gguf',
      fileName: 'translategemma-4b-it.Q4_K_M.gguf',
      sizeBytes: 2489909760, // ~2.32 GB
      categories: [ModelCategory.writing, ModelCategory.general],
    ),
  ];

  /// Default model to use (Phi-4 Mini)
  static AIModel get defaultModel => availableModels.firstWhere(
    (m) => m.isDefault,
    orElse: () => availableModels.first,
  );

  /// Get models by category
  static List<AIModel> getModelsForCategory(ModelCategory category) {
    return availableModels.where((m) => m.supportsCategory(category)).toList();
  }

  /// Get recommended model for a category
  static AIModel getRecommendedModel(ModelCategory category) {
    final models = getModelsForCategory(category);
    // Return first model that matches, or default if none
    return models.isNotEmpty ? models.first : defaultModel;
  }

  /// Currently loaded model ID (tracked at runtime)
  String? _currentlyLoadedModelId;

  /// Get the currently loaded model
  AIModel? get currentlyLoadedModel {
    if (_currentlyLoadedModelId == null) return null;
    return availableModels.firstWhere(
      (m) => m.id == _currentlyLoadedModelId,
      orElse: () => defaultModel,
    );
  }

  /// Set the currently loaded model ID
  void setCurrentlyLoadedModel(String? modelId) {
    _currentlyLoadedModelId = modelId;
  }

  /// Get model by ID
  static AIModel? getModelById(String id) {
    try {
      return availableModels.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all downloaded models
  Future<List<AIModel>> getDownloadedModels() async {
    final downloaded = <AIModel>[];
    for (final model in availableModels) {
      if (await isModelDownloaded(model)) {
        downloaded.add(model);
      }
    }
    return downloaded;
  }

  /// Stream controller for download progress updates
  final _progressController =
      StreamController<ModelDownloadProgress>.broadcast();

  /// Stream of download progress updates
  Stream<ModelDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Current download state
  var _currentProgress = const ModelDownloadProgress(
    state: ModelDownloadState.notDownloaded,
  );

  ModelDownloadProgress get currentProgress => _currentProgress;

  /// Active download tasks for the current model download session.
  final Map<String, DownloadTask> _activeTasks = <String, DownloadTask>{};
  final Map<String, int> _taskSizes = <String, int>{};
  final Map<String, double> _taskProgress = <String, double>{};
  final Set<String> _taskPaused = <String>{};
  final Set<String> _taskCompleted = <String>{};
  AIModel? _activeDownloadModel;
  double? _latestNetworkSpeed;

  /// Flag to track if manager is initialized
  var _isInitialized = false;

  /// Initialize the model manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configure the FileDownloader
    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Downloading AI Model',
        'Kivixa is downloading the AI model for offline use',
      ),
      complete: const TaskNotification(
        'Download Complete',
        'AI model is ready to use',
      ),
      error: const TaskNotification(
        'Download Failed',
        'There was an error downloading the AI model',
      ),
      paused: const TaskNotification(
        'Download Paused',
        'AI model download is paused',
      ),
      progressBar: true,
    );

    // Check if model is already downloaded
    final isDownloaded = await isModelDownloaded();
    if (isDownloaded) {
      _updateProgress(
        ModelDownloadProgress(
          state: ModelDownloadState.completed,
          progress: 1.0,
          modelId: defaultModel.id,
        ),
      );
    }

    // Listen for background download updates
    FileDownloader().updates.listen(_handleTaskUpdate);

    _isInitialized = true;
  }

  /// Returns the canonical directory where models are stored.
  ///
  /// Downloads are written to application support by `DownloadTask`
  /// (`BaseDirectory.applicationSupport`).
  Future<Directory> getModelsDirectory() async {
    final baseDir = await getApplicationSupportDirectory();
    final modelsDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}models',
    );
    // ignore: avoid_slow_async_io
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  Future<List<Directory>> _getModelSearchDirectories() async {
    final dirs = <Directory>[];

    final appSupportDir = await getApplicationSupportDirectory();
    dirs.add(Directory('${appSupportDir.path}${Platform.pathSeparator}models'));

    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final androidExternal = Directory(
          '${externalDir.path}${Platform.pathSeparator}models',
        );
        if (androidExternal.path != dirs.first.path) {
          dirs.add(androidExternal);
        }
      }
    }

    return dirs;
  }

  Set<String> _buildCandidateFileNames(AIModel model) {
    final candidates = <String>{model.fileName, ...model.alternateFileNames};

    final parsedUri = Uri.tryParse(model.url);
    final uriName = parsedUri != null && parsedUri.pathSegments.isNotEmpty
        ? Uri.decodeComponent(parsedUri.pathSegments.last)
        : null;
    if (uriName != null && uriName.isNotEmpty) {
      candidates.add(uriName);
    }

    return candidates.where((f) => f.trim().isNotEmpty).toSet();
  }

  @visibleForTesting
  List<String> candidateFileNames([AIModel? model]) {
    model ??= defaultModel;
    return _buildCandidateFileNames(model).toList();
  }

  Future<String?> _findExistingModelPath(
    AIModel model, {
    bool requireSizeThreshold = true,
  }) async {
    final dirs = await _getModelSearchDirectories();
    final candidates = _buildCandidateFileNames(model);
    final normalizedCandidates = candidates.map((c) => c.toLowerCase()).toSet();

    Future<bool> isValidFile(File file) async {
      // ignore: avoid_slow_async_io
      if (!await file.exists()) return false;
      // ignore: avoid_slow_async_io
      final stat = await file.stat();
      if (!requireSizeThreshold) return true;
      return stat.size >= model.sizeBytes * 0.9;
    }

    for (final dir in dirs) {
      // Fast exact-name checks first
      for (final name in candidates) {
        final file = File('${dir.path}${Platform.pathSeparator}$name');
        if (await isValidFile(file)) {
          return file.path;
        }
      }

      // Case-insensitive fallback scan
      // ignore: avoid_slow_async_io
      if (!await dir.exists()) {
        continue;
      }

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final fileName = p.basename(entity.path).toLowerCase();
        if (!normalizedCandidates.contains(fileName)) continue;
        if (await isValidFile(entity)) {
          return entity.path;
        }
      }
    }

    return null;
  }

  /// Returns the full local path for a specific model
  Future<String> getModelPath([AIModel? model]) async {
    model ??= defaultModel;
    final existingPath = await _findExistingModelPath(model);
    if (existingPath != null) return existingPath;

    final modelsDir = await getModelsDirectory();
    return '${modelsDir.path}${Platform.pathSeparator}${model.fileName}';
  }

  /// Checks if a model exists locally
  Future<bool> isModelDownloaded([AIModel? model]) async {
    model ??= defaultModel;
    return await _findExistingModelPath(model) != null;
  }

  /// Get the size of a partially downloaded model (for resume info)
  Future<int> getPartialDownloadSize([AIModel? model]) async {
    model ??= defaultModel;
    final existingPath = await _findExistingModelPath(
      model,
      requireSizeThreshold: false,
    );
    if (existingPath == null) return 0;
    // ignore: avoid_slow_async_io
    final stat = await File(existingPath).stat();
    return stat.size;
  }

  /// Starts or resumes the model download
  Future<void> startDownload([AIModel? model]) async {
    model ??= defaultModel;
    await initialize();

    // Check if already downloaded
    if (await isModelDownloaded(model)) {
      _updateProgress(
        const ModelDownloadProgress(
          state: ModelDownloadState.completed,
          progress: 1.0,
        ),
      );
      return;
    }

    // Enable wakelock to prevent screen from sleeping during download
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Failed to enable wakelock: $e');
    }

    _updateProgress(
      const ModelDownloadProgress(state: ModelDownloadState.queued),
    );

    // Create download task with resume support
    _activeTask = createDownloadTask(model);

    // Enqueue the download (handles resume automatically)
    final result = await FileDownloader().enqueue(_activeTask!);
    if (!result) {
      _updateProgress(
        const ModelDownloadProgress(
          state: ModelDownloadState.failed,
          errorMessage: 'Failed to start download',
        ),
      );
      await _disableWakelock();
    }
  }

  @visibleForTesting
  DownloadTask createDownloadTask(AIModel model) {
    return DownloadTask(
      url: model.url,
      filename: model.fileName,
      directory: 'models',
      baseDirectory: BaseDirectory.applicationSupport,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
      metaData: model.id,
    );
  }

  /// Pauses the current download
  Future<void> pauseDownload() async {
    if (_activeTask != null) {
      await FileDownloader().pause(_activeTask!);
      _updateProgress(
        _currentProgress.copyWith(state: ModelDownloadState.paused),
      );
    }
  }

  /// Resumes a paused download
  Future<void> resumeDownload() async {
    if (_activeTask != null) {
      final resumed = await FileDownloader().resume(_activeTask!);
      if (resumed) {
        _updateProgress(
          _currentProgress.copyWith(state: ModelDownloadState.downloading),
        );
      }
    } else {
      // If no active task, start a new download
      await startDownload();
    }
  }

  /// Cancels the current download
  Future<void> cancelDownload() async {
    if (_activeTask != null) {
      await FileDownloader().cancelTaskWithId(_activeTask!.taskId);
      _activeTask = null;
      _updateProgress(
        const ModelDownloadProgress(state: ModelDownloadState.notDownloaded),
      );
      await _disableWakelock();
    }
  }

  /// Deletes a downloaded model
  Future<void> deleteModel([AIModel? model]) async {
    model ??= defaultModel;
    final directories = await _getModelSearchDirectories();
    final candidates = _buildCandidateFileNames(model);
    final normalizedCandidates = candidates.map((c) => c.toLowerCase()).toSet();

    for (final dir in directories) {
      for (final name in candidates) {
        final file = File('${dir.path}${Platform.pathSeparator}$name');
        // ignore: avoid_slow_async_io
        if (await file.exists()) {
          await file.delete();
        }
      }

      // ignore: avoid_slow_async_io
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final fileName = p.basename(entity.path).toLowerCase();
        if (normalizedCandidates.contains(fileName)) {
          await entity.delete();
        }
      }
    }
    _updateProgress(
      const ModelDownloadProgress(state: ModelDownloadState.notDownloaded),
    );
  }

  /// Handles updates from the background downloader
  void _handleTaskUpdate(TaskUpdate update) {
    if (update is TaskStatusUpdate) {
      _handleStatusUpdate(update);
    } else if (update is TaskProgressUpdate) {
      _handleProgressUpdate(update);
    }
  }

  void _handleStatusUpdate(TaskStatusUpdate update) {
    switch (update.status) {
      case TaskStatus.enqueued:
        _updateProgress(
          _currentProgress.copyWith(state: ModelDownloadState.queued),
        );
      case TaskStatus.running:
        _updateProgress(
          _currentProgress.copyWith(state: ModelDownloadState.downloading),
        );
      case TaskStatus.paused:
        _updateProgress(
          _currentProgress.copyWith(state: ModelDownloadState.paused),
        );
      case TaskStatus.complete:
        _updateProgress(
          const ModelDownloadProgress(
            state: ModelDownloadState.completed,
            progress: 1.0,
          ),
        );
        _activeTask = null;
        _disableWakelock();
      case TaskStatus.failed:
        _updateProgress(
          ModelDownloadProgress(
            state: ModelDownloadState.failed,
            errorMessage: update.exception?.description ?? 'Download failed',
          ),
        );
        _activeTask = null;
        _disableWakelock();
      case TaskStatus.canceled:
        _updateProgress(
          const ModelDownloadProgress(state: ModelDownloadState.notDownloaded),
        );
        _activeTask = null;
        _disableWakelock();
      case TaskStatus.notFound:
        _updateProgress(
          const ModelDownloadProgress(
            state: ModelDownloadState.failed,
            errorMessage: 'Model file not found on server',
          ),
        );
        _activeTask = null;
        _disableWakelock();
      case TaskStatus.waitingToRetry:
        // Keep downloading state, will retry automatically
        break;
    }
  }

  void _handleProgressUpdate(TaskProgressUpdate update) {
    final progress = update.progress;
    if (progress < 0) return; // Invalid progress

    // Calculate bytes from progress and expected size
    final model = availableModels.firstWhere(
      (m) => m.id == update.task.metaData,
      orElse: () => defaultModel,
    );

    final downloadedBytes = (progress * model.sizeBytes).round();
    final networkSpeed = update.networkSpeed; // bytes per second

    _updateProgress(
      ModelDownloadProgress(
        state: ModelDownloadState.downloading,
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: model.sizeBytes,
        networkSpeed: networkSpeed,
      ),
    );
  }

  void _updateProgress(ModelDownloadProgress progress) {
    _currentProgress = progress;
    _progressController.add(progress);
  }

  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Failed to disable wakelock: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _progressController.close();
    _disableWakelock();
  }
}
