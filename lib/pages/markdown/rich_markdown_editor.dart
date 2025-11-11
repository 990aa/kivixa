import 'dart:async';
import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:logging/logging.dart';

class TextBoxData {
  String id;
  Offset position;
  Size size;
  String text;
  TextEditingController controller;

  TextBoxData({
    required this.id,
    required this.position,
    required this.size,
    required this.text,
  }) : controller = TextEditingController(text: text);

  void dispose() {
    controller.dispose();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': position.dx,
    'y': position.dy,
    'width': size.width,
    'height': size.height,
    'text': text,
  };

  factory TextBoxData.fromJson(Map<String, dynamic> json) {
    return TextBoxData(
      id: json['id'],
      position: Offset(json['x'], json['y']),
      size: Size(json['width'], json['height']),
      text: json['text'],
    );
  }
}

class RichMarkdownEditor extends StatefulWidget {
  const RichMarkdownEditor({super.key, this.filePath});

  final String? filePath;

  static const extension = '.md';

  @override
  State<RichMarkdownEditor> createState() => _RichMarkdownEditorState();
}

class _RichMarkdownEditorState extends State<RichMarkdownEditor> {
  late EditorState _editorState;
  late TextEditingController _fileNameController;
  var _isLoading = true;
  String? _currentFilePath;
  var _fileName = 'Untitled';
  Timer? _autosaveTimer;
  Timer? _renameTimer;
  final log = Logger('RichMarkdownEditor');

  // Text box tool state
  final List<TextBoxData> _textBoxes = [];
  var _textBoxMode = false;
  final GlobalKey _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController();
    _editorState = EditorState.blank();
    _loadFile();
  }

  Future<void> _loadFile() async {
    if (widget.filePath != null) {
      try {
        _currentFilePath = widget.filePath! + RichMarkdownEditor.extension;

        try {
          final content = await FileManager.readFile(_currentFilePath!);
          if (content != null) {
            final jsonString = String.fromCharCodes(content);
            final data = json.decode(jsonString);

            // Handle new format with document and textBoxes
            if (data is Map && data.containsKey('document')) {
              final document = Document.fromJson(
                Map<String, Object>.from(data['document']),
              );
              _editorState = EditorState(document: document);

              // Load text boxes if available
              if (data.containsKey('textBoxes')) {
                for (final boxJson in data['textBoxes']) {
                  _textBoxes.add(
                    TextBoxData.fromJson(Map<String, dynamic>.from(boxJson)),
                  );
                }
              }
            } else {
              // Handle old format (just document)
              final document = Document.fromJson(
                Map<String, Object>.from(data),
              );
              _editorState = EditorState(document: document);
            }

            _fileName = _getFileNameFromPath(_currentFilePath!);
          }
        } catch (e) {
          // File doesn't exist or is in old format, create new editor
          _currentFilePath = widget.filePath! + RichMarkdownEditor.extension;
          _fileName = _getFileNameFromPath(widget.filePath!);
          _editorState = EditorState.blank();
          log.info('Creating new markdown file: $_currentFilePath');
        }
      } catch (e) {
        log.severe('Error loading markdown file', e);
      }
    }

    setState(() {
      _isLoading = false;
    });

    // Setup filename controller
    _fileNameController.text = _fileName;
    _fileNameController.addListener(_onFileNameChanged);

    // Setup autosave listener on editor changes
    _editorState.transactionStream.listen((_) {
      _onEditorChanged();
    });
  }

  String _getFileNameFromPath(String path) {
    final parts = path.split('/');
    var name = parts.last;
    if (name.endsWith(RichMarkdownEditor.extension)) {
      name = name.substring(
        0,
        name.length - RichMarkdownEditor.extension.length,
      );
    }
    return name;
  }

  void _onFileNameChanged() {
    _renameTimer?.cancel();
    _renameTimer = Timer(const Duration(seconds: 1), () {
      _renameFile();
    });
  }

  void _onEditorChanged() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      _saveFile();
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
        final newFilePath = '$dirPath/$newName${RichMarkdownEditor.extension}';

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
    _currentFilePath ??= '/Untitled${RichMarkdownEditor.extension}';

    try {
      final documentJson = _editorState.document.toJson();
      final textBoxesJson = _textBoxes.map((tb) => tb.toJson()).toList();

      final fullData = {'document': documentJson, 'textBoxes': textBoxesJson};

      final jsonString = json.encode(fullData);
      await FileManager.writeFile(_currentFilePath!, utf8.encode(jsonString));
      log.info('File saved: $_currentFilePath');
    } catch (e) {
      log.severe('Error saving file', e);
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _renameTimer?.cancel();
    _fileNameController.dispose();
    _editorState.dispose();
    for (final textBox in _textBoxes) {
      textBox.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            // Select all text when tapped
            _fileNameController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _fileNameController.text.length,
            );
          },
          child: IntrinsicWidth(
            child: TextField(
              controller: _fileNameController,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar
            _buildToolbar(),
            const Divider(height: 1),
            // Editor with text box overlay
            Expanded(
              child: Stack(
                key: _stackKey,
                children: [
                  // Main editor (only interactable when NOT in text box mode)
                  IgnorePointer(
                    ignoring: _textBoxMode,
                    child: AppFlowyEditor(
                      editorState: _editorState,
                      editorStyle: _buildEditorStyle(context),
                    ),
                  ),
                  // Clickable overlay for creating text boxes (only in text box mode)
                  if (_textBoxMode)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (details) {
                          _addTextBox(details.localPosition);
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  // Text boxes stack (always visible when there are text boxes)
                  ...(_textBoxes.map((textBox) => _buildTextBox(textBox))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: 'Bold',
              onPressed: () => _formatText(BuiltInAttributeKey.bold),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: 'Italic',
              onPressed: () => _formatText(BuiltInAttributeKey.italic),
            ),
            _ToolbarButton(
              icon: Icons.format_underlined,
              tooltip: 'Underline',
              onPressed: () => _formatText(BuiltInAttributeKey.underline),
            ),
            _ToolbarButton(
              icon: Icons.strikethrough_s,
              tooltip: 'Strikethrough',
              onPressed: () => _formatText(BuiltInAttributeKey.strikethrough),
            ),
            const VerticalDivider(),
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: 'Bullet List',
              onPressed: () => _formatBlock(BulletedListBlockKeys.type),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: 'Numbered List',
              onPressed: () => _formatBlock(NumberedListBlockKeys.type),
            ),
            _ToolbarButton(
              icon: Icons.check_box_outlined,
              tooltip: 'Checklist',
              onPressed: () => _formatBlock(TodoListBlockKeys.type),
            ),
            const VerticalDivider(),
            _ToolbarButton(
              icon: Icons.format_quote,
              tooltip: 'Quote',
              onPressed: () => _formatBlock(QuoteBlockKeys.type),
            ),
            _ToolbarButton(
              icon: Icons.code,
              tooltip: 'Code Block',
              onPressed: () => _formatBlock('code'),
            ),
            const VerticalDivider(),
            _ToolbarButton(
              icon: Icons.link,
              tooltip: 'Insert Link',
              onPressed: _insertLink,
            ),
            const VerticalDivider(),
            _ToolbarButton(
              icon: Icons.text_fields,
              tooltip: 'Text Box Tool',
              onPressed: _toggleTextBoxMode,
              isActive: _textBoxMode,
            ),
          ],
        ),
      ),
    );
  }

  void _formatText(String attribute) {
    final selection = _editorState.selection;
    if (selection == null) return;

    _editorState.formatDelta(selection, {attribute: true});
  }

  void _formatBlock(String blockType) {
    final selection = _editorState.selection;
    if (selection == null) return;

    _editorState.formatNode(selection, (node) {
      return node.copyWith(type: blockType);
    });
  }

  void _insertLink() {
    // Show dialog to insert link
    showDialog(
      context: context,
      builder: (context) => _LinkDialog(
        onInsert: (text, url) {
          final selection = _editorState.selection;
          if (selection == null) return;

          _editorState.insertTextAtCurrentSelection(text);
          _editorState.formatDelta(selection, {BuiltInAttributeKey.href: url});
        },
      ),
    );
  }

  void _toggleTextBoxMode() {
    setState(() {
      _textBoxMode = !_textBoxMode;
    });
  }

  void _addTextBox(Offset position) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final textBox = TextBoxData(
      id: id,
      position: position,
      size: const Size(200, 100),
      text: '',
    );

    setState(() {
      _textBoxes.add(textBox);
    });

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), _saveFile);
  }

  void _updateTextBox(String id, {Offset? position, Size? size, String? text}) {
    final index = _textBoxes.indexWhere((tb) => tb.id == id);
    if (index == -1) return;

    setState(() {
      if (position != null) _textBoxes[index].position = position;
      if (size != null) _textBoxes[index].size = size;
      if (text != null) {
        _textBoxes[index].text = text;
        _textBoxes[index].controller.text = text;
      }
    });

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), _saveFile);
  }

  void _deleteTextBox(String id) {
    final index = _textBoxes.indexWhere((tb) => tb.id == id);
    if (index == -1) return;

    setState(() {
      _textBoxes[index].dispose();
      _textBoxes.removeAt(index);
    });

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), _saveFile);
  }

  Widget _buildTextBox(TextBoxData textBox) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned(
      left: textBox.position.dx,
      top: textBox.position.dy,
      child: GestureDetector(
        // Allow dragging only when NOT in text box mode
        onPanUpdate: _textBoxMode
            ? null
            : (details) {
                _updateTextBox(
                  textBox.id,
                  position: textBox.position + details.delta,
                );
              },
        // Prevent text box from intercepting clicks meant for creating new text boxes
        behavior: _textBoxMode
            ? HitTestBehavior.deferToChild
            : HitTestBehavior.translucent,
        child: Container(
          width: textBox.size.width,
          height: textBox.size.height,
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.9),
            border: Border.all(
              color: _textBoxMode
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.5),
              width: _textBoxMode ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Text field (editable only in text box mode)
              if (_textBoxMode)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: textBox.controller,
                    maxLines: null,
                    expands: true,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: theme.textTheme.bodyMedium,
                    onChanged: (value) {
                      _updateTextBox(textBox.id, text: value);
                    },
                  ),
                )
              else
                // Read-only text display
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(textBox.text, style: theme.textTheme.bodyMedium),
                ),

              // Resize handle (only visible in text box mode)
              if (_textBoxMode)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final newWidth = textBox.size.width + details.delta.dx;
                      final newHeight = textBox.size.height + details.delta.dy;
                      _updateTextBox(
                        textBox.id,
                        size: Size(
                          newWidth.clamp(100, 800),
                          newHeight.clamp(50, 600),
                        ),
                      );
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      child: Icon(
                        Icons.drag_handle,
                        size: 16,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),

              // Delete button (only visible in text box mode)
              if (_textBoxMode)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 16, color: colorScheme.error),
                    onPressed: () => _deleteTextBox(textBox.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  EditorStyle _buildEditorStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EditorStyle.desktop(
      padding: const EdgeInsets.all(16),
      cursorColor: colorScheme.primary,
      selectionColor: colorScheme.primary.withValues(alpha: 0.3),
      textStyleConfiguration: TextStyleConfiguration(
        text: TextStyle(fontSize: 16, color: colorScheme.onSurface),
        bold: const TextStyle(fontWeight: FontWeight.bold),
        italic: const TextStyle(fontStyle: FontStyle.italic),
        underline: const TextStyle(decoration: TextDecoration.underline),
        strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
        href: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      style: isActive
          ? IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }
}

class _LinkDialog extends StatefulWidget {
  const _LinkDialog({required this.onInsert});

  final void Function(String text, String url) onInsert;

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late TextEditingController _textController;
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Link Text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        TextButton(
          onPressed: () {
            widget.onInsert(_textController.text, _urlController.text);
            Navigator.of(context).pop();
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}
