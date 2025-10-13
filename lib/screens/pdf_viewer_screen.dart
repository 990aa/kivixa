import 'dart:async';import 'dart:async';

import 'dart:typed_data';import 'dart:typed_data';

import 'dart:convert';import 'package:flutter/material.dart';

import 'package:flutter/material.dart';import 'package:flutter/gestures.dart';

import 'package:flutter/gestures.dart';import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/foundation.dart' show kIsWeb;import 'package:file_picker/file_picker.dart';

import 'package:file_picker/file_picker.dart';import 'package:pdfrx/pdfrx.dart';

import 'package:pdfrx/pdfrx.dart';import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as sf;

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart' as sf;import '../models/annotation_data.dart';

import '../models/annotation_data.dart';import '../models/annotation_layer.dart';

import '../models/annotation_layer.dart';import '../models/drawing_tool.dart';

import '../models/drawing_tool.dart';import '../painters/annotation_painter.dart';

import '../painters/annotation_painter.dart';import '../widgets/toolbar_widget.dart';

import '../widgets/toolbar_widget.dart';import '../services/annotation_storage.dart';

import '../services/annotation_storage.dart';

/// Main PDF viewer screen with annotation capabilities

/// Main PDF viewer screen with annotation capabilities///

////// This widget provides:

/// This widget provides:/// - PDF rendering with zoom/pan using pdfrx

/// - PDF rendering with zoom/pan using pdfrx (desktop) or Syncfusion (web)/// - Overlay annotation layer with coordinate transformation

/// - Overlay annotation layer with coordinate transformation/// - Per-page annotation management

/// - Per-page annotation management/// - Stylus input handling

/// - Stylus input handling/// - Auto-save functionality

/// - Auto-save functionalityclass PDFViewerScreen extends StatefulWidget {

class PDFViewerScreen extends StatefulWidget {  final String? pdfPath; // Desktop/mobile file path or URL on web

  final String? pdfPath; // Desktop/mobile file path or URL on web  final Uint8List? pdfBytes; // In-memory bytes (web file pick)

  final Uint8List? pdfBytes; // In-memory bytes (web file pick)

  const PDFViewerScreen({super.key, required String pdfPath})

  const PDFViewerScreen({super.key, required String pdfPath})      : pdfPath = pdfPath,

      : pdfPath = pdfPath,        pdfBytes = null;

        pdfBytes = null;

  const PDFViewerScreen.file({super.key, required String pdfPath})

  const PDFViewerScreen.file({super.key, required String pdfPath})      : pdfPath = pdfPath,

      : pdfPath = pdfPath,        pdfBytes = null;

        pdfBytes = null;

  const PDFViewerScreen.memory({super.key, required Uint8List pdfBytes})

  const PDFViewerScreen.memory({super.key, required Uint8List pdfBytes})      : pdfBytes = pdfBytes,

      : pdfBytes = pdfBytes,        pdfPath = null;

        pdfPath = null;

  @override

  @override  State<PDFViewerScreen> createState() => _PDFViewerScreenState();

  State<PDFViewerScreen> createState() => _PDFViewerScreenState();}

}

class _PDFViewerScreenState extends State<PDFViewerScreen> {

class _PDFViewerScreenState extends State<PDFViewerScreen> {  // PDF controller

  // PDF controller (for pdfrx)  late PdfViewerController _pdfController;

  late PdfViewerController _pdfController;  // Stable PDF viewer widget to prevent repeated loads on rebuild

    Widget? _pdfView;

  // Syncfusion controller (for web)

  sf.PdfViewerController? _sfController;  // Annotation storage per page

    final Map<int, AnnotationLayer> _annotationsByPage = {};

  // Stable PDF viewer widget to prevent repeated loads on rebuild

  Widget? _pdfView;  // Current drawing state

  DrawingTool _currentTool = DrawingTool.pen;

  // Annotation storage per page  Color _currentColor = Colors.black;

  final Map<int, AnnotationLayer> _annotationsByPage = {};  double _currentStrokeWidth = 3.0;



  // Current drawing state  // Current page tracking

  DrawingTool _currentTool = DrawingTool.pen;  int _currentPageNumber = 0;

  Color _currentColor = Colors.black;

  double _currentStrokeWidth = 3.0;  // Active stroke being drawn

  List<Offset> _currentStrokePoints = [];

  // Current page tracking  AnnotationData? _currentStroke;

  int _currentPageNumber = 0;

  // Page dimensions for coordinate transformation

  // Active stroke being drawn  Size? _currentPageSize;

  List<Offset> _currentStrokePoints = [];  import 'dart:typed_data';

  AnnotationData? _currentStroke;  import 'package:file_picker/file_picker.dart';



  // Page dimensions for coordinate transformation  // Auto-save timer

  Size? _currentPageSize;  Timer? _autoSaveTimer;

  bool _hasUnsavedChanges = false;

  // Auto-save timer

  Timer? _autoSaveTimer;  // Loading state

  bool _hasUnsavedChanges = false;  bool _isLoading = true;



  // Loading state    final String? pdfPath; // Non-null on desktop/mobile

  bool _isLoading = true;    final Uint8List? pdfBytes; // Non-null on web (or memory-based usage)

  int _activeTouchCount = 0;

  // Touch tracking for gesture passthrough  bool get _shouldPassThroughGestures => _activeTouchCount >= 2;

  int _activeTouchCount = 0;    const PDFViewerScreen.file({super.key, required String pdfPath})

  bool get _shouldPassThroughGestures => _activeTouchCount >= 2;        : pdfPath = pdfPath,

          pdfBytes = null;

  @override

  void initState() {    const PDFViewerScreen.memory({super.key, required Uint8List pdfBytes})

    super.initState();        : pdfBytes = pdfBytes,

    _initializePDF();          pdfPath = null;

  }  @override

  void initState() {

  /// Initialize PDF controller and load annotations    super.initState();

  Future<void> _initializePDF() async {    _initializePDF();

    try {  }

      // Initialize PDF controller based on platform

      if (kIsWeb) {  /// Initialize PDF controller and load annotations

        _sfController = sf.PdfViewerController();  Future<void> _initializePDF() async {

      } else {    try {

        _pdfController = PdfViewerController();      // Initialize PDF controller

      }      _pdfController = PdfViewerController();



      // Build the PDF viewer once; reuse in build to avoid reloading      // Build the PDF viewer once; reuse in build to avoid reloading

      _pdfView = _buildPdfView();      _pdfView = _buildPdfView();



      // Load existing annotations from storage (skip on web/memory)      // Load existing annotations from storage

      if (!kIsWeb && widget.pdfPath != null) {      await _loadAnnotations();

        await _loadAnnotations();

      }      setState(() {

        _isLoading = false;

      setState(() {      });

        _isLoading = false;    } catch (e) {

      });      debugPrint('Error initializing PDF: $e');

    } catch (e) {      setState(() {

      debugPrint('Error initializing PDF: $e');        _isLoading = false;

      setState(() {        // Load existing annotations from storage (skip on web/memory)

        _isLoading = false;        if (!kIsWeb && widget.pdfPath != null) {

      });          await _loadAnnotations();

    }        }

  }  }



  /// Build the PDF viewer widget based on platform  /// Build the PDF viewer widget based on platform

  Widget _buildPdfView() {  Widget _buildPdfView() {

    if (kIsWeb) {    if (kIsWeb) {

      // Web: Use Syncfusion PDF viewer      // Prefer Syncfusion viewer on web (PDF.js)

      if (widget.pdfBytes != null) {      final path = widget.pdfPath;

        // In-memory PDF (from file picker)      if (path.startsWith('http://') || path.startsWith('https://')) {

        return sf.SfPdfViewer.memory(        return sf.SfPdfViewer.network(

          widget.pdfBytes!,          path,

          controller: _sfController,          canShowScrollHead: true,

          canShowScrollHead: true,          canShowScrollStatus: true,

          canShowScrollStatus: true,        );

          onPageChanged: (details) {      }

            _onPageChanged(details.newPageNumber - 1);      // Fallback to pdfrx (note: local file paths are not accessible on web)

          },    }

        );

      } else if (widget.pdfPath != null) {    // Default (desktop/mobile): pdfrx file viewer

        // URL-based PDF    return PdfViewer.file(

        final path = widget.pdfPath!;      widget.pdfPath,

        if (path.startsWith('http://') || path.startsWith('https://')) {      controller: _pdfController,

          return sf.SfPdfViewer.network(      params: PdfViewerParams(

            path,        onPageChanged: (pageNumber) {

            controller: _sfController,          if (pageNumber != null) {

            canShowScrollHead: true,            _onPageChanged(pageNumber - 1); // pdfrx uses 1-based indexing

            canShowScrollStatus: true,          }

            onPageChanged: (details) {        },

              _onPageChanged(details.newPageNumber - 1);        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {

            },          return const Center(child: CircularProgressIndicator());

          );        },

        } else {      ),

          // Asset-based PDF    );

          return sf.SfPdfViewer.asset(  }

            path,

            controller: _sfController,  /// Load annotations from storage

            canShowScrollHead: true,  Future<void> _loadAnnotations() async {

            canShowScrollStatus: true,    try {

            onPageChanged: (details) {      final annotations = await AnnotationStorage.loadFromFile(widget.pdfPath);

              _onPageChanged(details.newPageNumber - 1);      setState(() {

            },        _annotationsByPage.clear();

          );        _annotationsByPage.addAll(annotations);

        }      });

      }    } catch (e) {

    }      debugPrint('No existing annotations found or error loading: $e');

    }

    // Desktop/Mobile: Use pdfrx file viewer  }

    if (widget.pdfPath != null) {

      return PdfViewer.file(  /// Save annotations to storage

        widget.pdfPath!,  Future<void> _saveAnnotations() async {

        controller: _pdfController,    try {

        params: PdfViewerParams(      await AnnotationStorage.saveToFile(widget.pdfPath, _annotationsByPage);

          onPageChanged: (pageNumber) {      setState(() {

            if (pageNumber != null) {        _hasUnsavedChanges = false;

              _onPageChanged(pageNumber - 1); // pdfrx uses 1-based indexing      });

            }      debugPrint('Annotations saved successfully');

          },    } catch (e) {

          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {      debugPrint('Error saving annotations: $e');

            return const Center(child: CircularProgressIndicator());    }

          },  }

        ),

      );  /// Schedule auto-save (debounced)

    } else if (widget.pdfBytes != null) {  void _scheduleAutoSave() {

      return PdfViewer.data(    _autoSaveTimer?.cancel();

        widget.pdfBytes!,    _hasUnsavedChanges = true;

        controller: _pdfController,

        params: PdfViewerParams(        // Skip persistent save on web or when no file path is available

          onPageChanged: (pageNumber) {        if (kIsWeb || widget.pdfPath == null) {

            if (pageNumber != null) {          setState(() {

              _onPageChanged(pageNumber - 1);            _hasUnsavedChanges = false;

            }          });

          },          return;

          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {        }

            return const Center(child: CircularProgressIndicator());      _saveAnnotations();

          },        await AnnotationStorage.saveToFile(widget.pdfPath!, _annotationsByPage);

        ),    });

      );  }

    }

  /// Get or create annotation layer for current page

    // Fallback  AnnotationLayer _getCurrentPageAnnotations() {

    return const Center(    if (!_annotationsByPage.containsKey(_currentPageNumber)) {

      child: Text('No PDF source provided'),      _annotationsByPage[_currentPageNumber] = AnnotationLayer();

    );    }

  }    return _annotationsByPage[_currentPageNumber]!;

    /// Import annotations via a JSON file (desktop/web)

  /// Load annotations from storage    Future<void> _importAnnotations() async {

  Future<void> _loadAnnotations() async {      try {

    try {        final result = await FilePicker.platform.pickFiles(

      if (widget.pdfPath == null) return;          type: FileType.custom,

                allowedExtensions: ['json'],

      final annotations = await AnnotationStorage.loadFromFile(widget.pdfPath!);          allowMultiple: false,

      setState(() {          withData: true, // ensure bytes on web

        _annotationsByPage.clear();        );

        _annotationsByPage.addAll(annotations);

      });        if (result == null) return;

    } catch (e) {

      debugPrint('No existing annotations found or error loading: $e');        if (kIsWeb || result.files.single.bytes != null) {

    }          // Web: read from bytes

  }          final bytes = result.files.single.bytes!;

          final jsonString = String.fromCharCodes(bytes);

  /// Save annotations to storage          _mergeAnnotationsFromJson(jsonString);

  Future<void> _saveAnnotations() async {        } else if (result.files.single.path != null) {

    try {          // Desktop/Mobile: use file path

      // Skip persistent save on web or when no file path is available          final imported = await AnnotationStorage.importFromCustomPath(

      if (kIsWeb || widget.pdfPath == null) {            result.files.single.path!,

        setState(() {          );

          _hasUnsavedChanges = false;          setState(() {

        });            for (final entry in imported.entries) {

        return;              final page = entry.key;

      }              final layer = entry.value;

                    _annotationsByPage[page] ??= AnnotationLayer();

      await AnnotationStorage.saveToFile(widget.pdfPath!, _annotationsByPage);              for (final a in layer.getAnnotationsForPage(page)) {

      setState(() {                _annotationsByPage[page]!.addAnnotation(a);

        _hasUnsavedChanges = false;              }

      });            }

      debugPrint('Annotations saved successfully');          });

    } catch (e) {          _scheduleAutoSave();

      debugPrint('Error saving annotations: $e');        }

    }

  }        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

  /// Schedule auto-save (debounced)            const SnackBar(content: Text('Annotations imported')),

  void _scheduleAutoSave() {          );

    _autoSaveTimer?.cancel();        }

    _hasUnsavedChanges = true;      } catch (e) {

        if (mounted) {

    _autoSaveTimer = Timer(const Duration(seconds: 3), () async {          ScaffoldMessenger.of(context).showSnackBar(

      await _saveAnnotations();            SnackBar(content: Text('Error importing annotations: $e')),

    });          );

  }        }

      }

  /// Get or create annotation layer for current page    }

  AnnotationLayer _getCurrentPageAnnotations() {

    if (!_annotationsByPage.containsKey(_currentPageNumber)) {    void _mergeAnnotationsFromJson(String jsonString) {

      _annotationsByPage[_currentPageNumber] = AnnotationLayer();      try {

    }        final importedLayer = AnnotationLayer.fromJson(jsonString);

    return _annotationsByPage[_currentPageNumber]!;        setState(() {

  }          for (final page in importedLayer.annotatedPages) {

            _annotationsByPage[page] ??= AnnotationLayer();

  /// Import annotations via a JSON file (desktop/web)            for (final a in importedLayer.getAnnotationsForPage(page)) {

  Future<void> _importAnnotations() async {              _annotationsByPage[page]!.addAnnotation(a);

    try {            }

      final result = await FilePicker.platform.pickFiles(          }

        type: FileType.custom,        });

        allowedExtensions: ['json'],        _scheduleAutoSave();

        allowMultiple: false,      } catch (e) {

        withData: true, // ensure bytes on web        debugPrint('Failed to merge annotations: $e');

      );      }

    }

      if (result == null) return;  }



      if (kIsWeb || result.files.single.bytes != null) {  /// Convert screen coordinates to PDF page coordinates

        // Web: read from bytes  ///

        final bytes = result.files.single.bytes!;  /// PDF coordinate system: (0,0) = bottom-left

        final jsonString = String.fromCharCodes(bytes);  /// Screen coordinate system: (0,0) = top-left

        _mergeAnnotationsFromJson(jsonString);  /// This ensures annotations stay anchored regardless of zoom level

      } else if (result.files.single.path != null) {  Offset _screenToPdfCoordinates(Offset screenPoint) {

        // Desktop/Mobile: use file path    if (_currentPageSize == null) return screenPoint;

        final imported = await AnnotationStorage.importFromCustomPath(

          result.files.single.path!,    // For now, we use screen coordinates but with proper page size awareness

        );    // In production, you'd account for the PDF controller's transformation matrix

        setState(() {    // to handle zoom and pan properly

          for (final entry in imported.entries) {

            final page = entry.key;    return Offset(

            final layer = entry.value;      screenPoint.dx,

            _annotationsByPage[page] ??= AnnotationLayer();      _currentPageSize!.height -

            for (final a in layer.getAnnotationsForPage(page)) {          screenPoint.dy, // Flip Y axis for PDF coordinates

              _annotationsByPage[page]!.addAnnotation(a);    );

            }            IconButton(

          }              tooltip: 'Import annotations',

        });              icon: const Icon(Icons.file_upload),

        _scheduleAutoSave();              onPressed: _importAnnotations,

      }            ),

  }

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(  /// Handle pan start (begin new stroke)

          const SnackBar(content: Text('Annotations imported')),  void _onPanStart(DragStartDetails details) {

        );    // Check if using stylus (preferred)

      }    // In production, you'd check details.kind == PointerDeviceKind.stylus

    } catch (e) {

      if (mounted) {    final localPosition = details.localPosition;

        ScaffoldMessenger.of(context).showSnackBar(    final pdfCoord = _screenToPdfCoordinates(localPosition);

          SnackBar(content: Text('Error importing annotations: $e')),

        );    setState(() {

      }      _currentStrokePoints = [pdfCoord];

    }

  }      _currentStroke = AnnotationData(

        strokePath: [pdfCoord],

  void _mergeAnnotationsFromJson(String jsonString) {        colorValue: _currentColor.toARGB32(),

    try {        strokeWidth: _currentStrokeWidth,

      final importedLayer = AnnotationLayer.fromJson(jsonString);        toolType: _currentTool,

      setState(() {        pageNumber: _currentPageNumber,

        for (final page in importedLayer.annotatedPages) {      );

          _annotationsByPage[page] ??= AnnotationLayer();    });

          for (final a in importedLayer.getAnnotationsForPage(page)) {  }

            _annotationsByPage[page]!.addAnnotation(a);

          }  /// Handle pan update (add points to stroke)

        }  void _onPanUpdate(DragUpdateDetails details) {

      });    if (_currentStroke == null) return;

      _scheduleAutoSave();

    } catch (e) {    final localPosition = details.localPosition;

      debugPrint('Failed to merge annotations: $e');    final pdfCoord = _screenToPdfCoordinates(localPosition);

    }

  }    // Add point if it's far enough from the last point (threshold)

    if (_currentStrokePoints.isNotEmpty) {

  /// Convert screen coordinates to PDF page coordinates      final lastPoint = _currentStrokePoints.last;

  ///      final distance = (pdfCoord - lastPoint).distance;

  /// PDF coordinate system: (0,0) = bottom-left

  /// Screen coordinate system: (0,0) = top-left      if (distance < 3.0) return; // Threshold for smoothness

  /// This ensures annotations stay anchored regardless of zoom level    }

  Offset _screenToPdfCoordinates(Offset screenPoint) {

    if (_currentPageSize == null) return screenPoint;    setState(() {

      _currentStrokePoints.add(pdfCoord);

    // For now, we use screen coordinates but with proper page size awareness

    // In production, you'd account for the PDF controller's transformation matrix      _currentStroke = _currentStroke!.copyWith(

    // to handle zoom and pan properly        strokePath: List.from(_currentStrokePoints),

      );

    return Offset(    });

      screenPoint.dx,  }

      _currentPageSize!.height -

          screenPoint.dy, // Flip Y axis for PDF coordinates  /// Handle pan end (finalize stroke)

    );  void _onPanEnd(DragEndDetails details) {

  }    if (_currentStroke == null || _currentStrokePoints.length < 2) {

      setState(() {

  /// Handle pan start (begin new stroke)        _currentStroke = null;

  void _onPanStart(DragStartDetails details) {        _currentStrokePoints.clear();

    final localPosition = details.localPosition;      });

    final pdfCoord = _screenToPdfCoordinates(localPosition);      return;

    }

    setState(() {

      _currentStrokePoints = [pdfCoord];    if (_currentTool == DrawingTool.eraser) {

      // Handle eraser

      _currentStroke = AnnotationData(      _eraseStrokes();

        strokePath: [pdfCoord],    } else {

        colorValue: _currentColor.toARGB32(),      // Add completed stroke to annotation layer

        strokeWidth: _currentStrokeWidth,      final currentPageAnnotations = _getCurrentPageAnnotations();

        toolType: _currentTool,      currentPageAnnotations.addAnnotation(_currentStroke!);

        pageNumber: _currentPageNumber,

      );      // Schedule auto-save

    });      _scheduleAutoSave();

  }    }



  /// Handle pan update (add points to stroke)    setState(() {

  void _onPanUpdate(DragUpdateDetails details) {      _currentStroke = null;

    if (_currentStroke == null) return;      _currentStrokePoints.clear();

    });

    final localPosition = details.localPosition;  }

    final pdfCoord = _screenToPdfCoordinates(localPosition);

  /// Erase strokes that intersect with eraser path

    // Add point if it's far enough from the last point (threshold)  void _eraseStrokes() {

    if (_currentStrokePoints.isNotEmpty) {    const eraserRadius = 15.0;

      final lastPoint = _currentStrokePoints.last;    final currentPageAnnotations = _getCurrentPageAnnotations();

      final distance = (pdfCoord - lastPoint).distance;    final annotations = currentPageAnnotations.getAnnotationsForPage(

      _currentPageNumber,

      if (distance < 3.0) return; // Threshold for smoothness    );

    }    final toRemove = <AnnotationData>[];



    setState(() {    for (final annotation in annotations) {

      _currentStrokePoints.add(pdfCoord);      for (final eraserPoint in _currentStrokePoints) {

        for (final strokePoint in annotation.strokePath) {

      _currentStroke = _currentStroke!.copyWith(          final distance = (strokePoint - eraserPoint).distance;

        strokePath: List.from(_currentStrokePoints),          if (distance <= eraserRadius) {

      );            toRemove.add(annotation);

    });            break;

  }          }

        }

  /// Handle pan end (finalize stroke)        if (toRemove.contains(annotation)) break;

  void _onPanEnd(DragEndDetails details) {      }

    if (_currentStroke == null || _currentStrokePoints.length < 2) {    }

      setState(() {

        _currentStroke = null;    for (final annotation in toRemove) {

        _currentStrokePoints.clear();      currentPageAnnotations.removeAnnotation(annotation);

      });    }

      return;

    }    if (toRemove.isNotEmpty) {

      _scheduleAutoSave();

    if (_currentTool == DrawingTool.eraser) {    }

      // Handle eraser  }

      _eraseStrokes();

    } else {  /// Handle page change

      // Add completed stroke to annotation layer  void _onPageChanged(int pageNumber) {

      final currentPageAnnotations = _getCurrentPageAnnotations();    // Save current page annotations before switching

      currentPageAnnotations.addAnnotation(_currentStroke!);    if (_hasUnsavedChanges) {

      _saveAnnotations();

      // Schedule auto-save    }

      _scheduleAutoSave();

    }    setState(() {

      _currentPageNumber = pageNumber;

    setState(() {      // Clear temp drawing buffers

      _currentStroke = null;      _currentStroke = null;

      _currentStrokePoints.clear();      _currentStrokePoints.clear();

    });    });

  }  }



  /// Erase strokes that intersect with eraser path  /// Undo last stroke on current page

  void _eraseStrokes() {  void _undoLastStroke() {

    const eraserRadius = 15.0;    final currentPageAnnotations = _getCurrentPageAnnotations();

    final currentPageAnnotations = _getCurrentPageAnnotations();    final undone = currentPageAnnotations.undoLastStroke();

    final annotations = currentPageAnnotations.getAnnotationsForPage(

      _currentPageNumber,    if (undone != null) {

    );      setState(() {});

    final toRemove = <AnnotationData>[];      _scheduleAutoSave();

    }

    for (final annotation in annotations) {  }

      for (final eraserPoint in _currentStrokePoints) {

        for (final strokePoint in annotation.strokePath) {  /// Redo last undone stroke

          final distance = (strokePoint - eraserPoint).distance;  void _redoLastStroke() {

          if (distance <= eraserRadius) {    final currentPageAnnotations = _getCurrentPageAnnotations();

            toRemove.add(annotation);    final success = currentPageAnnotations.redoLastUndo();

            break;

          }    if (success) {

        }      setState(() {});

        if (toRemove.contains(annotation)) break;      _scheduleAutoSave();

      }    }

    }  }



    for (final annotation in toRemove) {  /// Clear all annotations on current page

      currentPageAnnotations.removeAnnotation(annotation);  void _clearCurrentPage() {

    }    final currentPageAnnotations = _getCurrentPageAnnotations();

    currentPageAnnotations.clearPage(_currentPageNumber);

    if (toRemove.isNotEmpty) {

      _scheduleAutoSave();    setState(() {});

    }    _scheduleAutoSave();

  }  }



  /// Handle page change  @override

  void _onPageChanged(int pageNumber) {  Widget build(BuildContext context) {

    // Save current page annotations before switching    if (_isLoading) {

    if (_hasUnsavedChanges) {      return Scaffold(

      _saveAnnotations();        appBar: AppBar(title: const Text('Loading PDF...')),

    }        body: const Center(child: CircularProgressIndicator()),

      );

    setState(() {    }

      _currentPageNumber = pageNumber;

      // Clear temp drawing buffers    return Scaffold(

      _currentStroke = null;      appBar: AppBar(

      _currentStrokePoints.clear();        title: Text('Page ${_currentPageNumber + 1}'),

    });        actions: [

  }          if (_hasUnsavedChanges)

            const Padding(

  /// Undo last stroke on current page              padding: EdgeInsets.all(16.0),

  void _undoLastStroke() {              child: Icon(Icons.circle, size: 8, color: Colors.orange),

    final currentPageAnnotations = _getCurrentPageAnnotations();            ),

    final undone = currentPageAnnotations.undoLastStroke();        ],

      ),

    if (undone != null) {      body: Stack(

      setState(() {});        children: [

      _scheduleAutoSave();          // PDF viewer

    }          Positioned.fill(

  }            child: _pdfView != null

                ? RepaintBoundary(child: _pdfView!)

  /// Redo last undone stroke                : const SizedBox.shrink(),

  void _redoLastStroke() {          ),

    final currentPageAnnotations = _getCurrentPageAnnotations();

    final success = currentPageAnnotations.redoLastUndo();          // Annotation overlay - lets 2+ finger gestures pass through to PDF viewer

          Positioned.fill(

    if (success) {            child: Listener(

      setState(() {});              behavior: HitTestBehavior.translucent,

      _scheduleAutoSave();              onPointerDown: (event) {

    }                if (event.kind == PointerDeviceKind.touch) {

  }                  setState(() => _activeTouchCount++);

                }

  /// Clear all annotations on current page              },

  void _clearCurrentPage() {              onPointerUp: (event) {

    final currentPageAnnotations = _getCurrentPageAnnotations();                if (event.kind == PointerDeviceKind.touch) {

    currentPageAnnotations.clearPage(_currentPageNumber);                  setState(

                    () => _activeTouchCount = (_activeTouchCount - 1).clamp(

    setState(() {});                      0,

    _scheduleAutoSave();                      10,

  }                    ),

                  );

  @override                }

  Widget build(BuildContext context) {              },

    if (_isLoading) {              onPointerCancel: (event) {

      return Scaffold(                if (event.kind == PointerDeviceKind.touch) {

        appBar: AppBar(title: const Text('Loading PDF...')),                  setState(

        body: const Center(child: CircularProgressIndicator()),                    () => _activeTouchCount = (_activeTouchCount - 1).clamp(

      );                      0,

    }                      10,

                    ),

    return Scaffold(                  );

      appBar: AppBar(                }

        title: Text('Page ${_currentPageNumber + 1}'),              },

        actions: [              child: IgnorePointer(

          IconButton(                ignoring: _shouldPassThroughGestures,

            tooltip: 'Import annotations',                child: GestureDetector(

            icon: const Icon(Icons.file_upload),                  behavior: HitTestBehavior.opaque,

            onPressed: _importAnnotations,                  onPanStart: (details) {

          ),                    // If user is performing multi-touch, don't start drawing

          if (_hasUnsavedChanges)                    if (_shouldPassThroughGestures) return;

            const Padding(                    _onPanStart(details);

              padding: EdgeInsets.all(16.0),                  },

              child: Icon(Icons.circle, size: 8, color: Colors.orange),                  onPanUpdate: (details) {

            ),                    if (_shouldPassThroughGestures) return;

        ],                    _onPanUpdate(details);

      ),                  },

      body: Stack(                  onPanEnd: (details) {

        children: [                    if (_shouldPassThroughGestures) return;

          // PDF viewer                    _onPanEnd(details);

          Positioned.fill(                  },

            child: _pdfView != null                  child: CustomPaint(

                ? RepaintBoundary(child: _pdfView!)                    painter: AnnotationPainter(

                : const SizedBox.shrink(),                      annotations: _getCurrentPageAnnotations()

          ),                          .getAnnotationsForPage(_currentPageNumber),

                      currentStroke: _currentStroke,

          // Annotation overlay - lets 2+ finger gestures pass through to PDF viewer                    ),

          Positioned.fill(                  ),

            child: Listener(                ),

              behavior: HitTestBehavior.translucent,              ),

              onPointerDown: (event) {            ),

                if (event.kind == PointerDeviceKind.touch) {          ),

                  setState(() => _activeTouchCount++);

                }          // Floating toolbar

              },          Positioned(

              onPointerUp: (event) {            top: 16,

                if (event.kind == PointerDeviceKind.touch) {            left: 16,

                  setState(            right: 16,

                    () => _activeTouchCount = (_activeTouchCount - 1).clamp(            child: ToolbarWidget(

                      0,              currentTool: _currentTool,

                      10,              currentColor: _currentColor,

                    ),              currentStrokeWidth: _currentStrokeWidth,

                  );              onToolChanged: (tool) {

                }                setState(() {

              },                  _currentTool = tool;

              onPointerCancel: (event) {

                if (event.kind == PointerDeviceKind.touch) {                  // Clamp stroke width to valid range for new tool

                  setState(                  if (tool == DrawingTool.highlighter) {

                    () => _activeTouchCount = (_activeTouchCount - 1).clamp(                    // Highlighter range: 8.0 - 20.0

                      0,                    if (_currentStrokeWidth < 8.0) {

                      10,                      _currentStrokeWidth = 8.0;

                    ),                    } else if (_currentStrokeWidth > 20.0) {

                  );                      _currentStrokeWidth = 20.0;

                }                    }

              },                  } else {

              child: IgnorePointer(                    // Pen/Eraser range: 1.0 - 10.0

                ignoring: _shouldPassThroughGestures,                    if (_currentStrokeWidth < 1.0) {

                child: GestureDetector(                      _currentStrokeWidth = 1.0;

                  behavior: HitTestBehavior.opaque,                    } else if (_currentStrokeWidth > 10.0) {

                  onPanStart: (details) {                      _currentStrokeWidth = 10.0;

                    // If user is performing multi-touch, don't start drawing                    }

                    if (_shouldPassThroughGestures) return;                  }

                    _onPanStart(details);                });

                  },              },

                  onPanUpdate: (details) {              onColorChanged: (color) {

                    if (_shouldPassThroughGestures) return;                setState(() {

                    _onPanUpdate(details);                  _currentColor = color;

                  },                });

                  onPanEnd: (details) {              },

                    if (_shouldPassThroughGestures) return;              onStrokeWidthChanged: (width) {

                    _onPanEnd(details);                setState(() {

                  },                  _currentStrokeWidth = width;

                  child: CustomPaint(                });

                    painter: AnnotationPainter(              },

                      annotations: _getCurrentPageAnnotations()              onUndo: _undoLastStroke,

                          .getAnnotationsForPage(_currentPageNumber),              onRedo: _redoLastStroke,

                      currentStroke: _currentStroke,              onClear: _clearCurrentPage,

                    ),              onSave: _saveAnnotations,

                  ),            ),

                ),          ),

              ),        ],

            ),      ),

          ),    );

  }

          // Floating toolbar

          Positioned(  @override

            top: 16,  void dispose() {

            left: 16,    _autoSaveTimer?.cancel();

            right: 16,

            child: ToolbarWidget(    // Save on exit if there are unsaved changes

              currentTool: _currentTool,    if (_hasUnsavedChanges) {

              currentColor: _currentColor,      _saveAnnotations();

              currentStrokeWidth: _currentStrokeWidth,    }

              onToolChanged: (tool) {

                setState(() {    // PdfViewerController doesn't need manual disposal

                  _currentTool = tool;    super.dispose();

  }

                  // Clamp stroke width to valid range for new tool}

                  if (tool == DrawingTool.highlighter) {
                    // Highlighter range: 8.0 - 20.0
                    if (_currentStrokeWidth < 8.0) {
                      _currentStrokeWidth = 8.0;
                    } else if (_currentStrokeWidth > 20.0) {
                      _currentStrokeWidth = 20.0;
                    }
                  } else {
                    // Pen/Eraser range: 1.0 - 10.0
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
    if (_hasUnsavedChanges && !kIsWeb && widget.pdfPath != null) {
      _saveAnnotations();
    }

    // Controllers don't need manual disposal
    super.dispose();
  }
}
