import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key, this.filePath});

  final String? filePath;

  static const extension = '.md';

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late TextEditingController _fileNameController;
  late TabController _tabController;
  var _isLoading = true;
  String? _currentFilePath;
  var _fileName = 'Untitled';
  Timer? _autosaveTimer;
  Timer? _renameTimer;
  var _isEditingFileName = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _fileNameController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes
    });
    _loadFile();
  }

  Future<void> _loadFile() async {
    if (widget.filePath != null) {
      try {
        _currentFilePath = widget.filePath! + MarkdownEditor.extension;

        try {
          final content = await FileManager.readFile(_currentFilePath!);
          if (content != null) {
            _controller.text = String.fromCharCodes(content);
            _fileName = _getFileNameFromPath(_currentFilePath!);
          }
        } catch (e) {
          // File doesn't exist yet, that's okay
          _currentFilePath = widget.filePath! + MarkdownEditor.extension;
          _fileName = _getFileNameFromPath(widget.filePath!);
        }
      } catch (e) {
        debugPrint('Error loading markdown file: $e');
      }
    }

    setState(() {
      _isLoading = false;
    });

    // Setup filename controller
    _fileNameController.text = _fileName;
    _fileNameController.addListener(_onFileNameChanged);

    // Setup autosave listener
    _controller.addListener(_onTextChanged);
  }

  void _onFileNameChanged() {
    // Cancel existing rename timer
    _renameTimer?.cancel();

    // Start new timer for rename (1 second after user stops typing)
    _renameTimer = Timer(const Duration(seconds: 1), () {
      _renameFile();
    });
  }

  Future<void> _renameFile() async {
    final newName = _fileNameController.text.trim();
    if (newName.isEmpty || newName == _fileName) return;

    try {
      if (_currentFilePath != null) {
        // Get the directory path
        final parts = _currentFilePath!.split('/');
        parts.removeLast(); // Remove old filename
        final dirPath = parts.join('/');

        // Create new file path
        final newFilePath = '$dirPath/$newName${MarkdownEditor.extension}';

        // Move the file
        final actualNewPath = await FileManager.moveFile(
          _currentFilePath!,
          newFilePath,
        );

        _currentFilePath = actualNewPath;
        _fileName = newName;

        setState(() {});
      } else {
        // File hasn't been created yet, just update the name
        _fileName = newName;
      }
    } catch (e) {
      debugPrint('Error renaming file: $e');
      // Revert the filename on error
      _fileNameController.text = _fileName;
    }
  }

  void _onTextChanged() {
    // Cancel existing timer
    _autosaveTimer?.cancel();

    // Start new timer for autosave (2 seconds after user stops typing)
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      _saveFile();
    });
  }

  String _getFileNameFromPath(String path) {
    final parts = path.split('/');
    final nameWithExt = parts.last;
    if (nameWithExt.endsWith(MarkdownEditor.extension)) {
      return nameWithExt.substring(
        0,
        nameWithExt.length - MarkdownEditor.extension.length,
      );
    }
    return nameWithExt;
  }

  Future<void> _saveFile() async {
    _currentFilePath ??=
        '${await FileManager.newFilePath('/')}$_fileName${MarkdownEditor.extension}';

    try {
      await FileManager.writeFile(
        _currentFilePath!,
        _controller.text.codeUnits,
        awaitWrite: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _renameTimer?.cancel();
    _controller.dispose();
    _fileNameController.dispose();
    _tabController.dispose();
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
                    Text(_fileName),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 18),
                  ],
                ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit), text: 'Edit'),
            Tab(icon: Icon(Icons.preview), text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildEditor(), _buildPreview()],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: 'Start typing markdown here...',
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 16, fontFamily: 'FiraMono'),
      ),
    );
  }

  Widget _buildPreview() {
    return Markdown(
      data: _controller.text,
      selectable: true,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [md.EmojiSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
      ),
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        h2: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
        h3: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.lightBlue,
        ),
        h4: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.cyan,
        ),
        h5: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
        h6: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        code: const TextStyle(
          fontFamily: 'FiraMono',
          backgroundColor: Color(0xFFf5f5f5),
          color: Color(0xFFd73a49),
        ),
        codeblockDecoration: BoxDecoration(
          color: const Color(0xFFf6f8fa),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFe1e4e8)),
        ),
        blockquote: const TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        tableHead: const TextStyle(fontWeight: FontWeight.bold),
        tableBody: const TextStyle(),
        tableBorder: TableBorder.all(color: const Color(0xFFe1e4e8), width: 1),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
    );
  }
}
