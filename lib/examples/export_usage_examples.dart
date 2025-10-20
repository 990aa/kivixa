import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kivixa/models/drawing_layer.dart';
import 'package:kivixa/models/layer_stroke.dart';
import 'package:kivixa/models/stroke_point.dart';
import 'package:kivixa/services/high_resolution_exporter.dart';
import 'package:kivixa/services/pdf_drawing_manager.dart';

/// Simple usage examples for High-Resolution Export and PDF Integration
/// These are function examples, not a UI - integrate into your app as needed

class ExportUsageExamples {
  // =================================================================
  // HIGH-RESOLUTION EXPORT EXAMPLES
  // =================================================================

  /// Example 1: Export at specific DPI (print quality)
  Future<Uint8List> exportForPrinting(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) async {
    final exporter = HighResolutionExporter();

    // Export at 300 DPI for professional printing
    final imageBytes = await exporter.exportAtDPI(
      layers: layers,
      canvasSize: canvasSize,
      targetDPI: 300.0,
      format: ExportFormat.png,
      backgroundColor: Colors.white,
    );

    print('Exported at 300 DPI for printing');
    return imageBytes;
  }

  /// Example 2: Export using quality presets
  Future<Uint8List> exportWithQualityPreset(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) async {
    final exporter = HighResolutionExporter();

    // Use preset quality (screen, highQuality, print, or custom)
    final imageBytes = await exporter.exportWithQuality(
      layers: layers,
      canvasSize: canvasSize,
      quality: ExportQuality.print, // 300 DPI
      format: ExportFormat.jpg, // Use JPG for smaller file size
      backgroundColor: Colors.white,
    );

    print('Exported with print quality preset');
    return imageBytes;
  }

  /// Example 3: Export with progress tracking (for large exports)
  Future<Uint8List> exportWithProgress(
    List<DrawingLayer> layers,
    Size canvasSize,
  ) async {
    final exporter = HighResolutionExporter();

    // Export with progress callback
    final imageBytes = await exporter.exportWithProgress(
      layers: layers,
      canvasSize: canvasSize,
      targetDPI: 300.0,
      format: ExportFormat.png,
      backgroundColor: Colors.white,
      onProgress: (progress, status) {
        print(
          'Export progress: ${(progress * 100).toStringAsFixed(1)}% - $status',
        );
      },
    );

    return imageBytes;
  }

  /// Example 4: Check export dimensions before exporting
  void checkExportSize(Size canvasSize, double targetDPI) {
    final exporter = HighResolutionExporter();

    // Calculate output dimensions without exporting
    final outputSize = exporter.calculateExportDimensions(
      canvasSize,
      targetDPI,
    );
    print(
      'Output size will be: ${outputSize.width} × ${outputSize.height} pixels',
    );

    // Estimate file size
    final estimatedSizePNG = exporter.estimateFileSizeMB(
      canvasSize,
      targetDPI,
      format: ExportFormat.png,
    );
    final estimatedSizeJPG = exporter.estimateFileSizeMB(
      canvasSize,
      targetDPI,
      format: ExportFormat.jpg,
    );
    print('Estimated PNG size: ${estimatedSizePNG.toStringAsFixed(2)} MB');
    print('Estimated JPG size: ${estimatedSizeJPG.toStringAsFixed(2)} MB');

    // Check recommended maximum DPI
    final maxDPI = exporter.getRecommendedMaxDPI(canvasSize);
    print('Recommended maximum DPI: ${maxDPI.toStringAsFixed(0)}');
  }

  // =================================================================
  // PDF INTEGRATION EXAMPLES
  // =================================================================

  /// Example 5: Create a blank PDF and add drawings
  Future<Uint8List> createAnnotatedPDF() async {
    final pdfManager = PDFDrawingManager();

    // Create a blank A4-sized PDF
    await pdfManager.createBlankPDF(
      pageSize: const Size(595, 842), // A4 in points (72 points per inch)
      pageCount: 3,
    );

    // Create some sample strokes
    final stroke1 = _createSampleStroke(
      start: const Offset(100, 100),
      end: const Offset(300, 300),
      color: Colors.blue,
    );

    final stroke2 = _createSampleStroke(
      start: const Offset(300, 100),
      end: const Offset(100, 300),
      color: Colors.red,
    );

    // Add strokes to different pages
    // The coordinate transformer will handle Flutter->PDF conversion
    final screenSize = const Size(595, 842); // Match page size for 1:1 mapping
    pdfManager.addStrokeToPage(0, stroke1, screenSize);
    pdfManager.addStrokeToPage(1, stroke2, screenSize);

    // Export the annotated PDF
    final pdfBytes = await pdfManager.exportAnnotatedPDF();
    print('Created annotated PDF with ${pdfManager.pageLayerMap.length} pages');

    return pdfBytes;
  }

  /// Example 6: Load existing PDF and add annotations
  Future<Uint8List> annotateExistingPDF(Uint8List existingPdfBytes) async {
    final pdfManager = PDFDrawingManager();

    // Load the existing PDF
    await pdfManager.loadPDF(existingPdfBytes);

    // Create annotation strokes
    final highlightStroke = _createSampleStroke(
      start: const Offset(50, 50),
      end: const Offset(500, 50),
      color: Colors.yellow.withValues(alpha: 0.5),
    );

    // Add to first page
    final screenSize = const Size(595, 842);
    await pdfManager.addStrokeToPage(highlightStroke, 0, screenSize);

    // Export with annotations flattened
    final annotatedPdfBytes = await pdfManager.exportAnnotatedPDF();
    print('Added annotations to existing PDF');

    return annotatedPdfBytes;
  }

  /// Example 7: Use enhanced PDF manager with metadata
  Future<Uint8List> exportPDFWithMetadata(List<DrawingLayer> layers) async {
    final enhancedManager = EnhancedPDFManager();

    // Create a blank PDF
    await enhancedManager.createBlankPDF(
      pageSize: const Size(595, 842),
      pageCount: 1,
    );

    // Add drawings from layers
    final screenSize = const Size(595, 842);
    for (final layer in layers) {
      for (final stroke in layer.strokes) {
        await enhancedManager.addStrokeToPage(stroke, 0, screenSize);
      }
    }

    // Export with settings and metadata
    final settings = PDFExportSettings(
      flattenAnnotations: true,
      includeMetadata: true,
      optimizeForWeb: false,
      title: 'My Drawing',
      author: 'Artist Name',
      subject: 'Digital Artwork',
      keywords: 'drawing, art, digital',
    );

    final pdfBytes = await enhancedManager.exportWithSettings(settings);
    print('Exported PDF with metadata');

    return pdfBytes;
  }

  /// Example 8: Understanding coordinate transformation
  void demonstrateCoordinateTransformation() {
    final transformer = PDFCoordinateTransformer();

    // Flutter coordinates (top-left origin, Y increases downward)
    const flutterPoint = Offset(100, 200);
    const screenSize = Size(595, 842); // Screen/canvas size
    const pageSize = Size(595, 842); // PDF page size

    // Calculate the screen-to-PDF ratio
    final ratio = transformer.calculateScreenToPointRatio(screenSize, pageSize);
    print('Screen-to-PDF ratio: $ratio');

    // Convert Flutter coordinates to PDF coordinates
    // PDF uses bottom-left origin, Y increases upward
    final pdfPoint = transformer.flutterToPDF(
      flutterPoint,
      pageSize.height,
      ratio,
    );
    print(
      'Flutter point (100, 200) → PDF point (${pdfPoint.dx}, ${pdfPoint.dy})',
    );

    // Convert back to verify
    final backToFlutter = transformer.pdfToFlutter(
      pdfPoint,
      pageSize.height,
      ratio,
    );
    print('Back to Flutter: (${backToFlutter.dx}, ${backToFlutter.dy})');

    // Batch transform multiple points
    final flutterPoints = [
      const Offset(0, 0),
      const Offset(100, 100),
      const Offset(200, 200),
    ];

    final pdfPoints = transformer.transformPoints(
      flutterPoints,
      pageSize.height,
      ratio,
      flutterToPDF: true,
    );

    print('Transformed ${pdfPoints.length} points to PDF coordinates');
  }

  // =================================================================
  // HELPER METHODS
  // =================================================================

  /// Create a sample stroke for demonstration
  LayerStroke _createSampleStroke({
    required Offset start,
    required Offset end,
    required Color color,
  }) {
    // Create points from start to end
    final points = <StrokePoint>[];
    const steps = 10;

    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final position = Offset.lerp(start, end, t)!;
      points.add(StrokePoint(position: position, pressure: 1.0));
    }

    // Create paint for the stroke
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    return LayerStroke(points: points, brushProperties: paint);
  }
}

// =================================================================
// INTEGRATION GUIDE
// =================================================================

/*
HOW TO INTEGRATE INTO YOUR APP:

1. HIGH-RESOLUTION EXPORT:
   
   // In your export button handler:
   final exporter = HighResolutionExporter();
   final imageBytes = await exporter.exportAtDPI(
     layers: drawingController.layers,
     canvasSize: canvasSize,
     targetDPI: 300.0,
     format: ExportFormat.png,
   );
   
   // Save to file:
   final file = File('export.png');
   await file.writeAsBytes(imageBytes);

2. PDF ANNOTATION:
   
   // Load PDF from file picker:
   final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
   final pdfBytes = await File(result!.files.first.path!).readAsBytes();
   
   // Add annotations:
   final pdfManager = PDFDrawingManager();
   await pdfManager.loadPDF(pdfBytes);
   
   // As user draws, add strokes:
   await pdfManager.addStrokeToPage(newStroke, currentPage, screenSize);
   
   // Export when done:
   final annotatedBytes = await pdfManager.exportAnnotatedPDF();
   await File('annotated.pdf').writeAsBytes(annotatedBytes);

3. COORDINATE TRANSFORMATION:
   
   When working with PDFs, you need to transform coordinates:
   - Flutter: Top-left origin (0,0), Y increases down
   - PDF: Bottom-left origin (0,0), Y increases up
   
   The PDFCoordinateTransformer handles this automatically when you use
   PDFDrawingManager.addStrokeToPage().
   
   Manual transformation:
   final transformer = PDFCoordinateTransformer();
   final ratio = transformer.calculateScreenToPointRatio(screenSize, pageSize);
   final pdfPoint = transformer.flutterToPDF(flutterPoint, pageHeight, ratio);

4. PROGRESS TRACKING:
   
   For large exports, show progress to user:
   await exporter.exportWithProgress(
     layers: layers,
     canvasSize: canvasSize,
     targetDPI: 300.0,
     onProgress: (progress, status) {
       setState(() {
         _exportProgress = progress;
         _exportStatus = status;
       });
     },
   );

5. FILE SIZE ESTIMATION:
   
   Before exporting, estimate size and warn user:
   final outputSize = exporter.calculateExportDimensions(canvasSize, 300.0);
   final estimatedMB = exporter.estimateFileSizeMB(outputSize, ExportFormat.png);
   
   if (estimatedMB > 50) {
     // Show warning dialog
   }
*/
