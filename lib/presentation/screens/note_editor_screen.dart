// lib/presentation/screens/note_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/note.dart';
import '../widgets/canvas_widget.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/page_sidebar.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final TransformationController _transformationController = TransformationController();
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _showSidebar = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sidebar),
            onPressed: () => setState(() => _showSidebar = !_showSidebar),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
          ),
        ],
      ),
      body: Row(
        children: [
          if (_showSidebar) 
            PageSidebar(
              note: widget.note,
              currentPageIndex: _currentPageIndex,
              onPageSelected: (index) {
                setState(() => _currentPageIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          Expanded(
            child: Column(
              children: [
                const ToolbarWidget(),
                Expanded(
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    maxScale: 5.0,
                    minScale: 0.5,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.note.pages.length,
                      onPageChanged: (index) => setState(() => _currentPageIndex = index),
                      itemBuilder: (context, index) {
                        return CanvasWidget(
                          page: widget.note.pages[index],
                          pageIndex: index,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportToPdf() {
    // PDF export implementation
    // This would use the pdf package to generate PDF from note pages
  }
}