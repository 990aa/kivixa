import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kivixa/components/media/embedded_media_renderer.dart';
import 'package:kivixa/data/models/media_element.dart';

/// A builder widget that renders interactive media elements in markdown content.
///
/// This widget handles:
/// - Parsing extended markdown syntax for media
/// - Rendering interactive media widgets with resize/rotate/drag
/// - Updating markdown syntax when media properties change
/// - Performance optimization via lazy loading and caching
///
/// Usage in markdown preview:
/// ```dart
/// SmoothMarkdown(
///   data: markdownContent,
///   imageBuilder: (uri, title, alt) {
///     return MarkdownMediaBuilder(
///       markdownSyntax: '![$alt]($uri)',
///       onSyntaxChanged: (newSyntax) {
///         // Update markdown content with new syntax
///       },
///     );
///   },
/// )
/// ```
class MarkdownMediaBuilder extends StatefulWidget {
  const MarkdownMediaBuilder({
    super.key,
    required this.markdownSyntax,
    required this.onSyntaxChanged,
    this.onDeleted,
    this.isEditable = true,
    this.showControls = true,
  });

  /// The original markdown syntax for the media
  /// e.g., '![Alt|width=300,height=200](path/to/image.jpg)'
  final String markdownSyntax;

  /// Callback when the markdown syntax changes (resize, rotate, etc.)
  final ValueChanged<String> onSyntaxChanged;

  /// Callback when the media is deleted
  final VoidCallback? onDeleted;

  /// Whether the media can be edited
  final bool isEditable;

  /// Whether to show control buttons
  final bool showControls;

  @override
  State<MarkdownMediaBuilder> createState() => _MarkdownMediaBuilderState();
}

class _MarkdownMediaBuilderState extends State<MarkdownMediaBuilder> {
  MediaElement? _element;

  @override
  void initState() {
    super.initState();
    _parseElement();
  }

  @override
  void didUpdateWidget(MarkdownMediaBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdownSyntax != widget.markdownSyntax) {
      _parseElement();
    }
  }

  void _parseElement() {
    final element = MediaElement.fromMarkdownSyntax(widget.markdownSyntax);
    setState(() => _element = element);
  }

  void _handleElementChanged(MediaElement newElement) {
    final newSyntax = newElement.toMarkdownSyntax();
    widget.onSyntaxChanged(newSyntax);
    setState(() => _element = newElement);
  }

  void _handleDeleted(MediaElement element) {
    widget.onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_element == null) {
      return _buildFallback();
    }

    return EmbeddedMediaRenderer(
      element: _element!,
      onChanged: _handleElementChanged,
      onDeleted: widget.onDeleted != null ? _handleDeleted : null,
      isEditable: widget.isEditable,
      showControls: widget.showControls,
    );
  }

  Widget _buildFallback() {
    // Simple fallback for non-parseable syntax
    final urlMatch = RegExp(r'\]\(([^)]+)\)').firstMatch(widget.markdownSyntax);
    final url = urlMatch?.group(1) ?? '';

    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    // Try to display as a simple image
    Widget imageWidget;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget(loadingProgress);
        },
      );
    } else {
      final file = File(url);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      } else {
        imageWidget = _buildErrorWidget();
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageWidget,
      ),
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent progress) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 150,
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
        ],
      ),
    );
  }
}

/// Widget that renders media from a URL (local path or web URL).
///
/// This is a simpler alternative to MarkdownMediaBuilder that handles
/// basic image/video display without the full markdown parsing.
class MediaUrlWidget extends StatefulWidget {
  const MediaUrlWidget({
    super.key,
    required this.url,
    this.altText,
    this.width,
    this.height,
    this.onSizeChanged,
    this.isInteractive = true,
  });

  /// The URL or path to the media
  final String url;

  /// Alt text for accessibility
  final String? altText;

  /// Initial width
  final double? width;

  /// Initial height
  final double? height;

  /// Callback when size changes (after resize)
  final ValueChanged<Size>? onSizeChanged;

  /// Whether to enable interactive features
  final bool isInteractive;

  @override
  State<MediaUrlWidget> createState() => _MediaUrlWidgetState();
}

class _MediaUrlWidgetState extends State<MediaUrlWidget> {
  late MediaElement _element;

  @override
  void initState() {
    super.initState();
    _initElement();
  }

  @override
  void didUpdateWidget(MediaUrlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height) {
      _initElement();
    }
  }

  void _initElement() {
    final isWeb = widget.url.startsWith('http://') ||
        widget.url.startsWith('https://');
    final mediaType = _getMediaType(widget.url);

    _element = MediaElement(
      path: widget.url,
      mediaType: mediaType,
      sourceType: isWeb ? MediaSourceType.web : MediaSourceType.local,
      altText: widget.altText ?? '',
      width: widget.width,
      height: widget.height,
    );
  }

  MediaType _getMediaType(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm')) {
      return MediaType.video;
    }
    return MediaType.image;
  }

  void _handleChanged(MediaElement element) {
    setState(() => _element = element);
    if (element.width != null && element.height != null) {
      widget.onSizeChanged?.call(Size(element.width!, element.height!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmbeddedMediaRenderer(
      element: _element,
      onChanged: _handleChanged,
      isEditable: widget.isInteractive,
      showControls: widget.isInteractive,
    );
  }
}

/// Widget that manages multiple media elements in a document.
///
/// Handles:
/// - Tracking all media elements in the document
/// - Coordinating changes to the underlying content
/// - Performance optimization via widget pooling
class MediaDocumentManager extends StatefulWidget {
  const MediaDocumentManager({
    super.key,
    required this.content,
    required this.onContentChanged,
    required this.childBuilder,
  });

  /// The document content containing media elements
  final String content;

  /// Callback when content changes
  final ValueChanged<String> onContentChanged;

  /// Builder for non-media content
  final Widget Function(BuildContext context, String content) childBuilder;

  @override
  State<MediaDocumentManager> createState() => _MediaDocumentManagerState();
}

class _MediaDocumentManagerState extends State<MediaDocumentManager> {
  List<MediaParseResult> _mediaElements = [];
  final _elementKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _parseContent();
  }

  @override
  void didUpdateWidget(MediaDocumentManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _parseContent();
    }
  }

  void _parseContent() {
    _mediaElements = MediaContentParser.parseMarkdown(widget.content);
  }

  void _handleMediaChanged(MediaParseResult result, MediaElement newElement) {
    final newContent = MediaContentParser.replaceElement(
      widget.content,
      result,
      newElement,
    );
    widget.onContentChanged(newContent);
  }

  void _handleMediaDeleted(MediaParseResult result) {
    final newContent = MediaContentParser.deleteElement(
      widget.content,
      result,
    );
    widget.onContentChanged(newContent);
  }

  @override
  Widget build(BuildContext context) {
    // Build content with media elements replaced by widgets
    final widgets = <Widget>[];
    var lastEnd = 0;

    for (final result in _mediaElements) {
      // Add text before this media element
      if (result.startIndex > lastEnd) {
        final textContent = widget.content.substring(lastEnd, result.startIndex);
        widgets.add(widget.childBuilder(context, textContent));
      }

      // Add media widget
      final key = _elementKeys.putIfAbsent(
        result.element.path,
        () => GlobalKey(),
      );

      widgets.add(
        RepaintBoundary(
          key: key,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: EmbeddedMediaRenderer(
              element: result.element,
              onChanged: (element) => _handleMediaChanged(result, element),
              onDeleted: (element) => _handleMediaDeleted(result),
            ),
          ),
        ),
      );

      lastEnd = result.endIndex;
    }

    // Add remaining text after last media element
    if (lastEnd < widget.content.length) {
      final textContent = widget.content.substring(lastEnd);
      widgets.add(widget.childBuilder(context, textContent));
    }

    // If no media elements, just build the content
    if (widgets.isEmpty) {
      return widget.childBuilder(context, widget.content);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
