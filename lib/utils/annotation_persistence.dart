import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../models/annotation_layer.dart';
import '../services/export_service.dart';

/// Utilities for saving and loading annotation data to/from files
class AnnotationPersistence {
  /// Saves annotation layer to a JSON file
  ///
  /// Returns the file path where annotations were saved
  static Future<String> saveAnnotations(
    AnnotationLayer annotationLayer,
    String pdfFileName,
  ) async {
    try {
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create annotations subdirectory if it doesn't exist
      final annotationsDir = Directory('${directory.path}/annotations');
      if (!await annotationsDir.exists()) {
        await annotationsDir.create(recursive: true);
      }

      // Generate filename based on PDF name
      final annotationFileName = '${pdfFileName}_annotations.json';
      final filePath = '${annotationsDir.path}/$annotationFileName';

      // Export to JSON
      final jsonString = annotationLayer.exportToJson();

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      debugPrint('Saved annotations to: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error saving annotations: $e');
      rethrow;
    }
  }

  /// Loads annotation layer from a JSON file
  ///
  /// Returns a new AnnotationLayer with the loaded data
  static Future<AnnotationLayer> loadAnnotations(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        throw Exception('Annotation file not found: $filePath');
      }

      // Read JSON string
      final jsonString = await file.readAsString();

      // Parse and return
      final annotationLayer = AnnotationLayer.fromJson(jsonString);

      debugPrint(
        'Loaded ${annotationLayer.totalAnnotationCount} annotations from: $filePath',
      );
      return annotationLayer;
    } catch (e) {
      debugPrint('Error loading annotations: $e');
      rethrow;
    }
  }

  /// Checks if annotations exist for a given PDF file
  static Future<bool> annotationsExist(String pdfFileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final annotationFileName = '${pdfFileName}_annotations.json';
      final filePath = '${directory.path}/annotations/$annotationFileName';

      return await File(filePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets the annotation file path for a given PDF
  static Future<String> getAnnotationPath(String pdfFileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final annotationFileName = '${pdfFileName}_annotations.json';
    return '${directory.path}/annotations/$annotationFileName';
  }

  /// Lists all saved annotation files
  static Future<List<String>> listAnnotationFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final annotationsDir = Directory('${directory.path}/annotations');

      if (!await annotationsDir.exists()) {
        return [];
      }

      final files = await annotationsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .map((entity) => entity.path)
          .toList();

      return files;
    } catch (e) {
      debugPrint('Error listing annotation files: $e');
      return [];
    }
  }

  /// Deletes annotation file for a given PDF
  static Future<bool> deleteAnnotations(String pdfFileName) async {
    try {
      final filePath = await getAnnotationPath(pdfFileName);
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted annotations: $filePath');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error deleting annotations: $e');
      return false;
    }
  }
}

/// Helper class for working with PDF files
///
/// This provides utilities for:
/// - Loading PDF documents
/// - Rendering PDF pages
/// - Exporting annotated PDFs
class PDFHelper {
  /// Load a PDF document from file path
  ///
  /// Returns a PdfDocument that can be used for rendering
  static Future<PdfDocument?> loadPDF(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $path');
      }

      final document = await PdfDocument.openFile(path);
      debugPrint('Loaded PDF document');
      return document;
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      return null;
    }
  }

  /// Get page count from PDF file
  static Future<int> getPageCount(String path) async {
    try {
      final document = await loadPDF(path);
      if (document == null) return 0;
      // pdfrx page count is handled through PdfViewer widget
      return 0;
    } catch (e) {
      debugPrint('Error getting page count: $e');
      return 0;
    }
  }

  /// Render a PDF page
  ///
  /// Note: pdfrx uses PdfViewerController for page rendering in widgets
  static Future<PdfPage?> renderPage(
    PdfDocument document,
    int pageNumber,
  ) async {
    try {
      debugPrint('Page rendering handled by PdfViewer widget');
      // pdfrx rendering is handled through PdfViewer widget
      // This method is kept for API compatibility
      return null;
    } catch (e) {
      debugPrint('Error rendering page: $e');
      return null;
    }
  }

  /// Export annotated PDF using syncfusion_flutter_pdf
  ///
  /// Creates a new PDF with annotations burned into it
  static Future<String?> exportAnnotatedPDF(
    String pdfPath,
    Map<int, AnnotationLayer> annotationsByPage,
    String outputPath,
  ) async {
    try {
      // Use ExportService for PDF export
      final result = await ExportService.exportAnnotatedPDF(
        sourcePdfPath: pdfPath,
        annotationsByPage: annotationsByPage,
        outputPath: outputPath,
      );

      debugPrint('Exported annotated PDF to: $result');
      return result;
    } catch (e) {
      debugPrint('Error exporting annotated PDF: $e');
      return null;
    }
  }

  /// Export annotated PDF to application documents directory
  ///
  /// Automatically generates a filename based on original PDF name
  static Future<String?> exportAnnotatedPDFToDocuments(
    String pdfPath,
    Map<int, AnnotationLayer> annotationsByPage,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      // Create exports subdirectory
      final exportsDir = Directory('${directory.path}/exports');
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }

      // Generate output filename
      final originalName = pdfPath.split(Platform.pathSeparator).last;
      final nameWithoutExtension = originalName.replaceAll('.pdf', '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFileName =
          '${nameWithoutExtension}_annotated_$timestamp.pdf';
      final outputPath = '${exportsDir.path}/$outputFileName';

      return await exportAnnotatedPDF(pdfPath, annotationsByPage, outputPath);
    } catch (e) {
      debugPrint('Error exporting to documents: $e');
      return null;
    }
  }
}
