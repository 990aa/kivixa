import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:xml/xml.dart' as xml;
import 'package:path_drawing/path_drawing.dart';
import '../models/stroke.dart';
import '../models/canvas_element.dart';

/// Service for exporting and importing canvas data
class ExportImportService {
  static const double defaultCanvasWidth = 1920;
  static const double defaultCanvasHeight = 1080;

  /// Export strokes to PDF
  Future<File> exportToPDF({
    required List<Stroke> strokes,
    required List<CanvasElement> elements,
    double canvasWidth = defaultCanvasWidth,
    double canvasHeight = defaultCanvasHeight,
    String? filename,
  }) async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    // Set page size
    page.graphics.clientSize = Size(canvasWidth, canvasHeight);

    // Render each stroke
    for (final stroke in strokes) {
      await _renderStrokeToPdf(graphics, stroke);
    }

    // Render canvas elements
    for (final element in elements) {
      if (element is TextElement) {
        _renderTextToPdf(graphics, element);
      } else if (element is ImageElement) {
        _renderImageToPdf(graphics, element);
      }
    }

    // Save document
    final List<int> bytes = await document.save();
    document.dispose();

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final name = filename ?? 'canvas_${DateTime.now().millisecondsSinceEpoch}';
    final file = File('${directory.path}/$name.pdf');
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Export strokes to SVG
  Future<String> exportToSVG({
    required List<Stroke> strokes,
    required List<CanvasElement> elements,
    double canvasWidth = defaultCanvasWidth,
    double canvasHeight = defaultCanvasHeight,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'viewBox="0 0 $canvasWidth $canvasHeight" '
      'width="$canvasWidth" height="$canvasHeight">',
    );

    // Add background
    buffer.writeln(
      '<rect width="$canvasWidth" height="$canvasHeight" fill="white"/>',
    );

    // Render strokes
    for (final stroke in strokes) {
      final svgPath = _strokeToSvgPath(stroke);
      if (svgPath.isNotEmpty) {
        buffer.writeln(svgPath);
      }
    }

    // Render elements
    for (final element in elements) {
      if (element is TextElement) {
        buffer.writeln(_textElementToSvg(element));
      }
      // Note: Image elements require base64 encoding for SVG
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Save SVG to file
  Future<File> saveSvgToFile(
    String svgContent, {
    String? filename,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = filename ?? 'canvas_${DateTime.now().millisecondsSinceEpoch}';
    final file = File('${directory.path}/$name.svg');
    await file.writeAsString(svgContent);
    return file;
  }

  /// Import SVG paths and convert to strokes
  Future<List<Stroke>> importSVG(String svgContent) async {
    final List<Stroke> strokes = [];

    try {
      final document = xml.XmlDocument.parse(svgContent);
      final paths = document.findAllElements('path');

      for (final pathElement in paths) {
        final pathData = pathElement.getAttribute('d');
        final fillAttr = pathElement.getAttribute('fill');

        if (pathData != null && pathData.isNotEmpty) {
          final stroke = _convertSvgPathToStroke(
            pathData,
            fillAttr ?? '#000000',
          );
          if (stroke != null) {
            strokes.add(stroke);
          }
        }
      }
    } catch (e) {
      debugPrint('Error importing SVG: $e');
    }

    return strokes;
  }

  // Private helper methods

  Future<void> _renderStrokeToPdf(PdfGraphics graphics, Stroke stroke) async {
    if (stroke.points.isEmpty) return;

    try {
      final outlinePoints = getStroke(
        stroke.points,
        options: StrokeOptions(
          size: stroke.strokeWidth,
          thinning: stroke.isHighlighter ? 0.0 : 0.7,
          smoothing: 0.5,
          streamline: 0.5,
        ),
      );

      if (outlinePoints.isEmpty) return;

      final path = PdfPath();
      final points = outlinePoints
          .map((p) => Offset(p.dx, p.dy))
          .toList();

      if (points.isNotEmpty) {
        path.addPolygon(points);

        final pdfColor = PdfColor(
          stroke.color.red,
          stroke.color.green,
          stroke.color.blue,
        );

        graphics.drawPath(
          path,
          pen: PdfPens.transparent,
          brush: PdfSolidBrush(pdfColor),
        );
      }
    } catch (e) {
      debugPrint('Error rendering stroke to PDF: $e');
    }
  }

  void _renderTextToPdf(PdfGraphics graphics, TextElement element) {
    try {
      final font = PdfStandardFont(PdfFontFamily.helvetica, element.style.fontSize ?? 24);
      final color = PdfColor(
        element.style.color?.red ?? 0,
        element.style.color?.green ?? 0,
        element.style.color?.blue ?? 0,
      );

      graphics.save();
      graphics.translateTransform(element.position.dx, element.position.dy);
      graphics.rotateTransform(element.rotation * 180 / 3.14159); // Convert to degrees
      graphics.scaleTransform(element.scale, element.scale);

      graphics.drawString(
        element.text,
        font,
        pen: PdfPen(color),
        brush: PdfSolidBrush(color),
      );

      graphics.restore();
    } catch (e) {
      debugPrint('Error rendering text to PDF: $e');
    }
  }

  void _renderImageToPdf(PdfGraphics graphics, ImageElement element) {
    try {
      final pdfImage = PdfBitmap(element.imageData);

      graphics.save();
      graphics.translateTransform(element.position.dx, element.position.dy);
      graphics.rotateTransform(element.rotation * 180 / 3.14159);
      graphics.scaleTransform(element.scale, element.scale);

      graphics.drawImage(
        pdfImage,
        Rect.fromLTWH(0, 0, element.width, element.height),
      );

      graphics.restore();
    } catch (e) {
      debugPrint('Error rendering image to PDF: $e');
    }
  }

  String _strokeToSvgPath(Stroke stroke) {
    if (stroke.points.isEmpty) return '';

    try {
      final outlinePoints = getStroke(
        stroke.points,
        options: StrokeOptions(
          size: stroke.strokeWidth,
          thinning: stroke.isHighlighter ? 0.0 : 0.7,
          smoothing: 0.5,
          streamline: 0.5,
        ),
      );

      if (outlinePoints.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.write('M ${outlinePoints.first.dx} ${outlinePoints.first.dy} ');

      for (int i = 1; i < outlinePoints.length; i++) {
        buffer.write('L ${outlinePoints[i].dx} ${outlinePoints[i].dy} ');
      }

      final colorHex = _colorToHex(stroke.color);
      final opacity = stroke.isHighlighter ? 0.5 : 1.0;

      return '<path d="$buffer Z" '
          'fill="$colorHex" '
          'fill-opacity="$opacity" '
          'stroke="none" />';
    } catch (e) {
      debugPrint('Error converting stroke to SVG: $e');
      return '';
    }
  }

  String _textElementToSvg(TextElement element) {
    final colorHex = _colorToHex(element.style.color ?? Colors.black);
    final fontSize = element.style.fontSize ?? 24;

    return '<text x="${element.position.dx}" y="${element.position.dy}" '
        'fill="$colorHex" '
        'font-size="$fontSize" '
        'transform="rotate(${element.rotation * 180 / 3.14159} ${element.position.dx} ${element.position.dy}) '
        'scale(${element.scale})">'
        '${_escapeXml(element.text)}</text>';
  }

  Stroke? _convertSvgPathToStroke(String pathData, String fillColor) {
    try {
      final path = parseSvgPathData(pathData);
      final points = <PointVector>[];

      // Extract points from path (simplified approach)
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final length = metric.length;
        final steps = (length / 5).ceil(); // Sample every 5 pixels

        for (int i = 0; i <= steps; i++) {
          final distance = (i / steps) * length;
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            points.add(PointVector(tangent.position.dx, tangent.position.dy));
          }
        }
      }

      if (points.isEmpty) return null;

      return Stroke(
        points: points,
        color: _hexToColor(fillColor),
        strokeWidth: 4.0,
        isHighlighter: false,
      );
    } catch (e) {
      debugPrint('Error converting SVG path to stroke: $e');
      return null;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}';
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
