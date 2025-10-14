import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdfrx/pdfrx.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as sf;
import 'dart:ui' as ui;
import '../models/annotation_data.dart';
import '../models/annotation_layer.dart';
import '../models/image_annotation.dart';
import '../models/drawing_tool.dart';
import '../painters/annotation_painter.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/image_annotation_widget.dart';
import '../services/annotation_storage.dart';
import '../services/image_service.dart';

class PDFViewerScreen extends StatefulWidget {
  final String? pdfPath;
  final Uint8List? pdfBytes;

  const PDFViewerScreen({super.key, required this.pdfPath}) : pdfBytes = null;

  const PDFViewerScreen.file({super.key, required this.pdfPath})
    : pdfBytes = null;

  const PDFViewerScreen.memory({super.key, required this.pdfBytes})
    : pdfPath = null;
  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  late PdfViewerController _pdfController;
  sf.PdfViewerController? _sfController;
  Widget? _pdfView;
  final Map<int, AnnotationLayer> _annotationsByPage = {};
  DrawingTool _currentTool = DrawingTool.pen;

  // Separate colors for pen and highlighter
  Color _penColor = Colors.black;
  Color _highlighterColor = Colors.yellow.withValues(alpha: 0.5);

  // Fixed eraser color - always light gray, never changes
  static const Color _eraserColor = Color(0xFFD3D3D3);

  double _currentStrokeWidth = 3.0;
  int _currentPageNumber = 0;
  List<Offset> _currentStrokePoints = [];
  AnnotationData? _currentStroke;
  Size? _currentPageSize;
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  int _activeTouchCount = 0;
  int _activeDrawingPointers = 0; // Track stylus/touch pointers for drawing
  bool get _shouldPassThroughGestures =>
      _activeTouchCount >= 2 || _activeDrawingPointers == 0;
  bool _isDrawing = false;

  // PDF coordinate transformation tracking
  Rect? _currentPageRect; // Page position and size in view coordinates

  // Image annotation editing state
  String? _selectedImageId;

  // Helper to get the current color based on tool
  Color get _currentColor {
    switch (_currentTool) {
      case DrawingTool.pen:
        return _penColor;
      case DrawingTool.highlighter:
        return _highlighterColor;
      case DrawingTool.eraser:
        return _eraserColor; // Always returns the fixed light gray
    }
  }

  @override
  void initState() {
    super.initState();
    _initializePDF();
  }
  // .

  Future<void> _initializePDF() async {
    try {
      if (kIsWeb) {
        _sfController = sf.PdfViewerController();
      } else {
        _pdfController = PdfViewerController();
        // Listen to PDF controller changes for zoom/scroll updates
        _pdfController.addListener(_onPdfViewChanged);
      }
      _pdfView = _buildPdfView();
      if (!kIsWeb && widget.pdfPath != null) {
        await _loadAnnotations();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error initializing PDF: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onPdfViewChanged() {
    // PDF view has changed (zoom, scroll, etc.)
    // Trigger a rebuild to update annotation rendering
    if (mounted) {
      setState(() {
        // The state change will trigger AnnotationPainter to repaint
        // with updated coordinate transformation
      });
    }
  }

  Widget _buildPdfView() {
    if (kIsWeb) {
      if (widget.pdfBytes != null) {
        return sf.SfPdfViewer.memory(
          widget.pdfBytes!,
          controller: _sfController,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          onPageChanged: (details) => _onPageChanged(details.newPageNumber - 1),
        );
      } else if (widget.pdfPath != null) {
        final path = widget.pdfPath!;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          return sf.SfPdfViewer.network(
            path,
            controller: _sfController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onPageChanged: (details) =>
                _onPageChanged(details.newPageNumber - 1),
          );
        } else {
          return sf.SfPdfViewer.asset(
            path,
            controller: _sfController,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            onPageChanged: (details) =>
                _onPageChanged(details.newPageNumber - 1),
          );
        }
      }
    }
    if (widget.pdfPath != null) {
      return PdfViewer.file(
        widget.pdfPath!,
        controller: _pdfController,
        params: PdfViewerParams(
          onPageChanged: (pageNumber) {
            if (pageNumber != null) _onPageChanged(pageNumber - 1);
          },
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    } else if (widget.pdfBytes != null) {
      return PdfViewer.data(
        widget.pdfBytes!,
        controller: _pdfController,
        sourceName: 'document.pdf',
        params: PdfViewerParams(
          onPageChanged: (pageNumber) {
            if (pageNumber != null) _onPageChanged(pageNumber - 1);
          },
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }
    return const Center(child: Text('No PDF source provided'));
  }

  Future<void> _loadAnnotations() async {
    try {
      if (widget.pdfPath == null) return;
      final annotations = await AnnotationStorage.loadFromFile(widget.pdfPath!);
      setState(() {
        _annotationsByPage.clear();
        _annotationsByPage.addAll(annotations);
      });
    } catch (e) {
      debugPrint('No existing annotations found or error loading: $e');
    }
  }

  Future<void> _saveAnnotations() async {
    try {
      if (kIsWeb || widget.pdfPath == null) {
        setState(() => _hasUnsavedChanges = false);
        return;
      }
      await AnnotationStorage.saveToFile(widget.pdfPath!, _annotationsByPage);
      setState(() => _hasUnsavedChanges = false);
      debugPrint('Annotations saved successfully');
    } catch (e) {
      debugPrint('Error saving annotations: $e');
    }
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _hasUnsavedChanges = true;
    _autoSaveTimer = Timer(const Duration(seconds: 3), () async {
      await _saveAnnotations();
    });
  }

  AnnotationLayer _getCurrentPageAnnotations() {
    if (!_annotationsByPage.containsKey(_currentPageNumber)) {
      _annotationsByPage[_currentPageNumber] = AnnotationLayer();
    }
    return _annotationsByPage[_currentPageNumber]!;
  }

  /// Converts screen/view coordinates to PDF page coordinates
  ///
  /// Takes into account:
  /// - Current zoom level
  /// - Scroll offset
  /// - PDF coordinate system (origin at bottom-left, y-axis points up)
  /// - Page position in the widget
  Offset _screenToPdfCoordinates(Offset screenPoint) {
    if (_currentPageSize == null) return screenPoint;

    // If we have page rect information (from pdfrx), use it for accurate transformation
    if (_currentPageRect != null && !kIsWeb) {
      // Account for page position in view
      final relativeX = screenPoint.dx - _currentPageRect!.left;
      final relativeY = screenPoint.dy - _currentPageRect!.top;

      // Scale from view coordinates to PDF coordinates
      final pdfX =
          (relativeX / _currentPageRect!.width) * _currentPageSize!.width;
      final pdfY =
          _currentPageSize!.height -
          ((relativeY / _currentPageRect!.height) * _currentPageSize!.height);

      return Offset(pdfX, pdfY);
    }

    // Fallback: Simple transformation (for web or when page rect unavailable)
    // Assumes page fills the widget area
    return Offset(screenPoint.dx, _currentPageSize!.height - screenPoint.dy);
  }

  /// Converts PDF page coordinates to screen/view coordinates
  ///
  /// Reverse transformation of _screenToPdfCoordinates
  Offset _pdfToScreenCoordinates(Offset pdfPoint) {
    if (_currentPageSize == null) return pdfPoint;

    // If we have page rect information, use it for accurate transformation
    if (_currentPageRect != null && !kIsWeb) {
      // Convert from PDF coordinates to normalized coordinates (0-1)
      final normalizedX = pdfPoint.dx / _currentPageSize!.width;
      final normalizedY =
          (_currentPageSize!.height - pdfPoint.dy) / _currentPageSize!.height;

      // Scale to view coordinates and account for page position
      final screenX =
          normalizedX * _currentPageRect!.width + _currentPageRect!.left;
      final screenY =
          normalizedY * _currentPageRect!.height + _currentPageRect!.top;

      return Offset(screenX, screenY);
    }

    // Fallback: Simple transformation
    return Offset(pdfPoint.dx, _currentPageSize!.height - pdfPoint.dy);
  }

  void _onPanStart(DragStartDetails details) {
    // Don't start drawing if multi-touch is active
    if (_shouldPassThroughGestures) return;

    _isDrawing = true;
    final pdfCoord = _screenToPdfCoordinates(details.localPosition);
    setState(() {
      _currentStrokePoints = [pdfCoord];

      // For eraser, create a visual feedback stroke (light gray) but don't store it as annotation
      _currentStroke = AnnotationData(
        strokePath: [pdfCoord],
        colorValue: _currentColor.toARGB32(),
        strokeWidth: _currentStrokeWidth,
        toolType: _currentTool,
        pageNumber: _currentPageNumber,
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null || !_isDrawing) return;
    final pdfCoord = _screenToPdfCoordinates(details.localPosition);
    if (_currentStrokePoints.isNotEmpty) {
      final distance = (pdfCoord - _currentStrokePoints.last).distance;
      if (distance < 3.0) return;
    }
    setState(() {
      _currentStrokePoints.add(pdfCoord);
      _currentStroke = _currentStroke!.copyWith(
        strokePath: List.from(_currentStrokePoints),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDrawing = false;
    if (_currentStroke == null || _currentStrokePoints.length < 2) {
      setState(() {
        _currentStroke = null;
        _currentStrokePoints.clear();
      });
      return;
    }
    if (_currentTool == DrawingTool.eraser) {
      // For eraser, remove intersecting strokes/images but don't save the eraser stroke itself
      _eraseStrokes();
    } else {
      // For pen and highlighter, save the stroke
      _getCurrentPageAnnotations().addAnnotation(_currentStroke!);
      _scheduleAutoSave();
    }
    setState(() {
      _currentStroke = null;
      _currentStrokePoints.clear();
    });
  }

  void _eraseStrokes() {
    const eraserRadius = 15.0;

    // Erase ink annotations
    final annotations = _getCurrentPageAnnotations().getAnnotationsForPage(
      _currentPageNumber,
    );
    final toRemove = <AnnotationData>[];
    for (final annotation in annotations) {
      for (final eraserPoint in _currentStrokePoints) {
        for (final strokePoint in annotation.strokePath) {
          if ((strokePoint - eraserPoint).distance <= eraserRadius) {
            toRemove.add(annotation);
            break;
          }
        }
        if (toRemove.contains(annotation)) break;
      }
    }
    for (final annotation in toRemove) {
      _getCurrentPageAnnotations().removeAnnotation(annotation);
    }

    // Erase image annotations that intersect with eraser path
    final imageAnnotations = _getCurrentPageAnnotations()
        .getImageAnnotationsForPage(_currentPageNumber);
    final imagesToRemove = <ImageAnnotation>[];

    for (final imageAnnotation in imageAnnotations) {
      for (final eraserPoint in _currentStrokePoints) {
        // Check if eraser point is within image bounds
        final imgRect = Rect.fromLTWH(
          imageAnnotation.position.dx,
          imageAnnotation.position.dy - imageAnnotation.size.height,
          imageAnnotation.size.width,
          imageAnnotation.size.height,
        );

        // Create eraser circle region
        final eraserCircle = Rect.fromCircle(
          center: eraserPoint,
          radius: eraserRadius,
        );

        if (imgRect.overlaps(eraserCircle)) {
          imagesToRemove.add(imageAnnotation);
          break;
        }
      }
    }

    for (final imageAnnotation in imagesToRemove) {
      _getCurrentPageAnnotations().removeImageAnnotation(imageAnnotation);
    }

    if (toRemove.isNotEmpty || imagesToRemove.isNotEmpty) {
      _scheduleAutoSave();
    }
  }

  void _onPageChanged(int pageNumber) {
    if (_hasUnsavedChanges) _saveAnnotations();
    setState(() {
      _currentPageNumber = pageNumber;
      _currentStroke = null;
      _currentStrokePoints.clear();
    });
  }

  void _undoLastStroke() {
    if (_getCurrentPageAnnotations().undoLastStroke() != null) {
      setState(() {});
      _scheduleAutoSave();
    }
  }

  void _redoLastStroke() {
    if (_getCurrentPageAnnotations().redoLastUndo()) {
      setState(() {});
      _scheduleAutoSave();
    }
  }

  void _clearCurrentPage() {
    _getCurrentPageAnnotations().clearPage(_currentPageNumber);
    setState(() {});
    _scheduleAutoSave();
  }

  // Image annotation methods
  Future<void> _insertImageFromClipboard() async {
    try {
      final imageBytes = await ImageService.getImageFromClipboard();

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image found in clipboard')),
          );
        }
        return;
      }

      if (!ImageService.isValidImageData(imageBytes)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid image format')));
        }
        return;
      }

      await _addImageAnnotation(imageBytes);
    } catch (e) {
      debugPrint('Error inserting image from clipboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inserting image: $e')));
      }
    }
  }

  Future<void> _insertImageFromFile() async {
    try {
      final imageBytes = await ImageService.pickImageFromFile();

      if (imageBytes == null) {
        return; // User cancelled
      }

      if (!ImageService.isValidImageData(imageBytes)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid image format')));
        }
        return;
      }

      await _addImageAnnotation(imageBytes);
    } catch (e) {
      debugPrint('Error inserting image from file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inserting image: $e')));
      }
    }
  }

  Future<void> _addImageAnnotation(Uint8List imageBytes) async {
    try {
      // Decode image to get dimensions
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final originalWidth = image.width.toDouble();
      final originalHeight = image.height.toDouble();

      // Calculate size to fit within page (max 300px width/height)
      const maxDimension = 300.0;
      double width = originalWidth;
      double height = originalHeight;

      if (width > maxDimension || height > maxDimension) {
        final scale = maxDimension / (width > height ? width : height);
        width *= scale;
        height *= scale;
      }

      // Get page size for positioning
      final pageSize = _currentPageSize ?? const Size(595, 842); // A4 default

      // Position at center of page
      final position = Offset(
        (pageSize.width - width) / 2,
        pageSize.height - height - 100, // 100px from top in PDF coordinates
      );

      // Create image annotation
      final imageAnnotation = ImageAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageBytes: imageBytes,
        position: position,
        size: Size(width, height),
        pageNumber: _currentPageNumber,
        createdAt: DateTime.now(),
      );

      // Add to current page
      _getCurrentPageAnnotations().addImageAnnotation(imageAnnotation);

      setState(() {});
      _scheduleAutoSave();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image added')));
      }
    } catch (e) {
      debugPrint('Error adding image annotation: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing image: $e')));
      }
    }
  }

  void _updateImageAnnotation(ImageAnnotation updated) {
    _getCurrentPageAnnotations().updateImageAnnotation(updated);
    setState(() {});
    _scheduleAutoSave();
  }

  void _deleteImageAnnotation(ImageAnnotation image) {
    _getCurrentPageAnnotations().removeImageAnnotation(image);
    setState(() {});
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading PDF...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // Handle Ctrl+V for paste
        if (event is KeyDownEvent) {
          if ((event.logicalKey == LogicalKeyboardKey.keyV) &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            _insertImageFromClipboard();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Page ${_currentPageNumber + 1}'),
          actions: [
            if (_hasUnsavedChanges)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.circle, size: 8, color: Colors.orange),
              ),
          ],
        ),
        body: Stack(
          children: [
            // PDF viewer
            Positioned.fill(
              child: _pdfView != null
                  ? RepaintBoundary(child: _pdfView!)
                  : const SizedBox.shrink(),
            ),

            // Annotation overlay - only intercepts stylus and single-finger touches
            Positioned.fill(
              child: GestureDetector(
                // Tap outside to deselect any selected image
                onTapDown: (details) {
                  if (_selectedImageId != null) {
                    setState(() {
                      _selectedImageId = null;
                    });
                  }
                },
                behavior: HitTestBehavior.translucent,
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    setState(() {
                      _activeTouchCount++;

                      // Only track stylus or touch devices for drawing
                      if (event.kind == PointerDeviceKind.stylus ||
                          event.kind == PointerDeviceKind.touch ||
                          event.kind == PointerDeviceKind.invertedStylus) {
                        _activeDrawingPointers++;
                      }

                      // Cancel any active drawing if multi-touch starts
                      if (_activeTouchCount >= 2 && _isDrawing) {
                        _isDrawing = false;
                        _currentStroke = null;
                        _currentStrokePoints.clear();
                      }
                    });
                  },
                  onPointerUp: (event) {
                    setState(() {
                      _activeTouchCount = (_activeTouchCount - 1).clamp(0, 10);

                      // Decrease drawing pointer count for stylus/touch
                      if (event.kind == PointerDeviceKind.stylus ||
                          event.kind == PointerDeviceKind.touch ||
                          event.kind == PointerDeviceKind.invertedStylus) {
                        _activeDrawingPointers = (_activeDrawingPointers - 1)
                            .clamp(0, 10);
                      }
                    });
                  },
                  onPointerCancel: (event) {
                    setState(() {
                      _activeTouchCount = (_activeTouchCount - 1).clamp(0, 10);

                      // Decrease drawing pointer count for stylus/touch
                      if (event.kind == PointerDeviceKind.stylus ||
                          event.kind == PointerDeviceKind.touch ||
                          event.kind == PointerDeviceKind.invertedStylus) {
                        _activeDrawingPointers = (_activeDrawingPointers - 1)
                            .clamp(0, 10);
                      }

                      _isDrawing = false;
                    });
                  },
                  child: IgnorePointer(
                    // Ignore pointer events when:
                    // 1. Multi-touch is active (2+ fingers for zoom/scroll)
                    // 2. No drawing pointers are active (mouse/trackpad)
                    ignoring: _shouldPassThroughGestures,
                    child: GestureDetector(
                      behavior: _shouldPassThroughGestures
                          ? HitTestBehavior.translucent
                          : HitTestBehavior.opaque,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Update page rect for coordinate transformation
                          // This assumes the annotation overlay fills the same area as the PDF
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_currentPageRect == null ||
                                _currentPageRect!.width !=
                                    constraints.maxWidth ||
                                _currentPageRect!.height !=
                                    constraints.maxHeight) {
                              setState(() {
                                _currentPageRect = Rect.fromLTWH(
                                  0,
                                  0,
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                              });
                            }
                          });

                          return CustomPaint(
                            painter: AnnotationPainter(
                              annotations: _getCurrentPageAnnotations()
                                  .getAnnotationsForPage(_currentPageNumber),
                              currentStroke: _currentStroke,
                              pdfToScreenTransform: _pdfToScreenCoordinates,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 16,
              right: 16,
              child: ToolbarWidget(
                currentTool: _currentTool,
                currentColor: _currentColor,
                currentStrokeWidth: _currentStrokeWidth,
                onToolChanged: (tool) {
                  setState(() {
                    _currentTool = tool;
                    if (tool == DrawingTool.highlighter) {
                      if (_currentStrokeWidth < 8.0) {
                        _currentStrokeWidth = 8.0;
                      } else if (_currentStrokeWidth > 20.0) {
                        _currentStrokeWidth = 20.0;
                      }
                    } else {
                      if (_currentStrokeWidth < 1.0) {
                        _currentStrokeWidth = 1.0;
                      } else if (_currentStrokeWidth > 10.0) {
                        _currentStrokeWidth = 10.0;
                      }
                    }
                  });
                },
                onColorChanged: (color) {
                  setState(() {
                    // Update color based on current tool
                    switch (_currentTool) {
                      case DrawingTool.pen:
                        _penColor = color;
                        break;
                      case DrawingTool.highlighter:
                        _highlighterColor = color;
                        break;
                      case DrawingTool.eraser:
                        // Eraser color is fixed, don't change it
                        break;
                    }
                  });
                },
                onStrokeWidthChanged: (width) =>
                    setState(() => _currentStrokeWidth = width),
                onUndo: _undoLastStroke,
                onRedo: _redoLastStroke,
                onClear: _clearCurrentPage,
                onSave: _saveAnnotations,
                onInsertImage: _insertImageFromFile,
              ),
            ),

            // Image annotations - rendered on top
            ...(_getCurrentPageAnnotations()
                .getImageAnnotationsForPage(_currentPageNumber)
                .map(
                  (imageAnnotation) => ImageAnnotationWidget(
                    imageAnnotation: imageAnnotation,
                    onUpdate: _updateImageAnnotation,
                    onDelete: _deleteImageAnnotation,
                    pageSize: _currentPageSize ?? const Size(595, 842),
                    pdfToScreenTransform: _pdfToScreenCoordinates,
                    screenToPdfTransform: _screenToPdfCoordinates,
                    isSelected: _selectedImageId == imageAnnotation.id,
                    onSelect: () {
                      setState(() {
                        _selectedImageId = imageAnnotation.id;
                      });
                    },
                    onDeselect: () {
                      setState(() {
                        _selectedImageId = null;
                      });
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (!kIsWeb) {
      _pdfController.removeListener(_onPdfViewChanged);
    }
    if (_hasUnsavedChanges && !kIsWeb && widget.pdfPath != null) {
      _saveAnnotations();
    }
    super.dispose();
  }
}
