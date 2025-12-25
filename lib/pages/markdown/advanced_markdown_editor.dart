import 'dart:async';
import 'dart:typed_data';

import 'package:code_text_field/code_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:kivixa/components/life_git/time_travel_slider.dart';
import 'package:kivixa/components/media/media_video_player.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/services/life_git/life_git.dart';
import 'package:kivixa/services/media_service.dart';
import 'package:logging/logging.dart';

/// Advanced VS Code-like Markdown editor with:
/// - Syntax highlighting in edit mode
/// - Rich preview with flutter_smooth_markdown
/// - Toolbar with formatting buttons
/// - Split view mode
/// - Theme support (light/dark)
/// - Code block copy buttons
/// - LaTeX math rendering
/// - Table support
/// - Footnotes
class AdvancedMarkdownEditor extends StatefulWidget {
  const AdvancedMarkdownEditor({super.key, this.filePath});

  final String? filePath;

  static const extension = '.md';

  @override
  State<AdvancedMarkdownEditor> createState() => _AdvancedMarkdownEditorState();
}

enum EditorViewMode { edit, preview, split }

class _AdvancedMarkdownEditorState extends State<AdvancedMarkdownEditor>
    with SingleTickerProviderStateMixin {
  CodeController? _codeController;
  late TextEditingController _fileNameController;
  late TabController _tabController;

  final _previewScrollController = ScrollController();

  var _isLoading = true;
  String? _currentFilePath;
  var _fileName = 'Untitled';
  Timer? _autosaveTimer;
  Timer? _renameTimer;
  var _viewMode = EditorViewMode.edit;
  var _isEditingFileName = false;
  var _wordCount = 0;
  var _charCount = 0;
  var _lastThemeIsDark = false;

  // Time Travel state
  var _isTimeTraveling = false;
  String? _originalContent;
  String? _timeTravelContent;

  final log = Logger('AdvancedMarkdownEditor');

  // Supported markdown types for toolbar
  static const _toolbarActions = <_ToolbarAction>[
    _ToolbarAction(
      icon: Icons.format_bold,
      tooltip: 'Bold (Ctrl+B)',
      type: _FormatType.bold,
    ),
    _ToolbarAction(
      icon: Icons.format_italic,
      tooltip: 'Italic (Ctrl+I)',
      type: _FormatType.italic,
    ),
    _ToolbarAction(
      icon: Icons.strikethrough_s,
      tooltip: 'Strikethrough',
      type: _FormatType.strikethrough,
    ),
    _ToolbarAction(
      icon: Icons.code,
      tooltip: 'Inline Code',
      type: _FormatType.inlineCode,
    ),
    _ToolbarAction(
      icon: Icons.format_quote,
      tooltip: 'Quote',
      type: _FormatType.quote,
    ),
    _ToolbarAction(
      icon: Icons.link,
      tooltip: 'Link (Ctrl+K)',
      type: _FormatType.link,
    ),
    _ToolbarAction(
      icon: Icons.image,
      tooltip: 'Image',
      type: _FormatType.image,
    ),
    _ToolbarAction(
      icon: Icons.videocam,
      tooltip: 'Video',
      type: _FormatType.video,
    ),
    _ToolbarAction(
      icon: Icons.format_list_bulleted,
      tooltip: 'Bullet List',
      type: _FormatType.bulletList,
    ),
    _ToolbarAction(
      icon: Icons.format_list_numbered,
      tooltip: 'Numbered List',
      type: _FormatType.numberedList,
    ),
    _ToolbarAction(
      icon: Icons.check_box,
      tooltip: 'Task List',
      type: _FormatType.taskList,
    ),
    _ToolbarAction(
      icon: Icons.data_array,
      tooltip: 'Code Block',
      type: _FormatType.codeBlock,
    ),
    _ToolbarAction(
      icon: Icons.table_chart,
      tooltip: 'Table',
      type: _FormatType.table,
    ),
    _ToolbarAction(
      icon: Icons.horizontal_rule,
      tooltip: 'Horizontal Rule',
      type: _FormatType.horizontalRule,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    _loadFile();
  }

  void _initCodeController(bool isDark, [String text = '']) {
    final currentText = _codeController?.text ?? text;
    final selection = _codeController?.selection;
    _codeController?.removeListener(_onTextChanged);
    _codeController?.dispose();
    _codeController = CodeController(text: currentText, language: markdown);
    if (selection != null && selection.isValid) {
      try {
        _codeController!.selection = selection;
      } catch (_) {
        // Selection may be invalid for new text
      }
    }
    _codeController!.addListener(_onTextChanged);
    _lastThemeIsDark = isDark;
  }

  void _onTabChanged() {
    setState(() {
      _viewMode = EditorViewMode.values[_tabController.index];
    });
  }

  Future<void> _loadFile() async {
    var fileContent = '';

    if (widget.filePath != null) {
      try {
        _currentFilePath = widget.filePath! + AdvancedMarkdownEditor.extension;

        try {
          final content = await FileManager.readFile(_currentFilePath!);
          if (content != null) {
            fileContent = String.fromCharCodes(content);
            _fileName = _getFileNameFromPath(_currentFilePath!);
          }
        } catch (e) {
          _currentFilePath =
              widget.filePath! + AdvancedMarkdownEditor.extension;
          _fileName = _getFileNameFromPath(widget.filePath!);
          log.info('Creating new markdown file: $_currentFilePath');
        }
      } catch (e) {
        log.severe('Error loading markdown file', e);
      }
    }

    // Initialize code controller (will get proper theme in build)
    _initCodeController(false, fileContent);
    _updateCounts();

    setState(() {
      _isLoading = false;
    });

    _fileNameController.text = _fileName;
    _fileNameController.addListener(_onFileNameChanged);
  }

  String _getFileNameFromPath(String path) {
    final parts = path.split('/');
    var name = parts.last;
    if (name.endsWith(AdvancedMarkdownEditor.extension)) {
      name = name.substring(
        0,
        name.length - AdvancedMarkdownEditor.extension.length,
      );
    }
    return name;
  }

  void _onFileNameChanged() {
    _renameTimer?.cancel();
    _renameTimer = Timer(const Duration(seconds: 1), _renameFile);
  }

  void _onTextChanged() {
    _updateCounts();
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), _saveFile);
  }

  void _updateCounts() {
    final controller = _codeController;
    if (controller == null) return;

    final text = controller.text;
    setState(() {
      _charCount = text.length;
      _wordCount = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _renameFile() async {
    final newName = _fileNameController.text.trim();
    if (newName.isEmpty || newName == _fileName) return;

    try {
      if (_currentFilePath != null) {
        final parts = _currentFilePath!.split('/');
        parts.removeLast();
        final dirPath = parts.join('/');
        final newFilePath =
            '$dirPath/$newName${AdvancedMarkdownEditor.extension}';

        final actualNewPath = await FileManager.moveFile(
          _currentFilePath!,
          newFilePath,
        );

        setState(() {
          _currentFilePath = actualNewPath;
          _fileName = newName;
        });

        log.info('File renamed to: $actualNewPath');
      }
    } catch (e) {
      log.severe('Error renaming file', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error renaming file: $e')));
      }
    }
  }

  Future<void> _saveFile() async {
    final controller = _codeController;
    if (controller == null) return;

    _currentFilePath ??= '/Untitled${AdvancedMarkdownEditor.extension}';

    try {
      final content = controller.text.codeUnits;
      await FileManager.writeFile(_currentFilePath!, content, awaitWrite: true);
      log.info('File saved: $_currentFilePath');
    } catch (e) {
      log.severe('Error saving file', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  Future<void> _commitVersion() async {
    if (_currentFilePath == null) return;

    // Show dialog to get optional commit message
    final messageController = TextEditingController();
    final shouldCommit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commit Version'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Commit message (optional)',
            hintText: 'Describe your changes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Commit'),
          ),
        ],
      ),
    );

    if (shouldCommit != true) {
      messageController.dispose();
      return;
    }

    final customMessage = messageController.text.trim();
    messageController.dispose();

    // Save first to ensure latest content is on disk
    await _saveFile();

    try {
      final snapshot = await LifeGitService.instance.snapshotFile(
        _currentFilePath!,
      );
      if (snapshot.exists) {
        final message = customMessage.isNotEmpty
            ? customMessage
            : 'Commit: $_fileName';
        await LifeGitService.instance.createCommit(
          snapshots: [snapshot],
          message: message,
        );
        log.info('Life Git commit created for: $_currentFilePath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Version committed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      log.warning('Failed to create Life Git commit', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to commit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _enterTimeTravel() {
    if (_currentFilePath == null) return;
    setState(() {
      _isTimeTraveling = true;
      _originalContent = _codeController?.text;
    });
  }

  void _exitTimeTravel() {
    setState(() {
      _isTimeTraveling = false;
      if (_originalContent != null && _codeController != null) {
        _codeController!.text = _originalContent!;
      }
      _originalContent = null;
      _timeTravelContent = null;
    });
  }

  void _onTimeTravelContent(Uint8List content, LifeGitCommit commit) {
    final textContent = String.fromCharCodes(content);
    setState(() {
      _timeTravelContent = textContent;
      _codeController?.text = textContent;
    });
  }

  void _restoreHistoricalVersion() {
    if (_timeTravelContent != null) {
      setState(() {
        _originalContent = _timeTravelContent;
        _isTimeTraveling = false;
        _timeTravelContent = null;
      });
      _saveFile(); // Save the restored version
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historical version restored')),
        );
      }
    }
  }

  void _onRestoreVersion(Uint8List content, LifeGitCommit commit) {
    final textContent = String.fromCharCodes(content);
    setState(() {
      _codeController?.text = textContent;
      _originalContent = textContent;
      _isTimeTraveling = false;
      _timeTravelContent = null;
    });
    _saveFile(); // Save the restored version
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restored to: ${commit.message}')));
    }
  }

  void _formatText(_FormatType type) {
    final controller = _codeController;
    if (controller == null) return;

    // For dialogs that don't need a valid selection, handle them first
    switch (type) {
      case _FormatType.link:
        _showLinkDialog();
        return;
      case _FormatType.image:
        _showImageDialog();
        return;
      case _FormatType.video:
        _showVideoDialog();
        return;
      default:
        break;
    }

    final selection = controller.selection;
    // Guard against invalid selection for formatting operations
    if (!selection.isValid || selection.start < 0) return;

    final text = controller.text;
    final start = selection.start;
    final end = selection.end;
    final selectedText = start < end ? text.substring(start, end) : '';

    String newText;
    int newStart;
    int newEnd;

    switch (type) {
      case _FormatType.bold:
        newText = '**$selectedText**';
        newStart = start + 2;
        newEnd = end + 2;
      case _FormatType.italic:
        newText = '*$selectedText*';
        newStart = start + 1;
        newEnd = end + 1;
      case _FormatType.strikethrough:
        newText = '~~$selectedText~~';
        newStart = start + 2;
        newEnd = end + 2;
      case _FormatType.inlineCode:
        newText = '`$selectedText`';
        newStart = start + 1;
        newEnd = end + 1;
      case _FormatType.quote:
        newText = '> $selectedText';
        newStart = start + 2;
        newEnd = end + 2;
      case _FormatType.link:
        return; // Already handled above
      case _FormatType.image:
        return; // Already handled above
      case _FormatType.video:
        return; // Already handled above
      case _FormatType.bulletList:
        final lines = selectedText.split('\n');
        newText = lines.map((l) => '- $l').join('\n');
        newStart = start;
        newEnd = start + newText.length;
      case _FormatType.numberedList:
        final lines = selectedText.split('\n');
        newText = lines
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value}')
            .join('\n');
        newStart = start;
        newEnd = start + newText.length;
      case _FormatType.taskList:
        final lines = selectedText.split('\n');
        newText = lines.map((l) => '- [ ] $l').join('\n');
        newStart = start;
        newEnd = start + newText.length;
      case _FormatType.codeBlock:
        newText = '```\n$selectedText\n```';
        newStart = start + 4;
        newEnd = end + 4;
      case _FormatType.table:
        newText =
            '| Column 1 | Column 2 | Column 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |';
        newStart = start;
        newEnd = start + newText.length;
      case _FormatType.horizontalRule:
        newText = '\n---\n';
        newStart = start + newText.length;
        newEnd = newStart;
      case _FormatType.heading1:
        newText = '# $selectedText';
        newStart = start + 2;
        newEnd = end + 2;
      case _FormatType.heading2:
        newText = '## $selectedText';
        newStart = start + 3;
        newEnd = end + 3;
      case _FormatType.heading3:
        newText = '### $selectedText';
        newStart = start + 4;
        newEnd = end + 4;
    }

    controller.text = text.replaceRange(start, end, newText);
    controller.selection = TextSelection(
      baseOffset: newStart,
      extentOffset: newEnd,
    );
  }

  void _showLinkDialog() {
    final controller = _codeController;
    if (controller == null) return;

    final textController = TextEditingController();
    final urlController = TextEditingController();

    final selection = controller.selection;
    if (selection.isValid &&
        selection.start >= 0 &&
        selection.start < selection.end) {
      final selectedText = controller.text.substring(
        selection.start,
        selection.end,
      );
      if (selectedText.isNotEmpty) {
        textController.text = selectedText;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Link Text',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final linkText = textController.text.isEmpty
                  ? 'Link'
                  : textController.text;
              final url = urlController.text;
              final mdLink = '[$linkText]($url)';

              final text = controller.text;
              // Handle invalid selection by inserting at end
              final start = selection.isValid && selection.start >= 0
                  ? selection.start
                  : text.length;
              final end = selection.isValid && selection.end >= 0
                  ? selection.end
                  : text.length;

              controller.text = text.replaceRange(start, end, mdLink);
              controller.selection = TextSelection.collapsed(
                offset: start + mdLink.length,
              );

              Navigator.pop(ctx);
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
  }

  void _showImageDialog() {
    _showMediaUploadDialog(isVideo: false);
  }

  void _showVideoDialog() {
    _showMediaUploadDialog(isVideo: true);
  }

  void _showMediaUploadDialog({required bool isVideo}) async {
    final controller = _codeController;
    if (controller == null) return;

    final altController = TextEditingController();
    final urlController = TextEditingController();
    var isLocalFile = false;
    String? localFilePath;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isVideo ? 'Insert Video' : 'Insert Image'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Source toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('URL'),
                      icon: Icon(Icons.link),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Local File'),
                      icon: Icon(Icons.folder_open),
                    ),
                  ],
                  selected: {isLocalFile},
                  onSelectionChanged: (selection) {
                    setDialogState(() => isLocalFile = selection.first);
                  },
                ),
                const SizedBox(height: 16),

                // Alt text
                TextField(
                  controller: altController,
                  decoration: InputDecoration(
                    labelText: isVideo ? 'Caption' : 'Alt Text',
                    border: const OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // URL or file picker
                if (isLocalFile)
                  _buildLocalFilePicker(
                    ctx,
                    isVideo,
                    localFilePath,
                    (path) => setDialogState(() => localFilePath = path),
                  )
                else
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      labelText: isVideo ? 'Video URL' : 'Image URL',
                      hintText: 'https://',
                      border: const OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () async {
                String path;
                if (isLocalFile) {
                  if (localFilePath == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please select a file')),
                    );
                    return;
                  }
                  // Upload to app storage
                  try {
                    final mediaService = MediaService.instance;
                    path = await mediaService.uploadMedia(localFilePath!);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Error uploading: $e')),
                      );
                    }
                    return;
                  }
                } else {
                  path = urlController.text;
                  if (path.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter a URL')),
                    );
                    return;
                  }
                }

                final altText = altController.text.isEmpty
                    ? (isVideo ? 'Video' : 'Image')
                    : altController.text;

                // Create extended markdown syntax
                final mdMedia = '![$altText]($path)';

                final selection = controller.selection;
                final text = controller.text;
                // Handle invalid selection by inserting at end
                final start = selection.isValid && selection.start >= 0
                    ? selection.start
                    : text.length;
                final end = selection.isValid && selection.end >= 0
                    ? selection.end
                    : text.length;

                controller.text = text.replaceRange(start, end, mdMedia);
                controller.selection = TextSelection.collapsed(
                  offset: start + mdMedia.length,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Insert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalFilePicker(
    BuildContext context,
    bool isVideo,
    String? currentPath,
    ValueChanged<String> onPathSelected,
  ) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final result = await FilePicker.platform.pickFiles(
              type: isVideo ? FileType.video : FileType.image,
              allowMultiple: false,
            );
            if (result != null && result.files.isNotEmpty) {
              final path = result.files.first.path;
              if (path != null) {
                onPathSelected(path);
              }
            }
          },
          icon: Icon(isVideo ? Icons.videocam : Icons.image),
          label: Text(
            currentPath != null
                ? _getFileName(currentPath)
                : 'Choose ${isVideo ? 'Video' : 'Image'}',
          ),
        ),
        if (currentPath != null) ...[
          const SizedBox(height: 8),
          Text(
            currentPath,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _getFileName(String path) {
    if (path.contains('/')) return path.split('/').last;
    if (path.contains('\\')) return path.split('\\').last;
    return path;
  }

  void _insertHeading(int level) {
    final controller = _codeController;
    if (controller == null) return;

    final prefix = '${'#' * level} ';
    final selection = controller.selection;
    if (!selection.isValid || selection.start < 0) return;

    final text = controller.text;
    final start = selection.start;
    final end = selection.end;
    final selectedText = start < end ? text.substring(start, end) : '';

    final newText = '$prefix$selectedText';
    controller.text = text.replaceRange(start, end, newText);
    controller.selection = TextSelection.collapsed(
      offset: start + newText.length,
    );
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _renameTimer?.cancel();
    _codeController?.dispose();
    _fileNameController.dispose();
    _tabController.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Recreate controller if theme changed
    if (_lastThemeIsDark != isDark) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initCodeController(isDark);
        setState(() {});
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: _buildTitleWidget(),
        bottom: _isTimeTraveling
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.edit), text: 'Edit'),
                  Tab(icon: Icon(Icons.preview), text: 'Preview'),
                  Tab(icon: Icon(Icons.splitscreen), text: 'Split'),
                ],
              ),
        actions: [
          if (!_isTimeTraveling) ...[
            // Heading dropdown
            PopupMenuButton<int>(
              icon: const Icon(Icons.title),
              tooltip: 'Insert Heading',
              onSelected: _insertHeading,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1, child: Text('Heading 1')),
                const PopupMenuItem(value: 2, child: Text('Heading 2')),
                const PopupMenuItem(value: 3, child: Text('Heading 3')),
                const PopupMenuItem(value: 4, child: Text('Heading 4')),
                const PopupMenuItem(value: 5, child: Text('Heading 5')),
                const PopupMenuItem(value: 6, child: Text('Heading 6')),
              ],
            ),
            // Time Travel button
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Time Travel',
              onPressed: _currentFilePath != null ? _enterTimeTravel : null,
            ),
            // View full history
            IconButton(
              icon: const Icon(Icons.manage_history),
              tooltip: 'View History',
              onPressed: _currentFilePath != null
                  ? () => context.push(
                      RoutePaths.lifeGitHistoryPath(filePath: _currentFilePath),
                    )
                  : null,
            ),
            // Commit version button (replaces save icon)
            IconButton(
              icon: const Icon(Icons.commit),
              tooltip: 'Commit Version',
              onPressed: _commitVersion,
            ),
          ] else ...[
            // Time Travel mode actions
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restore this version',
              onPressed: _restoreHistoricalVersion,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit Time Travel',
              onPressed: _exitTimeTravel,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Time Travel slider when in time travel mode
          if (_isTimeTraveling && _currentFilePath != null)
            TimeTravelSlider(
              filePath: _currentFilePath!,
              onHistoryContent: _onTimeTravelContent,
              onExitTimeTravel: _exitTimeTravel,
              onRestoreVersion: _onRestoreVersion,
              showCommitDetails: true,
            ),

          // Formatting toolbar (hidden during time travel)
          if (!_isTimeTraveling) ...[
            _buildToolbar(colorScheme),
            const Divider(height: 1),
          ],

          // Editor content
          Expanded(child: _buildContent(isDark)),

          // Status bar
          _buildStatusBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTitleWidget() {
    return InkWell(
      onTap: () {
        setState(() => _isEditingFileName = true);
        _fileNameController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _fileNameController.text.length,
        );
      },
      child: _isEditingFileName
          ? SizedBox(
              width: 200,
              child: TextField(
                controller: _fileNameController,
                autofocus: true,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => setState(() => _isEditingFileName = false),
                onTapOutside: (_) => setState(() => _isEditingFileName = false),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description, size: 20),
                const SizedBox(width: 8),
                Text(_fileName),
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 16),
              ],
            ),
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final action in _toolbarActions) ...[
              IconButton(
                icon: Icon(action.icon, size: 20),
                tooltip: action.tooltip,
                onPressed: () => _formatText(action.type),
                visualDensity: VisualDensity.compact,
              ),
              if (action.type == _FormatType.inlineCode ||
                  action.type == _FormatType.image ||
                  action.type == _FormatType.taskList)
                const VerticalDivider(width: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (_viewMode) {
      case EditorViewMode.edit:
        return _buildEditor(isDark);
      case EditorViewMode.preview:
        return _buildPreview(isDark);
      case EditorViewMode.split:
        return Row(
          children: [
            Expanded(child: _buildEditor(isDark)),
            const VerticalDivider(width: 1),
            Expanded(child: _buildPreview(isDark)),
          ],
        );
    }
  }

  Widget _buildEditor(bool isDark) {
    final controller = _codeController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = isDark ? vs2015Theme : githubTheme;

    return ColoredBox(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: CodeTheme(
        data: CodeThemeData(styles: theme),
        child: CodeField(
          controller: controller,
          textStyle: const TextStyle(
            fontFamily: 'FiraCode',
            fontSize: 14,
            height: 1.5,
          ),
          lineNumberStyle: LineNumberStyle(
            width: 56, // Increased width to accommodate larger line numbers
            textStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
              fontSize: 12,
            ),
            background: isDark
                ? const Color(0xFF252526)
                : const Color(0xFFF5F5F5),
          ),
          padding: const EdgeInsets.all(16),
          expands: true,
          wrap: true,
          minLines: null, // Allow dynamic line count
        ),
      ),
    );
  }

  Widget _buildPreview(bool isDark) {
    final controller = _codeController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ColoredBox(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: SingleChildScrollView(
        controller: _previewScrollController,
        padding: const EdgeInsets.all(16),
        child: SmoothMarkdown(
          data: controller.text,
          styleSheet: isDark
              ? MarkdownStyleSheet.vscode(brightness: Brightness.dark)
              : MarkdownStyleSheet.github(brightness: Brightness.light),
          onTapLink: (url) {
            log.info('Link tapped: $url');
          },
          imageBuilder: (uri, title, alt) {
            // Reconstruct the markdown syntax to parse metadata
            final mdSyntax = '![$alt]($uri)';
            return _buildInteractiveMedia(mdSyntax, isVideo: false);
          },
        ),
      ),
    );
  }

  /// Build interactive media widget with resize controls
  Widget _buildInteractiveMedia(String mdSyntax, {required bool isVideo}) {
    // Parse the element from markdown syntax
    final element = MediaElement.fromMarkdownSyntax(mdSyntax);
    if (element == null) {
      return _buildMediaError('Failed to parse media');
    }

    // Resolve relative paths using the markdown file's directory
    var resolvedPath = element.path;
    if (!element.isFromWeb && !element.path.startsWith('/')) {
      // Relative path - resolve against markdown file directory
      if (_currentFilePath != null) {
        final mdDir = _currentFilePath!.substring(
          0,
          _currentFilePath!.lastIndexOf('/'),
        );
        resolvedPath = '$mdDir/${element.path}';
      }
    }

    // Override media type if we know it's a video
    final actualElement = isVideo
        ? MediaElement(
            path: resolvedPath,
            mediaType: MediaType.video,
            sourceType: element.sourceType,
            altText: element.altText,
            width: element.width,
            height: element.height,
            rotation: element.rotation,
            posX: element.posX,
            posY: element.posY,
          )
        : element.copyWith(path: resolvedPath);

    return _InteractivePreviewMedia(
      key: ValueKey(actualElement.path),
      element: actualElement,
      onChanged: (newElement) {
        _updateMediaInSource(element.path, newElement);
      },
    );
  }

  /// Update media metadata in the source markdown
  void _updateMediaInSource(String originalPath, MediaElement newElement) {
    final controller = _codeController;
    if (controller == null) return;

    final text = controller.text;
    final newSyntax = newElement.toMarkdownSyntax();

    // Find and replace the media syntax in the source
    // Match patterns like ![alt](path) or ![alt|params](path)
    final regex = RegExp(
      r'!\[([^\]]*)\]\(' + RegExp.escape(originalPath) + r'\)',
    );

    final match = regex.firstMatch(text);
    if (match != null) {
      final newText = text.replaceRange(match.start, match.end, newSyntax);
      controller.text = newText;
      // Trigger save
      _onTextChanged();
    }
  }

  Widget _buildMediaError(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStatusBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Text(
            'Words: $_wordCount',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Text(
            'Characters: $_charCount',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            'Markdown',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

enum _FormatType {
  bold,
  italic,
  strikethrough,
  inlineCode,
  quote,
  link,
  image,
  video,
  bulletList,
  numberedList,
  taskList,
  codeBlock,
  table,
  horizontalRule,
  heading1,
  heading2,
  heading3,
}

class _ToolbarAction {
  const _ToolbarAction({
    required this.icon,
    required this.tooltip,
    required this.type,
  });

  final IconData icon;
  final String tooltip;
  final _FormatType type;
}

/// Interactive media widget for markdown preview with resize controls
class _InteractivePreviewMedia extends StatefulWidget {
  const _InteractivePreviewMedia({
    super.key,
    required this.element,
    required this.onChanged,
  });

  final MediaElement element;
  final ValueChanged<MediaElement> onChanged;

  @override
  State<_InteractivePreviewMedia> createState() =>
      _InteractivePreviewMediaState();
}

class _InteractivePreviewMediaState extends State<_InteractivePreviewMedia> {
  late MediaElement _element;
  var _isLoading = true;
  var _hasError = false;
  String? _errorMessage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _element = widget.element;
    _loadMedia();
  }

  @override
  void didUpdateWidget(_InteractivePreviewMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.path != widget.element.path) {
      _element = widget.element;
      _loadMedia();
    }
  }

  Future<void> _loadMedia() async {
    if (_element.isVideo) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await MediaService.instance.resolveMedia(_element);
      if (bytes != null && mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load media: ${_element.path}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _updateSize(double width, double height) {
    final newElement = _element.copyWith(width: width, height: height);
    setState(() => _element = newElement);
    widget.onChanged(newElement);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return _buildError();
    }

    if (_element.isVideo) {
      return _buildVideoWithControls();
    }

    return _buildImageWithControls();
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Failed to load media',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _element.path,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageWithControls() {
    final width = _element.width ?? 400.0;
    final height = _element.height ?? 300.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image with resize handles
          Center(
            child: _buildResizableContainer(
              width: width,
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _imageBytes != null
                    ? Image.memory(
                        _imageBytes!,
                        width: width,
                        height: height,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Size controls
          _buildSizeControls(width, height),
        ],
      ),
    );
  }

  Widget _buildVideoWithControls() {
    final width = _element.width ?? 400.0;
    final height = _element.height ?? 300.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Video player with resize handles
          Center(
            child: _buildResizableContainer(
              width: width,
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: MediaVideoPlayer(
                  element: _element.copyWith(width: width, height: height),
                  onChanged: (updated) {
                    setState(() => _element = updated);
                    widget.onChanged(updated);
                  },
                  autoPlay: false,
                  showControls: true,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Size controls
          _buildSizeControls(width, height),
        ],
      ),
    );
  }

  /// Build a resizable container with 8 handles around the content
  Widget _buildResizableContainer({
    required double width,
    required double height,
    required Widget child,
  }) {
    const handleSize = 10.0;
    const minSize = 100.0;
    const maxSize = 1200.0;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width + handleSize * 2,
      height: height + handleSize * 2,
      child: Stack(
        children: [
          // Main content
          Positioned(
            left: handleSize,
            top: handleSize,
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 2),
              ),
              child: child,
            ),
          ),
          // Resize handles
          ..._buildResizeHandles(
            width: width,
            height: height,
            handleSize: handleSize,
            minSize: minSize,
            maxSize: maxSize,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResizeHandles({
    required double width,
    required double height,
    required double handleSize,
    required double minSize,
    required double maxSize,
    required ColorScheme colorScheme,
  }) {
    Widget buildHandle({
      required double left,
      required double top,
      required MouseCursor cursor,
      required void Function(DragUpdateDetails) onUpdate,
    }) {
      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onPanUpdate: onUpdate,
          child: MouseRegion(
            cursor: cursor,
            child: Container(
              width: handleSize,
              height: handleSize,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return [
      // Top-left
      buildHandle(
        left: handleSize / 2,
        top: handleSize / 2,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        onUpdate: (d) {
          final newWidth = (width - d.delta.dx).clamp(minSize, maxSize);
          final newHeight = (height - d.delta.dy).clamp(minSize, maxSize);
          _updateSize(newWidth, newHeight);
        },
      ),
      // Top
      buildHandle(
        left: handleSize + width / 2 - handleSize / 2,
        top: handleSize / 2,
        cursor: SystemMouseCursors.resizeUpDown,
        onUpdate: (d) {
          final newHeight = (height - d.delta.dy).clamp(minSize, maxSize);
          _updateSize(width, newHeight);
        },
      ),
      // Top-right
      buildHandle(
        left: handleSize + width - handleSize / 2,
        top: handleSize / 2,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        onUpdate: (d) {
          final newWidth = (width + d.delta.dx).clamp(minSize, maxSize);
          final newHeight = (height - d.delta.dy).clamp(minSize, maxSize);
          _updateSize(newWidth, newHeight);
        },
      ),
      // Left
      buildHandle(
        left: handleSize / 2,
        top: handleSize + height / 2 - handleSize / 2,
        cursor: SystemMouseCursors.resizeLeftRight,
        onUpdate: (d) {
          final newWidth = (width - d.delta.dx).clamp(minSize, maxSize);
          _updateSize(newWidth, height);
        },
      ),
      // Right
      buildHandle(
        left: handleSize + width - handleSize / 2,
        top: handleSize + height / 2 - handleSize / 2,
        cursor: SystemMouseCursors.resizeLeftRight,
        onUpdate: (d) {
          final newWidth = (width + d.delta.dx).clamp(minSize, maxSize);
          _updateSize(newWidth, height);
        },
      ),
      // Bottom-left
      buildHandle(
        left: handleSize / 2,
        top: handleSize + height - handleSize / 2,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        onUpdate: (d) {
          final newWidth = (width - d.delta.dx).clamp(minSize, maxSize);
          final newHeight = (height + d.delta.dy).clamp(minSize, maxSize);
          _updateSize(newWidth, newHeight);
        },
      ),
      // Bottom
      buildHandle(
        left: handleSize + width / 2 - handleSize / 2,
        top: handleSize + height - handleSize / 2,
        cursor: SystemMouseCursors.resizeUpDown,
        onUpdate: (d) {
          final newHeight = (height + d.delta.dy).clamp(minSize, maxSize);
          _updateSize(width, newHeight);
        },
      ),
      // Bottom-right
      buildHandle(
        left: handleSize + width - handleSize / 2,
        top: handleSize + height - handleSize / 2,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        onUpdate: (d) {
          final newWidth = (width + d.delta.dx).clamp(minSize, maxSize);
          final newHeight = (height + d.delta.dy).clamp(minSize, maxSize);
          _updateSize(newWidth, newHeight);
        },
      ),
    ];
  }

  Widget _buildSizeControls(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Width input
        SizedBox(
          width: 80,
          child: TextField(
            controller: TextEditingController(text: width.toStringAsFixed(0)),
            decoration: const InputDecoration(
              labelText: 'Width',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              final newWidth = double.tryParse(value);
              if (newWidth != null && newWidth >= 50 && newWidth <= 2000) {
                _updateSize(newWidth, height);
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        const Text('×'),
        const SizedBox(width: 8),
        // Height input
        SizedBox(
          width: 80,
          child: TextField(
            controller: TextEditingController(text: height.toStringAsFixed(0)),
            decoration: const InputDecoration(
              labelText: 'Height',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (value) {
              final newHeight = double.tryParse(value);
              if (newHeight != null && newHeight >= 50 && newHeight <= 2000) {
                _updateSize(width, newHeight);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        // Preset size buttons
        _buildSizePresetButton('S', 200, 150),
        const SizedBox(width: 4),
        _buildSizePresetButton('M', 400, 300),
        const SizedBox(width: 4),
        _buildSizePresetButton('L', 600, 450),
      ],
    );
  }

  Widget _buildSizePresetButton(String label, double width, double height) {
    return SizedBox(
      width: 32,
      height: 32,
      child: OutlinedButton(
        onPressed: () => _updateSize(width, height),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(32, 32),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
