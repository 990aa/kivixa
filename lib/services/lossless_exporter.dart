import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/drawing_layer.dart';
import '../models/layer_stroke.dart';
import '../models/vector_stroke.dart';
import 'high_resolution_exporter.dart';

/// Lossless export strategies for preserving maximum quality
class LosslessExporter {
  /// Option 1: Export as vector SVG (infinite zoom, but limited app support)
  Future<String> exportAsSVG({
    required List<DrawingLayer> layers,
    required Size canvasSize,
  }) async {
    final svg = StringBuffer();
    svg.writeln(
      '<svg width="${canvasSize.width}" height="${canvasSize.height}" xmlns="http://www.w3.org/2000/svg">',
    );

    for (final layer in layers) {
      if (!layer.isVisible) continue;

      svg.writeln('<g opacity="${layer.opacity}">');

      for (final stroke in layer.strokes) {
        final color = stroke.brushProperties.color;
        final colorStr =
            'rgb(${(color.r * 255).round()},${(color.g * 255).round()},${(color.b * 255).round()})';

        // Generate SVG path from stroke points
        final pathData = _strokeToSVGPath(stroke);

        svg.writeln('<path d="$pathData" ');
        svg.writeln('  stroke="$colorStr" ');
        svg.writeln('  stroke-width="${stroke.brushProperties.strokeWidth}" ');
        svg.writeln('  stroke-linecap="round" ');
        svg.writeln('  stroke-linejoin="round" ');
        svg.writeln('  fill="none" ');
        svg.writeln('  opacity="${color.a}" />');
      }

      svg.writeln('</g>');
    }

    svg.writeln('</svg>');
    return svg.toString();
  }

  /// Convert stroke to SVG path data
  String _strokeToSVGPath(LayerStroke stroke) {
    if (stroke.points.isEmpty) return '';

    final buffer = StringBuffer();

    // Move to first point
    final firstPoint = stroke.points.first;
    buffer.write('M ${firstPoint.position.dx} ${firstPoint.position.dy}');

    // Line to subsequent points
    for (int i = 1; i < stroke.points.length; i++) {
      final point = stroke.points[i];
      buffer.write(' L ${point.position.dx} ${point.position.dy}');
    }

    return buffer.toString();
  }

  /// Convert vector stroke to SVG path with Bezier curves
  /// Note: Reserved for future VectorStroke implementation
  // String _vectorStrokeToSVGPath(VectorStroke stroke) {
  //   if (stroke.points.isEmpty) return '';
  //
  //   final buffer = StringBuffer();
  //
  //   // Move to first point
  //   final firstPoint = stroke.points.first;
  //   buffer.write('M ${firstPoint.position.dx} ${firstPoint.position.dy}');
  //
  //   // Use quadratic Bezier curves for smoother paths
  //   for (int i = 1; i < stroke.points.length; i++) {
  //     final point = stroke.points[i];
  //
  //     if (i < stroke.points.length - 1) {
  //       // Use quadratic Bezier to next point
  //       final nextPoint = stroke.points[i + 1];
  //       final controlX = (point.position.dx + nextPoint.position.dx) / 2;
  //       final controlY = (point.position.dy + nextPoint.position.dy) / 2;
  //
  //       buffer.write(
  //         ' Q ${point.position.dx} ${point.position.dy} $controlX $controlY',
  //       );
  //     } else {
  //       // Last point - just line to it
  //       buffer.write(' L ${point.position.dx} ${point.position.dy}');
  //     }
  //   }
  //
  //   return buffer.toString();
  // }

  /// Option 2: Export PDF with embedded high-res raster at 300+ DPI
  Future<Uint8List> exportAsPDFWithHighResRaster({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    Uint8List? basePdfBytes,
    double targetDPI = 300.0,
    Color backgroundColor = Colors.white,
  }) async {
    // Render at high DPI
    final exporter = HighResolutionExporter();
    final highResImage = await exporter.exportAtDPI(
      layers: layers,
      canvasSize: canvasSize,
      targetDPI: targetDPI,
      format: ExportFormat.png,
      backgroundColor: backgroundColor,
    );

    // Create or load PDF
    final document = basePdfBytes != null
        ? PdfDocument(inputBytes: basePdfBytes)
        : PdfDocument();

    // Add image to PDF at correct size
    final page = basePdfBytes != null && document.pages.count > 0
        ? document.pages[0]
        : document.pages.add();

    final image = PdfBitmap(highResImage);

    // Calculate image size to maintain aspect ratio
    final pageSize = Size(page.size.width, page.size.height);
    final imageAspect = canvasSize.width / canvasSize.height;
    final pageAspect = pageSize.width / pageSize.height;

    late Rect imageRect;
    if (imageAspect > pageAspect) {
      // Image is wider - fit to width
      final width = pageSize.width;
      final height = width / imageAspect;
      final y = (pageSize.height - height) / 2;
      imageRect = Rect.fromLTWH(0, y, width, height);
    } else {
      // Image is taller - fit to height
      final height = pageSize.height;
      final width = height * imageAspect;
      final x = (pageSize.width - width) / 2;
      imageRect = Rect.fromLTWH(x, 0, width, height);
    }

    // Draw at calculated size (maintains high DPI)
    page.graphics.drawImage(image, imageRect);

    final bytes = await document.save();
    document.dispose();

    return Uint8List.fromList(bytes);
  }

  /// Option 3: Export as PDF with vector strokes (true vector, infinite zoom)
  Future<Uint8List> exportAsPDFWithVectorStrokes({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    Uint8List? basePdfBytes,
    String title = 'Vector Drawing',
    String author = '',
  }) async {
    // Create or load PDF
    final document = basePdfBytes != null
        ? PdfDocument(inputBytes: basePdfBytes)
        : PdfDocument();

    // Set document properties
    document.documentInformation.title = title;
    document.documentInformation.author = author;
    document.documentInformation.creationDate = DateTime.now();

    // Add page if needed
    final page = basePdfBytes != null && document.pages.count > 0
        ? document.pages[0]
        : document.pages.add();

    final graphics = page.graphics;

    // Calculate scale to fit canvas to page
    final pageSize = Size(page.size.width, page.size.height);
    final scaleX = pageSize.width / canvasSize.width;
    final scaleY = pageSize.height / canvasSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    // Render each layer as vector paths
    for (final layer in layers) {
      if (!layer.isVisible) continue;

      for (final stroke in layer.strokes) {
        _drawVectorStrokeOnPDF(graphics, stroke, scale, layer.opacity);
      }
    }

    final bytes = await document.save();
    document.dispose();

    return Uint8List.fromList(bytes);
  }

  /// Draw stroke as vector path on PDF
  void _drawVectorStrokeOnPDF(
    PdfGraphics graphics,
    LayerStroke stroke,
    double scale,
    double opacity,
  ) {
    if (stroke.points.length < 2) {
      // Single point - draw as filled circle
      if (stroke.points.isNotEmpty) {
        final point = stroke.points.first;
        final color = stroke.brushProperties.color;
        final pdfColor = PdfColor(
          (color.r * 255).round(),
          (color.g * 255).round(),
          (color.b * 255).round(),
        );

        final brush = PdfSolidBrush(pdfColor);
        final radius = stroke.brushProperties.strokeWidth * scale / 2;

        graphics.drawEllipse(
          Rect.fromCircle(
            center: Offset(
              point.position.dx * scale,
              point.position.dy * scale,
            ),
            radius: radius,
          ),
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

    final pen =
        PdfPen(pdfColor, width: stroke.brushProperties.strokeWidth * scale)
          ..lineCap = PdfLineCap.round
          ..lineJoin = PdfLineJoin.round;

    // Draw path segments
    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];

      // Adjust width based on pressure if available
      final avgPressure = (prev.pressure + curr.pressure) / 2;
      pen.width = stroke.brushProperties.strokeWidth * scale * avgPressure;

      graphics.drawLine(
        pen,
        Offset(prev.position.dx * scale, prev.position.dy * scale),
        Offset(curr.position.dx * scale, curr.position.dy * scale),
      );
    }
  }

  /// Export with automatic format selection based on content
  Future<Uint8List> exportWithAutoFormat({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    Uint8List? basePdfBytes,
    double targetDPI = 300.0,
    bool preferVector = true,
  }) async {
    // Analyze content to decide format
    final hasComplexStrokes = _hasComplexStrokes(layers);

    if (preferVector && !hasComplexStrokes) {
      // Use vector format for simple strokes
      return await exportAsPDFWithVectorStrokes(
        layers: layers,
        canvasSize: canvasSize,
        basePdfBytes: basePdfBytes,
      );
    } else {
      // Use high-res raster for complex content
      return await exportAsPDFWithHighResRaster(
        layers: layers,
        canvasSize: canvasSize,
        basePdfBytes: basePdfBytes,
        targetDPI: targetDPI,
      );
    }
  }

  /// Check if layers contain complex strokes that benefit from rasterization
  bool _hasComplexStrokes(List<DrawingLayer> layers) {
    int totalPoints = 0;
    int totalStrokes = 0;

    for (final layer in layers) {
      for (final stroke in layer.strokes) {
        totalStrokes++;
        totalPoints += stroke.points.length;
      }
    }

    // If average points per stroke is high, consider it complex
    if (totalStrokes == 0) return false;
    final avgPointsPerStroke = totalPoints / totalStrokes;

    return avgPointsPerStroke > 50; // Threshold for complexity
  }

  /// Estimate file size for different export formats
  Map<String, double> estimateFileSizes({
    required List<DrawingLayer> layers,
    required Size canvasSize,
    double targetDPI = 300.0,
  }) {
    final exporter = HighResolutionExporter();

    // Estimate PNG size
    final pngSize = exporter.estimateFileSizeMB(
      canvasSize,
      targetDPI,
      format: ExportFormat.png,
    );

    // Estimate JPG size
    final jpgSize = exporter.estimateFileSizeMB(
      canvasSize,
      targetDPI,
      format: ExportFormat.jpg,
    );

    // Estimate SVG size (rough approximation)
    int totalPoints = 0;
    for (final layer in layers) {
      for (final stroke in layer.strokes) {
        totalPoints += stroke.points.length;
      }
    }
    // ~50 bytes per point in SVG (path data + attributes)
    final svgSize = (totalPoints * 50) / (1024 * 1024);

    // Estimate vector PDF size (similar to SVG but with PDF overhead)
    final vectorPdfSize = svgSize * 1.5;

    // Estimate raster PDF size (image data + PDF structure)
    final rasterPdfSize = pngSize * 0.8 + 0.1; // PNG data + PDF overhead

    return {
      'png': pngSize,
      'jpg': jpgSize,
      'svg': svgSize,
      'vector_pdf': vectorPdfSize,
      'raster_pdf': rasterPdfSize,
    };
  }
}
