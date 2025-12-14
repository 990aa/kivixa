// AI Chat Page
//
// A dedicated page for interacting with the AI assistant.
// Provides a full chat interface with context from the user's notes.

import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';

/// AI Chat Page
///
/// Provides a chat interface for users to interact with the AI.
/// Supports:
/// - Conversation history
/// - Note context injection
/// - Model status monitoring
/// - System prompt customization
class AIChatPage extends StatefulWidget {
  /// Optional initial context to provide to the AI
  final String? initialContext;

  /// Optional initial message to send
  final String? initialMessage;

  const AIChatPage({super.key, this.initialContext, this.initialMessage});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  late AIChatController _chatController;
  late ModelManager _modelManager;
  var _isModelReady = false;
  String? _modelError;

  @override
  void initState() {
    super.initState();
    _modelManager = ModelManager();
    _chatController = AIChatController(systemPrompt: _buildSystemPrompt());

    _checkModelStatus();

    // Send initial message if provided
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatController.sendMessage(widget.initialMessage!);
      });
    }
  }

  String _buildSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are Kivixa AI, a helpful assistant integrated into a note-taking and '
      'knowledge management application. You help users organize, understand, and '
      'explore their notes and ideas.',
    );
    buffer.writeln();
    buffer.writeln('Your capabilities include:');
    buffer.writeln('- Answering questions about the user\'s notes');
    buffer.writeln('- Summarizing content');
    buffer.writeln('- Finding connections between topics');
    buffer.writeln('- Helping with writing and brainstorming');
    buffer.writeln('- Explaining concepts');
    buffer.writeln();
    buffer.writeln(
      'Be concise, helpful, and friendly. If you don\'t know something, say so.',
    );

    if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Here is some context from the user\'s current note:');
      buffer.writeln('---');
      buffer.writeln(widget.initialContext);
      buffer.writeln('---');
    }

    return buffer.toString();
  }

  Future<void> _checkModelStatus() async {
    try {
      await _modelManager.initialize();
      final inferenceService = InferenceService();
      await inferenceService.initialize();

      // Check if model is downloaded and loaded
      final isDownloaded = await _modelManager.isModelDownloaded();

      setState(() {
        _isModelReady = inferenceService.isModelLoaded || isDownloaded;
        _modelError = null;
      });
    } catch (e) {
      setState(() {
        _isModelReady = false;
        _modelError = e.toString();
      });
    }
  }

  Future<void> _loadModel() async {
    try {
      setState(() {
        _modelError = null;
      });

      // Navigate to model manager to load a model
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ModelSelectionPage()),
        );
        _checkModelStatus();
      }
    } catch (e) {
      setState(() {
        _modelError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isModelReady
          ? AIChatInterface(
              controller: _chatController,
              title: 'Kivixa AI',
              placeholder: 'Ask me about your notes...',
              emptyState: _buildWelcomeWidget(),
            )
          : _buildModelNotLoadedWidget(),
    );
  }

  Widget _buildWelcomeWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 48,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Kivixa AI',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your intelligent note-taking companion',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          const _FeatureCard(
            icon: Icons.search,
            title: 'Smart Search',
            description: 'Find related notes and ideas',
          ),
          const SizedBox(height: 12),
          const _FeatureCard(
            icon: Icons.summarize,
            title: 'Summarize',
            description: 'Get quick summaries of your notes',
          ),
          const SizedBox(height: 12),
          const _FeatureCard(
            icon: Icons.lightbulb_outline,
            title: 'Discover',
            description: 'Explore connections between topics',
          ),
        ],
      ),
    );
  }

  Widget _buildModelNotLoadedWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if this is a DLL loading error
    final isDllError =
        _modelError != null &&
        (_modelError!.contains('kivixa_native') ||
            _modelError!.contains('error code 126') ||
            _modelError!.contains('dynamic library') ||
            _modelError!.contains('DllNotFoundException'));

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDllError ? Icons.error_outline : Icons.model_training,
              size: 80,
              color: isDllError
                  ? colorScheme.error.withValues(alpha: 0.7)
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              isDllError ? 'AI Engine Not Available' : 'AI Model Not Loaded',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDllError
                  ? 'The native AI library could not be loaded.'
                  : 'Load an AI model to start chatting with Kivixa AI.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (isDllError) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Possible Solutions:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSolutionItem(
                      theme,
                      '1',
                      'Install Visual C++ Redistributable',
                      'Download from Microsoft\'s website',
                    ),
                    const SizedBox(height: 8),
                    _buildSolutionItem(
                      theme,
                      '2',
                      'Reinstall the application',
                      'The native library may be missing',
                    ),
                    const SizedBox(height: 8),
                    _buildSolutionItem(
                      theme,
                      '3',
                      'Check antivirus software',
                      'It may be blocking the library',
                    ),
                  ],
                ),
              ),
            ],
            if (_modelError != null && !isDllError) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _modelError!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_modelError != null && isDllError) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'Technical Details',
                  style: theme.textTheme.bodySmall,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _modelError!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (!isDllError) ...[
              FilledButton.icon(
                onPressed: _loadModel,
                icon: const Icon(Icons.download),
                label: const Text('Load Model'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: _checkModelStatus,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionItem(
    ThemeData theme,
    String number,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          child: Text(number, style: const TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Feature card for the welcome widget
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Model selection page
class ModelSelectionPage extends StatefulWidget {
  const ModelSelectionPage({super.key});

  @override
  State<ModelSelectionPage> createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  final _modelManager = ModelManager();
  List<AIModel> _availableModels = [];
  var _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _modelManager.initialize();
      setState(() {
        _availableModels = ModelManager.availableModels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadModel(AIModel model) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if model is downloaded, if not start download
      final isDownloaded = await _modelManager.isModelDownloaded(model);
      if (!isDownloaded) {
        await _modelManager.startDownload(model);
        // Show download progress dialog
        if (mounted) {
          await _showDownloadProgressDialog(model);
        }
      }

      // Load the model into inference service
      final modelPath = await _modelManager.getModelPath(model);
      final inferenceService = InferenceService();
      await inferenceService.loadModel(modelPath);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showDownloadProgressDialog(AIModel model) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _DownloadProgressDialog(modelManager: _modelManager, model: model),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select AI Model')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAvailableModels,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _availableModels.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64),
                  const SizedBox(height: 16),
                  const Text('No models found'),
                  const SizedBox(height: 8),
                  Text(
                    'Place GGUF model files in the models folder',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAvailableModels,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableModels.length,
              itemBuilder: (context, index) {
                final model = _availableModels[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.model_training),
                    title: Text(model.name),
                    subtitle: Text(
                      '${model.description}\nSize: ${model.sizeText}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      onPressed: () => _loadModel(model),
                      child: const Text('Load'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Download progress dialog
class _DownloadProgressDialog extends StatefulWidget {
  final ModelManager modelManager;
  final AIModel model;

  const _DownloadProgressDialog({
    required this.modelManager,
    required this.model,
  });

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  late Stream<ModelDownloadProgress> _progressStream;

  @override
  void initState() {
    super.initState();
    _progressStream = widget.modelManager.progressStream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ModelDownloadProgress>(
      stream: _progressStream,
      initialData: widget.modelManager.currentProgress,
      builder: (context, snapshot) {
        final progress = snapshot.data!;

        return AlertDialog(
          title: Text('Downloading ${widget.model.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: progress.progress),
              const SizedBox(height: 16),
              Text(progress.progressText),
              if (progress.speedText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '${progress.speedText} • ${progress.etaText}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (progress.state == ModelDownloadState.failed &&
                  progress.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  progress.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            if (progress.state == ModelDownloadState.downloading)
              TextButton(
                onPressed: () => widget.modelManager.pauseDownload(),
                child: const Text('Pause'),
              ),
            if (progress.state == ModelDownloadState.paused)
              TextButton(
                onPressed: () => widget.modelManager.resumeDownload(),
                child: const Text('Resume'),
              ),
            if (progress.state == ModelDownloadState.failed)
              TextButton(
                onPressed: () =>
                    widget.modelManager.startDownload(widget.model),
                child: const Text('Retry'),
              ),
            TextButton(
              onPressed: () {
                widget.modelManager.cancelDownload();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            if (progress.state == ModelDownloadState.completed)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
          ],
        );
      },
    );
  }
}
