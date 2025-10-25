import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({super.key});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late TabController _tabController;
  var _markdownText = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller.addListener(() {
      setState(() {
        _markdownText = _controller.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveMarkdown() async {
    try {
      final String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Markdown File',
        fileName: 'markdown.md',
        allowedExtensions: ['md'],
      );

      if (filePath != null) {
        final File file = File(filePath);
        await file.writeAsString(_markdownText);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Markdown file saved successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markdownConfig = MarkdownConfig(
      configs: [
        H1Config(
          style: GoogleFonts.lato(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.lightBlue,
          ),
        ),
        H2Config(
          style: GoogleFonts.lato(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.lightGreen,
          ),
        ),
        H3Config(
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orangeAccent,
          ),
        ),
        H4Config(
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.purpleAccent,
          ),
        ),
        H5Config(
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
        H6Config(
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.tealAccent,
          ),
        ),
        CodeConfig(
          style: GoogleFonts.robotoMono(
            backgroundColor: Colors.grey.shade200,
            color: Colors.black,
          ),
        ),
        PreConfig(
          decoration: BoxDecoration(
            color: const Color(0xff1e1e1e),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        TableConfig(
          border: TableBorder.all(color: Colors.grey.shade400, width: 1),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown Editor'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveMarkdown),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Editor'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Enter your markdown here...',
                border: InputBorder.none,
              ),
            ),
          ),
          MarkdownWidget(data: _markdownText, config: markdownConfig),
        ],
      ),
    );
  }
}
