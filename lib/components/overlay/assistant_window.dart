import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

/// A floating AI assistant window that provides quick access to AI chat.
///
/// This window floats above the main app content and can be moved/resized.
/// It uses the same chat interface as the full AI chat page.
class AssistantWindow extends StatefulWidget {
  const AssistantWindow({super.key});

  @override
  State<AssistantWindow> createState() => _AssistantWindowState();
}

class _AssistantWindowState extends State<AssistantWindow> {
  final _chatController = AIChatController();
  MCPChatController? _mcpChatController;
  var _isMcpMode = false;

  @override
  void initState() {
    super.initState();
    OverlayController.instance.addListener(_onOverlayChanged);
    _initializeMcpController();
  }

  Future<void> _initializeMcpController() async {
    try {
      _mcpChatController = MCPChatController(
        systemPrompt: 'You are Kivixa AI, a helpful assistant.',
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize MCP controller: $e');
    }
  }

  void _onOverlayChanged() {
    if (mounted) setState(() {});
  }

  void _toggleMcpMode() {
    setState(() {
      _isMcpMode = !_isMcpMode;
      if (_isMcpMode && _mcpChatController == null) {
        _initializeMcpController();
      }
    });
  }

  @override
  void dispose() {
    OverlayController.instance.removeListener(_onOverlayChanged);
    _chatController.dispose();
    _mcpChatController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OverlayController.instance;

    if (!controller.assistantOpen) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        // Clamp window to screen bounds
        final clampedRect = controller.clampToScreen(
          controller.assistantWindowRect,
          screenSize,
        );

        // FloatingWindow returns a Positioned widget, which must be inside a Stack
        return Stack(
          children: [
            FloatingWindow(
              rect: clampedRect,
              onRectChanged: (newRect) {
                controller.updateAssistantRect(
                  controller.clampToScreen(newRect, screenSize),
                );
              },
              onClose: controller.closeAssistant,
              title: _isMcpMode && _mcpChatController != null
                  ? 'AI Assistant (MCP)'
                  : 'AI Assistant',
              icon: Icons.smart_toy_rounded,
              minWidth: 350,
              minHeight: 400,
              child: _buildAssistantContent(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssistantContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isMcpMode && _mcpChatController != null) {
      return Column(
        children: [
          _buildQuickActionBar(context),
          Expanded(
            child: MCPChatInterface(
              controller: _mcpChatController!,
              context: context,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildQuickActionBar(context),
        // Chat interface
        Expanded(
          child: AIChatInterface(controller: _chatController, compact: true),
        ),
      ],
    );
  }

  Widget _buildQuickActionBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!_isMcpMode)
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuickActionChip(
                      icon: Icons.summarize_rounded,
                      label: 'Summarize',
                      onTap: () => _sendQuickAction(
                        'Please summarize the current context.',
                      ),
                    ),
                    const SizedBox(width: 4),
                    _QuickActionChip(
                      icon: Icons.code_rounded,
                      label: 'Code',
                      onTap: () => _sendQuickAction('Help me with code.'),
                    ),
                    const SizedBox(width: 4),
                    _QuickActionChip(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Ideas',
                      onTap: () => _sendQuickAction('Give me some ideas.'),
                    ),
                  ],
                ),
              ),
            )
          else
            const Expanded(child: Text('MCP Mode')),

          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              _isMcpMode ? Icons.build : Icons.build_outlined,
              color: _isMcpMode ? colorScheme.primary : null,
            ),
            iconSize: 18,
            tooltip: _isMcpMode ? 'Disable MCP Tools' : 'Enable MCP Tools',
            onPressed: _toggleMcpMode,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            iconSize: 18,
            tooltip: 'Clear chat',
            onPressed: _isMcpMode && _mcpChatController != null
                ? _mcpChatController!.clearMessages
                : _chatController.clearMessages,
          ),
        ],
      ),
    );
  }

  void _sendQuickAction(String prompt) {
    _chatController.sendMessage(prompt);
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
