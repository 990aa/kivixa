// AI Chat Page
//
// A dedicated page for interacting with the AI assistant.
// Provides a full chat interface with context from the user's notes.
// Supports MCP (Model Context Protocol) for tool execution.

import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/mcp_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';
import 'package:kivixa/services/ai/model_router.dart';

/// AI Chat Page
///
/// Provides a chat interface for users to interact with the AI.
/// Supports:
/// - Conversation history
/// - Note context injection
/// - Model status monitoring
/// - System prompt customization
/// - MCP tool execution (file operations, Lua scripts, exports)
/// - Multi-model routing (Phi-4, Qwen, Function Gemma)
class AIChatPage extends StatefulWidget {
  /// Optional initial context to provide to the AI
  final String? initialContext;

  /// Optional initial message to send
  final String? initialMessage;

  /// Whether to enable MCP tools (default: true)
  final bool enableMcp;

  const AIChatPage({
    super.key,
    this.initialContext,
    this.initialMessage,
    this.enableMcp = true,
  });

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  late AIChatController _chatController;
  MCPChatController? _mcpChatController;
  late ModelManager _modelManager;
  var _isModelReady = false;
  var _isMcpMode = false;
  String? _modelError;

  @override
  void initState() {
    super.initState();
    _modelManager = ModelManager();
    _chatController = AIChatController(systemPrompt: _buildSystemPrompt());

    // Initialize MCP controller if enabled
    if (widget.enableMcp) {
      _initializeMcpController();
    }

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

  /// Initialize MCP controller for tool-enabled mode
  Future<void> _initializeMcpController() async {
    try {
      // Get the browse directory (notes folder)
      final browseDir = FileManager.documentsDirectory;

      _mcpChatController = MCPChatController(
        systemPrompt: _buildMcpSystemPrompt(),
        browseDirectory: browseDir,
      );

      // Set up model switch callback
      _mcpChatController!.onModelSwitchRequired = () {
        if (mounted) {
          final modelType = _mcpChatController!.currentModelType;
          if (modelType != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Switching to ${modelType.displayName} for this task',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      };

      setState(() {
        _isMcpMode = true;
      });
    } catch (e) {
      debugPrint('Failed to initialize MCP controller: $e');
    }
  }

  /// Build system prompt with MCP tool information
  String _buildMcpSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are Kivixa AI, a helpful assistant integrated into a note-taking and '
      'knowledge management application with advanced tool capabilities.',
    );
    buffer.writeln();
    buffer.writeln('Your capabilities include:');
    buffer.writeln('- Answering questions about the user\'s notes');
    buffer.writeln('- Reading, writing, and managing files');
    buffer.writeln('- Creating and organizing folders');
    buffer.writeln('- Exporting content as markdown');
    buffer.writeln('- Running calendar and timer scripts');
    buffer.writeln('- Finding connections between topics');
    buffer.writeln();

    if (widget.initialContext != null && widget.initialContext!.isNotEmpty) {
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
    _mcpChatController?.dispose();
    super.dispose();
  }

  /// Toggle MCP mode on/off
  void _toggleMcpMode() {
    setState(() {
      _isMcpMode = !_isMcpMode && _mcpChatController != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isModelReady
          ? _isMcpMode && _mcpChatController != null
                ? _buildMcpChatInterface()
                : AIChatInterface(
                    controller: _chatController,
                    title: 'Kivixa AI',
                    placeholder: 'Ask me about your notes...',
                    emptyState: _buildWelcomeWidget(),
                    headerActions: [
                      if (widget.enableMcp && _mcpChatController != null)
                        IconButton(
                          icon: const Icon(Icons.build_outlined),
                          tooltip: 'Enable MCP Tools',
                          onPressed: _toggleMcpMode,
                        ),
                    ],
                  )
          : _buildModelNotLoadedWidget(),
    );
  }

  /// Build the MCP-enabled chat interface with tool support
  Widget _buildMcpChatInterface() {
    return Column(
      children: [
        // MCP Status Bar
        _buildMcpStatusBar(),

        // Chat Interface
        Expanded(
          child: MCPChatInterface(
            controller: _mcpChatController!,
            context: context,
            emptyState: _buildMcpWelcomeWidget(),
          ),
        ),
      ],
    );
  }

  /// Build MCP status bar showing current mode and available tools
  Widget _buildMcpStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mcpService = MCPService.instance;
    final modelRouter = ModelRouterService.instance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // MCP Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.build,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  'MCP Mode',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Current model type
          if (modelRouter.currentModel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                modelRouter.currentModel!.shortName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Tool count
          Text(
            '${mcpService.getAvailableTools().length} tools',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const Spacer(),

          // Disable MCP button
          IconButton(
            icon: const Icon(Icons.build, size: 20),
            tooltip: 'Disable MCP Tools',
            onPressed: _toggleMcpMode,
            style: IconButton.styleFrom(foregroundColor: colorScheme.primary),
          ),
        ],
      ),
    );
  }

  /// Build welcome widget for MCP mode
  Widget _buildMcpWelcomeWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mcpService = MCPService.instance;
    final tools = mcpService.getAvailableTools();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.build_circle,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MCP Tools Enabled',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI can now execute actions on your behalf',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Available Tools
          Text(
            'Available Tools',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Tool cards in a grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tools.map((tool) {
              IconData icon;
              switch (tool.name) {
                case 'read_file':
                  icon = Icons.description;
                case 'write_file':
                  icon = Icons.edit_document;
                case 'delete_file':
                  icon = Icons.delete;
                case 'create_folder':
                  icon = Icons.create_new_folder;
                case 'list_files':
                  icon = Icons.folder_open;
                case 'calendar_lua':
                  icon = Icons.calendar_today;
                case 'timer_lua':
                  icon = Icons.timer;
                case 'export_markdown':
                  icon = Icons.file_download;
                default:
                  icon = Icons.extension;
              }

              return Container(
                width: 160,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 24, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      tool.name.replaceAll('_', ' '),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Safety note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: colorScheme.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safety First',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All tool executions require your confirmation. Files are sandboxed to your notes folder.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  Set<String> _downloadedModelIds = {};
  var _isLoading = false;
  String? _error;
  ModelCategory? _selectedCategory;

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

      // Get downloaded status for each model
      final downloadedIds = <String>{};
      for (final model in ModelManager.availableModels) {
        if (await _modelManager.isModelDownloaded(model)) {
          downloadedIds.add(model.id);
        }
      }

      setState(() {
        _availableModels = ModelManager.availableModels;
        _downloadedModelIds = downloadedIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AIModel> get _filteredModels {
    if (_selectedCategory == null) {
      return _availableModels;
    }
    return _availableModels
        .where((m) => m.supportsCategory(_selectedCategory!))
        .toList();
  }

  Future<void> _downloadModel(AIModel model) async {
    await _modelManager.startDownload(model);
    if (mounted) {
      await _showDownloadProgressDialog(model);
      // Refresh downloaded status
      await _loadAvailableModels();
    }
  }

  Future<void> _loadModel(AIModel model) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the model into inference service
      final modelPath = await _modelManager.getModelPath(model);
      final inferenceService = InferenceService();
      await inferenceService.loadModel(modelPath);
      _modelManager.setCurrentlyLoadedModel(model.id);

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

  Future<void> _deleteModel(AIModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${model.name}?'),
        content: Text(
          'This will delete the downloaded model file (${model.sizeText}). '
          'You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _modelManager.deleteModel(model);
      await _loadAvailableModels();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableModels,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading models',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loadAvailableModels,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      ...ModelCategory.values.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category.displayName),
                            selected: _selectedCategory == category,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = category),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Models list
                Expanded(
                  child: _filteredModels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No models in this category',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredModels.length,
                          itemBuilder: (context, index) {
                            final model = _filteredModels[index];
                            final isDownloaded = _downloadedModelIds.contains(
                              model.id,
                            );
                            final isCurrentlyLoaded =
                                _modelManager.currentlyLoadedModel?.id ==
                                model.id;

                            return _ModelCard(
                              model: model,
                              isDownloaded: isDownloaded,
                              isCurrentlyLoaded: isCurrentlyLoaded,
                              onDownload: () => _downloadModel(model),
                              onLoad: () => _loadModel(model),
                              onDelete: () => _deleteModel(model),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// Card widget for displaying a model
class _ModelCard extends StatelessWidget {
  final AIModel model;
  final bool isDownloaded;
  final bool isCurrentlyLoaded;
  final VoidCallback onDownload;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _ModelCard({
    required this.model,
    required this.isDownloaded,
    required this.isCurrentlyLoaded,
    required this.onDownload,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: isCurrentlyLoaded
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (model.isDefault) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Default'),
                              backgroundColor: colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: colorScheme.onSecondaryContainer,
                                fontSize: 10,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                          if (isCurrentlyLoaded) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Active'),
                              backgroundColor: colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 10,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        model.sizeText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(model.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            // Category chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: model.categories.map((category) {
                return Chip(
                  label: Text(category.displayName),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isDownloaded && !isCurrentlyLoaded)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                const SizedBox(width: 8),
                if (isDownloaded)
                  FilledButton.icon(
                    onPressed: isCurrentlyLoaded ? null : onLoad,
                    icon: Icon(
                      isCurrentlyLoaded ? Icons.check : Icons.play_arrow,
                    ),
                    label: Text(isCurrentlyLoaded ? 'Loaded' : 'Load'),
                  )
                else
                  FilledButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
              ],
            ),
          ],
        ),
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

/// MCP Chat View Widget
///
/// Displays the chat interface for MCP-enabled conversations with tool support.
