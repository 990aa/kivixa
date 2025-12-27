import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:kivixa/components/life_git/time_travel_slider.dart';
import 'package:kivixa/data/file_manager/file_manager.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/data/routes.dart';
import 'package:kivixa/i18n/strings.g.dart';
import 'package:kivixa/services/life_git/life_git.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

/// Custom embed type for interactive images with metadata
const kInteractiveImageType = 'interactive-image';

/// Custom image embed builder for QuillEditor that handles local file images
/// with persistent metadata (size, rotation, position)
class _ImageEmbedBuilder extends EmbedBuilder {
  _ImageEmbedBuilder({required this.onMediaChanged});

  /// Callback when media properties change - triggers document update
  final void Function(int index, MediaElement element) onMediaChanged;

  @override
  String get key => kInteractiveImageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final value = node.value;

    // Parse MediaElement from node data (should be JSON string or Map)
    MediaElement element;
    if (value.data is String) {
      final dataStr = value.data as String;
      // Check if it's a JSON string (starts with {)
      if (dataStr.startsWith('{')) {
        try {
          element = MediaElement.fromJsonString(dataStr);
        } catch (e) {
          // Not valid JSON, treat as simple path
          element = MediaElement(path: dataStr, mediaType: MediaType.image);
        }
      } else {
        // Simple path string
        element = MediaElement(path: dataStr, mediaType: MediaType.image);
      }
    } else if (value.data is Map) {
      try {
        final map = Map<String, dynamic>.from(value.data as Map);
        element = MediaElement.fromJson(map);
      } catch (e) {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }

    // Use a stateful widget wrapper to handle selection and interactions
    return _InteractiveImageEmbed(
      element: element,
      onChanged: (newElement) {
        // Update the document with new metadata
        onMediaChanged(node.documentOffset, newElement);
      },
    );
  }
}

/// Legacy image embed builder for standard BlockEmbed.image type
class _LegacyImageEmbedBuilder extends EmbedBuilder {
  _LegacyImageEmbedBuilder({required this.onMediaChanged});

  final void Function(int index, MediaElement element) onMediaChanged;

  @override
  String get key => BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    final value = node.value;

    if (value.data is! String) return const SizedBox.shrink();

    final path = value.data as String;
    final element = MediaElement(path: path, mediaType: MediaType.image);

    return _InteractiveImageEmbed(
      element: element,
      onChanged: (newElement) {
        onMediaChanged(node.documentOffset, newElement);
      },
    );
  }
}

/// Inline media embed widget for Quill editor - truly inline with text flow.
/// Unlike the floating InteractiveMediaWidget, this widget flows with text
/// like Microsoft Word's inline images - no transforms or absolute positioning.
class _InteractiveImageEmbed extends StatefulWidget {
  const _InteractiveImageEmbed({
    required this.element,
    required this.onChanged,
  });

  final MediaElement element;
  final void Function(MediaElement) onChanged;

  @override
  State<_InteractiveImageEmbed> createState() => _InteractiveImageEmbedState();
}

class _InteractiveImageEmbedState extends State<_InteractiveImageEmbed> {
  late MediaElement _element;
  var _isSelected = false;
  var _isResizing = false;

  // For video playback
  Player? _player;
  VideoController? _videoController;
  var _isVideoInitialized = false;

  // Debounce timer to prevent rapid document updates during resize
  Timer? _resizeDebounce;

  static const _handleSize = 10.0;
  static const _minSize = 50.0;
  static const _maxSize = 2000.0;

  @override
  void initState() {
    super.initState();
    _element = widget.element;
    _initializeMedia();
  }

  @override
  void didUpdateWidget(_InteractiveImageEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.path != widget.element.path) {
      _element = widget.element;
      _disposeVideo();
      _initializeMedia();
    }
  }

  void _initializeMedia() {
    if (_element.mediaType == MediaType.video) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    final file = File(_element.path);
    if (!file.existsSync()) return;

    _player = Player();
    _videoController = VideoController(_player!);

    await _player!.open(Media(file.path), play: false);

    if (mounted) {
      setState(() => _isVideoInitialized = true);
    }
  }

  void _disposeVideo() {
    _player?.dispose();
    _player = null;
    _videoController = null;
    _isVideoInitialized = false;
  }

  @override
  void dispose() {
    _resizeDebounce?.cancel();
    _disposeVideo();
    super.dispose();
  }

  void _handleTapOutside() {
    if (_isSelected) {
      setState(() => _isSelected = false);
    }
  }

  void _updateSize(double newWidth, double newHeight, {bool saveNow = false}) {
    final clampedWidth = newWidth.clamp(_minSize, _maxSize);
    final clampedHeight = newHeight.clamp(_minSize, _maxSize);

    setState(() {
      _element = _element.copyWith(width: clampedWidth, height: clampedHeight);
    });

    // Debounce document updates to prevent duplicates during rapid resizing
    _resizeDebounce?.cancel();
    if (saveNow) {
      widget.onChanged(_element);
    } else {
      _resizeDebounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) widget.onChanged(_element);
      });
    }
  }

  void _openFullscreen() {
    if (_element.mediaType == MediaType.video && _player != null) {
      // Show fullscreen video dialog
      showDialog(
        context: context,
        builder: (ctx) => _FullscreenVideoDialog(
          player: _player!,
          controller: _videoController!,
        ),
      );
    } else {
      // Show fullscreen image
      showDialog(
        context: context,
        builder: (ctx) => _FullscreenImageDialog(path: _element.path),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TapRegion(
      onTapOutside: (_) => _handleTapOutside(),
      child: GestureDetector(
        onTap: () => setState(() => _isSelected = !_isSelected),
        onDoubleTap: _openFullscreen,
        child: Container(
          width: (_element.width ?? 200) + (_isSelected ? _handleSize * 2 : 0),
          height:
              (_element.height ?? 200) + (_isSelected ? _handleSize * 2 : 0),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            children: [
              // Main content - positioned with padding when selected
              Positioned(
                left: _isSelected ? _handleSize : 0,
                top: _isSelected ? _handleSize : 0,
                width: _element.width ?? 200,
                height: _element.height ?? 200,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: _isSelected
                        ? Border.all(color: colorScheme.primary, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: _isResizing
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildMediaContent(),
                  ),
                ),
              ),

              // Resize handles when selected
              if (_isSelected) ..._buildResizeHandles(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_element.mediaType == MediaType.video) {
      return _buildVideoContent();
    } else {
      return _buildImageContent();
    }
  }

  Widget _buildImageContent() {
    final file = File(_element.path);

    return Container(
      width: _element.width ?? 200,
      height: _element.height ?? 200,
      color: Colors.grey[100],
      child: Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return ColoredBox(
            color: Colors.grey[300]!,
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoContent() {
    if (!_isVideoInitialized || _videoController == null) {
      // Show thumbnail or loading state
      return ColoredBox(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Try to show a thumbnail from the video
            FutureBuilder<Uint8List?>(
              future: _getVideoThumbnail(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: _element.width ?? 200,
                    height: _element.height ?? 200,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Play button overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
            ),
            // Loading indicator
            if (!_isVideoInitialized)
              const Positioned(
                bottom: 8,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      );
    }

    // Show actual video player
    return Stack(
      children: [
        Video(controller: _videoController!, fit: BoxFit.contain),
        // Video controls overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _VideoControlsOverlay(player: _player!),
        ),
      ],
    );
  }

  Future<Uint8List?> _getVideoThumbnail() async {
    // For now, return null - could implement thumbnail extraction later
    return null;
  }

  List<Widget> _buildResizeHandles(ColorScheme colorScheme) {
    return [
      // Top-left
      _buildHandle(colorScheme, Alignment.topLeft, _ResizeDirection.topLeft),
      // Top-right
      _buildHandle(colorScheme, Alignment.topRight, _ResizeDirection.topRight),
      // Bottom-left
      _buildHandle(
        colorScheme,
        Alignment.bottomLeft,
        _ResizeDirection.bottomLeft,
      ),
      // Bottom-right
      _buildHandle(
        colorScheme,
        Alignment.bottomRight,
        _ResizeDirection.bottomRight,
      ),
      // Top center
      _buildHandle(colorScheme, Alignment.topCenter, _ResizeDirection.top),
      // Bottom center
      _buildHandle(
        colorScheme,
        Alignment.bottomCenter,
        _ResizeDirection.bottom,
      ),
      // Left center
      _buildHandle(colorScheme, Alignment.centerLeft, _ResizeDirection.left),
      // Right center
      _buildHandle(colorScheme, Alignment.centerRight, _ResizeDirection.right),
    ];
  }

  Widget _buildHandle(
    ColorScheme colorScheme,
    Alignment alignment,
    _ResizeDirection direction,
  ) {
    // Calculate position based on alignment to avoid Positioned.fill
    final width = (_element.width ?? 200) + _handleSize * 2;
    final height = (_element.height ?? 200) + _handleSize * 2;

    double? left, right, top, bottom;

    // Horizontal position
    if (alignment.x == -1) {
      left = 0;
    } else if (alignment.x == 1) {
      right = 0;
    } else {
      left = (width - _handleSize) / 2;
    }

    // Vertical position
    if (alignment.y == -1) {
      top = 0;
    } else if (alignment.y == 1) {
      bottom = 0;
    } else {
      top = (height - _handleSize) / 2;
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isResizing = true),
        onPanUpdate: (details) => _handleResize(details, direction),
        onPanEnd: (_) {
          setState(() => _isResizing = false);
          // Save document after resize completes
          _updateSize(
            _element.width ?? 200,
            _element.height ?? 200,
            saveNow: true,
          );
        },
        child: MouseRegion(
          cursor: _getCursorForDirection(direction),
          child: Container(
            width: _handleSize,
            height: _handleSize,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              border: Border.all(color: Colors.white, width: 1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  MouseCursor _getCursorForDirection(_ResizeDirection direction) {
    switch (direction) {
      case _ResizeDirection.topLeft:
      case _ResizeDirection.bottomRight:
        return SystemMouseCursors.resizeUpLeftDownRight;
      case _ResizeDirection.topRight:
      case _ResizeDirection.bottomLeft:
        return SystemMouseCursors.resizeUpRightDownLeft;
      case _ResizeDirection.top:
      case _ResizeDirection.bottom:
        return SystemMouseCursors.resizeUpDown;
      case _ResizeDirection.left:
      case _ResizeDirection.right:
        return SystemMouseCursors.resizeLeftRight;
    }
  }

  void _handleResize(DragUpdateDetails details, _ResizeDirection direction) {
    var newWidth = _element.width ?? 200.0;
    var newHeight = _element.height ?? 200.0;

    switch (direction) {
      case _ResizeDirection.topLeft:
        newWidth -= details.delta.dx;
        newHeight -= details.delta.dy;
      case _ResizeDirection.topRight:
        newWidth += details.delta.dx;
        newHeight -= details.delta.dy;
      case _ResizeDirection.bottomLeft:
        newWidth -= details.delta.dx;
        newHeight += details.delta.dy;
      case _ResizeDirection.bottomRight:
        newWidth += details.delta.dx;
        newHeight += details.delta.dy;
      case _ResizeDirection.top:
        newHeight -= details.delta.dy;
      case _ResizeDirection.bottom:
        newHeight += details.delta.dy;
      case _ResizeDirection.left:
        newWidth -= details.delta.dx;
      case _ResizeDirection.right:
        newWidth += details.delta.dx;
    }

    // Update local state only during drag - don't save to document yet
    _updateSizeLocal(newWidth, newHeight);
  }

  /// Update local state without triggering document save
  void _updateSizeLocal(double newWidth, double newHeight) {
    final clampedWidth = newWidth.clamp(_minSize, _maxSize);
    final clampedHeight = newHeight.clamp(_minSize, _maxSize);

    setState(() {
      _element = _element.copyWith(width: clampedWidth, height: clampedHeight);
    });
  }
}

enum _ResizeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}

/// Video controls overlay with play/pause, seek, and fullscreen
class _VideoControlsOverlay extends StatefulWidget {
  const _VideoControlsOverlay({required this.player});

  final Player player;

  @override
  State<_VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<_VideoControlsOverlay> {
  var _isPlaying = false;
  var _position = Duration.zero;
  var _duration = Duration.zero;
  var _isVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    widget.player.stream.position.listen((position) {
      if (mounted) setState(() => _position = position);
    });
    widget.player.stream.duration.listen((duration) {
      if (mounted) setState(() => _duration = duration);
    });
  }

  void _showControls() {
    setState(() => _isVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showControls(),
      onHover: (_) => _showControls(),
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                    onChanged: (value) {
                      widget.player.seek(
                        Duration(
                          milliseconds: (value * _duration.inMilliseconds)
                              .round(),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        if (_isPlaying) {
                          widget.player.pause();
                        } else {
                          widget.player.play();
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    // Time display
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    const Spacer(),
                    // Volume
                    IconButton(
                      icon: const Icon(
                        Icons.volume_up,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        // Could show volume slider
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fullscreen video dialog
class _FullscreenVideoDialog extends StatelessWidget {
  const _FullscreenVideoDialog({
    required this.player,
    required this.controller,
  });

  final Player player;
  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Video(controller: controller, fit: BoxFit.contain),
          ),
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _VideoControlsOverlay(player: player),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen image dialog
class _FullscreenImageDialog extends StatelessWidget {
  const _FullscreenImageDialog({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

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
  final _editorFocusNode = FocusNode();
  final _scrollController = ScrollController();

  var _isLoading = true;
  String? _currentFilePath;
  var _fileName = 'Untitled';
  Timer? _autosaveTimer;
  Timer? _renameTimer;
  // ignore: unused_field
  var _isEditingFileName = false;

  // Time Travel state
  var _isTimeTraveling = false;
  Document? _originalDocument;

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

  /// Update a media embed in the document with new metadata
  void _updateMediaEmbed(int index, MediaElement element) {
    // Delete the old embed and insert a new one with updated data
    _controller.document.delete(index, 1);
    final embed = BlockEmbed.custom(
      CustomBlockEmbed(kInteractiveImageType, element.toJsonString()),
    );
    _controller.document.insert(index, embed);
    // Trigger autosave
    _onDocumentChanged();
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

  Future<void> _commitVersion() async {
    if (_currentFilePath == null) return;

    // Show dialog to get optional commit message
    final messageController = TextEditingController();
    final shouldCommit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commit Version'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Commit message (optional)',
            hintText: 'Describe your changes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Commit'),
          ),
        ],
      ),
    );

    if (shouldCommit != true) {
      messageController.dispose();
      return;
    }

    final customMessage = messageController.text.trim();
    messageController.dispose();

    // Save first to ensure latest content is on disk
    await _saveFile();

    try {
      final snapshot = await LifeGitService.instance.snapshotFile(
        _currentFilePath!,
      );
      if (snapshot.exists) {
        final message = customMessage.isNotEmpty
            ? customMessage
            : 'Commit: $_fileName';
        await LifeGitService.instance.createCommit(
          snapshots: [snapshot],
          message: message,
        );
        log.info('Life Git commit created for: $_currentFilePath');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Version committed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      log.warning('Failed to create Life Git commit', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to commit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _enterTimeTravel() {
    if (_currentFilePath == null) return;
    setState(() {
      _isTimeTraveling = true;
      _originalDocument = _controller.document;
    });
  }

  void _exitTimeTravel() {
    setState(() {
      _isTimeTraveling = false;
      if (_originalDocument != null) {
        _controller = QuillController(
          document: _originalDocument!,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
      _originalDocument = null;
    });
  }

  void _onTimeTravelContent(Uint8List content, LifeGitCommit commit) {
    try {
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
        setState(() {
          _controller = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
          );
        });
      }
    } catch (e) {
      log.warning('Failed to parse historical version', e);
    }
  }

  void _onRestoreVersion(Uint8List content, LifeGitCommit commit) {
    try {
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
        setState(() {
          _controller = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
          );
          _originalDocument = document;
          _isTimeTraveling = false;
        });
        _saveFile(); // Save the restored version
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restored to: ${commit.message}')),
          );
        }
      }
    } catch (e) {
      log.warning('Failed to restore historical version', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore version: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _restoreHistoricalVersion() {
    setState(() {
      _originalDocument = _controller.document;
      _isTimeTraveling = false;
    });
    _saveFile(); // Save the restored version
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historical version restored')),
      );
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
    const contentTypes = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
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
    const rels = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
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
    return Uint8List.fromList(zipEncoder.encode(archive));
  }

  String _convertDeltaToDocx() {
    final buffer = StringBuffer();
    buffer.write('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>''');

    final delta = _controller.document.toDelta();
    var currentParagraph = StringBuffer();

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

  Future<void> _insertMedia() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          // Images
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg',
          // Videos
          'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', 'wmv', 'flv',
        ],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      // Copy media to app's assets directory
      final appDir = await getApplicationDocumentsDirectory();
      final assetsDir = Directory('${appDir.path}/kivixa/assets/media');
      if (!assetsDir.existsSync()) {
        assetsDir.createSync(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      final newPath = '${assetsDir.path}/$fileName';
      await File(filePath).copy(newPath);

      // Determine media type from extension
      final ext = fileName.toLowerCase();
      final isVideo =
          ext.endsWith('.mp4') ||
          ext.endsWith('.mov') ||
          ext.endsWith('.avi') ||
          ext.endsWith('.mkv') ||
          ext.endsWith('.webm');

      // Get actual image dimensions for proper initial sizing
      double? width;
      double? height;
      if (!isVideo) {
        try {
          final imageFile = File(newPath);
          final bytes = await imageFile.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final imageWidth = frame.image.width.toDouble();
          final imageHeight = frame.image.height.toDouble();

          // Scale down if too large, keeping aspect ratio
          const maxInitialSize = 500.0;
          if (imageWidth > maxInitialSize || imageHeight > maxInitialSize) {
            final scale =
                maxInitialSize /
                (imageWidth > imageHeight ? imageWidth : imageHeight);
            width = imageWidth * scale;
            height = imageHeight * scale;
          } else {
            width = imageWidth;
            height = imageHeight;
          }
          frame.image.dispose();
        } catch (e) {
          // Fall back to default size if we can't read dimensions
          width = 300;
          height = 200;
        }
      } else {
        // Default size for videos
        width = 400;
        height = 225; // 16:9 aspect ratio
      }

      // Create MediaElement with actual dimensions
      final element = MediaElement(
        path: newPath,
        mediaType: isVideo ? MediaType.video : MediaType.image,
        sourceType: MediaSourceType.local,
        width: width,
        height: height,
      );

      // Insert custom media embed with metadata into document
      final index = _controller.selection.baseOffset;
      final embed = BlockEmbed.custom(
        CustomBlockEmbed(kInteractiveImageType, element.toJsonString()),
      );
      _controller.document.insert(index, embed);
      _controller.updateSelection(
        TextSelection.collapsed(offset: index + 1),
        ChangeSource.local,
      );
    } catch (e) {
      log.severe('Error inserting media', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inserting media: $e')));
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
          if (!_isTimeTraveling) ...[
            IconButton(
              icon: const Icon(Icons.perm_media),
              tooltip: 'Insert Media',
              onPressed: _insertMedia,
            ),
            IconButton(
              icon: const Icon(Icons.table_chart),
              tooltip: 'Insert Table',
              onPressed: _insertTable,
            ),
            // Time Travel button
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Time Travel',
              onPressed: _currentFilePath != null ? _enterTimeTravel : null,
            ),
            // View full history
            IconButton(
              icon: const Icon(Icons.manage_history),
              tooltip: 'View History',
              onPressed: _currentFilePath != null
                  ? () => context.push(
                      RoutePaths.lifeGitHistoryPath(filePath: _currentFilePath),
                    )
                  : null,
            ),
            // Commit version button
            IconButton(
              icon: const Icon(Icons.commit),
              tooltip: 'Commit Version',
              onPressed: _commitVersion,
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export',
              onPressed: _showExportMenu,
            ),
          ] else ...[
            // Time Travel mode actions
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restore this version',
              onPressed: _restoreHistoricalVersion,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit Time Travel',
              onPressed: _exitTimeTravel,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Time Travel slider when in time travel mode
            if (_isTimeTraveling && _currentFilePath != null)
              TimeTravelSlider(
                filePath: _currentFilePath!,
                onHistoryContent: _onTimeTravelContent,
                onExitTimeTravel: _exitTimeTravel,
                onRestoreVersion: _onRestoreVersion,
                showCommitDetails: true,
              ),
            // Rich toolbar with all formatting options (hidden during time travel)
            if (!_isTimeTraveling) ...[
              _buildToolbar(colorScheme),
              const Divider(height: 1),
            ],
            // Editor
            Expanded(
              child: Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.all(16),
                child: QuillEditor(
                  controller: _controller,
                  focusNode: _editorFocusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    placeholder: 'Start typing...',
                    padding: const EdgeInsets.all(16),
                    autoFocus: false,
                    expands: true,
                    embedBuilders: [
                      _ImageEmbedBuilder(onMediaChanged: _updateMediaEmbed),
                      _LegacyImageEmbedBuilder(
                        onMediaChanged: _updateMediaEmbed,
                      ),
                    ],
                    customStyles: DefaultStyles(
                      paragraph: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                        HorizontalSpacing.zero,
                        const VerticalSpacing(8, 8),
                        VerticalSpacing.zero,
                        null,
                      ),
                      h1: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        HorizontalSpacing.zero,
                        const VerticalSpacing(16, 8),
                        VerticalSpacing.zero,
                        null,
                      ),
                      h2: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        HorizontalSpacing.zero,
                        const VerticalSpacing(14, 6),
                        VerticalSpacing.zero,
                        null,
                      ),
                      h3: DefaultTextBlockStyle(
                        TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        HorizontalSpacing.zero,
                        const VerticalSpacing(12, 4),
                        VerticalSpacing.zero,
                        null,
                      ),
                      code: DefaultTextBlockStyle(
                        TextStyle(
                          fontFamily: 'FiraMono',
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                        HorizontalSpacing.zero,
                        const VerticalSpacing(8, 8),
                        VerticalSpacing.zero,
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
            // Alignment - using toggle buttons for each alignment
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.leftAlignment,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_align_left,
              ),
            ),
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.centerAlignment,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_align_center,
              ),
            ),
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.rightAlignment,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_align_right,
              ),
            ),
            QuillToolbarToggleStyleButton(
              controller: _controller,
              attribute: Attribute.justifyAlignment,
              options: const QuillToolbarToggleStyleButtonOptions(
                iconData: Icons.format_align_justify,
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
      width: 130,
      child: DropdownButtonFormField<String>(
        initialValue: _fontValues[0],
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        items: List.generate(_fonts.length, (i) {
          return DropdownMenuItem(
            value: _fontValues[i],
            child: Text(
              _fonts[i],
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
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
      width: 75,
      child: DropdownButtonFormField<String>(
        initialValue: '14',
        isExpanded: true,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
        items: _sizes.map((size) {
          return DropdownMenuItem(
            value: size,
            child: Text(
              size,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
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
                  initialValue: _rows,
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
                  initialValue: _cols,
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
