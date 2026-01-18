// MCP-Integrated Chat Controller
//
// Extends the base AIChatController to add MCP tool execution capabilities
// with automatic model switching based on task classification.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/mcp_service.dart';
import 'package:kivixa/services/ai/model_router.dart';

/// Tool execution status for messages
enum ToolStatus {
  /// Normal message, no tool involved
  none,

  /// AI is deciding whether to use a tool
  analyzing,

  /// Waiting for user confirmation
  pendingConfirmation,

  /// Tool is being executed
  executing,

  /// Tool execution completed successfully
  completed,

  /// Tool execution was cancelled by user
  cancelled,

  /// Tool execution failed
  failed,
}

/// Extended chat message with tool information
class MCPChatMessage extends AIChatMessage {
  final ToolStatus toolStatus;
  final PendingToolCall? toolCall;
  final MCPExecutionResult? toolResult;

  MCPChatMessage({
    required super.role,
    required super.content,
    super.timestamp,
    super.isLoading,
    this.toolStatus = ToolStatus.none,
    this.toolCall,
    this.toolResult,
  });

  @override
  MCPChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isLoading,
    ToolStatus? toolStatus,
    PendingToolCall? toolCall,
    MCPExecutionResult? toolResult,
  }) {
    return MCPChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      toolStatus: toolStatus ?? this.toolStatus,
      toolCall: toolCall ?? this.toolCall,
      toolResult: toolResult ?? this.toolResult,
    );
  }
}

/// MCP-aware chat controller with tool execution and model routing
class MCPChatController extends ChangeNotifier {
  final InferenceService _inferenceService;
  final MCPService _mcpService;
  final ModelRouterService _modelRouter;
  final List<MCPChatMessage> _messages = [];

  var _isGenerating = false;
  var _isInitializing = false;
  final _isLoadingModel = false;
  var _isMcpEnabled = true;
  String? _systemPrompt;
  String? _browseDirectory;

  /// Callback for when model needs to be switched
  VoidCallback? onModelSwitchRequired;

  MCPChatController({
    InferenceService? inferenceService,
    MCPService? mcpService,
    ModelRouterService? modelRouter,
    String? systemPrompt,
    String? browseDirectory,
  }) : _inferenceService = inferenceService ?? InferenceService(),
       _mcpService = mcpService ?? MCPService.instance,
       _modelRouter = modelRouter ?? ModelRouterService.instance,
       _systemPrompt = systemPrompt,
       _browseDirectory = browseDirectory {
    _initialize();
  }

  // Getters
  List<MCPChatMessage> get messages => List.unmodifiable(_messages);
  bool get isGenerating => _isGenerating;
  bool get isModelLoaded => _inferenceService.isModelLoaded;
  bool get isInitializing => _isInitializing;
  bool get isLoadingModel => _isLoadingModel;
  bool get isMcpEnabled => _isMcpEnabled;
  bool get isMcpInitialized => _mcpService.isInitialized;
  MCPTaskCategory? get currentTaskCategory => _lastClassifiedCategory;
  AIModelType? get currentModelType => _modelRouter.currentModel;
  String? get systemPrompt => _systemPrompt;

  MCPTaskCategory? _lastClassifiedCategory;

  set systemPrompt(String? value) {
    _systemPrompt = value;
    notifyListeners();
  }

  set isMcpEnabled(bool value) {
    _isMcpEnabled = value;
    notifyListeners();
  }

  /// Initialize the controller
  Future<void> _initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      await _inferenceService.initialize();

      // Initialize MCP if browse directory is set
      if (_browseDirectory != null && _browseDirectory!.isNotEmpty) {
        await _mcpService.initialize(_browseDirectory!);
      }
    } catch (e) {
      debugPrint('Failed to initialize MCP chat controller: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Set the browse directory for MCP file operations
  Future<void> setBrowseDirectory(String directory) async {
    _browseDirectory = directory;
    if (!_mcpService.isInitialized) {
      await _mcpService.initialize(directory);
    }
    notifyListeners();
  }

  /// Get available MCP tools
  List<MCPToolInfo> getAvailableTools() {
    if (!_mcpService.isInitialized) return [];
    return _mcpService.getAvailableTools();
  }

  /// Build system prompt with MCP tool information
  String _buildMcpSystemPrompt() {
    final buffer = StringBuffer();

    // Base system prompt
    if (_systemPrompt != null && _systemPrompt!.isNotEmpty) {
      buffer.writeln(_systemPrompt);
      buffer.writeln();
    }

    // Add MCP tools if enabled
    if (_isMcpEnabled && _mcpService.isInitialized) {
      buffer.writeln('## Available Tools');
      buffer.writeln();
      buffer.writeln(
        'You have access to the following tools. When you need to use a tool, respond with a JSON object:',
      );
      buffer.writeln('```json');
      buffer.writeln(
        '{"tool": "tool_name", "parameters": {"param1": "value1", ...}}',
      );
      buffer.writeln('```');
      buffer.writeln();

      final tools = _mcpService.getAvailableTools();
      for (final tool in tools) {
        buffer.writeln('### ${tool.name}');
        buffer.writeln(tool.description);
        if (tool.parameters.isNotEmpty) {
          buffer.writeln('Parameters:');
          for (final param in tool.parameters) {
            final required = param.required ? ' (required)' : ' (optional)';
            buffer.writeln('- ${param.name}: ${param.description}$required');
          }
        }
        buffer.writeln();
      }

      buffer.writeln('Important:');
      buffer.writeln('- Only use tools when necessary for the user\'s request');
      buffer.writeln('- File operations are sandboxed to the browse/ folder');
      buffer.writeln('- All tool executions require user confirmation');
    }

    return buffer.toString();
  }

  /// Classify user message and potentially switch models
  Future<void> _analyzeAndPrepareModel(String message) async {
    if (!_isMcpEnabled) return;

    final category = _mcpService.classifyTask(message);
    _lastClassifiedCategory = category;

    // Check if we need to switch models
    if (_modelRouter.needsModelSwitch(message)) {
      final selection = _modelRouter.analyzeAndSelectModel(message);
      debugPrint(
        'MCP: Task classified as ${selection.taskCategory}, recommending ${selection.modelName}',
      );

      if (selection.isAvailable) {
        onModelSwitchRequired?.call();
      }
    }
  }

  /// Send a message and get AI response with MCP tool support
  Future<void> sendMessage(String content, {BuildContext? context}) async {
    if (content.trim().isEmpty) return;
    if (_isGenerating) return;

    // Analyze and prepare model
    await _analyzeAndPrepareModel(content);

    // Add user message
    _messages.add(MCPChatMessage(role: 'user', content: content.trim()));
    notifyListeners();

    // Add loading assistant message
    _messages.add(
      MCPChatMessage(
        role: 'assistant',
        content: '',
        isLoading: true,
        toolStatus: _isMcpEnabled ? ToolStatus.analyzing : ToolStatus.none,
      ),
    );
    _isGenerating = true;
    notifyListeners();

    try {
      // Build conversation history
      final chatMessages = <ChatMessage>[];

      // Add system prompt with MCP tools
      final systemPrompt = _buildMcpSystemPrompt();
      if (systemPrompt.isNotEmpty) {
        chatMessages.add(ChatMessage.system(systemPrompt));
      }

      // Add conversation history (excluding loading message)
      for (final msg in _messages) {
        if (!msg.isLoading) {
          chatMessages.add(msg.toChatMessage());
        }
      }

      // Get AI response
      final response = await _inferenceService.chat(chatMessages);

      // Check if response contains a tool call
      final toolCall = _tryParseToolCall(response);

      if (toolCall != null && context != null && _isMcpEnabled) {
        // Update message to show pending tool execution
        _updateLastMessage(
          MCPChatMessage(
            role: 'assistant',
            content: 'I\'d like to ${toolCall.displayDescription}',
            toolStatus: ToolStatus.pendingConfirmation,
            toolCall: toolCall,
          ),
        );

        // Execute tool with confirmation
        final result = await _mcpService.executeWithConfirmation(
          context,
          toolCall,
        );

        if (result.success) {
          _updateLastMessage(
            MCPChatMessage(
              role: 'assistant',
              content: _formatToolResult(toolCall, result),
              toolStatus: ToolStatus.completed,
              toolCall: toolCall,
              toolResult: result,
            ),
          );
        } else if (result.userCancelled) {
          _updateLastMessage(
            MCPChatMessage(
              role: 'assistant',
              content: 'Tool execution was cancelled.',
              toolStatus: ToolStatus.cancelled,
              toolCall: toolCall,
              toolResult: result,
            ),
          );
        } else {
          _updateLastMessage(
            MCPChatMessage(
              role: 'assistant',
              content: 'Tool execution failed: ${result.result}',
              toolStatus: ToolStatus.failed,
              toolCall: toolCall,
              toolResult: result,
            ),
          );
        }
      } else {
        // Normal response without tool
        _updateLastMessage(
          MCPChatMessage(
            role: 'assistant',
            content: response,
            toolStatus: ToolStatus.none,
          ),
        );
      }
    } catch (e) {
      _updateLastMessage(
        MCPChatMessage(
          role: 'assistant',
          content: 'Error: ${e.toString()}',
          toolStatus: ToolStatus.failed,
        ),
      );
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Try to parse a tool call from AI response
  PendingToolCall? _tryParseToolCall(String response) {
    if (!_isMcpEnabled || !_mcpService.isInitialized) return null;

    try {
      // Look for JSON in response
      final jsonPattern = RegExp(r'\{[^{}]*"tool"[^{}]*\}', multiLine: true);
      final match = jsonPattern.firstMatch(response);

      if (match != null) {
        final jsonStr = match.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

        if (parsed.containsKey('tool')) {
          final tool = parsed['tool'] as String;
          final params = (parsed['parameters'] as Map<String, dynamic>?) ?? {};

          return PendingToolCall(
            tool: tool,
            parameters: params,
            description: 'Execute $tool',
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to parse tool call: $e');
    }

    return null;
  }

  /// Format tool execution result for display
  String _formatToolResult(
    PendingToolCall toolCall,
    MCPExecutionResult result,
  ) {
    final buffer = StringBuffer();

    switch (toolCall.tool) {
      case 'read_file':
        buffer.writeln('📄 **File Contents:**');
        buffer.writeln('```');
        buffer.writeln(result.result);
        buffer.writeln('```');

      case 'write_file':
      case 'export_markdown':
        buffer.writeln('✅ File saved successfully.');
        buffer.writeln();
        buffer.writeln(result.result);

      case 'delete_file':
        buffer.writeln('🗑️ File deleted.');
        buffer.writeln(result.result);

      case 'create_folder':
        buffer.writeln('📁 Folder created.');
        buffer.writeln(result.result);

      case 'list_files':
        buffer.writeln('📂 **Directory Contents:**');
        buffer.writeln('```');
        buffer.writeln(result.result);
        buffer.writeln('```');

      case 'calendar_lua':
        buffer.writeln('📅 Calendar operation completed.');
        buffer.writeln(result.result);

      case 'timer_lua':
        buffer.writeln('⏱️ Timer operation completed.');
        buffer.writeln(result.result);

      default:
        buffer.writeln('✅ Operation completed.');
        buffer.writeln(result.result);
    }

    return buffer.toString();
  }

  /// Update the last message
  void _updateLastMessage(MCPChatMessage message) {
    if (_messages.isNotEmpty) {
      _messages[_messages.length - 1] = message;
      notifyListeners();
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _lastClassifiedCategory = null;
    notifyListeners();
  }

  /// Remove the last message
  void removeLastMessage() {
    if (_messages.isNotEmpty) {
      _messages.removeLast();
      notifyListeners();
    }
  }

  /// Retry the last user message
  Future<void> retryLastMessage({BuildContext? context}) async {
    if (_messages.isEmpty) return;

    String? lastUserMessage;
    int removeCount = 0;

    for (int i = _messages.length - 1; i >= 0; i--) {
      removeCount++;
      if (_messages[i].isUser) {
        lastUserMessage = _messages[i].content;
        break;
      }
    }

    if (lastUserMessage != null) {
      for (int i = 0; i < removeCount; i++) {
        _messages.removeLast();
      }
      notifyListeners();

      await sendMessage(lastUserMessage, context: context);
    }
  }

  /// Execute a tool directly (without AI involvement)
  Future<MCPExecutionResult> executeTool(
    BuildContext context,
    String tool,
    Map<String, dynamic> parameters,
  ) async {
    final toolCall = PendingToolCall(
      tool: tool,
      parameters: parameters,
      description: 'Manual tool execution',
    );

    return await _mcpService.executeWithConfirmation(context, toolCall);
  }

  @override
  void dispose() {
    _messages.clear();
    super.dispose();
  }
}

/// Widget for displaying tool status in chat messages
class ToolStatusIndicator extends StatelessWidget {
  final ToolStatus status;
  final PendingToolCall? toolCall;

  const ToolStatusIndicator({super.key, required this.status, this.toolCall});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;
    String label;

    switch (status) {
      case ToolStatus.none:
        return const SizedBox.shrink();

      case ToolStatus.analyzing:
        icon = Icons.psychology;
        color = colorScheme.tertiary;
        label = 'Analyzing request...';

      case ToolStatus.pendingConfirmation:
        icon = Icons.pending_actions;
        color = colorScheme.secondary;
        label = 'Waiting for confirmation';

      case ToolStatus.executing:
        icon = Icons.sync;
        color = colorScheme.primary;
        label = 'Executing tool...';

      case ToolStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Tool executed';

      case ToolStatus.cancelled:
        icon = Icons.cancel;
        color = colorScheme.outline;
        label = 'Cancelled';

      case ToolStatus.failed:
        icon = Icons.error;
        color = colorScheme.error;
        label = 'Failed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            toolCall != null ? '${toolCall!.tool}: $label' : label,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Widget showing current model and MCP status
class MCPStatusBar extends StatelessWidget {
  final MCPChatController controller;
  final bool compact;

  const MCPStatusBar({
    super.key,
    required this.controller,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // MCP status
          Icon(
            controller.isMcpEnabled ? Icons.extension : Icons.extension_off,
            size: compact ? 14 : 16,
            color: controller.isMcpEnabled
                ? colorScheme.primary
                : colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            'MCP',
            style:
                (compact
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(
                      color: controller.isMcpEnabled
                          ? colorScheme.primary
                          : colorScheme.outline,
                    ),
          ),
          if (controller.currentModelType != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: compact ? 12 : 16,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(width: 8),
            Text(
              controller.currentModelType!.displayName,
              style:
                  (compact
                          ? theme.textTheme.labelSmall
                          : theme.textTheme.labelMedium)
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
