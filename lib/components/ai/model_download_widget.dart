import 'package:flutter/material.dart';
import 'package:kivixa/services/ai/model_manager.dart';

/// A widget that displays the AI model download progress and controls
class ModelDownloadWidget extends StatefulWidget {
  final AIModel? model;
  final VoidCallback? onDownloadComplete;

  const ModelDownloadWidget({
    super.key,
    this.model,
    this.onDownloadComplete,
  });

  @override
  State<ModelDownloadWidget> createState() => _ModelDownloadWidgetState();
}

class _ModelDownloadWidgetState extends State<ModelDownloadWidget> {
  final _modelManager = ModelManager();
  late AIModel _model;

  @override
  void initState() {
    super.initState();
    _model = widget.model ?? ModelManager.defaultModel;
    _modelManager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<ModelDownloadProgress>(
      stream: _modelManager.progressStream,
      initialData: _modelManager.currentProgress,
      builder: (context, snapshot) {
        final progress = snapshot.data!;

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _model.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _model.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Status and size info
                _buildStatusSection(progress, colorScheme),

                const SizedBox(height: 16),

                // Progress bar (if downloading)
                if (progress.state == ModelDownloadState.downloading ||
                    progress.state == ModelDownloadState.paused) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress.progress,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        progress.state == ModelDownloadState.paused
                            ? colorScheme.secondary
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progress.progressText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (progress.speedText.isNotEmpty)
                        Text(
                          '${progress.speedText} • ${progress.etaText}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                _buildActionButtons(progress, colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(
      ModelDownloadProgress progress, ColorScheme colorScheme) {
    IconData icon;
    String statusText;
    Color statusColor;

    switch (progress.state) {
      case ModelDownloadState.notDownloaded:
        icon = Icons.download_outlined;
        statusText = 'Not downloaded';
        statusColor = colorScheme.onSurfaceVariant;
      case ModelDownloadState.queued:
        icon = Icons.hourglass_empty;
        statusText = 'Queued...';
        statusColor = colorScheme.tertiary;
      case ModelDownloadState.downloading:
        icon = Icons.downloading;
        statusText = 'Downloading...';
        statusColor = colorScheme.primary;
      case ModelDownloadState.paused:
        icon = Icons.pause_circle_outline;
        statusText = 'Paused';
        statusColor = colorScheme.secondary;
      case ModelDownloadState.completed:
        icon = Icons.check_circle_outline;
        statusText = 'Ready to use';
        statusColor = colorScheme.tertiary;
      case ModelDownloadState.failed:
        icon = Icons.error_outline;
        statusText = progress.errorMessage ?? 'Download failed';
        statusColor = colorScheme.error;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: statusColor),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _model.sizeText,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      ModelDownloadProgress progress, ColorScheme colorScheme) {
    switch (progress.state) {
      case ModelDownloadState.notDownloaded:
      case ModelDownloadState.failed:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _modelManager.startDownload(_model),
                icon: const Icon(Icons.download),
                label: Text(progress.state == ModelDownloadState.failed
                    ? 'Retry Download'
                    : 'Download Model'),
              ),
            ),
          ],
        );

      case ModelDownloadState.queued:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _modelManager.cancelDownload(),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
            ),
          ],
        );

      case ModelDownloadState.downloading:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _modelManager.pauseDownload(),
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _modelManager.cancelDownload(),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ),
          ],
        );

      case ModelDownloadState.paused:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _modelManager.resumeDownload(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Resume'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _modelManager.cancelDownload(),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ),
          ],
        );

      case ModelDownloadState.completed:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onDownloadComplete,
                icon: const Icon(Icons.check),
                label: const Text('Continue'),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => _showDeleteConfirmation(),
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Delete model',
            ),
          ],
        );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model?'),
        content: Text(
          'This will delete "${_model.name}" (${_model.sizeText}) from your device. '
          'You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _modelManager.deleteModel(_model);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// A full-screen page for model download (for initial setup)
class ModelDownloadPage extends StatelessWidget {
  final VoidCallback? onComplete;

  const ModelDownloadPage({
    super.key,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon or AI icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'AI Features Setup',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Kivixa uses an on-device AI model to power smart features. '
                    'Download once and use offline.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Benefits list
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitRow(
                          Icons.wifi_off,
                          'Works completely offline',
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildBenefitRow(
                          Icons.lock_outline,
                          'Your data stays on device',
                          colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _buildBenefitRow(
                          Icons.speed,
                          'Fast responses, no internet delay',
                          colorScheme,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Download widget
                  ModelDownloadWidget(
                    onDownloadComplete: onComplete,
                  ),

                  const SizedBox(height: 16),

                  // Skip option
                  TextButton(
                    onPressed: onComplete,
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
