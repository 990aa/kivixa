import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kivixa/components/canvas/_stroke.dart';
import 'package:kivixa/components/canvas/canvas_preview.dart';
import 'package:kivixa/components/canvas/inner_canvas.dart';
import 'package:kivixa/components/canvas/invert_widget.dart';

import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/markdown/markdown_editor.dart';

class PreviewCard extends StatefulWidget {
  PreviewCard({
    required this.filePath,
    required this.toggleSelection,
    required this.selected,
    required this.isAnythingSelected,
  }) : super(key: ValueKey('PreviewCard$filePath'));

  final String filePath;
  final bool selected;
  final bool isAnythingSelected;
  final void Function(String, bool) toggleSelection;

  @override
  State<PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<PreviewCard> {
  final expanded = ValueNotifier(false);
  final thumbnail = _ThumbnailState();
  String? _markdownContent;

  @override
  void initState() {
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );

    expanded.value = widget.selected;
    
    // Load markdown content if it's a markdown file
    if (widget.filePath.endsWith('.md')) {
      _loadMarkdownContent();
    }
    
    super.initState();
  }

  Future<void> _loadMarkdownContent() async {
    try {
      final file = FileManager.getFile('${widget.filePath}.md');
      if (file.existsSync()) {
        final content = await file.readAsString();
        if (mounted) {
          setState(() {
            _markdownContent = content;
          });
        }
      }
    } catch (e) {
      // Ignore errors, will show fallback
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final imageFile = FileManager.getFile(
      '${widget.filePath}${Editor.extension}.p',
    );
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      // Avoid FileImages in tests
      thumbnail.image = imageFile.existsSync()
          ? MemoryImage(imageFile.readAsBytesSync())
          : null;
    } else {
      thumbnail.image = FileImage(imageFile);
    }
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    if (event.filePath != widget.filePath) return;
    if (event.type == FileOperationType.delete) {
      thumbnail.image = null;
      if (widget.filePath.endsWith('.md')) {
        setState(() {
          _markdownContent = null;
        });
      }
    } else if (event.type == FileOperationType.write) {
      thumbnail.image?.evict();
      thumbnail.markAsChanged();
      if (widget.filePath.endsWith('.md')) {
        _loadMarkdownContent();
      }
    } else {
      throw Exception('Unknown file operation type: ${event.type}');
    }
  }

  void _toggleCardSelection() {
    expanded.value = !expanded.value;
    widget.toggleSelection(widget.filePath, expanded.value);
  }

  Widget _buildMarkdownPreview(ColorScheme colorScheme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 200,
      ),
      child: ClipRect(
        child: _markdownContent == null
            ? const _FallbackThumbnail()
            : Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: 200,
                      child: IgnorePointer(
                        child: Markdown(
                          data: _markdownContent!,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          styleSheet: MarkdownStyleSheet(
                            textScaler: const TextScaler.linear(0.7),
                            p: TextStyle(fontSize: 10, color: colorScheme.onSurface),
                            h1: TextStyle(fontSize: 14, color: colorScheme.primary),
                            h2: TextStyle(fontSize: 13, color: colorScheme.primary),
                            h3: TextStyle(fontSize: 12, color: colorScheme.primary),
                            code: TextStyle(
                              fontSize: 9,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildNotePreview(bool invert) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 200,
      ),
      child: ClipRect(
        child: FutureBuilder(
          future: _loadNotePreview(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            
            if (snapshot.hasError || !snapshot.hasData) {
              return const _FallbackThumbnail();
            }

            return SizedBox(
              height: 200,
              child: IgnorePointer(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  child: InvertWidget(
                    invert: invert,
                    child: CanvasPreview.fromFile(
                      filePath: widget.filePath,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<dynamic> _loadNotePreview() async {
    try {
      final file = FileManager.getFile('${widget.filePath}${Editor.extension}');
      if (!file.existsSync()) {
        return null;
      }
      // Just return a placeholder to indicate file exists
      // CanvasPreview.fromFile will handle the actual loading
      return true;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final transitionDuration = Duration(
      milliseconds: disableAnimations ? 0 : 300,
    );
    final invert =
        theme.brightness == Brightness.dark && stows.editorAutoInvert.value;

    final Widget card = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isAnythingSelected ? _toggleCardSelection : null,
        onSecondaryTap: _toggleCardSelection,
        onLongPress: _toggleCardSelection,
        child: ColoredBox(
          color: colorScheme.surfaceContainerLow,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      // Preview content based on file type
                      if (widget.filePath.endsWith('.md'))
                        _buildMarkdownPreview(colorScheme)
                      else
                        _buildNotePreview(invert),
                      Positioned.fill(
                        left: -1,
                        top: -1,
                        right: -1,
                        bottom: -1,
                        child: ValueListenableBuilder(
                          valueListenable: expanded,
                          builder: (context, expanded, child) =>
                              AnimatedOpacity(
                                opacity: expanded ? 1 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: IgnorePointer(
                                  ignoring: !expanded,
                                  child: child!,
                                ),
                              ),
                          child: GestureDetector(
                            onTap: _toggleCardSelection,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    colorScheme.surface.withValues(alpha: 0.2),
                                    colorScheme.surface.withValues(alpha: 0.8),
                                    colorScheme.surface.withValues(alpha: 1),
                                  ],
                                ),
                              ),
                              child: ColoredBox(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        widget.filePath.substring(
                          widget.filePath.lastIndexOf('/') + 1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return ValueListenableBuilder(
      valueListenable: expanded,
      builder: (context, expanded, _) {
        // Determine which editor to open based on file extension
        final isMarkdown = widget.filePath.endsWith('.md');
        final editor = isMarkdown
            ? MarkdownEditor(filePath: widget.filePath)
            : Editor(path: widget.filePath);

        return OpenContainer(
          closedColor: colorScheme.surface,
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          closedElevation: expanded ? 4 : 1,
          closedBuilder: (context, action) => card,
          openColor: colorScheme.surface,
          openBuilder: (context, action) => editor,
          transitionDuration: transitionDuration,
          routeSettings: RouteSettings(
            name: isMarkdown
                ? RoutePaths.markdownFilePath(widget.filePath)
                : RoutePaths.editFilePath(widget.filePath),
          ),
          onClosed: (_) {
            thumbnail.image?.evict();
            thumbnail.markAsChanged();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    fileWriteSubscription?.cancel();
    super.dispose();
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: InnerCanvas.defaultBackgroundColor,
      child: Center(
        child: Text(
          t.home.noPreviewAvailable,
          style: TextTheme.of(context).bodyMedium?.copyWith(
            color: Stroke.defaultColor.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ThumbnailState extends ChangeNotifier {
  var updateCount = 0;
  ImageProvider? _image;

  void markAsChanged() {
    ++updateCount;
    notifyListeners();
  }

  ImageProvider? get image => _image;
  set image(ImageProvider? image) {
    _image = image;
    markAsChanged();
  }

  bool get doesImageExist => switch (image) {
    (final FileImage fileImage) => fileImage.file.existsSync(),
    null => false,
    _ => true,
  };
}
