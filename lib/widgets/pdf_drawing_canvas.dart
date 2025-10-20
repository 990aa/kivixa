import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_drawing_manager.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/stroke_point.dart';
import '../models/brush_settings.dart';

/// PDF viewer with drawing overlay for annotation
class PDFDrawingCanvas extends StatefulWidget {
  final Uint8List pdfBytes;
  final BrushSettings? defaultBrushSettings;
  final VoidCallback? onStrokeAdded;

  const PDFDrawingCanvas({
    super.key,
    required this.pdfBytes,
    this.defaultBrushSettings,
    this.onStrokeAdded,
  });

  @override
  State<PDFDrawingCanvas> createState() => _PDFDrawingCanvasState();
}

class _PDFDrawingCanvasState extends State<PDFDrawingCanvas> {
  final PdfViewerController _pdfController = PdfViewerController();
  final PDFDrawingManager _drawingManager = PDFDrawingManager();

  LayerStroke? _currentStroke;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _drawingEnabled = true;

  // Current brush settings
  late BrushSettings _brushSettings;

  @override
  void initState() {
    super.initState();
    _brushSettings =
        widget.defaultBrushSettings ??
        BrushSettings(
          brushType: 'pen',
          color: Colors.black,
          size: 3.0,
          opacity: 1.0,
          flowRate: 1.0,
        );
    _initializePDF();
  }

  Future<void> _initializePDF() async {
    try {
      await _drawingManager.loadPDF(widget.pdfBytes);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _drawingManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        // PDF Viewer
        SfPdfViewer.memory(
          widget.pdfBytes,
          controller: _pdfController,
          onPageChanged: (details) {
            setState(() {
              _currentPage =
                  details.newPageNumber - 1; // Convert to 0-based index
            });
          },
        ),

        // Drawing overlay
        if (_drawingEnabled)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _startStroke,
              onPanUpdate: _continueStroke,
              onPanEnd: _endStroke,
              child: CustomPaint(
                painter: PDFOverlayPainter(
                  layers: _drawingManager.getLayersForPage(_currentPage),
                  currentStroke: _currentStroke,
                ),
              ),
            ),
          ),

        // Drawing controls
        Positioned(top: 16, right: 16, child: _buildDrawingControls()),
      ],
    );
  }

  Widget _buildDrawingControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle drawing mode
            IconButton(
              icon: Icon(_drawingEnabled ? Icons.edit : Icons.edit_off),
              tooltip: _drawingEnabled ? 'Disable Drawing' : 'Enable Drawing',
              onPressed: () {
                setState(() {
                  _drawingEnabled = !_drawingEnabled;
                });
              },
            ),

            const Divider(),

            // Color picker
            _buildColorButton(Colors.black),
            _buildColorButton(Colors.red),
            _buildColorButton(Colors.blue),
            _buildColorButton(Colors.green),
            _buildColorButton(Colors.yellow),

            const Divider(),

            // Brush size
            Text('Size: ${_brushSettings.size.toInt()}'),
            SizedBox(
              width: 40,
              child: Slider(
                value: _brushSettings.size,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _brushSettings = _brushSettings.copyWith(size: value);
                  });
                },
              ),
            ),

            const Divider(),

            // Export button
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Export Annotated PDF',
              onPressed: _exportPDF,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _brushSettings.color == color;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _brushSettings = _brushSettings.copyWith(color: color);
          });
        },
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.grey,
              width: isSelected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }

  void _startStroke(DragStartDetails details) {
    if (!_drawingEnabled) return;

    setState(() {
      final paint = Paint()
        ..color = _brushSettings.color
        ..strokeWidth = _brushSettings.size
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      _currentStroke = LayerStroke(
        points: [StrokePoint(position: details.localPosition, pressure: 1.0)],
        brushProperties: paint,
      );
    });
  }

  void _continueStroke(DragUpdateDetails details) {
    if (_currentStroke == null || !_drawingEnabled) return;

    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [
          ..._currentStroke!.points,
          StrokePoint(position: details.localPosition, pressure: 1.0),
        ],
      );
    });
  }

  void _endStroke(DragEndDetails details) {
    if (_currentStroke == null || !_drawingEnabled) return;

    // Get page size for coordinate transformation
    final pageSize = MediaQuery.of(context).size;

    // Add stroke to PDF page
    _drawingManager.addStrokeToPage(_currentPage, _currentStroke!, pageSize);

    setState(() {
      _currentStroke = null;
    });

    widget.onStrokeAdded?.call();
  }

  // Export final PDF with annotations
  Future<Uint8List> exportPDF() async {
    return await _drawingManager.exportAnnotatedPDF();
  }

  Future<void> _exportPDF() async {
    try {
      final bytes = await exportPDF();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported: ${bytes.length} bytes'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () {
                // Implement share/save functionality
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  // Get drawing manager for external access
  PDFDrawingManager get drawingManager => _drawingManager;

  // Update brush settings
  void updateBrushSettings(BrushSettings settings) {
    setState(() {
      _brushSettings = settings;
    });
  }
}

/// Custom painter for drawing overlay on PDF
class PDFOverlayPainter extends CustomPainter {
  final List<DrawingLayer> layers;
  final LayerStroke? currentStroke;

  PDFOverlayPainter({required this.layers, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw existing layers
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        _drawStroke(canvas, stroke, layer.opacity);
      }
    }

    // Draw current stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!, 1.0);
    }
  }

  void _drawStroke(Canvas canvas, LayerStroke stroke, double layerOpacity) {
    if (stroke.points.length < 2) {
      // Single point - draw as circle
      if (stroke.points.isNotEmpty) {
        final point = stroke.points.first;
        final paint = Paint()
          ..color = stroke.brushProperties.color.withValues(
            alpha: stroke.brushProperties.color.a * layerOpacity,
          )
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          point.position,
          stroke.brushProperties.strokeWidth / 2,
          paint,
        );
      }
      return;
    }

    // Draw stroke as connected lines
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      final paint = Paint()
        ..color = stroke.brushProperties.color.withValues(
          alpha: stroke.brushProperties.color.a * layerOpacity,
        )
        ..strokeWidth = stroke.brushProperties.strokeWidth * curr.pressure
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawLine(prev.position, curr.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PDFOverlayPainter oldDelegate) {
    return layers != oldDelegate.layers ||
        currentStroke != oldDelegate.currentStroke;
  }
}
