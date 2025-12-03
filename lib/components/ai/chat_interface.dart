// AI Chat Interface Component
//
// A reusable chat interface for interacting with the AI model.
// Supports conversation history, markdown rendering, and streaming responses.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kivixa/services/ai/inference_service.dart';

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
  final List<AIChatMessage> _messages = [];
  bool _isGenerating = false;
  String? _systemPrompt;

  AIChatController({InferenceService? inferenceService, String? systemPrompt})
    : _inferenceService = inferenceService ?? InferenceService(),
      _systemPrompt = systemPrompt;

  List<AIChatMessage> get messages => List.unmodifiable(_messages);
  bool get isGenerating => _isGenerating;
  bool get isModelLoaded => _inferenceService.isModelLoaded;
  String? get systemPrompt => _systemPrompt;

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

  const AIChatInterface({
    super.key,
    required this.controller,
    this.placeholder,
    this.emptyState,
    this.showHeader = true,
    this.title,
    this.onClear,
  });

  @override
  State<AIChatInterface> createState() => _AIChatInterfaceState();
}

class _AIChatInterfaceState extends State<AIChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

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

    return Column(
      children: [
        // Header
        if (widget.showHeader)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  widget.title ?? 'AI Assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!widget.controller.isModelLoaded)
                  Chip(
                    label: const Text('Model not loaded'),
                    backgroundColor: colorScheme.errorContainer,
                    labelStyle: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                if (widget.controller.messages.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.controller.messages.length,
                  itemBuilder: (context, index) {
                    return _ChatMessageBubble(
                      message: widget.controller.messages[index],
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
          padding: const EdgeInsets.all(16),
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
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSubmit(),
                  decoration: InputDecoration(
                    hintText: widget.placeholder ?? 'Ask me anything...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: widget.controller.isGenerating
                    ? null
                    : _handleSubmit,
                elevation: 0,
                child: widget.controller.isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

  const _ChatMessageBubble({required this.message, this.onRetry, this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
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
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
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
                      ),
                    ),
                  if (!message.isLoading && !isUser) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onCopy != null)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: onCopy,
                            tooltip: 'Copy',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        if (onRetry != null)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 16),
                            onPressed: onRetry,
                            tooltip: 'Retry',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
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
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
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
