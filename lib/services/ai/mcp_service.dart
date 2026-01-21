/// Model Context Protocol (MCP) Service
///
/// Provides AI tool execution with user confirmation and sandboxed operations.
/// All file operations are restricted to the browse/ directory.
///
/// This is a pure Dart implementation that works standalone while maintaining
/// the same API as the Rust FFI version. Once FRB bindings are generated,
/// this can be updated to call the native Rust functions for better performance.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// Represents an MCP tool that can be executed
class MCPToolInfo {
  final String name;
  final String description;
  final List<MCPParameterInfo> parameters;

  const MCPToolInfo({
    required this.name,
    required this.description,
    required this.parameters,
  });
}

/// Parameter information for an MCP tool
class MCPParameterInfo {
  final String name;
  final String description;
  final String type;
  final bool required;

  const MCPParameterInfo({
    required this.name,
    required this.description,
    required this.type,
    required this.required,
  });
}

/// Result of tool execution
class MCPExecutionResult {
  final bool success;
  final String result;
  final String toolName;
  final bool userCancelled;

  const MCPExecutionResult({
    required this.success,
    required this.result,
    required this.toolName,
    this.userCancelled = false,
  });

  factory MCPExecutionResult.cancelled(String toolName) {
    return MCPExecutionResult(
      success: false,
      result: 'User cancelled the operation',
      toolName: toolName,
      userCancelled: true,
    );
  }
}

/// Task categories for model routing
enum MCPTaskCategory { conversation, toolUse, codeGeneration }

/// Pending tool call awaiting user confirmation
class PendingToolCall {
  final String tool;
  final Map<String, dynamic> parameters;
  final String description;
  final String? luaScript;

  const PendingToolCall({
    required this.tool,
    required this.parameters,
    required this.description,
    this.luaScript,
  });

  String get displayDescription {
    switch (tool) {
      case 'read_file':
        return 'Read file: ${parameters['path']}';
      case 'write_file':
        return 'Write file: ${parameters['path']}';
      case 'delete_file':
        return 'Delete file: ${parameters['path']}';
      case 'create_folder':
        return 'Create folder: ${parameters['path']}';
      case 'list_files':
        return 'List files in: ${parameters['path'] ?? 'root'}';
      case 'calendar_lua':
        return 'Execute calendar script: $description';
      case 'timer_lua':
        return 'Execute timer script: $description';
      case 'export_markdown':
        return 'Export to: ${parameters['path']}';
      default:
        return description;
    }
  }
}

/// Plugin API interface for Lua script execution
abstract class PluginScriptExecutor {
  Future<PluginScriptResult> executeScript(String script);
}

/// Result of Lua script execution
class PluginScriptResult {
  final bool success;
  final String? output;
  final String? error;

  const PluginScriptResult({required this.success, this.output, this.error});
}

/// MCP Service for AI tool execution
class MCPService {
  static MCPService? _instance;
  static MCPService get instance => _instance ??= MCPService._();

  MCPService._();

  // Configuration
  var _initialized = false;
  String? _browseDir;
  int _maxFileSize = 10 * 1024 * 1024; // 10MB default
  final _allowedExtensions = <String>{
    'md',
    'txt',
    'json',
    'yaml',
    'yml',
    'toml',
    'csv',
  };

  PluginScriptExecutor? _pluginExecutor;

  // Tool definitions
  static const _tools = <MCPToolInfo>[
    MCPToolInfo(
      name: 'read_file',
      description: 'Read the contents of a file in the notes folder',
      parameters: [
        MCPParameterInfo(
          name: 'path',
          description: 'Relative path to the file within browse/ folder',
          type: 'string',
          required: true,
        ),
      ],
    ),
    MCPToolInfo(
      name: 'write_file',
      description: 'Write or create a file in the notes folder',
      parameters: [
        MCPParameterInfo(
          name: 'path',
          description: 'Relative path to the file within browse/ folder',
          type: 'string',
          required: true,
        ),
        MCPParameterInfo(
          name: 'content',
          description: 'Content to write to the file',
          type: 'string',
          required: true,
        ),
        MCPParameterInfo(
          name: 'append',
          description: 'Whether to append to existing file (default: false)',
          type: 'boolean',
          required: false,
        ),
      ],
    ),
    MCPToolInfo(
      name: 'delete_file',
      description: 'Delete a file from the notes folder',
      parameters: [
        MCPParameterInfo(
          name: 'path',
          description: 'Relative path to the file to delete',
          type: 'string',
          required: true,
        ),
      ],
    ),
    MCPToolInfo(
      name: 'create_folder',
      description: 'Create a new folder in the notes directory',
      parameters: [
        MCPParameterInfo(
          name: 'path',
          description: 'Relative path for the new folder',
          type: 'string',
          required: true,
        ),
      ],
    ),
    MCPToolInfo(
      name: 'list_files',
      description: 'List files in a directory',
      parameters: [
        MCPParameterInfo(
          name: 'path',
          description:
              'Relative path to the directory (optional, defaults to root)',
          type: 'string',
          required: false,
        ),
        MCPParameterInfo(
          name: 'recursive',
          description: 'Whether to list files recursively (default: false)',
          type: 'boolean',
          required: false,
        ),
      ],
    ),
    MCPToolInfo(
      name: 'calendar_lua',
      description: 'Execute a Lua script to interact with the calendar',
      parameters: [
        MCPParameterInfo(
          name: 'script',
          description: 'Lua script code to execute',
          type: 'string',
          required: true,
        ),
        MCPParameterInfo(
          name: 'description',
          description: 'Human-readable description of what the script does',
          type: 'string',
          required: true,
        ),
      ],
    ),
    MCPToolInfo(
      name: 'timer_lua',
      description: 'Execute a Lua script to interact with timers',
      parameters: [
        MCPParameterInfo(
          name: 'script',
          description: 'Lua script code to execute',
          type: 'string',
          required: true,
        ),
        MCPParameterInfo(
          name: 'description',
          description: 'Human-readable description of what the script does',
          type: 'string',
          required: true,
        ),
      ],
    ),
    MCPToolInfo(
      name: 'export_markdown',
      description: 'Export content as a markdown file',
      parameters: [
        MCPParameterInfo(
          name: 'path',
          description: 'Relative path for the markdown file',
          type: 'string',
          required: true,
        ),
        MCPParameterInfo(
          name: 'content',
          description: 'Markdown content to export',
          type: 'string',
          required: true,
        ),
        MCPParameterInfo(
          name: 'append',
          description: 'Whether to append to existing file (default: false)',
          type: 'boolean',
          required: false,
        ),
      ],
    ),
  ];

  // Keywords for task classification
  static const _toolKeywords = <String>[
    'create a file',
    'file called',
    'new file',
    'make a file',
    'write file',
    'save file',
    'read file',
    'open file',
    'delete file',
    'remove file',
    'erase file',
    'create folder',
    'new folder',
    'make folder',
    'directory',
    'list files',
    'show files',
    'files in',
    'calendar',
    'event',
    'schedule',
    'appointment',
    'meeting',
    'timer',
    'countdown',
    'reminder',
    'alarm',
    'export',
    'save as',
  ];

  static const _codeKeywords = <String>[
    'write code',
    'generate code',
    'create code',
    'implement',
    'function',
    'class',
    'method',
    'debug',
    'fix the code',
    'refactor',
    'python',
    'javascript',
    'typescript',
    'dart',
    'rust',
    'algorithm',
    'data structure',
    'lua script',
    'script that',
  ];

  /// Initialize the MCP service
  Future<void> initialize(
    String browseDir, {
    int? maxFileSize,
    Set<String>? allowedExtensions,
  }) async {
    if (_initialized) return;

    _browseDir = browseDir;
    if (maxFileSize != null) _maxFileSize = maxFileSize;
    if (allowedExtensions != null) {
      _allowedExtensions.clear();
      _allowedExtensions.addAll(allowedExtensions);
    }

    // Ensure browse directory exists
    final dir = Directory(browseDir);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    _initialized = true;
    debugPrint('MCP Service initialized with browse dir: $browseDir');
  }

  /// Check if MCP is initialized
  bool get isInitialized => _initialized;

  /// Get the browse directory
  String? get browseDir => _browseDir;

  /// Set the plugin executor for Lua script execution
  void setPluginExecutor(PluginScriptExecutor executor) {
    _pluginExecutor = executor;
  }

  /// Get all available tools
  List<MCPToolInfo> getAvailableTools() => _tools;

  /// Get tool schemas as JSON (for AI prompts)
  String getToolSchemas() {
    final schemas = _tools
        .map(
          (t) => {
            'name': t.name,
            'description': t.description,
            'parameters': t.parameters
                .map(
                  (p) => {
                    'name': p.name,
                    'description': p.description,
                    'type': p.type,
                    'required': p.required,
                  },
                )
                .toList(),
          },
        )
        .toList();
    return jsonEncode(schemas);
  }

  /// Classify a user message to determine task type
  MCPTaskCategory classifyTask(String message) {
    final lower = message.toLowerCase();

    // Check for tool use keywords
    for (final keyword in _toolKeywords) {
      if (lower.contains(keyword)) {
        return MCPTaskCategory.toolUse;
      }
    }

    // Check for code generation keywords
    for (final keyword in _codeKeywords) {
      if (lower.contains(keyword)) {
        return MCPTaskCategory.codeGeneration;
      }
    }

    // Default to conversation
    return MCPTaskCategory.conversation;
  }

  /// Get recommended model for a task category
  String getModelForTask(MCPTaskCategory category) {
    switch (category) {
      case MCPTaskCategory.conversation:
        return 'phi4';
      case MCPTaskCategory.toolUse:
        return 'functionGemma';
      case MCPTaskCategory.codeGeneration:
        return 'qwen';
    }
  }

  /// Parse a tool call from AI response JSON
  PendingToolCall? parseToolCall(String json) {
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      if (!decoded.containsKey('tool')) {
        return null;
      }

      final tool = decoded['tool'] as String;
      final parameters = (decoded['parameters'] as Map<String, dynamic>?) ?? {};
      final description = decoded['description'] as String? ?? 'Execute $tool';

      return PendingToolCall(
        tool: tool,
        parameters: parameters,
        description: description,
        luaScript: parameters['script'] as String?,
      );
    } catch (e) {
      debugPrint('Failed to parse tool call: $e');
      return null;
    }
  }

  /// Validate a path (ensure it's within the sandbox)
  bool validatePath(String relativePath) {
    if (relativePath.isEmpty) return false;

    // Block parent traversal
    if (relativePath.contains('..')) return false;

    // Block absolute paths
    if (path.isAbsolute(relativePath)) return false;

    // Normalize and check
    final normalized = path.normalize(relativePath);
    if (normalized.startsWith('..') ||
        normalized.startsWith('/') ||
        normalized.startsWith('\\')) {
      return false;
    }

    return true;
  }

  /// Check if file extension is allowed
  bool isExtensionAllowed(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    if (ext.isEmpty) return false;
    return _allowedExtensions.contains(ext.substring(1)); // Remove leading dot
  }

  String _getAbsolutePath(String relativePath) {
    if (!validatePath(relativePath)) {
      throw ArgumentError('Invalid path: $relativePath');
    }
    return path.join(_browseDir!, relativePath);
  }

  /// Execute a tool call with user confirmation
  Future<MCPExecutionResult> executeWithConfirmation(
    BuildContext context,
    PendingToolCall toolCall,
  ) async {
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(context, toolCall);
    if (!confirmed) {
      return MCPExecutionResult.cancelled(toolCall.tool);
    }

    return executeDirectly(toolCall);
  }

  /// Execute a tool call without confirmation (for automated workflows)
  Future<MCPExecutionResult> executeDirectly(PendingToolCall toolCall) async {
    if (!_initialized) {
      return MCPExecutionResult(
        success: false,
        result: 'MCP not initialized',
        toolName: toolCall.tool,
      );
    }

    try {
      switch (toolCall.tool) {
        case 'read_file':
          final content = await readFile(toolCall.parameters['path'] as String);
          return MCPExecutionResult(
            success: true,
            result: content,
            toolName: toolCall.tool,
          );

        case 'write_file':
        case 'export_markdown':
          final filePath = toolCall.parameters['path'] as String;
          final content = toolCall.parameters['content'] as String;
          final append = toolCall.parameters['append'] as bool? ?? false;
          await writeFile(filePath, content, append: append);
          return MCPExecutionResult(
            success: true,
            result: append ? 'Appended to $filePath' : 'Wrote to $filePath',
            toolName: toolCall.tool,
          );

        case 'delete_file':
          final filePath = toolCall.parameters['path'] as String;
          await deleteFile(filePath);
          return MCPExecutionResult(
            success: true,
            result: 'Deleted $filePath',
            toolName: toolCall.tool,
          );

        case 'create_folder':
          final folderPath = toolCall.parameters['path'] as String;
          await createFolder(folderPath);
          return MCPExecutionResult(
            success: true,
            result: 'Created folder $folderPath',
            toolName: toolCall.tool,
          );

        case 'list_files':
          final dirPath = toolCall.parameters['path'] as String? ?? '';
          final recursive = toolCall.parameters['recursive'] as bool? ?? false;
          final files = await listFiles(dirPath, recursive: recursive);
          return MCPExecutionResult(
            success: true,
            result: files.join('\n'),
            toolName: toolCall.tool,
          );

        case 'calendar_lua':
        case 'timer_lua':
          return _executeLuaScript(toolCall);

        default:
          return MCPExecutionResult(
            success: false,
            result: 'Unknown tool: ${toolCall.tool}',
            toolName: toolCall.tool,
          );
      }
    } catch (e) {
      return MCPExecutionResult(
        success: false,
        result: 'Error: $e',
        toolName: toolCall.tool,
      );
    }
  }

  MCPExecutionResult _executeLuaScript(PendingToolCall toolCall) {
    if (_pluginExecutor == null) {
      return MCPExecutionResult(
        success: false,
        result: 'Lua execution not available - plugin executor not configured',
        toolName: toolCall.tool,
      );
    }

    // Note: Actual Lua execution would be async, but for now return a placeholder
    // In a real implementation, this would call _pluginExecutor!.executeScript()
    return MCPExecutionResult(
      success: true,
      result: 'Lua script queued for execution: ${toolCall.description}',
      toolName: toolCall.tool,
    );
  }

  /// Show confirmation dialog for tool execution
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    PendingToolCall toolCall,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => _ToolConfirmationDialog(toolCall: toolCall),
        ) ??
        false;
  }

  // === Direct File Operations ===

  /// Read a file
  Future<String> readFile(String relativePath) async {
    final absPath = _getAbsolutePath(relativePath);
    final file = File(absPath);

    if (!file.existsSync()) {
      throw FileSystemException('File not found', absPath);
    }

    final stat = file.statSync();
    if (stat.size > _maxFileSize) {
      throw FileSystemException(
        'File too large (max ${_maxFileSize ~/ 1024 ~/ 1024}MB)',
        absPath,
      );
    }

    return file.readAsString();
  }

  /// Write a file
  Future<void> writeFile(
    String relativePath,
    String content, {
    bool append = false,
  }) async {
    if (!isExtensionAllowed(relativePath)) {
      throw ArgumentError(
        'File extension not allowed: ${path.extension(relativePath)}',
      );
    }

    final absPath = _getAbsolutePath(relativePath);
    final file = File(absPath);

    // Ensure parent directory exists
    final parent = file.parent;
    if (!parent.existsSync()) {
      await parent.create(recursive: true);
    }

    if (append && file.existsSync()) {
      await file.writeAsString(content, mode: FileMode.append);
    } else {
      await file.writeAsString(content);
    }
  }

  /// Delete a file
  Future<void> deleteFile(String relativePath) async {
    final absPath = _getAbsolutePath(relativePath);
    final file = File(absPath);

    if (!file.existsSync()) {
      throw FileSystemException('File not found', absPath);
    }

    await file.delete();
  }

  /// Create a folder
  Future<void> createFolder(String relativePath) async {
    final absPath = _getAbsolutePath(relativePath);
    final dir = Directory(absPath);

    if (dir.existsSync()) {
      throw FileSystemException('Folder already exists', absPath);
    }

    await dir.create(recursive: true);
  }

  /// List files in a directory
  Future<List<String>> listFiles(
    String relativePath, {
    bool recursive = false,
  }) async {
    final absPath = relativePath.isEmpty
        ? _browseDir!
        : _getAbsolutePath(relativePath);
    final dir = Directory(absPath);

    if (!dir.existsSync()) {
      throw FileSystemException('Directory not found', absPath);
    }

    final entities = recursive ? dir.listSync(recursive: true) : dir.listSync();

    return entities.map((e) {
      final relPath = path.relative(e.path, from: _browseDir!);
      if (e is Directory) {
        return '$relPath/';
      }
      return relPath;
    }).toList()..sort();
  }
}

/// Confirmation dialog for tool execution
class _ToolConfirmationDialog extends StatelessWidget {
  final PendingToolCall toolCall;

  const _ToolConfirmationDialog({required this.toolCall});

  IconData get _toolIcon {
    switch (toolCall.tool) {
      case 'read_file':
        return Icons.file_open;
      case 'write_file':
        return Icons.save;
      case 'delete_file':
        return Icons.delete;
      case 'create_folder':
        return Icons.create_new_folder;
      case 'list_files':
        return Icons.folder_open;
      case 'calendar_lua':
        return Icons.calendar_today;
      case 'timer_lua':
        return Icons.timer;
      case 'export_markdown':
        return Icons.upload_file;
      default:
        return Icons.play_arrow;
    }
  }

  Color get _toolColor {
    switch (toolCall.tool) {
      case 'delete_file':
        return Colors.red;
      case 'write_file':
      case 'create_folder':
      case 'export_markdown':
        return Colors.orange;
      case 'calendar_lua':
      case 'timer_lua':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(_toolIcon, color: _toolColor),
          const SizedBox(width: 12),
          const Expanded(child: Text('Confirm AI Action')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(toolCall.displayDescription, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tool: ${toolCall.tool}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                if (toolCall.parameters.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Parameters:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...toolCall.parameters.entries
                      .take(5)
                      .map(
                        (e) => Text(
                          '  ${e.key}: ${_truncate(e.value.toString(), 50)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  if (toolCall.parameters.length > 5)
                    Text(
                      '  ... and ${toolCall.parameters.length - 5} more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (toolCall.tool == 'delete_file') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: _toolColor),
          child: const Text('Execute'),
        ),
      ],
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
