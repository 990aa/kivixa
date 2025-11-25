import 'dart:async';

import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/i18n/strings.g.dart';
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
      await FileManager.writeFile(
        _currentFilePath!,
        controller.text.codeUnits,
        awaitWrite: true,
      );
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

  void _formatText(_FormatType type) {
    final controller = _codeController;
    if (controller == null) return;

    final selection = controller.selection;
    // Guard against invalid selection
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
        _showLinkDialog();
        return;
      case _FormatType.image:
        _showImageDialog();
        return;
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
              final start = selection.start;
              final end = selection.end;

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
    final controller = _codeController;
    if (controller == null) return;

    final altController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: altController,
              decoration: const InputDecoration(
                labelText: 'Alt Text',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
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
              final altText = altController.text.isEmpty
                  ? 'Image'
                  : altController.text;
              final url = urlController.text;
              final mdImage = '![$altText]($url)';

              final selection = controller.selection;
              final text = controller.text;
              final start = selection.start;
              final end = selection.end;

              controller.text = text.replaceRange(start, end, mdImage);
              controller.selection = TextSelection.collapsed(
                offset: start + mdImage.length,
              );

              Navigator.pop(ctx);
            },
            child: const Text('Insert'),
          ),
        ],
      ),
    );
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Edit'),
            Tab(icon: Icon(Icons.preview), text: 'Preview'),
            Tab(icon: Icon(Icons.splitscreen), text: 'Split'),
          ],
        ),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _saveFile,
          ),
        ],
      ),
      body: Column(
        children: [
          // Formatting toolbar
          _buildToolbar(colorScheme),
          const Divider(height: 1),

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
            width: 48,
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
        ),
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
