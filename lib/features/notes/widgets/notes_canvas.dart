import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kivixa/features/notes/blocs/drawing_bloc.dart';
import 'package:kivixa/features/notes/models/note_page.dart';
import 'package:kivixa/features/notes/services/paper_generator_service.dart';
import 'package:kivixa/features/notes/widgets/notes_drawing_canvas.dart';

class NotesCanvas extends StatefulWidget {
  final List<NotePage> pages;
  final Function(NotePage) onPageAdded;

  const NotesCanvas({
    super.key,
    required this.pages,
    required this.onPageAdded,
  });

  @override
  State<NotesCanvas> createState() => _NotesCanvasState();
}

class _NotesCanvasState extends State<NotesCanvas> {
  final PaperGeneratorService _paperGeneratorService = PaperGeneratorService();
  final Map<int, Uint8List> _pageBackgrounds = {};

  @override
  void initState() {
    super.initState();
    _generateAllPageBackgrounds();
  }

  @override
  void didUpdateWidget(covariant NotesCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pages.length > oldWidget.pages.length) {
      _generatePageBackground(widget.pages.last);
    }
  }

  Future<void> _generatePageBackground(NotePage page) async {
    if (_pageBackgrounds.containsKey(page.pageNumber)) return;

    final paperSettings = page.paperSettings;

    final imageBytes = await _paperGeneratorService.generatePaper(
      paperType: paperSettings.paperType,
      paperSize: paperSettings.paperSize,
      options: paperSettings.options,
    );

    if (mounted) {
      setState(() {
        _pageBackgrounds[page.pageNumber] = imageBytes;
      });
    }
  }

  void _generateAllPageBackgrounds() {
    for (final page in widget.pages) {
      _generatePageBackground(page);
    }
  }

  @override
  void dispose() {
    _paperGeneratorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.pages.length,
            itemBuilder: (context, index) {
              final page = widget.pages[index];
              final background = _pageBackgrounds[page.pageNumber];

              return AspectRatio(
                aspectRatio: page.paperSettings.paperSize.width /
                    page.paperSettings.paperSize.height,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((255 * 0.2).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: background == null
                      ? const Center(child: CircularProgressIndicator())
                      : BlocBuilder<DrawingBloc, DrawingState>(
                          builder: (context, drawingState) {
                            if (drawingState is DrawingLoadSuccess) {
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.memory(
                                      background,
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  NotesDrawingCanvas(
                                    notifier: drawingState.notifier,
                                    // This assumes one drawing canvas for all pages,
                                    // which might need adjustment for multi-page documents.
                                  ),
                                ],
                              );
                            }
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                        ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Page'),
            onPressed: () {
              final lastPage = widget.pages.last;
              final newPage = NotePage(
                pageNumber: lastPage.pageNumber + 1,
                paperSettings: lastPage.paperSettings, // Inherit settings
                strokes: [],
              );
              widget.onPageAdded(newPage);
            },
          ),
        ),
      ],
    );
  }
}