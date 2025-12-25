import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kivixa/components/media/image_preview_widget.dart';
import 'package:kivixa/components/media/interactive_media_widget.dart';
import 'package:kivixa/components/media/media_comment_overlay.dart';
import 'package:kivixa/components/media/media_video_player.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/services/media_service.dart';

/// Callback when media element properties change
typedef OnMediaChanged = void Function(MediaElement element);

/// Callback when media element is deleted
typedef OnMediaDeleted = void Function(MediaElement element);

/// High-performance embedded media renderer for markdown and text files.
///
/// This widget handles:
/// - Image and video display from local files, app storage, and web URLs
/// - Interactive resize, rotate, and drag operations
/// - Comment overlays with hover (desktop) and tap (mobile) interactions
/// - Large image preview mode with pan/zoom
/// - Performance optimizations via RepaintBoundary and caching
///
/// The widget automatically updates the underlying markdown/text syntax
/// when properties change (width, height, rotation, position).
class EmbeddedMediaRenderer extends StatefulWidget {
  const EmbeddedMediaRenderer({
    super.key,
    required this.element,
    required this.onChanged,
    this.onDeleted,
    this.isEditable = true,
    this.showControls = true,
    this.maxPreviewSize = 600,
  });

  /// The media element to render
  final MediaElement element;

  /// Callback when element properties change
  final OnMediaChanged onChanged;

  /// Callback when element is deleted
  final OnMediaDeleted? onDeleted;

  /// Whether the media can be edited (resize, rotate, drag)
  final bool isEditable;

  /// Whether to show control buttons (preview toggle, delete, etc.)
  final bool showControls;

  /// Maximum size for preview mode
  final double maxPreviewSize;

  @override
  State<EmbeddedMediaRenderer> createState() => _EmbeddedMediaRendererState();
}

class _EmbeddedMediaRendererState extends State<EmbeddedMediaRenderer>
    with SingleTickerProviderStateMixin {
  var _isSelected = false;
  var _isHovering = false;
  var _isLoading = true;
  var _hasError = false;
  String? _errorMessage;
  Uint8List? _imageBytes;
  Size? _naturalSize;

  // Animation for selection highlight
  late AnimationController _selectionController;
  // ignore: unused_field - may be used for selection highlight animation in future
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _selectionAnimation = CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeOut,
    );
    _loadMedia();
  }

  @override
  void didUpdateWidget(EmbeddedMediaRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.path != widget.element.path ||
        oldWidget.element.sourceType != widget.element.sourceType) {
      _loadMedia();
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    if (widget.element.isVideo) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final bytes = await MediaService.instance.resolveMedia(widget.element);
      if (bytes != null && mounted) {
        // Get natural dimensions
        final size = await _getImageSize(bytes);
        setState(() {
          _imageBytes = bytes;
          _naturalSize = size;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load media';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Size?> _getImageSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      frame.image.dispose();
      codec.dispose();
      return size;
    } catch (e) {
      return null;
    }
  }

  void _handleTap() {
    if (!widget.isEditable) return;

    setState(() {
      _isSelected = !_isSelected;
      if (_isSelected) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    });
  }

  void _handleDoubleTap() {
    // Toggle preview mode for large images
    if (widget.element.isImage && _naturalSize != null) {
      final isLarge = _naturalSize!.width > 2000 || _naturalSize!.height > 2000;
      if (isLarge) {
        widget.onChanged(
          widget.element.copyWith(isPreviewMode: !widget.element.isPreviewMode),
        );
      }
    }
  }

  void _handleElementChanged(MediaElement element) {
    widget.onChanged(element);
  }

  void _handleCommentChanged(String? comment) {
    widget.onChanged(widget.element.copyWith(comment: comment));
  }

  void _togglePreviewMode() {
    widget.onChanged(
      widget.element.copyWith(isPreviewMode: !widget.element.isPreviewMode),
    );
  }

  void _handleDelete() {
    widget.onDeleted?.call(widget.element);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: _handleTap,
          onDoubleTap: _handleDoubleTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content
              _buildContent(),

              // Control overlay (shown on hover or selection)
              if (widget.showControls && (_isHovering || _isSelected))
                Positioned(top: 8, right: 8, child: _buildControlOverlay()),

              // Move handle (4-way arrow) when selected
              if (_isSelected && widget.isEditable)
                Positioned(top: 8, left: 8, child: _buildMoveHandle()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_hasError) {
      return _buildErrorState();
    }

    // Video content
    if (widget.element.isVideo) {
      return _buildVideoContent();
    }

    // Image in preview mode (scrollable)
    if (widget.element.isPreviewMode) {
      return _buildPreviewContent();
    }

    // Regular interactive image
    return _buildInteractiveContent();
  }

  Widget _buildLoadingState() {
    final width = widget.element.width ?? 300;
    final height = widget.element.height ?? 200;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState() {
    final width = widget.element.width ?? 300;
    final height = widget.element.height ?? 150;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Failed to load media',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadMedia,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return MediaCommentOverlay(
      comment: widget.element.comment,
      onCommentChanged: _handleCommentChanged,
      child: InteractiveMediaWidget(
        element: widget.element,
        onChanged: _handleElementChanged,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        isSelected: _isSelected,
        showRotationHandle: false, // Videos typically don't rotate
        child: MediaVideoPlayer(
          element: widget.element,
          onChanged: _handleElementChanged,
          showControls: true,
        ),
      ),
    );
  }

  Widget _buildPreviewContent() {
    return MediaCommentOverlay(
      comment: widget.element.comment,
      onCommentChanged: _handleCommentChanged,
      child: ImagePreviewWidget(
        element: widget.element,
        onChanged: _handleElementChanged,
        onExitPreview: _togglePreviewMode,
      ),
    );
  }

  Widget _buildInteractiveContent() {
    if (_imageBytes == null) {
      return _buildErrorState();
    }

    final Widget imageWidget = Image.memory(
      _imageBytes!,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      // Use cacheWidth/cacheHeight for memory efficiency
      cacheWidth: (widget.element.width ?? _naturalSize?.width ?? 600).toInt(),
    );

    return MediaCommentOverlay(
      comment: widget.element.comment,
      onCommentChanged: _handleCommentChanged,
      child: InteractiveMediaWidget(
        element: widget.element,
        onChanged: _handleElementChanged,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        isSelected: _isSelected,
        child: imageWidget,
      ),
    );
  }

  Widget _buildControlOverlay() {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: _isHovering || _isSelected ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview mode toggle for large images
            if (widget.element.isImage && _isLargeImage())
              IconButton(
                icon: Icon(
                  widget.element.isPreviewMode
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  size: 18,
                ),
                onPressed: _togglePreviewMode,
                tooltip: widget.element.isPreviewMode
                    ? 'Exit preview mode'
                    : 'Enter preview mode',
                visualDensity: VisualDensity.compact,
              ),

            // Comment button
            IconButton(
              icon: Icon(
                widget.element.hasComment
                    ? Icons.comment
                    : Icons.add_comment_outlined,
                size: 18,
              ),
              onPressed: () {
                // Comment overlay handles this via hover/tap
              },
              tooltip: 'Comment',
              visualDensity: VisualDensity.compact,
            ),

            // Delete button
            if (widget.onDeleted != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: colorScheme.error,
                ),
                onPressed: _handleDelete,
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveHandle() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.open_with, size: 20, color: Colors.white),
    );
  }

  bool _isLargeImage() {
    if (_naturalSize == null) return false;
    return _naturalSize!.width > 2000 || _naturalSize!.height > 2000;
  }
}

/// Parses markdown content and extracts media elements
class MediaContentParser {
  MediaContentParser._();

  /// Regular expression for extended markdown media syntax
  /// Matches: ![alt|params](path)
  static final _mediaRegex = RegExp(
    r'!\[([^\|\]]*?)(?:\|([^\]]*))?\]\(([^)]+)\)',
  );

  /// Parse all media elements from markdown content
  static List<MediaParseResult> parseMarkdown(String content) {
    final results = <MediaParseResult>[];

    for (final match in _mediaRegex.allMatches(content)) {
      final element = MediaElement.fromMarkdownSyntax(match.group(0)!);
      if (element != null) {
        results.add(
          MediaParseResult(
            element: element,
            startIndex: match.start,
            endIndex: match.end,
            originalText: match.group(0)!,
          ),
        );
      }
    }

    return results;
  }

  /// Replace a media element in markdown content with updated syntax
  static String replaceElement(
    String content,
    MediaParseResult result,
    MediaElement newElement,
  ) {
    return content.replaceRange(
      result.startIndex,
      result.endIndex,
      newElement.toMarkdownSyntax(),
    );
  }

  /// Delete a media element from markdown content
  static String deleteElement(String content, MediaParseResult result) {
    // Also remove surrounding newlines if the media is on its own line
    var start = result.startIndex;
    var end = result.endIndex;

    // Check if preceded by newline
    if (start > 0 && content[start - 1] == '\n') {
      start--;
    }

    // Check if followed by newline
    if (end < content.length && content[end] == '\n') {
      end++;
    }

    return content.replaceRange(start, end, '');
  }

  /// Extract absolute local paths from text content
  /// Matches common path patterns like C:\..., /home/..., ~/...
  static List<String> extractLocalPaths(String content) {
    final paths = <String>[];

    // Windows absolute paths: C:\... or D:\...
    final windowsPathRegex = RegExp(r'[A-Za-z]:\\[^\s<>"|\*\?]+');
    for (final match in windowsPathRegex.allMatches(content)) {
      paths.add(match.group(0)!);
    }

    // Unix absolute paths: /home/... or /usr/...
    final unixPathRegex = RegExp(r'/(?:[^\s<>"|\*\?]+)');
    for (final match in unixPathRegex.allMatches(content)) {
      final path = match.group(0)!;
      // Filter out URLs by checking for common URL patterns
      if (!path.startsWith('//') &&
          !content.substring(0, match.start).endsWith('http:') &&
          !content.substring(0, match.start).endsWith('https:')) {
        paths.add(path);
      }
    }

    return paths.where(_isMediaFile).toList();
  }

  /// Extract web URLs for images from content
  static List<String> extractWebImageUrls(String content) {
    final urls = <String>[];

    final urlRegex = RegExp(
      r'https?://[^\s<>"]+\.(?:png|jpg|jpeg|gif|webp|bmp|svg)',
      caseSensitive: false,
    );

    for (final match in urlRegex.allMatches(content)) {
      urls.add(match.group(0)!);
    }

    return urls;
  }

  /// Check if a file path points to a media file
  static bool _isMediaFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm');
  }
}

/// Result of parsing a media element from content
class MediaParseResult {
  MediaParseResult({
    required this.element,
    required this.startIndex,
    required this.endIndex,
    required this.originalText,
  });

  final MediaElement element;
  final int startIndex;
  final int endIndex;
  final String originalText;
}
