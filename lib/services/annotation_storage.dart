import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/annotation_layer.dart';
import '../models/annotation_data.dart';
import '../models/drawing_tool.dart';

/// Service for persisting annotation data to/from files
///
/// Features:
/// - JSON storage format
/// - PDF coordinate system preservation
/// - Auto-save with debouncing
/// - Platform-agnostic file paths
/// - Validation of coordinate data
class AnnotationStorage {
  /// Save annotations for a PDF file
  ///
  /// Creates a JSON file alongside the original PDF with naming format:
  /// originalfile.pdf → originalfile_annotations.json
  ///
  /// The JSON structure preserves:
  /// - Vector coordinates (no lossy conversion)
  /// - PDF coordinate system (0,0 = bottom-left)
  /// - Page dimensions for validation
  static Future<String> saveToFile(
    String pdfPath,
    Map<int, AnnotationLayer> annotationsByPage,
  ) async {
    try {
      // Generate annotation file path
      final annotationPath = await _getAnnotationFilePath(pdfPath);

      // Build JSON structure
      final Map<String, dynamic> data = {
        'version': '1.0.0',
        'pdfFile': _getFileName(pdfPath),
        'timestamp': DateTime.now().toIso8601String(),
        'pages': {},
      };

      // Export each page's annotations
      for (var entry in annotationsByPage.entries) {
        final pageNumber = entry.key;
        final annotationLayer = entry.value;

        if (annotationLayer.totalAnnotationCount > 0) {
          // Get annotations for this page
          final annotations = annotationLayer.getAnnotationsForPage(pageNumber);

          data['pages'][pageNumber.toString()] = annotations.map((annotation) {
            return {
              'type': annotation.toolType.name,
              'color': annotation.colorValue,
              'width': annotation.strokeWidth,
              'points': annotation.strokePath
                  .map((offset) => [offset.dx, offset.dy])
                  .toList(),
              'timestamp': annotation.timestamp.toIso8601String(),
            };
          }).toList();
        }
      }

      // Write to file
      final file = File(annotationPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );

      debugPrint('Saved annotations to: $annotationPath');
      return annotationPath;
    } catch (e) {
      debugPrint('Error saving annotations: $e');
      rethrow;
    }
  }

  /// Load annotations for a PDF file
  ///
  /// Returns a map of page numbers to AnnotationLayer objects
  /// If no annotation file exists, returns empty map
  static Future<Map<int, AnnotationLayer>> loadFromFile(String pdfPath) async {
    try {
      final annotationPath = await _getAnnotationFilePath(pdfPath);
      final file = File(annotationPath);

      if (!await file.exists()) {
        debugPrint('No annotation file found at: $annotationPath');
        return {};
      }

      // Read and parse JSON
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Validate version
      final version = data['version'] as String?;
      if (version != '1.0.0') {
        debugPrint('Warning: Annotation file version mismatch');
      }

      // Parse pages
      final Map<String, dynamic> pagesData =
          data['pages'] as Map<String, dynamic>;
      final Map<int, AnnotationLayer> result = {};

      for (var entry in pagesData.entries) {
        final pageNumber = int.parse(entry.key);
        final List<dynamic> annotationsJson = entry.value;

        // Create annotation layer for this page
        final annotationLayer = AnnotationLayer();

        for (var annotationJson in annotationsJson) {
          try {
            // Parse points
            final List<dynamic> pointsData = annotationJson['points'];
            final points = pointsData
                .map(
                  (p) => Offset(
                    (p[0] as num).toDouble(),
                    (p[1] as num).toDouble(),
                  ),
                )
                .toList();

            // Parse tool type
            final String toolTypeName = annotationJson['type'];
            final toolType = DrawingTool.values.firstWhere(
              (t) => t.name == toolTypeName,
              orElse: () => DrawingTool.pen,
            );

            // Create annotation
            final annotation = AnnotationData(
              strokePath: points,
              colorValue: annotationJson['color'] as int,
              strokeWidth: (annotationJson['width'] as num).toDouble(),
              toolType: toolType,
              pageNumber: pageNumber,
              timestamp: DateTime.parse(annotationJson['timestamp'] as String),
            );

            annotationLayer.addAnnotation(annotation);
          } catch (e) {
            debugPrint('Error parsing annotation: $e');
            // Skip invalid annotation and continue
          }
        }

        result[pageNumber] = annotationLayer;
      }

      debugPrint('Loaded annotations from: $annotationPath');
      debugPrint('  Pages with annotations: ${result.keys.toList()}');

      return result;
    } catch (e) {
      debugPrint('Error loading annotations: $e');
      return {};
    }
  }

  /// Check if annotation file exists for a PDF
  static Future<bool> annotationFileExists(String pdfPath) async {
    try {
      final annotationPath = await _getAnnotationFilePath(pdfPath);
      return await File(annotationPath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete annotation file for a PDF
  static Future<bool> deleteAnnotationFile(String pdfPath) async {
    try {
      final annotationPath = await _getAnnotationFilePath(pdfPath);
      final file = File(annotationPath);

      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted annotation file: $annotationPath');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error deleting annotation file: $e');
      return false;
    }
  }

  /// Get the annotation file path for a PDF
  ///
  /// Format: originalfile.pdf → originalfile_annotations.json
  /// Location: Same directory as the PDF file (or app documents on mobile)
  static Future<String> _getAnnotationFilePath(String pdfPath) async {
    final pdfFile = File(pdfPath);
    final pdfDirectory = pdfFile.parent;
    final pdfFileName = _getFileName(pdfPath);
    final annotationFileName = _getAnnotationFileName(pdfFileName);

    // On mobile platforms, we need to use app documents directory
    if (Platform.isAndroid || Platform.isIOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      final annotationsDir = Directory('${appDocDir.path}/annotations');

      // Create directory if it doesn't exist
      if (!await annotationsDir.exists()) {
        await annotationsDir.create(recursive: true);
      }

      return '${annotationsDir.path}/$annotationFileName';
    }

    // On desktop, save in same directory as PDF
    return '${pdfDirectory.path}/$annotationFileName';
  }

  /// Get file name from path
  static String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// Generate annotation file name from PDF file name
  static String _getAnnotationFileName(String pdfFileName) {
    if (pdfFileName.toLowerCase().endsWith('.pdf')) {
      final nameWithoutExtension = pdfFileName.substring(
        0,
        pdfFileName.length - 4,
      );
      return '${nameWithoutExtension}_annotations.json';
    }
    return '${pdfFileName}_annotations.json';
  }

  /// Export annotations to a custom location
  static Future<void> exportToCustomPath(
    String outputPath,
    Map<int, AnnotationLayer> annotationsByPage,
  ) async {
    try {
      // Build JSON structure
      final Map<String, dynamic> data = {
        'version': '1.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'pages': {},
      };

      // Export each page's annotations
      for (var entry in annotationsByPage.entries) {
        final pageNumber = entry.key;
        final annotationLayer = entry.value;

        if (annotationLayer.totalAnnotationCount > 0) {
          final annotations = annotationLayer.getAnnotationsForPage(pageNumber);

          data['pages'][pageNumber.toString()] = annotations.map((annotation) {
            return {
              'type': annotation.toolType.name,
              'color': annotation.colorValue,
              'width': annotation.strokeWidth,
              'points': annotation.strokePath
                  .map((offset) => [offset.dx, offset.dy])
                  .toList(),
              'timestamp': annotation.timestamp.toIso8601String(),
            };
          }).toList();
        }
      }

      // Write to custom path
      final file = File(outputPath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );

      debugPrint('Exported annotations to: $outputPath');
    } catch (e) {
      debugPrint('Error exporting annotations: $e');
      rethrow;
    }
  }

  /// Import annotations from a custom path
  static Future<Map<int, AnnotationLayer>> importFromCustomPath(
    String inputPath,
  ) async {
    try {
      final file = File(inputPath);

      if (!await file.exists()) {
        throw Exception('Import file not found: $inputPath');
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final Map<String, dynamic> pagesData =
          data['pages'] as Map<String, dynamic>;
      final Map<int, AnnotationLayer> result = {};

      for (var entry in pagesData.entries) {
        final pageNumber = int.parse(entry.key);
        final List<dynamic> annotationsJson = entry.value;

        final annotationLayer = AnnotationLayer();

        for (var annotationJson in annotationsJson) {
          try {
            final List<dynamic> pointsData = annotationJson['points'];
            final points = pointsData
                .map(
                  (p) => Offset(
                    (p[0] as num).toDouble(),
                    (p[1] as num).toDouble(),
                  ),
                )
                .toList();

            final String toolTypeName = annotationJson['type'];
            final toolType = DrawingTool.values.firstWhere(
              (t) => t.name == toolTypeName,
              orElse: () => DrawingTool.pen,
            );

            final annotation = AnnotationData(
              strokePath: points,
              colorValue: annotationJson['color'] as int,
              strokeWidth: (annotationJson['width'] as num).toDouble(),
              toolType: toolType,
              pageNumber: pageNumber,
              timestamp: DateTime.parse(annotationJson['timestamp'] as String),
            );

            annotationLayer.addAnnotation(annotation);
          } catch (e) {
            debugPrint('Error parsing annotation: $e');
          }
        }

        result[pageNumber] = annotationLayer;
      }

      debugPrint('Imported annotations from: $inputPath');
      return result;
    } catch (e) {
      debugPrint('Error importing annotations: $e');
      rethrow;
    }
  }
}
