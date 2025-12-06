// AI Chat Interface Component
//
// A reusable chat interface for interacting with the AI model.
// Supports conversation history, markdown rendering, and streaming responses.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/pages/home/ai_chat.dart';
import 'package:kivixa/services/ai/inference_service.dart';
import 'package:kivixa/services/ai/model_manager.dart';

/// A single message in the chat
class AIChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  AIChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';

  ChatMessage toChatMessage() => ChatMessage(role: role, content: content);

  AIChatMessage copyWith({
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isLoading,
  }) {
    return AIChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Controller for managing chat state
class AIChatController extends ChangeNotifier {
  final InferenceService _inferenceService;
  final _modelManager = ModelManager();
  final List<AIChatMessage> _messages = [];
  var _isGenerating = false;
  var _isInitializing = false;
  String? _systemPrompt;
  String? _loadedModelName;

  AIChatController({InferenceService? inferenceService, String? systemPrompt})
    : _inferenceService = inferenceService ?? InferenceService(),
      _systemPrompt = systemPrompt {
    _initializeModel();
  }

  List<AIChatMessage> get messages => List.unmodifiable(_messages);
  bool get isGenerating => _isGenerating;
  bool get isModelLoaded => _inferenceService.isModelLoaded;
  bool get isInitializing => _isInitializing;
  String? get loadedModelName => _loadedModelName;
  String? get systemPrompt => _systemPrompt;

  /// Initialize and auto-load model if downloaded
  Future<void> _initializeModel() async {
    _isInitializing = true;
    notifyListeners();

    try {
      await _modelManager.initialize();
      await _inferenceService.initialize();

      // Check if model is already loaded in native
      if (_inferenceService.isModelLoaded) {
        _loadedModelName = ModelManager.defaultModel.name;
        _isInitializing = false;
        notifyListeners();
        return;
      }

      // Check if model is downloaded and auto-load it
      final isDownloaded = await _modelManager.isModelDownloaded();
      if (isDownloaded) {
        final modelPath = await _modelManager.getModelPath();
        await _inferenceService.loadModel(modelPath);
        _loadedModelName = ModelManager.defaultModel.name;
      }
    } catch (e) {
      debugPrint('Failed to initialize model: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Retry loading the model
  Future<void> retryLoadModel() async {
    await _initializeModel();
  }

  set systemPrompt(String? value) {
    _systemPrompt = value;
    notifyListeners();
  }

  /// Add a user message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (_isGenerating) return;

    // Add user message
    _messages.add(AIChatMessage(role: 'user', content: content.trim()));
    notifyListeners();

    // Add loading assistant message
    _messages.add(
      AIChatMessage(role: 'assistant', content: '', isLoading: true),
    );
    _isGenerating = true;
    notifyListeners();

    try {
      // Build conversation history
      final chatMessages = <ChatMessage>[];

      // Add system prompt if available
      if (_systemPrompt != null && _systemPrompt!.isNotEmpty) {
        chatMessages.add(ChatMessage.system(_systemPrompt!));
      }

      // Add conversation history
      for (final msg in _messages) {
        if (!msg.isLoading) {
          chatMessages.add(msg.toChatMessage());
        }
      }

      // Get AI response
      final response = await _inferenceService.chat(chatMessages);

      // Update the loading message with the response
      final loadingIndex = _messages.lastIndexWhere((m) => m.isLoading);
      if (loadingIndex != -1) {
        _messages[loadingIndex] = AIChatMessage(
          role: 'assistant',
          content: response,
        );
      }
    } catch (e) {
      // Update the loading message with error
      final loadingIndex = _messages.lastIndexWhere((m) => m.isLoading);
      if (loadingIndex != -1) {
        _messages[loadingIndex] = AIChatMessage(
          role: 'assistant',
          content: 'Error: ${e.toString()}',
        );
      }
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
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
  Future<void> retryLastMessage() async {
    if (_messages.isEmpty) return;

    // Find last user message
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
      // Remove messages from the last user message onwards
      for (int i = 0; i < removeCount; i++) {
        _messages.removeLast();
      }
      notifyListeners();

      // Resend
      await sendMessage(lastUserMessage);
    }
  }
}

/// The main chat interface widget
class AIChatInterface extends StatefulWidget {
  final AIChatController controller;
  final String? placeholder;
  final Widget? emptyState;
  final bool showHeader;
  final String? title;
  final VoidCallback? onClear;
  final bool compact;

  const AIChatInterface({
    super.key,
    required this.controller,
    this.placeholder,
    this.emptyState,
    this.showHeader = true,
    this.title,
    this.onClear,
    this.compact = false,
  });

  @override
  State<AIChatInterface> createState() => _AIChatInterfaceState();
}

class _AIChatInterfaceState extends State<AIChatInterface> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(AIChatInterface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    await widget.controller.sendMessage(text);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = widget.compact;
    final padding = isCompact ? 8.0 : 16.0;

    return Column(
      children: [
        // Header
        if (widget.showHeader)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: isCompact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: colorScheme.primary,
                  size: isCompact ? 18 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title ?? 'AI Assistant',
                  style:
                      (isCompact
                              ? theme.textTheme.titleSmall
                              : theme.textTheme.titleMedium)
                          ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // Model status chip
                if (widget.controller.isInitializing)
                  Chip(
                    label: Text(isCompact ? 'Loading...' : 'Loading model...'),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontSize: isCompact ? 10 : null,
                    ),
                    padding: isCompact ? EdgeInsets.zero : null,
                    avatar: SizedBox(
                      width: isCompact ? 12 : 16,
                      height: isCompact ? 12 : 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  )
                else if (widget.controller.isModelLoaded)
                  ActionChip(
                    label: Text(
                      isCompact
                          ? (widget.controller.loadedModelName ?? 'Ready')
                          : '${widget.controller.loadedModelName ?? 'Model'} loaded',
                    ),
                    backgroundColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: isCompact ? 10 : null,
                    ),
                    padding: isCompact ? EdgeInsets.zero : null,
                    avatar: Icon(
                      Icons.check_circle,
                      size: isCompact ? 14 : 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ModelSelectionPage(),
                        ),
                      );
                    },
                  )
                else
                  ActionChip(
                    label: Text(isCompact ? 'No model' : 'Model not loaded'),
                    backgroundColor: colorScheme.errorContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: isCompact ? 10 : null,
                    ),
                    padding: isCompact ? EdgeInsets.zero : null,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ModelSelectionPage(),
                        ),
                      );
                    },
                  ),
                if (widget.controller.messages.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    iconSize: isCompact ? 18 : 24,
                    onPressed: () {
                      widget.controller.clearMessages();
                      widget.onClear?.call();
                    },
                    tooltip: 'Clear chat',
                  ),
              ],
            ),
          ),

        // Messages
        Expanded(
          child: widget.controller.messages.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(padding),
                  itemCount: widget.controller.messages.length,
                  itemBuilder: (context, index) {
                    return _ChatMessageBubble(
                      message: widget.controller.messages[index],
                      compact: isCompact,
                      onRetry:
                          index == widget.controller.messages.length - 1 &&
                              widget.controller.messages[index].isAssistant &&
                              !widget.controller.isGenerating
                          ? widget.controller.retryLastMessage
                          : null,
                      onCopy: () => _copyMessage(
                        widget.controller.messages[index].content,
                      ),
                    );
                  },
                ),
        ),

        // Input area
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: isCompact ? 3 : 5,
                  minLines: 1,
                  style: isCompact ? theme.textTheme.bodySmall : null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSubmit(),
                  decoration: InputDecoration(
                    hintText:
                        widget.placeholder ??
                        (isCompact ? 'Ask...' : 'Ask me anything...'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 16,
                      vertical: isCompact ? 8 : 12,
                    ),
                    isDense: isCompact,
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 4 : 8),
              SizedBox(
                width: isCompact ? 36 : 56,
                height: isCompact ? 36 : 56,
                child: FloatingActionButton(
                  onPressed: widget.controller.isGenerating
                      ? null
                      : _handleSubmit,
                  elevation: 0,
                  mini: isCompact,
                  child: widget.controller.isGenerating
                      ? SizedBox(
                          width: isCompact ? 16 : 24,
                          height: isCompact ? 16 : 24,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.send, size: isCompact ? 18 : 24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    if (widget.emptyState != null) {
      return Center(child: widget.emptyState);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Start a conversation',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ask questions about your notes, get summaries, or explore ideas.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _SuggestionChip(
                    label: 'Summarize my notes',
                    onTap: () =>
                        _textController.text = 'Summarize my recent notes',
                  ),
                  _SuggestionChip(
                    label: 'Find related topics',
                    onTap: () =>
                        _textController.text = 'What topics are related to ',
                  ),
                  _SuggestionChip(
                    label: 'Help me write',
                    onTap: () => _textController.text = 'Help me write about ',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Individual chat message bubble
class _ChatMessageBubble extends StatelessWidget {
  final AIChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onCopy;
  final bool compact;

  const _ChatMessageBubble({
    required this.message,
    this.onRetry,
    this.onCopy,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;
    final avatarRadius = compact ? 12.0 : 16.0;
    final iconSize = compact ? 14.0 : 18.0;
    final horizontalPadding = compact ? 10.0 : 16.0;
    final verticalPadding = compact ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: iconSize,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(compact ? 12 : 16),
                  topRight: Radius.circular(compact ? 12 : 16),
                  bottomLeft: Radius.circular(isUser ? (compact ? 12 : 16) : 4),
                  bottomRight: Radius.circular(
                    isUser ? 4 : (compact ? 12 : 16),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isLoading)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: compact ? 12 : 16,
                          height: compact ? 12 : 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                            fontSize: compact ? 12 : null,
                          ),
                        ),
                      ],
                    )
                  else
                    SelectableText(
                      message.content,
                      style: TextStyle(
                        color: isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontSize: compact ? 13 : null,
                      ),
                    ),
                  if (!message.isLoading && !isUser) ...[
                    SizedBox(height: compact ? 4 : 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onCopy != null)
                          IconButton(
                            icon: Icon(Icons.copy, size: compact ? 12 : 16),
                            onPressed: onCopy,
                            tooltip: 'Copy',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: compact ? 24 : 32,
                              minHeight: compact ? 24 : 32,
                            ),
                          ),
                        if (onRetry != null)
                          IconButton(
                            icon: Icon(Icons.refresh, size: compact ? 12 : 16),
                            onPressed: onRetry,
                            tooltip: 'Retry',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: compact ? 24 : 32,
                              minHeight: compact ? 24 : 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: compact ? 6 : 8),
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: iconSize,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Suggestion chip for empty state
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.surfaceContainerHighest,
    );
  }
}
