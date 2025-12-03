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

  const AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.fileName,
    required this.sizeBytes,
    this.sha256Hash,
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
}

/// Manages AI model downloads with resume support and background downloading
class ModelManager {
  static final _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  /// Available models for download
  static const availableModels = <AIModel>[
    AIModel(
      id: 'phi4-mini-q4km',
      name: 'Phi-4 Mini',
      description:
          'Microsoft Phi-4 Mini Instruct - Compact and efficient model for on-device AI',
      url:
          'https://huggingface.co/bartowski/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf',
      fileName: 'phi4_mini_q4km.gguf',
      sizeBytes: 2576980378, // ~2.4 GB
    ),
  ];

  /// Default model to use
  static AIModel get defaultModel => availableModels.first;

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
  /// On Android: /storage/emulated/0/Android/data/com.kivixa.app/files/kivixa/models
  /// On Windows/macOS/Linux: Application support directory/kivixa/models
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
    final modelsDir = Directory('${baseDir.path}/kivixa/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir;
  }

  /// Returns the full local path for a specific model
  Future<String> getModelPath([AIModel? model]) async {
    model ??= defaultModel;
    final modelsDir = await getModelsDirectory();
    return '${modelsDir.path}/${model.fileName}';
  }

  /// Checks if a model exists locally
  Future<bool> isModelDownloaded([AIModel? model]) async {
    model ??= defaultModel;
    final path = await getModelPath(model);
    final file = File(path);
    if (!await file.exists()) return false;

    // Verify file size (at least 90% of expected to account for compression differences)
    final stat = await file.stat();
    return stat.size >= model.sizeBytes * 0.9;
  }

  /// Get the size of a partially downloaded model (for resume info)
  Future<int> getPartialDownloadSize([AIModel? model]) async {
    model ??= defaultModel;
    final path = await getModelPath(model);
    final file = File(path);
    if (!await file.exists()) return 0;
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
      baseDirectory: BaseDirectory.applicationDocuments,
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
