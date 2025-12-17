import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kivixa/data/models/media_element.dart';
import 'package:kivixa/data/prefs.dart';
import 'package:kivixa/services/media_service.dart';

/// Widget for displaying large images in a scrollable preview container.
///
/// Features:
/// - Constrained container that fits the image in a smaller viewport
/// - Pan/zoom within container using InteractiveViewer
/// - Toggle between preview and full modes
/// - Minimap showing current visible region
class ImagePreviewWidget extends StatefulWidget {
  const ImagePreviewWidget({
    super.key,
    required this.element,
    required this.onChanged,
    this.onExitPreview,
  });

  /// The media element
  final MediaElement element;

  /// Callback when element changes (scroll position, etc)
  final ValueChanged<MediaElement> onChanged;

  /// Callback to exit preview mode
  final VoidCallback? onExitPreview;

  @override
  State<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<ImagePreviewWidget> {
  final _transformationController = TransformationController();

  Uint8List? _imageBytes;
  var _isLoading = true;
  Size? _naturalSize;

  // Minimap state
  Rect _visibleRect = Rect.zero;
  var _showMinimap = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _transformationController.addListener(_onTransformChanged);

    // Initialize from saved scroll position
    if (widget.element.scrollOffsetX != 0 ||
        widget.element.scrollOffsetY != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transformationController.value = Matrix4.identity()
          ..translate(
            -widget.element.scrollOffsetX,
            -widget.element.scrollOffsetY,
          );
      });
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await MediaService.instance.resolveMedia(widget.element);
    if (bytes != null && mounted) {
      // Decode to get natural size
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();

      setState(() {
        _imageBytes = bytes;
        _naturalSize = Size(
          frameInfo.image.width.toDouble(),
          frameInfo.image.height.toDouble(),
        );
        _isLoading = false;
      });

      frameInfo.image.dispose();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onTransformChanged() {
    if (_naturalSize == null) return;

    final matrix = _transformationController.value;
    final translation = matrix.getTranslation();
    final scale = matrix.getMaxScaleOnAxis();

    // Calculate visible rect for minimap
    final containerSize = _getContainerSize();
    final visibleWidth = containerSize.width / scale;
    final visibleHeight = containerSize.height / scale;

    setState(() {
      _visibleRect = Rect.fromLTWH(
        -translation.x / scale,
        -translation.y / scale,
        visibleWidth,
        visibleHeight,
      );
    });
  }

  Size _getContainerSize() {
    final previewWidth =
        widget.element.previewWidth ?? stows.mediaPreviewMaxSize.value;
    final previewHeight =
        widget.element.previewHeight ?? stows.mediaPreviewMaxSize.value;
    return Size(previewWidth, previewHeight);
  }

  void _saveScrollPosition() {
    final translation = _transformationController.value.getTranslation();
    widget.onChanged(
      widget.element.copyWith(
        scrollOffsetX: -translation.x,
        scrollOffsetY: -translation.y,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final containerSize = _getContainerSize();

    return Container(
      width: containerSize.width,
      height: containerSize.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Main content
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: _buildContent(),
          ),

          // Controls overlay
          Positioned(top: 8, right: 8, child: _buildControls(colorScheme)),

          // Minimap
          if (_showMinimap && _naturalSize != null && !_isLoading)
            Positioned(bottom: 8, right: 8, child: _buildMinimap(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_imageBytes == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      constrained: false,
      onInteractionEnd: (_) => _saveScrollPosition(),
      child: Image.memory(
        _imageBytes!,
        fit: BoxFit.none,
        gaplessPlayback: true,
      ),
    );
  }

  Widget _buildControls(ColorScheme colorScheme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle minimap
          IconButton(
            icon: Icon(_showMinimap ? Icons.map : Icons.map_outlined, size: 18),
            onPressed: () => setState(() => _showMinimap = !_showMinimap),
            tooltip: 'Toggle minimap',
            visualDensity: VisualDensity.compact,
          ),

          // Reset zoom
          IconButton(
            icon: const Icon(Icons.fit_screen, size: 18),
            onPressed: () {
              _transformationController.value = Matrix4.identity();
            },
            tooltip: 'Reset zoom',
            visualDensity: VisualDensity.compact,
          ),

          // Exit preview mode
          if (widget.onExitPreview != null)
            IconButton(
              icon: const Icon(Icons.fullscreen_exit, size: 18),
              onPressed: widget.onExitPreview,
              tooltip: 'Exit preview mode',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildMinimap(ColorScheme colorScheme) {
    if (_naturalSize == null) return const SizedBox.shrink();

    const minimapSize = 80.0;
    final aspectRatio = _naturalSize!.width / _naturalSize!.height;
    final minimapWidth = aspectRatio > 1
        ? minimapSize
        : minimapSize * aspectRatio;
    final minimapHeight = aspectRatio > 1
        ? minimapSize / aspectRatio
        : minimapSize;

    // Scale visible rect to minimap coordinates
    final scaleX = minimapWidth / _naturalSize!.width;
    final scaleY = minimapHeight / _naturalSize!.height;

    final minimapRect = Rect.fromLTWH(
      (_visibleRect.left * scaleX).clamp(0, minimapWidth),
      (_visibleRect.top * scaleY).clamp(0, minimapHeight),
      (_visibleRect.width * scaleX).clamp(0, minimapWidth),
      (_visibleRect.height * scaleY).clamp(0, minimapHeight),
    );

    return Container(
      width: minimapWidth,
      height: minimapHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          // Thumbnail
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.memory(
                _imageBytes!,
                width: minimapWidth,
                height: minimapHeight,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),

          // Visible region indicator
          Positioned(
            left: minimapRect.left,
            top: minimapRect.top,
            child: Container(
              width: minimapRect.width,
              height: minimapRect.height,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 2),
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
