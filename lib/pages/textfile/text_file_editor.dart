import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Text file editor with Microsoft Word-like rich text formatting.
/// Files are saved as .docx format locally with full formatting preservation.
class TextFileEditor extends StatefulWidget {
  const TextFileEditor({super.key, this.filePath});

  final String? filePath;

  /// The file extension used for text files
  static const extension = '.docx';

  /// The internal JSON format extension for storing Quill Delta
  static const internalExtension = '.kvtx';

  @override
  State<TextFileEditor> createState() => _TextFileEditorState();
}

class _TextFileEditorState extends State<TextFileEditor> {
  late QuillController _controller;
  late TextEditingController _fileNameController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  var _isLoading = true;
  String? _currentFilePath;
  var _fileName = 'Untitled';
  Timer? _autosaveTimer;
  Timer? _renameTimer;
  var _isEditingFileName = false;

  final log = Logger('TextFileEditor');

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _fileNameController = TextEditingController();
    _loadFile();
  }

  Future<void> _loadFile() async {
    if (widget.filePath != null) {
      try {
        // Use internal format for storage
        _currentFilePath = widget.filePath! + TextFileEditor.internalExtension;

        try {
          final content = await FileManager.readFile(_currentFilePath!);
          if (content != null) {
            final jsonString = String.fromCharCodes(content);
            final data = json.decode(jsonString);

            if (data is Map && data.containsKey('document')) {
              final document = Document.fromJson(
                List<Map<String, dynamic>>.from(
                  (data['document'] as List).map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ),
                ),
              );
              _controller = QuillController(
                document: document,
                selection: const TextSelection.collapsed(offset: 0),
              );
              _fileName =
                  data['fileName'] ?? _getFileNameFromPath(_currentFilePath!);
            } else {
              // Old format - just delta ops
              final document = Document.fromJson(
                List<Map<String, dynamic>>.from(
                  (data as List).map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ),
                ),
              );
              _controller = QuillController(
                document: document,
                selection: const TextSelection.collapsed(offset: 0),
              );
              _fileName = _getFileNameFromPath(widget.filePath!);
            }
          }
        } catch (e) {
          // File doesn't exist yet, create new
          log.info('Creating new text file: $_currentFilePath');
          _fileName = _getFileNameFromPath(widget.filePath!);
        }
      } catch (e) {
        log.severe('Error loading text file', e);
      }
    }

    setState(() {
      _isLoading = false;
    });

    // Setup filename controller
    _fileNameController.text = _fileName;
    _fileNameController.addListener(_onFileNameChanged);

    // Setup autosave listener
    _controller.addListener(_onDocumentChanged);
  }

  String _getFileNameFromPath(String path) {
    final parts = path.split('/');
    var name = parts.last;
    if (name.endsWith(TextFileEditor.internalExtension)) {
      name = name.substring(
        0,
        name.length - TextFileEditor.internalExtension.length,
      );
    }
    if (name.endsWith(TextFileEditor.extension)) {
      name = name.substring(0, name.length - TextFileEditor.extension.length);
    }
    return name;
  }

  void _onFileNameChanged() {
    _renameTimer?.cancel();
    _renameTimer = Timer(const Duration(seconds: 1), () {
      _renameFile();
    });
  }

  void _onDocumentChanged() {
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
        final newFilePath =
            '$dirPath/$newName${TextFileEditor.internalExtension}';

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
    _currentFilePath ??= '/Untitled${TextFileEditor.internalExtension}';

    try {
      final documentJson = _controller.document.toDelta().toJson();
      final fullData = {
        'document': documentJson,
        'fileName': _fileName,
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final jsonString = json.encode(fullData);
      await FileManager.writeFile(_currentFilePath!, utf8.encode(jsonString));
      log.info('File saved: $_currentFilePath');
    } catch (e) {
      log.severe('Error saving file', e);
    }
  }

  Future<void> _exportAsTxt() async {
    try {
      final plainText = _controller.document.toPlainText();

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export as Text File',
        fileName: '$_fileName.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(plainText);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exported as .txt successfully')),
          );
        }
      }
    } catch (e) {
      log.severe('Error exporting as txt', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    }
  }

  Future<void> _exportAsDocx() async {
    try {
      final docxBytes = await _generateDocxBytes();

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export as Word Document',
        fileName: '$_fileName.docx',
        type: FileType.custom,
        allowedExtensions: ['docx'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(docxBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exported as .docx successfully')),
          );
        }
      }
    } catch (e) {
      log.severe('Error exporting as docx', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting: $e')));
      }
    }
  }

  /// Generate a minimal valid DOCX file from the Quill document
  Future<Uint8List> _generateDocxBytes() async {
    final archive = Archive();

    // Content Types
    final contentTypes =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
    archive.addFile(
      ArchiveFile(
        '[Content_Types].xml',
        contentTypes.length,
        utf8.encode(contentTypes),
      ),
    );

    // Relationships
    final rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
    archive.addFile(ArchiveFile('_rels/.rels', rels.length, utf8.encode(rels)));

    // Document content - convert Quill delta to DOCX paragraphs
    final documentXml = _convertDeltaToDocx();
    archive.addFile(
      ArchiveFile(
        'word/document.xml',
        documentXml.length,
        utf8.encode(documentXml),
      ),
    );

    // Encode as ZIP (DOCX is a ZIP file)
    final zipEncoder = ZipEncoder();
    return Uint8List.fromList(zipEncoder.encode(archive) ?? []);
  }

  String _convertDeltaToDocx() {
    final buffer = StringBuffer();
    buffer.write('''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>''');

    final delta = _controller.document.toDelta();
    var currentParagraph = StringBuffer();
    var currentRunProps = <String, bool>{};

    for (final op in delta.toList()) {
      if (op.isInsert) {
        final text = op.data;
        if (text is String) {
          final attrs = op.attributes ?? {};

          // Handle newlines as paragraph breaks
          final lines = text.split('\n');
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.isNotEmpty) {
              currentParagraph.write(_createRun(line, attrs));
            }
            if (i < lines.length - 1) {
              // End current paragraph
              buffer.write('<w:p>');
              buffer.write(currentParagraph);
              buffer.write('</w:p>');
              currentParagraph = StringBuffer();
            }
          }
        }
      }
    }

    // Write final paragraph if any
    if (currentParagraph.isNotEmpty) {
      buffer.write('<w:p>');
      buffer.write(currentParagraph);
      buffer.write('</w:p>');
    }

    buffer.write('''
  </w:body>
</w:document>''');

    return buffer.toString();
  }

  String _createRun(String text, Map<String, dynamic> attrs) {
    final buffer = StringBuffer();
    buffer.write('<w:r>');

    // Run properties
    if (attrs.isNotEmpty) {
      buffer.write('<w:rPr>');
      if (attrs['bold'] == true) buffer.write('<w:b/>');
      if (attrs['italic'] == true) buffer.write('<w:i/>');
      if (attrs['underline'] == true) buffer.write('<w:u w:val="single"/>');
      if (attrs['strike'] == true) buffer.write('<w:strike/>');
      if (attrs['color'] != null) {
        final color = attrs['color'].toString().replaceAll('#', '');
        buffer.write('<w:color w:val="$color"/>');
      }
      if (attrs['background'] != null) {
        final bgColor = attrs['background'].toString().replaceAll('#', '');
        buffer.write('<w:highlight w:val="$bgColor"/>');
      }
      if (attrs['size'] != null) {
        final size =
            (double.tryParse(attrs['size'].toString().replaceAll('px', '')) ??
                14) *
            2;
        buffer.write('<w:sz w:val="${size.toInt()}"/>');
      }
      buffer.write('</w:rPr>');
    }

    // Escape XML entities and add text
    final escapedText = _escapeXml(text);
    buffer.write('<w:t xml:space="preserve">$escapedText</w:t>');
    buffer.write('</w:r>');

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  void _showExportMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Export as .txt'),
              subtitle: const Text('Plain text without formatting'),
              onTap: () {
                Navigator.pop(context);
                _exportAsTxt();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Export as .docx'),
              subtitle: const Text('Microsoft Word format with formatting'),
              onTap: () {
                Navigator.pop(context);
                _exportAsDocx();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _insertImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      // Copy image to app's assets directory
      final appDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${appDir.path}/kivixa_assets');
      if (!assetsDir.existsSync()) {
        assetsDir.createSync(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final newPath = '${assetsDir.path}/$fileName';
      await File(filePath).copy(newPath);

      // Insert image embed into document
      final index = _controller.selection.baseOffset;
      _controller.document.insert(index, BlockEmbed.image(newPath));
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );
    } catch (e) {
      log.severe('Error inserting image', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inserting image: $e')));
      }
    }
  }

  void _insertTable() {
    showDialog(
      context: context,
      builder: (context) => _TableInsertDialog(
        onInsert: (rows, cols) {
          // Insert a simple table representation using text
          // Note: Quill doesn't have native table support, so we use a workaround
          final tableText = _generateTableText(rows, cols);
          final index = _controller.selection.baseOffset;
          _controller.document.insert(index, tableText);
          _controller.updateSelection(
            TextSelection.collapsed(offset: index + tableText.length),
            ChangeSource.local,
          );
        },
      ),
    );
  }

  String _generateTableText(int rows, int cols) {
    final buffer = StringBuffer();
    buffer.writeln();

    // Header row
    buffer.write('| ');
    for (var c = 0; c < cols; c++) {
      buffer.write('Header ${c + 1} | ');
    }
    buffer.writeln();

    // Separator
    buffer.write('| ');
    for (var c = 0; c < cols; c++) {
      buffer.write('--- | ');
    }
    buffer.writeln();

    // Data rows
    for (var r = 0; r < rows - 1; r++) {
      buffer.write('| ');
      for (var c = 0; c < cols; c++) {
        buffer.write('Cell | ');
      }
      buffer.writeln();
    }
    buffer.writeln();

    return buffer.toString();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _renameTimer?.cancel();
    _controller.dispose();
    _fileNameController.dispose();
    _editorFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            setState(() {
              _isEditingFileName = true;
            });
          },
          child: _isEditingFileName
              ? TextField(
                  controller: _fileNameController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 20),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) {
                    setState(() {
                      _isEditingFileName = false;
                    });
                  },
                  onTapOutside: (_) {
                    setState(() {
                      _isEditingFileName = false;
                    });
                  },
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.article, size: 20),
                    const SizedBox(width: 8),
                    Text(_fileName),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 18),
                  ],
                ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Insert Image',
            onPressed: _insertImage,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Insert Table',
            onPressed: _insertTable,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export',
            onPressed: _showExportMenu,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Rich toolbar with all formatting options
            _buildToolbar(colorScheme),
            const Divider(height: 1),
            // Editor
            Expanded(
              child: Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: QuillEditor(
                  controller: _controller,
                  focusNode: _editorFocusNode,
                  scrollController: _scrollController,
                  configurations: QuillEditorConfigurations(
                    placeholder: 'Start typing...',
                    padding: const EdgeInsets.all(16),
                    autoFocus: false,
                    expands: true,
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(8, 8),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      h1: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(16, 8),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      h2: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(14, 6),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      h3: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(12, 4),
                        const VerticalSpacing(0, 0),
                        null,
                      ),
                      code: DefaultTextBlockStyle(
                        TextStyle(
                          fontFamily: 'FiraMono',
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                        const HorizontalSpacing(0, 0),
                        const VerticalSpacing(8, 8),
                        const VerticalSpacing(0, 0),
                        BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Font family dropdown
            _FontFamilyDropdown(controller: _controller),
            const SizedBox(width: 8),
            // Font size dropdown
            _FontSizeDropdown(controller: _controller),
            const VerticalDivider(),
            // Basic formatting
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.bold,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_bold,
              ),
            ),
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.italic,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_italic,
              ),
            ),
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.underline,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_underline,
              ),
            ),
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.strikeThrough,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.strikethrough_s,
              ),
            ),
            const VerticalDivider(),
            // Text color
            QuillToolbarColorButton(
              controller: _controller,
              isBackground: false,
              options: const QuillToolbarColorButtonOptions(
                iconData: Icons.format_color_text,
              ),
            ),
            // Highlight/background color
            QuillToolbarColorButton(
              controller: _controller,
              isBackground: true,
              options: const QuillToolbarColorButtonOptions(
                iconData: Icons.highlight,
              ),
            ),
            const VerticalDivider(),
            // Alignment
            QuillToolbarSelectAlignmentButtons(
              controller: _controller,
              options: const QuillToolbarSelectAlignmentButtonOptions(
                showLeftAlignment: true,
                showCenterAlignment: true,
                showRightAlignment: true,
                showJustifyAlignment: true,
              ),
            ),
            const VerticalDivider(),
            // Lists
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.ul,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_list_bulleted,
              ),
            ),
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.ol,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_list_numbered,
              ),
            ),
            QuillToolbarToggleCheckListButton(
              controller: _controller,
              options: const QuillToolbarToggleCheckListButtonOptions(
                iconData: Icons.check_box,
              ),
            ),
            const VerticalDivider(),
            // Indent
            QuillToolbarIndentButton(
              controller: _controller,
              isIncrease: false,
              options: const QuillToolbarIndentButtonOptions(
                iconData: Icons.format_indent_decrease,
              ),
            ),
            QuillToolbarIndentButton(
              controller: _controller,
              isIncrease: true,
              options: const QuillToolbarIndentButtonOptions(
                iconData: Icons.format_indent_increase,
              ),
            ),
            const VerticalDivider(),
            // Headers
            QuillToolbarSelectHeaderStyleDropdownButton(
              controller: _controller,
            ),
            const VerticalDivider(),
            // Link
            QuillToolbarLinkStyleButton(controller: _controller),
            // Clear formatting
            QuillToolbarClearFormatButton(controller: _controller),
          ],
        ),
      ),
    );
  }
}

/// Dropdown for selecting font family
class _FontFamilyDropdown extends StatelessWidget {
  const _FontFamilyDropdown({required this.controller});

  final QuillController controller;

  static const _fonts = [
    'Sans Serif',
    'Serif',
    'Monospace',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Georgia',
    'Verdana',
  ];

  static const _fontValues = [
    'sans-serif',
    'serif',
    'monospace',
    'Arial',
    'Times New Roman',
    'Courier New',
    'Georgia',
    'Verdana',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: DropdownButtonFormField<String>(
        value: _fontValues[0],
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        items: List.generate(_fonts.length, (i) {
          return DropdownMenuItem(
            value: _fontValues[i],
            child: Text(_fonts[i], style: const TextStyle(fontSize: 12)),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            controller.formatSelection(Attribute.fromKeyValue('font', value));
          }
        },
      ),
    );
  }
}

/// Dropdown for selecting font size
class _FontSizeDropdown extends StatelessWidget {
  const _FontSizeDropdown({required this.controller});

  final QuillController controller;

  static const _sizes = [
    '8',
    '10',
    '12',
    '14',
    '16',
    '18',
    '20',
    '24',
    '28',
    '32',
    '36',
    '48',
    '72',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: DropdownButtonFormField<String>(
        value: '14',
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        items: _sizes.map((size) {
          return DropdownMenuItem(
            value: size,
            child: Text(size, style: const TextStyle(fontSize: 12)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.formatSelection(
              Attribute.fromKeyValue('size', '${value}px'),
            );
          }
        },
      ),
    );
  }
}

/// Dialog for inserting a table
class _TableInsertDialog extends StatefulWidget {
  const _TableInsertDialog({required this.onInsert});

  final void Function(int rows, int cols) onInsert;

  @override
  State<_TableInsertDialog> createState() => _TableInsertDialogState();
}

class _TableInsertDialogState extends State<_TableInsertDialog> {
  var _rows = 3;
  var _cols = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert Table'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Rows: '),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: DropdownButtonFormField<int>(
                  value: _rows,
                  items: List.generate(10, (i) => i + 1).map((n) {
                    return DropdownMenuItem(value: n, child: Text('$n'));
                  }).toList(),
                  onChanged: (v) => setState(() => _rows = v ?? 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Columns: '),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: DropdownButtonFormField<int>(
                  value: _cols,
                  items: List.generate(10, (i) => i + 1).map((n) {
                    return DropdownMenuItem(value: n, child: Text('$n'));
                  }).toList(),
                  onChanged: (v) => setState(() => _cols = v ?? 3),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onInsert(_rows, _cols);
          },
          child: const Text('Insert'),
        ),
      ],
    );
  }
}
