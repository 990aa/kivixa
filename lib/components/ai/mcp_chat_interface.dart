import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';

class MCPChatInterface extends StatefulWidget {
  final MCPChatController controller;
  final BuildContext context;
  final Widget? emptyState;

  const MCPChatInterface({
    super.key,
    required this.controller,
    required this.context,
    this.emptyState,
  });

  @override
  State<MCPChatInterface> createState() => _MCPChatInterfaceState();
}

class _MCPChatInterfaceState extends State<MCPChatInterface> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await widget.controller.sendMessage(text, context: widget.context);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messages = widget.controller.messages;

    return Column(
      children: [
        // Messages list
        Expanded(
          child: messages.isEmpty && widget.emptyState != null
              ? widget.emptyState!
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
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
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Ask Kivixa AI (MCP enabled)...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: widget.controller.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: widget.controller.isGenerating ? null : _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(MCPChatMessage message) {
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
                _getAvatarIcon(message),
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: _getMessageBorder(message, colorScheme),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tool status indicator
                  if (message.toolStatus != ToolStatus.none &&
                      message.toolStatus != ToolStatus.completed) ...[
                    _buildToolStatusIndicator(message),
                    const SizedBox(height: 8),
                  ],

                  // Message content
                  if (message.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    SelectableText(
                      message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),

                  // Tool result
                  if (message.toolStatus == ToolStatus.completed &&
                      message.toolResult != null) ...[
                    const SizedBox(height: 8),
                    _buildToolResultIndicator(message),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  IconData _getAvatarIcon(MCPChatMessage message) {
    switch (message.toolStatus) {
      case ToolStatus.analyzing:
        return Icons.psychology;
      case ToolStatus.pendingConfirmation:
        return Icons.help_outline;
      case ToolStatus.executing:
        return Icons.build;
      case ToolStatus.completed:
        return Icons.check_circle;
      case ToolStatus.cancelled:
        return Icons.cancel;
      case ToolStatus.failed:
        return Icons.error;
      default:
        return Icons.smart_toy;
    }
  }

  Border? _getMessageBorder(MCPChatMessage message, ColorScheme colorScheme) {
    switch (message.toolStatus) {
      case ToolStatus.pendingConfirmation:
        return Border.all(color: colorScheme.primary, width: 2);
      case ToolStatus.executing:
        return Border.all(color: colorScheme.tertiary, width: 2);
      case ToolStatus.failed:
        return Border.all(color: colorScheme.error, width: 2);
      default:
        return null;
    }
  }

  Widget _buildToolStatusIndicator(MCPChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String label;
    Color color;
    IconData icon;

    switch (message.toolStatus) {
      case ToolStatus.analyzing:
        label = 'Analyzing request...';
        color = colorScheme.primary;
        icon = Icons.psychology;
      case ToolStatus.pendingConfirmation:
        label = 'Awaiting confirmation';
        color = colorScheme.primary;
        icon = Icons.hourglass_empty;
      case ToolStatus.executing:
        label = 'Executing tool...';
        color = colorScheme.tertiary;
        icon = Icons.build;
      case ToolStatus.cancelled:
        label = 'Cancelled';
        color = colorScheme.outline;
        icon = Icons.cancel;
      case ToolStatus.failed:
        label = 'Failed';
        color = colorScheme.error;
        icon = Icons.error;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildToolResultIndicator(MCPChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            'Tool executed successfully',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
