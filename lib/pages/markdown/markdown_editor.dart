import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({super.key, this.filePath});

  final String? filePath;

  static const String extension = '.md';

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late TabController _tabController;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  String? _currentFilePath;
  String _fileName = 'Untitled';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
        final file = FileManager.getFile(_currentFilePath!);
        
        if (await file.exists()) {
          final content = await file.readAsString();
          _controller.text = content;
          _fileName = _getFileNameFromPath(_currentFilePath!);
        } else {
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

    _controller.addListener(() {
      if (!_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = true;
        });
      }
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
    if (_currentFilePath == null) {
      _currentFilePath = await FileManager.newFilePath(
        '/$_fileName',
        extension: MarkdownEditor.extension,
      );
    }

    try {
      await FileManager.writeFile(
        _currentFilePath!,
        _controller.text.codeUnits,
        awaitWrite: true,
      );

      setState(() {
        _hasUnsavedChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Markdown file saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName),
        actions: [
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveFile,
              tooltip: 'Save',
            ),
        ],
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
        children: [
          _buildEditor(),
          _buildPreview(),
        ],
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
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'FiraMono',
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Markdown(
      data: _controller.text,
      selectable: true,
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
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
        tableHead: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        tableBody: const TextStyle(),
        tableBorder: TableBorder.all(
          color: const Color(0xFFe1e4e8),
          width: 1,
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
    );
  }
}
