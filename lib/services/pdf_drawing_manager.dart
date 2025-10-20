import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/drawing_layer.dart';
import '../models/vector_stroke.dart';
import '../models/stroke_point.dart';
import '../models/layer_stroke.dart';

/// PDF coordinate system transformer
/// PDFs use bottom-left origin (72 points per inch)
/// Flutter uses top-left origin (pixels)
class PDFCoordinateTransformer {
  final double pageHeightInPoints;
  static const double pdfDPI = 72.0;

  PDFCoordinateTransformer(this.pageHeightInPoints);

  /// Convert Flutter screen coordinates to PDF coordinates
  Offset flutterToPDF(Offset flutterPoint, double screenToPointRatio) {
    // Flutter uses top-left origin, PDF uses bottom-left
    final pdfX = flutterPoint.dx * screenToPointRatio;
    final pdfY = pageHeightInPoints - (flutterPoint.dy * screenToPointRatio);

    return Offset(pdfX, pdfY);
  }

  /// Convert PDF coordinates to Flutter screen coordinates
  Offset pdfToFlutter(Offset pdfPoint, double screenToPointRatio) {
    final flutterX = pdfPoint.dx / screenToPointRatio;
    final flutterY = (pageHeightInPoints - pdfPoint.dy) / screenToPointRatio;

    return Offset(flutterX, flutterY);
  }

  /// Calculate scaling ratio between screen pixels and PDF points
  double calculateScreenToPointRatio(Size screenSize, Size pdfPageSize) {
    // pdfPageSize is in points (72 DPI)
    return pdfPageSize.width / screenSize.width;
  }

  /// Transform a list of points from Flutter to PDF coordinates
  List<Offset> transformPoints(
      List<Offset> flutterPoints, double screenToPointRatio) {
    return flutterPoints
        .map((point) => flutterToPDF(point, screenToPointRatio))
        .toList();
  }
}

/// PDF drawing and annotation manager
class PDFDrawingManager {
  PdfDocument? pdfDocument;
  Map<int, List<DrawingLayer>> pageLayerMap = {}; // Layers per page
  PDFCoordinateTransformer? transformer;

  /// Current page being drawn on
  int currentPageIndex = 0;

  /// Load PDF and prepare for annotation
  Future<void> loadPDF(Uint8List pdfBytes) async {
    pdfDocument = PdfDocument(inputBytes: pdfBytes);

    // Initialize layers for each page
    for (int i = 0; i < pdfDocument!.pages.count; i++) {
      pageLayerMap[i] = [
        DrawingLayer(
          name: 'Drawing Layer',
        ),
      ];
    }
  }

  /// Create new blank PDF with specified page size
  Future<void> createBlankPDF({
    Size pageSize = const Size(595, 842), // A4 in points
    int pageCount = 1,
  }) async {
    pdfDocument = PdfDocument();

    // Add pages
    for (int i = 0; i < pageCount; i++) {
      pdfDocument!.pages.add();

      pageLayerMap[i] = [
        DrawingLayer(
          name: 'Drawing Layer',
        ),
      ];
    }
  }

  /// Get page count
  int get pageCount => pdfDocument?.pages.count ?? 0;

  /// Get page size in points
  Size getPageSize(int pageIndex) {
    if (pdfDocument == null || pageIndex >= pageCount) {
      return Size.zero;
    }

    final page = pdfDocument!.pages[pageIndex];
    return Size(page.size.width, page.size.height);
  }

  /// Add layer to specific page
  void addLayerToPage(int pageIndex, DrawingLayer layer) {
    if (!pageLayerMap.containsKey(pageIndex)) {
      pageLayerMap[pageIndex] = [];
    }
    pageLayerMap[pageIndex]!.add(layer);
  }

  /// Get layers for specific page
  List<DrawingLayer> getLayersForPage(int pageIndex) {
    return pageLayerMap[pageIndex] ?? [];
  }

  /// Add stroke to specific PDF page
  void addStrokeToPage(int pageIndex, LayerStroke stroke, Size screenSize) {
    if (!pageLayerMap.containsKey(pageIndex)) return;
    if (pageLayerMap[pageIndex]!.isEmpty) {
      pageLayerMap[pageIndex]!.add(DrawingLayer(name: 'Drawing Layer'));
    }

    final page = pdfDocument!.pages[pageIndex];
    final pageHeight = page.size.height; // In PDF points

    transformer = PDFCoordinateTransformer(pageHeight);
    final ratio = transformer!.calculateScreenToPointRatio(
      screenSize,
      Size(page.size.width, page.size.height),
    );

    // Transform stroke points to PDF coordinates
    final transformedPoints = stroke.points.map((point) {
      final pdfPoint = transformer!.flutterToPDF(point.position, ratio);
      return StrokePoint(
        position: pdfPoint,
        pressure: point.pressure,
        tilt: point.tilt,
        orientation: point.orientation,
      );
    }).toList();

    final transformedStroke = LayerStroke(
      points: transformedPoints,
      brushProperties: stroke.brushProperties,
    );

    // Add to first layer
    pageLayerMap[pageIndex]![0].addStroke(transformedStroke);
  }

  /// Add vector stroke to specific PDF page
  void addVectorStrokeToPage(
      int pageIndex, VectorStroke stroke, Size screenSize) {
    if (!pageLayerMap.containsKey(pageIndex)) return;
    if (pageLayerMap[pageIndex]!.isEmpty) {
      pageLayerMap[pageIndex]!.add(DrawingLayer(name: 'Drawing Layer'));
    }

    final page = pdfDocument!.pages[pageIndex];
    final pageHeight = page.size.height;

    transformer = PDFCoordinateTransformer(pageHeight);
    final ratio = transformer!.calculateScreenToPointRatio(
      screenSize,
      Size(page.size.width, page.size.height),
    );

    // Transform stroke points to PDF coordinates
    final transformedPoints = stroke.points.map((point) {
      final pdfPoint = transformer!.flutterToPDF(point.position, ratio);
      return StrokePoint(
        position: pdfPoint,
        pressure: point.pressure,
        tilt: point.tilt,
        orientation: point.orientation,
      );
    }).toList();

    final transformedStroke = VectorStroke(
      id: stroke.id,
      points: transformedPoints,
      brushSettings: stroke.brushSettings,
      timestamp: stroke.timestamp,
    );

    // Convert to LayerStroke for compatibility
    final layerStroke = LayerStroke(
      points: transformedPoints,
      brushProperties: stroke.brushSettings,
    );

    pageLayerMap[pageIndex]![0].addStroke(layerStroke);
  }

  /// Export PDF with all annotations flattened
  Future<Uint8List> exportAnnotatedPDF() async {
    if (pdfDocument == null) throw Exception('No PDF loaded');

    // Iterate through pages and flatten annotations
    for (int pageIndex = 0; pageIndex < pdfDocument!.pages.count; pageIndex++) {
      final page = pdfDocument!.pages[pageIndex];
      final layers = pageLayerMap[pageIndex] ?? [];

      if (layers.isEmpty) continue;

      // Get page graphics for drawing
      final graphics = page.graphics;

      // Render each layer to page
      for (final layer in layers) {
        if (!layer.isVisible) continue;

        for (final stroke in layer.strokes) {
          _drawStrokeOnPDFPage(graphics, stroke, layer.opacity);
        }
      }
    }

    // Save and return
    final bytes = pdfDocument!.save();
    return Uint8List.fromList(bytes);
  }

  /// Draw stroke on PDF page using PDF graphics
  void _drawStrokeOnPDFPage(
      PdfGraphics graphics, LayerStroke stroke, double opacity) {
    if (stroke.points.length < 2) {
      // Single point - draw as circle
      if (stroke.points.isNotEmpty) {
        final point = stroke.points.first;
        final color = stroke.brushProperties.color;
        final pdfColor = PdfColor(
          (color.r * 255).round(),
          (color.g * 255).round(),
          (color.b * 255).round(),
        );

        final brush = PdfSolidBrush(pdfColor);
        final radius = stroke.brushProperties.strokeWidth * point.pressure / 2;

        graphics.drawEllipse(
          Rect.fromCircle(center: point.position, radius: radius),
          brush: brush,
        );
      }
      return;
    }

    // Create PDF pen with stroke properties
    final color = stroke.brushProperties.color;
    final pdfColor = PdfColor(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );

    final pen = PdfPen(
      pdfColor,
      width: stroke.brushProperties.strokeWidth,
    )..lineCap = PdfLineCap.round;

    // Draw path on PDF
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      // Adjust width based on pressure
      final avgPressure = (prev.pressure + curr.pressure) / 2;
      pen.width = stroke.brushProperties.strokeWidth * avgPressure;

      graphics.drawLine(
        pen,
        Offset(prev.position.dx, prev.position.dy),
        Offset(curr.position.dx, curr.position.dy),
      );
    }
  }

  /// Export specific page as image
  Future<Uint8List?> exportPageAsImage(int pageIndex) async {
    if (pdfDocument == null || pageIndex >= pageCount) return null;

    final page = pdfDocument!.pages[pageIndex];

    // This would require additional implementation with image rendering
    // Syncfusion provides page rendering capabilities
    return null; // Placeholder
  }

  /// Clear all annotations from specific page
  void clearPageAnnotations(int pageIndex) {
    if (pageLayerMap.containsKey(pageIndex)) {
      for (final layer in pageLayerMap[pageIndex]!) {
        layer.clearStrokes();
      }
    }
  }

  /// Clear all annotations from all pages
  void clearAllAnnotations() {
    for (final layers in pageLayerMap.values) {
      for (final layer in layers) {
        layer.clearStrokes();
      }
    }
  }

  /// Get annotation count for specific page
  int getAnnotationCount(int pageIndex) {
    if (!pageLayerMap.containsKey(pageIndex)) return 0;

    int count = 0;
    for (final layer in pageLayerMap[pageIndex]!) {
      count += layer.strokes.length;
    }
    return count;
  }

  /// Check if page has annotations
  bool hasAnnotations(int pageIndex) {
    return getAnnotationCount(pageIndex) > 0;
  }

  /// Dispose resources
  void dispose() {
    pdfDocument?.dispose();
    pdfDocument = null;
    pageLayerMap.clear();
    transformer = null;
  }
}

/// PDF export settings
class PDFExportSettings {
  final bool flattenAnnotations;
  final bool includeMetadata;
  final String? title;
  final String? author;
  final String? subject;
  final bool optimizeForWeb;

  const PDFExportSettings({
    this.flattenAnnotations = true,
    this.includeMetadata = true,
    this.title,
    this.author,
    this.subject,
    this.optimizeForWeb = false,
  });
}

/// Enhanced PDF manager with export settings
class EnhancedPDFManager extends PDFDrawingManager {
  /// Export with custom settings
  Future<Uint8List> exportWithSettings(PDFExportSettings settings) async {
    if (pdfDocument == null) throw Exception('No PDF loaded');

    // Set metadata if requested
    if (settings.includeMetadata) {
      if (settings.title != null) {
        pdfDocument!.documentInformation.title = settings.title!;
      }
      if (settings.author != null) {
        pdfDocument!.documentInformation.author = settings.author!;
      }
      if (settings.subject != null) {
        pdfDocument!.documentInformation.subject = settings.subject!;
      }
      pdfDocument!.documentInformation.creator = 'Kivixa';
    }

    // Flatten annotations if requested
    if (settings.flattenAnnotations) {
      return exportAnnotatedPDF();
    }

    // Just save without flattening
    final bytes = pdfDocument!.save();
    return Uint8List.fromList(bytes);
  }

  /// Add text annotation to PDF page
  void addTextAnnotation(
    int pageIndex,
    String text,
    Offset position,
    Size screenSize, {
    Color color = Colors.black,
    double fontSize = 12.0,
  }) {
    if (pdfDocument == null || pageIndex >= pageCount) return;

    final page = pdfDocument!.pages[pageIndex];
    final pageHeight = page.size.height;

    transformer = PDFCoordinateTransformer(pageHeight);
    final ratio = transformer!.calculateScreenToPointRatio(
      screenSize,
      Size(page.size.width, page.size.height),
    );

    final pdfPosition = transformer!.flutterToPDF(position, ratio);

    // Draw text on page
    final pdfColor = PdfColor(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );

    final font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
    final brush = PdfSolidBrush(pdfColor);

    page.graphics.drawString(
      text,
      font,
      brush: brush,
      bounds: Rect.fromLTWH(pdfPosition.dx, pdfPosition.dy, 500, 100),
    );
  }
}
