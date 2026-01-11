import 'dart:async';
import 'dart:io';
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
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/services/life_git/life_git.dart';
import 'package:kivixa/services/media_service.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
    _ToolbarAction(
      icon: Icons.format_align_left,
      tooltip: 'Align Left',
      type: _FormatType.alignLeft,
    ),
    _ToolbarAction(
      icon: Icons.format_align_center,
      tooltip: 'Align Center',
      type: _FormatType.alignCenter,
    ),
    _ToolbarAction(
      icon: Icons.format_align_right,
      tooltip: 'Align Right',
      type: _FormatType.alignRight,
    ),
    _ToolbarAction(
      icon: Icons.format_align_justify,
      tooltip: 'Justify',
      type: _FormatType.alignJustify,
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
        print('DEBUG: Loading file: $_currentFilePath');

        try {
          final content = await FileManager.readFile(_currentFilePath!);
          if (content != null) {
            print('DEBUG: File content loaded, length: ${content.length}');
            fileContent = String.fromCharCodes(content);
            _fileName = _getFileNameFromPath(_currentFilePath!);
          } else {
            print('DEBUG: File content is NULL');
          }
        } catch (e) {
          print('DEBUG: Error reading file: $e');
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
      case _FormatType.alignLeft:
        newText = '<div style="text-align: left;">$selectedText</div>';
        newStart = start + 31;
        newEnd = end + 31;
      case _FormatType.alignCenter:
        newText = '<div style="text-align: center;">$selectedText</div>';
        newStart = start + 33;
        newEnd = end + 33;
      case _FormatType.alignRight:
        newText = '<div style="text-align: right;">$selectedText</div>';
        newStart = start + 32;
        newEnd = end + 32;
      case _FormatType.alignJustify:
        newText = '<div style="text-align: justify;">$selectedText</div>';
        newStart = start + 34;
        newEnd = end + 34;
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
    final widthController = TextEditingController(
      text: isVideo ? '640' : '400',
    );
    final heightController = TextEditingController(
      text: isVideo ? '360' : '300',
    );
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

                // Width and Height fields
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        decoration: const InputDecoration(
                          labelText: 'Width',
                          border: OutlineInputBorder(),
                          suffixText: 'px',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          border: OutlineInputBorder(),
                          suffixText: 'px',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
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

                final width = widthController.text;
                final height = heightController.text;

                // Create extended markdown syntax with width/height
                // For videos, use HTML video tag for proper playback
                // For images, use HTML img tag with dimensions
                String mdMedia;
                if (isVideo) {
                  mdMedia =
                      '<video src="$path" width="$width" height="$height" controls>$altText</video>';
                } else {
                  mdMedia =
                      '<img src="$path" alt="$altText" width="$width" height="$height" />';
                }

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

    // Pre-process content to extract video tags and replace with placeholders
    final content = controller.text;
    final processedData = _preprocessMarkdownWithVideos(content);

    return ColoredBox(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: SingleChildScrollView(
        controller: _previewScrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildPreviewContent(processedData, isDark),
        ),
      ),
    );
  }

  /// Preprocesses markdown content to handle video tags and alignment divs
  _ProcessedMarkdown _preprocessMarkdownWithVideos(String content) {
    final videos = <_VideoInfo>[];
    final images = <_ImageInfo>[];
    var processedContent = content;

    // Extract video tags: <video src="path" width="640" height="360" controls>caption</video>
    final videoRegex = RegExp(
      r'<video\s+src="([^"]+)"(?:\s+width="(\d+)")?(?:\s+height="(\d+)")?[^>]*>([^<]*)</video>',
      caseSensitive: false,
    );

    var videoIndex = 0;
    processedContent = processedContent.replaceAllMapped(videoRegex, (match) {
      final src = match.group(1) ?? '';
      final width = double.tryParse(match.group(2) ?? '') ?? 640;
      final height = double.tryParse(match.group(3) ?? '') ?? 360;
      final caption = match.group(4) ?? '';

      videos.add(
        _VideoInfo(
          src: src,
          width: width,
          height: height,
          caption: caption,
          placeholder: '<!--VIDEO_PLACEHOLDER_$videoIndex-->',
        ),
      );

      return '\n\n<!--VIDEO_PLACEHOLDER_${videoIndex++}-->\n\n';
    });

    // Extract img tags: <img src="path" alt="text" width="400" height="300" />
    final imgRegex = RegExp(
      r'<img\s+src="([^"]+)"(?:\s+alt="([^"]*)")?(?:\s+width="(\d+)")?(?:\s+height="(\d+)")?[^/]*/?>',
      caseSensitive: false,
    );

    var imgIndex = 0;
    processedContent = processedContent.replaceAllMapped(imgRegex, (match) {
      final src = match.group(1) ?? '';
      final alt = match.group(2) ?? '';
      final width = double.tryParse(match.group(3) ?? '') ?? 400;
      final height = double.tryParse(match.group(4) ?? '') ?? 300;

      images.add(
        _ImageInfo(
          src: src,
          alt: alt,
          width: width,
          height: height,
          placeholder: '<!--IMG_PLACEHOLDER_$imgIndex-->',
        ),
      );

      return '\n\n<!--IMG_PLACEHOLDER_${imgIndex++}-->\n\n';
    });

    return _ProcessedMarkdown(
      content: processedContent,
      videos: videos,
      images: images,
    );
  }

  /// Build preview content widgets from processed markdown
  List<Widget> _buildPreviewContent(_ProcessedMarkdown data, bool isDark) {
    final widgets = <Widget>[];
    var remainingContent = data.content;

    // Split by placeholders and build widgets
    final placeholderPattern = RegExp(r'<!--(VIDEO|IMG)_PLACEHOLDER_(\d+)-->');

    while (true) {
      final match = placeholderPattern.firstMatch(remainingContent);
      if (match == null) {
        // No more placeholders, add remaining markdown
        if (remainingContent.trim().isNotEmpty) {
          widgets.add(_buildMarkdownSection(remainingContent, isDark));
        }
        break;
      }

      // Add markdown before placeholder
      final before = remainingContent.substring(0, match.start);
      if (before.trim().isNotEmpty) {
        widgets.add(_buildMarkdownSection(before, isDark));
      }

      // Add video or image widget
      final type = match.group(1);
      final index = int.parse(match.group(2)!);

      if (type == 'VIDEO' && index < data.videos.length) {
        widgets.add(_buildVideoPlayer(data.videos[index]));
      } else if (type == 'IMG' && index < data.images.length) {
        widgets.add(_buildImageWithSize(data.images[index]));
      }

      remainingContent = remainingContent.substring(match.end);
    }

    return widgets;
  }

  Widget _buildMarkdownSection(String content, bool isDark) {
    return SmoothMarkdown(
      data: content,
      styleSheet: isDark
          ? MarkdownStyleSheet.vscode(brightness: Brightness.dark)
          : MarkdownStyleSheet.github(brightness: Brightness.light),
      onTapLink: (url) {
        log.info('Link tapped: $url');
      },
      imageBuilder: (uri, title, alt) {
        final imagePath = uri.toString();
        return _buildDirectImage(imagePath, alt ?? '');
      },
    );
  }

  /// Build video player widget with media_kit
  Widget _buildVideoPlayer(_VideoInfo video) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _MarkdownVideoPlayer(
          src: _resolvePath(video.src),
          width: video.width,
          height: video.height,
          caption: video.caption,
        ),
      ),
    );
  }

  /// Build image widget with explicit dimensions
  Widget _buildImageWithSize(_ImageInfo image) {
    final resolvedPath = _resolvePath(image.src);
    final isWeb =
        image.src.startsWith('http://') || image.src.startsWith('https://');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          width: image.width,
          height: image.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isWeb
                ? Image.network(
                    resolvedPath,
                    fit: BoxFit.contain,
                    semanticLabel: image.alt,
                    errorBuilder: (ctx, error, stack) =>
                        _buildImageError('Failed to load image'),
                  )
                : Image.file(
                    File(resolvedPath),
                    fit: BoxFit.contain,
                    semanticLabel: image.alt,
                    errorBuilder: (ctx, error, stack) =>
                        _buildImageError('Image not found'),
                  ),
          ),
        ),
      ),
    );
  }

  String _resolvePath(String path) {
    final isWebUrl = path.startsWith('http://') || path.startsWith('https://');
    final isAbsolutePath =
        path.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);

    if (!isWebUrl && !isAbsolutePath && _currentFilePath != null) {
      final lastSlash = _currentFilePath!.lastIndexOf('/');
      final lastBackslash = _currentFilePath!.lastIndexOf('\\');
      final lastSep = lastSlash > lastBackslash ? lastSlash : lastBackslash;

      if (lastSep > 0) {
        final mdDir = _currentFilePath!.substring(0, lastSep);
        final sep = lastBackslash > lastSlash ? '\\' : '/';
        return '$mdDir$sep$path';
      }
    }
    return path;
  }

  /// Build a simple image widget that handles path resolution
  Widget _buildDirectImage(String imagePath, String altText) {
    // Resolve the path
    var resolvedPath = imagePath;

    // Check if it's a web URL
    final isWebUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    // Check if it's an absolute path
    final isAbsolutePath =
        imagePath.startsWith('/') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(imagePath);

    if (!isWebUrl && !isAbsolutePath && _currentFilePath != null) {
      // Relative path - resolve against markdown file directory
      final lastSlash = _currentFilePath!.lastIndexOf('/');
      final lastBackslash = _currentFilePath!.lastIndexOf('\\');
      final lastSep = lastSlash > lastBackslash ? lastSlash : lastBackslash;

      if (lastSep > 0) {
        final mdDir = _currentFilePath!.substring(0, lastSep);
        final sep = lastBackslash > lastSlash ? '\\' : '/';
        resolvedPath = '$mdDir$sep$imagePath';
      }
    }

    log.info('Loading image - original: $imagePath, resolved: $resolvedPath');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImageWidget(resolvedPath, isWebUrl, altText),
          ),
        ),
      ),
    );
  }

  /// Build the actual image widget based on source type
  Widget _buildImageWidget(String path, bool isWeb, String altText) {
    if (isWeb) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        semanticLabel: altText,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 300,
            height: 200,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          log.warning('Failed to load web image: $path - $error');
          return _buildImageError('Failed to load image from web');
        },
      );
    }

    // Local file
    final file = File(path);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 300,
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data ?? false) {
          return Image.file(
            file,
            fit: BoxFit.contain,
            semanticLabel: altText,
            errorBuilder: (context, error, stackTrace) {
              log.warning('Failed to load local image: $path - $error');
              return _buildImageError('Failed to load image file');
            },
          );
        }

        log.warning('Image file not found: $path');
        return _buildImageError('Image not found: $path');
      },
    );
  }

  Widget _buildImageError(String message) {
    return Container(
      width: 300,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[500], size: 48),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
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
  alignLeft,
  alignCenter,
  alignRight,
  alignJustify,
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

/// Video info extracted from HTML video tags
class _VideoInfo {
  const _VideoInfo({
    required this.src,
    required this.width,
    required this.height,
    required this.caption,
    required this.placeholder,
  });

  final String src;
  final double width;
  final double height;
  final String caption;
  final String placeholder;
}

/// Image info extracted from HTML img tags
class _ImageInfo {
  const _ImageInfo({
    required this.src,
    required this.alt,
    required this.width,
    required this.height,
    required this.placeholder,
  });

  final String src;
  final String alt;
  final double width;
  final double height;
  final String placeholder;
}

/// Processed markdown data with extracted media
class _ProcessedMarkdown {
  const _ProcessedMarkdown({
    required this.content,
    required this.videos,
    required this.images,
  });

  final String content;
  final List<_VideoInfo> videos;
  final List<_ImageInfo> images;
}

/// Video player widget for markdown preview using media_kit
class _MarkdownVideoPlayer extends StatefulWidget {
  const _MarkdownVideoPlayer({
    required this.src,
    required this.width,
    required this.height,
    required this.caption,
  });

  final String src;
  final double width;
  final double height;
  final String caption;

  @override
  State<_MarkdownVideoPlayer> createState() => _MarkdownVideoPlayerState();
}

class _MarkdownVideoPlayerState extends State<_MarkdownVideoPlayer> {
  Player? _player;
  VideoController? _controller;
  var _isInitialized = false;
  var _isPlaying = false;
  var _position = Duration.zero;
  var _duration = Duration.zero;
  var _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final isWeb =
        widget.src.startsWith('http://') || widget.src.startsWith('https://');

    if (!isWeb) {
      final file = File(widget.src);
      if (!file.existsSync()) {
        return;
      }
    }

    _player = Player();
    _controller = VideoController(_player!);

    // Listen to player state
    _player!.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _player!.stream.position.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    _player!.stream.duration.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });

    await _player!.open(Media(widget.src), play: false);

    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _player?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player?.pause();
    } else {
      _player?.play();
    }
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _seekTo(double value) {
    _player?.seek(
      Duration(milliseconds: (value * _duration.inMilliseconds).round()),
    );
  }

  void _openFullscreen() {
    if (_player == null || _controller == null) return;

    showDialog(
      context: context,
      builder: (ctx) =>
          _FullscreenVideoDialog(player: _player!, controller: _controller!),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text('Loading video...', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Video
                Video(controller: _controller!, fit: BoxFit.contain),
                // Controls overlay
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _showControlsTemporarily,
                    child: MouseRegion(
                      onEnter: (_) => _showControlsTemporarily(),
                      child: AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Progress bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.grey[600],
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: _duration.inMilliseconds > 0
                                        ? _position.inMilliseconds /
                                              _duration.inMilliseconds
                                        : 0,
                                    onChanged: _seekTo,
                                  ),
                                ),
                              ),
                              // Controls row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: Row(
                                  children: [
                                    // Play/Pause
                                    IconButton(
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      onPressed: _togglePlay,
                                    ),
                                    // Time
                                    Text(
                                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    // Fullscreen
                                    IconButton(
                                      icon: const Icon(
                                        Icons.fullscreen,
                                        color: Colors.white,
                                      ),
                                      onPressed: _openFullscreen,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Center play button when paused
                if (!_isPlaying && _showControls)
                  Positioned.fill(
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white,
                          size: 64,
                        ),
                        onPressed: _togglePlay,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Caption
        if (widget.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.caption,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Fullscreen video dialog
class _FullscreenVideoDialog extends StatelessWidget {
  const _FullscreenVideoDialog({
    required this.player,
    required this.controller,
  });

  final Player player;
  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Video(controller: controller, fit: BoxFit.contain),
          ),
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
