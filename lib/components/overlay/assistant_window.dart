import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/components/ai/chat_interface.dart';
import 'package:kivixa/components/ai/mcp_chat_controller.dart';
import 'package:kivixa/components/ai/mcp_chat_interface.dart';
import 'package:kivixa/components/overlay/floating_window.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/services/overlay/overlay_controller.dart';

/// A floating AI assistant window that provides quick access to AI chat.
///
/// This window floats above the main app content and can be moved/resized.
/// It uses the same chat interface as the full AI chat page.
class AssistantWindow extends StatefulWidget {
  const AssistantWindow({super.key, this.chatController});

  final AIChatController? chatController;

  @override
  State<AssistantWindow> createState() => _AssistantWindowState();
}

class _AssistantWindowState extends State<AssistantWindow> {
  late final AIChatController _chatController;
  late final bool _ownsChatController;
  MCPChatController? _mcpChatController;
  var _isMcpMode = false;

  @override
  void initState() {
    super.initState();
    _ownsChatController = widget.chatController == null;
    _chatController = widget.chatController ?? AIChatController();
    OverlayController.instance.addListener(_onOverlayChanged);
    _initializeMcpController();
  }

  Future<void> _initializeMcpController() async {
    try {
      String? browseDirectory;
      try {
        browseDirectory = FileManager.documentsDirectory;
      } catch (_) {
        browseDirectory = null;
      }

      _mcpChatController = MCPChatController(
        systemPrompt: 'You are Kivixa AI, a helpful assistant.',
        browseDirectory: browseDirectory,
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
    if (_ownsChatController) {
      _chatController.dispose();
    }
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
    return Column(
      children: [
        _buildActionBar(context),
        Expanded(
          child: _isMcpMode && _mcpChatController != null
              ? MCPChatInterface(
                  controller: _mcpChatController!,
                  context: context,
                  showHeader: false,
                )
              : AIChatInterface(
                  controller: _chatController,
                  compact: true,
                  showHeader: false,
                ),
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context) {
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
          IconButton(
            icon: Icon(_isMcpMode ? Icons.auto_awesome : Icons.build_outlined),
            iconSize: 18,
            tooltip: _isMcpMode ? 'Switch to AI Chat' : 'Enable MCP Tools',
            onPressed: _toggleMcpMode,
            color: _isMcpMode ? colorScheme.primary : null,
          ),
          if (!_isMcpMode) ...[
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: _buildFloatingModelControl(theme, colorScheme),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            iconSize: 18,
            tooltip: 'Export chat as JSON',
            onPressed: _handleExportChat,
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

  Widget _buildFloatingModelControl(ThemeData theme, ColorScheme colorScheme) {
    if (_chatController.isInitializing || _chatController.isLoadingModel) {
      return Chip(
        label: Text(
          _chatController.isLoadingModel ? 'Switching...' : 'Loading...',
        ),
        backgroundColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        visualDensity: VisualDensity.compact,
      );
    }

    if (_chatController.isModelLoaded && _chatController.loadedModelId != null) {
      return ModelSwitcherChip(controller: _chatController, isCompact: true);
    }

    return Chip(
      label: Text(
        'No model',
        style: theme.textTheme.labelSmall,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _handleExportChat() async {
    final useMcp = _isMcpMode && _mcpChatController != null;
    final jsonPayload = useMcp
        ? _mcpChatController!.exportConversationAsJson()
        : _chatController.exportConversationAsJson();

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: useMcp ? 'Export MCP Chat as JSON' : 'Export Chat as JSON',
        fileName:
            '${useMcp ? 'kivixa_mcp_chat' : 'kivixa_ai_chat'}_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || !mounted) {
        return;
      }

      await File(result).writeAsString(jsonPayload);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            useMcp ? 'MCP chat exported as JSON' : 'Chat exported as JSON',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export chat: $e')),
      );
    }
  }
}
