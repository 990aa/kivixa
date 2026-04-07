// AI Chat Page
//
// A dedicated page for interacting with the AI assistant.
// Provides a full chat interface with context from the user's notes.
// Supports MCP (Model Context Protocol) for tool execution.

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';
import 'package:kivixa/components/ai/model_catalog_card.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/mcp_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';
import 'package:kivixa/services/ai/model_router.dart';

@visibleForTesting
const mainAiQuickActionPrompts = <String, String>{
  'Smart Search':
      'Use smart search across my notes and find the most relevant results for this topic: ',
  'Summarize':
      'Summarize my recent notes into key points, decisions, and action items.',
  'Discover':
      'Discover non-obvious connections between my recent notes and suggest follow-up ideas.',
};

@visibleForTesting
const mcpToolPromptTemplates = <String, String>{
  'read_file':
      'Use read_file to open sandbox/demo.md and summarize the file content in 3 bullets.',
  'write_file':
      'Use write_file to create sandbox/demo.md with this content:\n# Sandbox Demo\n- Item 1\n- Item 2',
  'delete_file': 'Use delete_file to remove sandbox/demo.md.',
  'create_folder': 'Use create_folder to create sandbox/tmp_folder.',
  'list_files':
      'Use list_files to list files under sandbox/ recursively and report the results.',
  'calendar_lua':
      'Use calendar_lua to create a demo event called "Sandbox Planning" for tomorrow at 10:00 AM.',
  'timer_lua': 'Use timer_lua to start a 5-minute timer named "Sandbox Focus".',
  'export_markdown':
      'Use export_markdown to save this markdown into sandbox/export_demo.md:\n# Export Demo\n- Alpha\n- Beta',
};

@visibleForTesting
String promptForMcpTool(String toolName) {
  return mcpToolPromptTemplates[toolName] ??
      'Use $toolName for this task and describe what you will do before executing it.';
}

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
  VoidCallback? _mcpControllerListener;
  late ModelManager _modelManager;
  final _mainPromptPrefill = ValueNotifier<String?>(null);
  final _mcpPromptPrefill = ValueNotifier<String?>(null);
  var _isModelReady = false;
  var _isMcpMode = false;
  String? _modelError;

  void _emitPrefillPrompt(ValueNotifier<String?> target, String prompt) {
    target.value = null;
    target.value = prompt;
  }

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

      _mcpChatController?.removeListener(_handleMcpControllerChanged);

      _mcpChatController = MCPChatController(
        systemPrompt: _buildMcpSystemPrompt(),
        browseDirectory: browseDir,
      );
      _mcpControllerListener = _handleMcpControllerChanged;
      _mcpChatController!.addListener(_mcpControllerListener!);

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
    if (_mcpControllerListener != null) {
      _mcpChatController?.removeListener(_mcpControllerListener!);
    }
    _mcpChatController?.dispose();
    _mainPromptPrefill.dispose();
    _mcpPromptPrefill.dispose();
    super.dispose();
  }

  void _handleMcpControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _exportMcpConversation() async {
    final controller = _mcpChatController;
    if (controller == null) return;

    final jsonPayload = controller.exportConversationAsJson();

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export MCP Chat as JSON',
        fileName:
            'kivixa_mcp_chat_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || !mounted) {
        return;
      }

      await File(result).writeAsString(jsonPayload);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('MCP chat exported as JSON'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export chat: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
                    promptPrefillListenable: _mainPromptPrefill,
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
        // Unified MCP top bar (status + actions)
        _buildMcpStatusBar(),

        // Chat Interface
        Expanded(
          child: MCPChatInterface(
            controller: _mcpChatController!,
            context: context,
            showHeader: false,
            promptPrefillListenable: _mcpPromptPrefill,
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
    final mcpController = _mcpChatController;
    final hasMessages =
        mcpController != null && mcpController.messages.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            'Kivixa MCP Assistant',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 12),

          // MCP mode indicator
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
                  size: 14,
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

          if (hasMessages)
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Export chat as JSON',
              onPressed: _exportMcpConversation,
            ),
          if (hasMessages)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
              onPressed: () {
                mcpController.clearMessages();
              },
            ),

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

              return Material(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _emitPrefillPrompt(
                    _mcpPromptPrefill,
                    promptForMcpTool(tool.name),
                  ),
                  child: Container(
                    width: 160,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
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
                  ),
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
          _FeatureCard(
            icon: Icons.search,
            title: 'Smart Search',
            description: 'Find related notes and ideas',
            onTap: () => _emitPrefillPrompt(
              _mainPromptPrefill,
              mainAiQuickActionPrompts['Smart Search']!,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.summarize,
            title: 'Summarize',
            description: 'Get quick summaries of your notes',
            onTap: () => _emitPrefillPrompt(
              _mainPromptPrefill,
              mainAiQuickActionPrompts['Summarize']!,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.lightbulb_outline,
            title: 'Discover',
            description: 'Explore connections between topics',
            onTap: () => _emitPrefillPrompt(
              _mainPromptPrefill,
              mainAiQuickActionPrompts['Discover']!,
            ),
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
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
        ),
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
  StreamSubscription<ModelDownloadProgress>? _downloadProgressSubscription;
  String? _activeDownloadModelId;
  var _didNotifyForActiveDownload = false;
  var _isLoading = false;
  String? _error;
  ModelCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _downloadProgressSubscription = _modelManager.progressStream.listen(
      _onDownloadProgress,
    );
    _loadAvailableModels();
  }

  @override
  void dispose() {
    _downloadProgressSubscription?.cancel();
    super.dispose();
  }

  void _onDownloadProgress(ModelDownloadProgress progress) {
    if (!mounted) {
      return;
    }

    if (_activeDownloadModelId == null) {
      return;
    }

    if (progress.modelId != null &&
        progress.modelId != _activeDownloadModelId) {
      return;
    }

    if (_didNotifyForActiveDownload) {
      return;
    }

    final activeModel = ModelManager.getModelById(_activeDownloadModelId!);
    final modelName = activeModel?.name ?? 'Model';

    if (progress.state == ModelDownloadState.completed) {
      _didNotifyForActiveDownload = true;
      _activeDownloadModelId = null;
      unawaited(_loadAvailableModels());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$modelName download completed'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (progress.state == ModelDownloadState.failed) {
      _didNotifyForActiveDownload = true;
      _activeDownloadModelId = null;

      final errorText = progress.errorMessage ?? 'Download failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$modelName download failed: $errorText'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
    _activeDownloadModelId = model.id;
    _didNotifyForActiveDownload = false;

    await _modelManager.startDownload(model);
    if (mounted) {
      await _showDownloadProgressDialog(model);
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
      barrierDismissible: true,
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

                            return ModelCatalogCard(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hide'),
            ),
            TextButton(
              onPressed: () {
                widget.modelManager.cancelDownload();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel Download'),
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
