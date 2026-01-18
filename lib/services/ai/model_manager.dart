import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
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
  code('Code Generation', 'Optimized for programming tasks');

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
  final String? errorMessage;
  final double? networkSpeed; // bytes per second

  const ModelDownloadProgress({
    required this.state,
    this.progress = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
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
    String? errorMessage,
    double? networkSpeed,
  }) {
    return ModelDownloadProgress(
      state: state ?? this.state,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      networkSpeed: networkSpeed ?? this.networkSpeed,
    );
  }
}

/// Information about a downloadable AI model
class AIModel {
  final String id;
  final String name;
  final String description;
  final String url;
  final String fileName;
  final int sizeBytes; // Expected size in bytes
  final String? sha256Hash; // Optional hash for verification
  final List<ModelCategory> categories; // Use cases for this model
  final bool isDefault; // Whether this is the default model

  const AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.fileName,
    required this.sizeBytes,
    this.sha256Hash,
    this.categories = const [ModelCategory.general],
    this.isDefault = false,
  });

  /// Human-readable size string
  String get sizeText {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

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
      description:
          'Microsoft Phi-4 Mini Instruct - Compact and efficient model for on-device AI. '
          'Great for general chat, writing assistance, and math/LaTeX help.',
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

    // Qwen2.5-3B - Writing and Code
    AIModel(
      id: 'qwen25-3b-q4km',
      name: 'Qwen2.5 3B',
      description:
          'Alibaba Qwen2.5 3B Instruct - Excellent for writing, notes, and code generation. '
          'Particularly strong at Lua and other scripting languages.',
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

    // Function-Gemma 2B - Agent/MCP tasks
    AIModel(
      id: 'functionary-gemma-2b',
      name: 'Functionary Gemma 2B',
      description:
          'Functionary model based on Google Gemma 2B - Optimized for function calling, '
          'tool use, and MCP agent tasks. Lightweight and fast.',
      url:
          'https://huggingface.co/meetkai/functionary-small-v3.2-GGUF/resolve/main/functionary-small-v3.2.Q4_K_M.gguf',
      fileName: 'functionary-small-v3.2.Q4_K_M.gguf',
      sizeBytes: 1626456064, // ~1.51 GB
      categories: [ModelCategory.agent, ModelCategory.code],
    ),

    // Function-Gemma 7B - Agent/MCP (larger)
    AIModel(
      id: 'functionary-gemma-7b',
      name: 'Functionary Gemma 7B',
      description:
          'Functionary model based on Google Gemma 7B - More capable function calling '
          'and reasoning. Better for complex MCP agent tasks.',
      url:
          'https://huggingface.co/meetkai/functionary-medium-v3.2-GGUF/resolve/main/functionary-medium-v3.2.Q4_K_M.gguf',
      fileName: 'functionary-medium-v3.2.Q4_K_M.gguf',
      sizeBytes: 5060478976, // ~4.71 GB
      categories: [
        ModelCategory.agent,
        ModelCategory.code,
        ModelCategory.general,
      ],
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

  /// Active download task (if any)
  DownloadTask? _activeTask;

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
        const ModelDownloadProgress(
          state: ModelDownloadState.completed,
          progress: 1.0,
        ),
      );
    }

    // Listen for background download updates
    FileDownloader().updates.listen(_handleTaskUpdate);

    _isInitialized = true;
  }

  /// Returns the directory where models are stored.
  /// On Android: /storage/emulated/0/Android/data/com.kivixa.app/files/models
  /// On Windows/macOS/Linux: Application support directory/models
  Future<Directory> getModelsDirectory() async {
    Directory baseDir;
    if (Platform.isAndroid) {
      // Use external storage on Android for easier access
      final externalDir = await getExternalStorageDirectory();
      baseDir = externalDir ?? await getApplicationSupportDirectory();
    } else {
      // Use application support directory on desktop
      baseDir = await getApplicationSupportDirectory();
    }
    // Note: Don't add 'kivixa' subdirectory - getApplicationSupportDirectory
    // already includes the app-specific folder
    final modelsDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}models',
    );
    // ignore: avoid_slow_async_io
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Returns the full local path for a specific model
  Future<String> getModelPath([AIModel? model]) async {
    model ??= defaultModel;
    final modelsDir = await getModelsDirectory();
    return '${modelsDir.path}${Platform.pathSeparator}${model.fileName}';
  }

  /// Checks if a model exists locally
  Future<bool> isModelDownloaded([AIModel? model]) async {
    model ??= defaultModel;
    final path = await getModelPath(model);
    final file = File(path);
    // ignore: avoid_slow_async_io
    if (!await file.exists()) return false;

    // Verify file size (at least 90% of expected to account for compression differences)
    // ignore: avoid_slow_async_io
    final stat = await file.stat();
    return stat.size >= model.sizeBytes * 0.9;
  }

  /// Get the size of a partially downloaded model (for resume info)
  Future<int> getPartialDownloadSize([AIModel? model]) async {
    model ??= defaultModel;
    final path = await getModelPath(model);
    final file = File(path);
    // ignore: avoid_slow_async_io
    if (!await file.exists()) return 0;
    // ignore: avoid_slow_async_io
    final stat = await file.stat();
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
    _activeTask = DownloadTask(
      url: model.url,
      filename: model.fileName,
      directory: 'models',
      baseDirectory: BaseDirectory.applicationSupport,
      updates: Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
      metaData: model.id,
    );

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
    final path = await getModelPath(model);
    final file = File(path);
    // ignore: avoid_slow_async_io
    if (await file.exists()) {
      await file.delete();
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
