import 'dart:async';
import 'dart:io';

import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:kivixa/components/canvas/_stroke.dart';
import 'package:kivixa/components/canvas/inner_canvas.dart';
import 'package:kivixa/components/canvas/invert_widget.dart';
import 'package:kivixa/components/home/folder_picker_dialog.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/pages/editor/editor.dart';
import 'package:kivixa/pages/markdown/rich_markdown_editor.dart';
import 'package:logging/logging.dart';

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
  final log = Logger('PreviewCard');

  // For rename functionality
  final _renameController = TextEditingController();

  @override
  void initState() {
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );

    expanded.value = widget.selected;

    // Load markdown content if it's a markdown file
    // Check actual file since extensions are stripped from filePath
    final mdFile = FileManager.getFile('${widget.filePath}.md');
    if (mdFile.existsSync()) {
      _loadMarkdownContent();
    }

    super.initState();
  }

  Future<void> _loadMarkdownContent() async {
    try {
      final file = FileManager.getFile('${widget.filePath}.md');
      if (!file.existsSync()) {
        log.warning('Markdown file does not exist: ${widget.filePath}.md');
        return;
      }

      final content = await file.readAsString();
      if (mounted) {
        setState(() {
          _markdownContent = content;
        });
      }
    } catch (e, stackTrace) {
      log.severe(
        'Error loading markdown content for ${widget.filePath}',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() {
          _markdownContent = null;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      final imageFile = FileManager.getFile(
        '${widget.filePath}${Editor.extension}.p',
      );

      if (!imageFile.existsSync()) {
        // File doesn't exist, thumbnail will show fallback
        thumbnail.image = null;
        return;
      }

      if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
        // Avoid FileImages in tests
        thumbnail.image = MemoryImage(imageFile.readAsBytesSync());
      } else {
        thumbnail.image = FileImage(imageFile);
      }
    } catch (e, stackTrace) {
      log.severe(
        'Error loading thumbnail for ${widget.filePath}',
        e,
        stackTrace,
      );
      thumbnail.image = null;
    }
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    if (event.filePath != widget.filePath) return;

    // Check if this is a markdown file
    final mdFile = FileManager.getFile('${widget.filePath}.md');
    final isMarkdown = mdFile.existsSync();

    if (event.type == FileOperationType.delete) {
      thumbnail.image = null;
      if (isMarkdown) {
        setState(() {
          _markdownContent = null;
        });
      }
    } else if (event.type == FileOperationType.write) {
      thumbnail.image?.evict();
      thumbnail.markAsChanged();
      if (isMarkdown) {
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
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
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
                            p: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurface,
                            ),
                            h1: TextStyle(
                              fontSize: 14,
                              color: colorScheme.primary,
                            ),
                            h2: TextStyle(
                              fontSize: 13,
                              color: colorScheme.primary,
                            ),
                            h3: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                            ),
                            code: TextStyle(
                              fontSize: 9,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
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
    return AnimatedBuilder(
      animation: thumbnail,
      builder: (context, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: ConstrainedBox(
          key: ValueKey(thumbnail.updateCount),
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 200),
          child: ClipRect(
            child: InvertWidget(
              invert: invert,
              child: thumbnail.doesImageExist
                  ? Image(
                      image: thumbnail.image!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : const _FallbackThumbnail(),
            ),
          ),
        ),
      ),
    );
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
                      // Check actual file since extensions are stripped
                      if (_markdownContent != null ||
                          FileManager.getFile(
                            '${widget.filePath}.md',
                          ).existsSync())
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
              // Three-dot menu button
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _showRenameDialog();
                        case 'move':
                          _showMoveDialog();
                        case 'delete':
                          _showDeleteDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 20,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            Text(t.common.rename),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'move',
                        child: Row(
                          children: [
                            Icon(
                              Icons.drive_file_move,
                              size: 20,
                              color: colorScheme.onSurface,
                            ),
                            const SizedBox(width: 12),
                            const Text('Move'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              t.common.delete,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ValueListenableBuilder(
      valueListenable: expanded,
      builder: (context, expanded, _) {
        // Determine which editor to open based on actual file type
        // Check if .md file exists (since extensions are stripped in file lists)
        final mdFile = FileManager.getFile('${widget.filePath}.md');
        final isMarkdown = mdFile.existsSync();

        final editor = isMarkdown
            ? RichMarkdownEditor(filePath: widget.filePath)
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

  Future<void> _showRenameDialog() async {
    final fileName = widget.filePath.substring(
      widget.filePath.lastIndexOf('/') + 1,
    );
    _renameController.text = fileName;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.home.renameFile),
        content: TextField(
          controller: _renameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: t.home.fileName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () {
              final newName = _renameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(context).pop(newName);
              }
            },
            child: Text(t.common.rename),
          ),
        ],
      ),
    );

    if (result != null && result != fileName) {
      await _renameFile(result);
    }
  }

  Future<void> _renameFile(String newName) async {
    try {
      final directory = widget.filePath.substring(
        0,
        widget.filePath.lastIndexOf('/') + 1,
      );
      final newPath = '$directory$newName';

      // Check if it's a markdown file
      final mdFile = FileManager.getFile('${widget.filePath}.md');
      final isMarkdown = mdFile.existsSync();

      if (isMarkdown) {
        // Rename the .md file
        await FileManager.moveFile('${widget.filePath}.md', '$newPath.md');
      } else {
        // Rename the note file (.kvx)
        await FileManager.moveFile(
          '${widget.filePath}${Editor.extension}',
          '$newPath${Editor.extension}',
        );
      }

      log.info('File renamed from ${widget.filePath} to $newPath');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.home.fileRenamed)));
      }
    } catch (e, stackTrace) {
      log.severe('Error renaming file ${widget.filePath}', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${t.common.error}: $e')));
      }
    }
  }

  Future<void> _showMoveDialog() async {
    final destinationFolder = await showDialog<String>(
      context: context,
      builder: (context) => const FolderPickerDialog(),
    );

    if (destinationFolder == null) return;

    await _moveFile(destinationFolder);
  }

  Future<void> _moveFile(String destinationFolder) async {
    try {
      // Get the filename without directory
      final fileName = widget.filePath.substring(
        widget.filePath.lastIndexOf('/') + 1,
      );

      // Construct new path
      final newPath = destinationFolder == '/'
          ? '/$fileName'
          : '$destinationFolder/$fileName';

      // Check if already in the destination
      if (newPath == widget.filePath) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File is already in this folder')),
          );
        }
        return;
      }

      // Check if it's a markdown file
      final mdFile = FileManager.getFile('${widget.filePath}.md');
      final isMarkdown = mdFile.existsSync();

      if (isMarkdown) {
        // Move the .md file
        await FileManager.moveFile('${widget.filePath}.md', '$newPath.md');
      } else {
        // Move the note file (.kvx)
        await FileManager.moveFile(
          '${widget.filePath}${Editor.extension}',
          '$newPath${Editor.extension}',
        );
      }

      log.info('File moved from ${widget.filePath} to $newPath');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File moved successfully')),
        );
      }
    } catch (e, stackTrace) {
      log.severe('Error moving file ${widget.filePath}', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${t.common.error}: $e')));
      }
    }
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.home.deleteFile),
        content: Text(t.home.deleteFileConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(t.common.delete),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await _deleteFile();
    }
  }

  Future<void> _deleteFile() async {
    try {
      // Check if it's a markdown file
      final mdFile = FileManager.getFile('${widget.filePath}.md');
      final isMarkdown = mdFile.existsSync();

      if (isMarkdown) {
        // Delete the .md file (this will also delete the .p preview)
        await FileManager.deleteFile('${widget.filePath}.md');
      } else {
        // Delete the note file (this will also delete assets and .p preview)
        await FileManager.deleteFile('${widget.filePath}${Editor.extension}');
      }

      log.info('File deleted: ${widget.filePath}');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.home.fileDeleted)));
      }
    } catch (e, stackTrace) {
      log.severe('Error deleting file ${widget.filePath}', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${t.common.error}: $e')));
      }
    }
  }

  @override
  void dispose() {
    fileWriteSubscription?.cancel();
    _renameController.dispose();
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
