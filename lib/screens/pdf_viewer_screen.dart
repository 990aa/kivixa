import 'dart:async';
import 'dart:typed_data';
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
  Color _currentColor = Colors.black;
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

  @override
  void initState() {
    super.initState();
    _initializePDF();
  }

  Future<void> _initializePDF() async {
    try {
      if (kIsWeb) {
        _sfController = sf.PdfViewerController();
      } else {
        _pdfController = PdfViewerController();
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

  Offset _screenToPdfCoordinates(Offset screenPoint) {
    if (_currentPageSize == null) return screenPoint;
    return Offset(screenPoint.dx, _currentPageSize!.height - screenPoint.dy);
  }

  void _onPanStart(DragStartDetails details) {
    // Don't start drawing if multi-touch is active
    if (_shouldPassThroughGestures) return;

    _isDrawing = true;
    final pdfCoord = _screenToPdfCoordinates(details.localPosition);
    setState(() {
      _currentStrokePoints = [pdfCoord];
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
      _eraseStrokes();
    } else {
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
    if (toRemove.isNotEmpty) _scheduleAutoSave();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading PDF...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
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
                    _activeDrawingPointers = (_activeDrawingPointers - 1).clamp(
                      0,
                      10,
                    );
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
                    _activeDrawingPointers = (_activeDrawingPointers - 1).clamp(
                      0,
                      10,
                    );
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
                  child: CustomPaint(
                    painter: AnnotationPainter(
                      annotations: _getCurrentPageAnnotations()
                          .getAnnotationsForPage(_currentPageNumber),
                      currentStroke: _currentStroke,
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
              onColorChanged: (color) => setState(() => _currentColor = color),
              onStrokeWidthChanged: (width) =>
                  setState(() => _currentStrokeWidth = width),
              onUndo: _undoLastStroke,
              onRedo: _redoLastStroke,
              onClear: _clearCurrentPage,
              onSave: _saveAnnotations,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (_hasUnsavedChanges && !kIsWeb && widget.pdfPath != null) {
      _saveAnnotations();
    }
    super.dispose();
  }
}
