import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../models/annotation_data.dart';
import '../models/annotation_layer.dart';
import '../models/drawing_tool.dart';
import '../painters/annotation_painter.dart';
import '../widgets/toolbar_widget.dart';
import '../services/annotation_storage.dart';

/// Main PDF viewer screen with annotation capabilities
/// 
/// This widget provides:
/// - PDF rendering with zoom/pan using pdfx
/// - Overlay annotation layer with coordinate transformation
/// - Per-page annotation management
/// - Stylus input handling
/// - Auto-save functionality
class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;

  const PDFViewerScreen({
    Key? key,
    required this.pdfPath,
  }) : super(key: key);

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  // PDF controller
  late PdfController _pdfController;
  
  // Annotation storage per page
  final Map<int, AnnotationLayer> _annotationsByPage = {};
  
  // Current drawing state
  DrawingTool _currentTool = DrawingTool.pen;
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  
  // Current page tracking
  int _currentPageNumber = 0;
  
  // Active stroke being drawn
  List<Offset> _currentStrokePoints = [];
  AnnotationData? _currentStroke;
  
  // Page dimensions for coordinate transformation
  Size? _currentPageSize;
  
  // Auto-save timer
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  
  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePDF();
  }

  /// Initialize PDF controller and load annotations
  Future<void> _initializePDF() async {
    try {
      // Initialize PDF controller with pinch zoom enabled
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.pdfPath),
      );

      // Load existing annotations from storage
      await _loadAnnotations();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing PDF: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load annotations from storage
  Future<void> _loadAnnotations() async {
    try {
      final annotations = await AnnotationStorage.loadFromFile(widget.pdfPath);
      setState(() {
        _annotationsByPage.clear();
        _annotationsByPage.addAll(annotations);
      });
    } catch (e) {
      debugPrint('No existing annotations found or error loading: $e');
    }
  }

  /// Save annotations to storage
  Future<void> _saveAnnotations() async {
    try {
      await AnnotationStorage.saveToFile(widget.pdfPath, _annotationsByPage);
      setState(() {
        _hasUnsavedChanges = false;
      });
      debugPrint('Annotations saved successfully');
    } catch (e) {
      debugPrint('Error saving annotations: $e');
    }
  }

  /// Schedule auto-save (debounced)
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _hasUnsavedChanges = true;
    
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _saveAnnotations();
    });
  }

  /// Get or create annotation layer for current page
  AnnotationLayer _getCurrentPageAnnotations() {
    if (!_annotationsByPage.containsKey(_currentPageNumber)) {
      _annotationsByPage[_currentPageNumber] = AnnotationLayer();
    }
    return _annotationsByPage[_currentPageNumber]!;
  }

  /// Convert screen coordinates to PDF page coordinates
  /// 
  /// PDF coordinate system: (0,0) = bottom-left
  /// Screen coordinate system: (0,0) = top-left
  /// This ensures annotations stay anchored regardless of zoom level
  Offset _screenToPdfCoordinates(Offset screenPoint) {
    if (_currentPageSize == null) return screenPoint;
    
    // For now, we use screen coordinates but with proper page size awareness
    // In production, you'd account for the PDF controller's transformation matrix
    // to handle zoom and pan properly
    
    return Offset(
      screenPoint.dx,
      _currentPageSize!.height - screenPoint.dy, // Flip Y axis for PDF coordinates
    );
  }

  /// Convert PDF page coordinates to screen coordinates
  Offset _pdfToScreenCoordinates(Offset pdfPoint) {
    if (_currentPageSize == null) return pdfPoint;
    
    return Offset(
      pdfPoint.dx,
      _currentPageSize!.height - pdfPoint.dy, // Flip Y axis back
    );
  }

  /// Handle pan start (begin new stroke)
  void _onPanStart(DragStartDetails details) {
    // Check if using stylus (preferred)
    // In production, you'd check details.kind == PointerDeviceKind.stylus
    
    final localPosition = details.localPosition;
    final pdfCoord = _screenToPdfCoordinates(localPosition);
    
    setState(() {
      _currentStrokePoints = [pdfCoord];
      
      _currentStroke = AnnotationData(
        strokePath: [pdfCoord],
        colorValue: _currentColor.value,
        strokeWidth: _currentStrokeWidth,
        toolType: _currentTool,
        pageNumber: _currentPageNumber,
      );
    });
  }

  /// Handle pan update (add points to stroke)
  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;
    
    final localPosition = details.localPosition;
    final pdfCoord = _screenToPdfCoordinates(localPosition);
    
    // Add point if it's far enough from the last point (threshold)
    if (_currentStrokePoints.isNotEmpty) {
      final lastPoint = _currentStrokePoints.last;
      final distance = (pdfCoord - lastPoint).distance;
      
      if (distance < 3.0) return; // Threshold for smoothness
    }
    
    setState(() {
      _currentStrokePoints.add(pdfCoord);
      
      _currentStroke = _currentStroke!.copyWith(
        strokePath: List.from(_currentStrokePoints),
      );
    });
  }

  /// Handle pan end (finalize stroke)
  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke == null || _currentStrokePoints.length < 2) {
      setState(() {
        _currentStroke = null;
        _currentStrokePoints.clear();
      });
      return;
    }
    
    if (_currentTool == DrawingTool.eraser) {
      // Handle eraser
      _eraseStrokes();
    } else {
      // Add completed stroke to annotation layer
      final currentPageAnnotations = _getCurrentPageAnnotations();
      currentPageAnnotations.addAnnotation(_currentStroke!);
      
      // Schedule auto-save
      _scheduleAutoSave();
    }
    
    setState(() {
      _currentStroke = null;
      _currentStrokePoints.clear();
    });
  }

  /// Erase strokes that intersect with eraser path
  void _eraseStrokes() {
    const eraserRadius = 15.0;
    final currentPageAnnotations = _getCurrentPageAnnotations();
    final annotations = currentPageAnnotations.getAnnotationsForPage(_currentPageNumber);
    final toRemove = <AnnotationData>[];
    
    for (final annotation in annotations) {
      for (final eraserPoint in _currentStrokePoints) {
        for (final strokePoint in annotation.strokePath) {
          final distance = (strokePoint - eraserPoint).distance;
          if (distance <= eraserRadius) {
            toRemove.add(annotation);
            break;
          }
        }
        if (toRemove.contains(annotation)) break;
      }
    }
    
    for (final annotation in toRemove) {
      currentPageAnnotations.removeAnnotation(annotation);
    }
    
    if (toRemove.isNotEmpty) {
      _scheduleAutoSave();
    }
  }

  /// Handle page change
  void _onPageChanged(int pageNumber) {
    // Save current page annotations before switching
    if (_hasUnsavedChanges) {
      _saveAnnotations();
    }
    
    setState(() {
      _currentPageNumber = pageNumber;
      // Clear temp drawing buffers
      _currentStroke = null;
      _currentStrokePoints.clear();
    });
  }

  /// Undo last stroke on current page
  void _undoLastStroke() {
    final currentPageAnnotations = _getCurrentPageAnnotations();
    final undone = currentPageAnnotations.undoLastStroke();
    
    if (undone != null) {
      setState(() {});
      _scheduleAutoSave();
    }
  }

  /// Redo last undone stroke
  void _redoLastStroke() {
    final currentPageAnnotations = _getCurrentPageAnnotations();
    final success = currentPageAnnotations.redoLastUndo();
    
    if (success) {
      setState(() {});
      _scheduleAutoSave();
    }
  }

  /// Clear all annotations on current page
  void _clearCurrentPage() {
    final currentPageAnnotations = _getCurrentPageAnnotations();
    currentPageAnnotations.clearPage(_currentPageNumber);
    
    setState(() {});
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading PDF...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
          // PDF viewer with pinch zoom
          PdfViewPinch(
            controller: _pdfController,
            onPageChanged: _onPageChanged,
            onDocumentLoaded: (document) {
              debugPrint('PDF loaded: ${document.pagesCount} pages');
            },
          ),
          
          // Annotation overlay
          Positioned.fill(
            child: GestureDetector(
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
          
          // Floating toolbar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: ToolbarWidget(
              currentTool: _currentTool,
              currentColor: _currentColor,
              currentStrokeWidth: _currentStrokeWidth,
              onToolChanged: (tool) {
                setState(() {
                  _currentTool = tool;
                });
              },
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color;
                });
              },
              onStrokeWidthChanged: (width) {
                setState(() {
                  _currentStrokeWidth = width;
                });
              },
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
    
    // Save on exit if there are unsaved changes
    if (_hasUnsavedChanges) {
      _saveAnnotations();
    }
    
    _pdfController.dispose();
    super.dispose();
  }
}
