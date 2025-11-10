import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for file picking and recent files management
///
/// Features:
/// - Platform-specific file picker integration
/// - PDF file validation
/// - Recent files tracking with SharedPreferences
/// - Permission handling
class FilePickerService {
  static const _recentFilesKey = 'recent_pdf_files';
  static const _maxRecentFiles = 10;

  /// Pick a PDF file from device storage
  ///
  /// Returns File object if successful, null if cancelled or error
  static Future<File?> pickPDFFile() async {
    try {
      debugPrint('Opening file picker for PDF selection...');

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false, // Don't load file data into memory
        withReadStream: false,
      );

      if (result == null || result.files.single.path == null) {
        debugPrint('File picker cancelled or no file selected');
        return null;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Validate file exists
      if (!await file.exists()) {
        debugPrint('Selected file does not exist: $filePath');
        throw FilePickerException('File does not exist');
      }

      // Validate it's a PDF file
      final isValidPDF = await _validatePDFFile(file);
      if (!isValidPDF) {
        debugPrint('Selected file is not a valid PDF: $filePath');
        throw FilePickerException('Invalid PDF file');
      }

      debugPrint('Successfully picked PDF: $filePath');
      debugPrint('  File size: ${await _getFileSizeString(file)}');

      // Add to recent files
      await addToRecentFiles(filePath);

      return file;
    } on FilePickerException {
      rethrow;
    } catch (e) {
      debugPrint('Error picking PDF file: $e');
      throw FilePickerException('Failed to pick file: $e');
    }
  }

  /// Pick multiple PDF files
  static Future<List<File>> pickMultiplePDFFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final List<File> files = [];

      for (final platformFile in result.files) {
        if (platformFile.path != null) {
          final file = File(platformFile.path!);

          if (await file.exists() && await _validatePDFFile(file)) {
            files.add(file);
            await addToRecentFiles(platformFile.path!);
          }
        }
      }

      debugPrint('Picked ${files.length} valid PDF files');
      return files;
    } catch (e) {
      debugPrint('Error picking multiple PDF files: $e');
      return [];
    }
  }

  /// Validate that file is a proper PDF by checking magic bytes
  ///
  /// PDF files start with "%PDF-" (25 50 44 46 2D in hex)
  static Future<bool> _validatePDFFile(File file) async {
    try {
      // Read first 5 bytes
      final bytes = await file.openRead(0, 5).first;

      // Check for PDF magic number: %PDF-
      if (bytes.length >= 5) {
        return bytes[0] == 0x25 && // %
            bytes[1] == 0x50 && // P
            bytes[2] == 0x44 && // D
            bytes[3] == 0x46 && // F
            bytes[4] == 0x2D; // -
      }

      return false;
    } catch (e) {
      debugPrint('Error validating PDF file: $e');
      return false;
    }
  }

  /// Add file path to recent files list
  static Future<void> addToRecentFiles(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> recentFiles = await getRecentFiles();

      // Remove if already exists (to move it to top)
      recentFiles.remove(filePath);

      // Add to beginning
      recentFiles.insert(0, filePath);

      // Limit to max count
      if (recentFiles.length > _maxRecentFiles) {
        recentFiles.removeRange(_maxRecentFiles, recentFiles.length);
      }

      // Save to SharedPreferences
      await prefs.setString(_recentFilesKey, jsonEncode(recentFiles));

      debugPrint('Added to recent files: $filePath');
    } catch (e) {
      debugPrint('Error adding to recent files: $e');
    }
  }

  /// Get list of recent PDF file paths
  static Future<List<String>> getRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_recentFilesKey);

      if (jsonString == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(jsonString);
      final List<String> paths = decoded.cast<String>();

      // Filter out files that no longer exist
      final List<String> validPaths = [];
      for (final path in paths) {
        if (await File(path).exists()) {
          validPaths.add(path);
        }
      }

      // If any files were removed, update SharedPreferences
      if (validPaths.length != paths.length) {
        await prefs.setString(_recentFilesKey, jsonEncode(validPaths));
      }

      return validPaths;
    } catch (e) {
      debugPrint('Error getting recent files: $e');
      return [];
    }
  }

  /// Clear all recent files
  static Future<void> clearRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentFilesKey);
      debugPrint('Cleared recent files');
    } catch (e) {
      debugPrint('Error clearing recent files: $e');
    }
  }

  /// Remove specific file from recent files
  static Future<void> removeFromRecentFiles(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> recentFiles = await getRecentFiles();

      recentFiles.remove(filePath);

      await prefs.setString(_recentFilesKey, jsonEncode(recentFiles));
      debugPrint('Removed from recent files: $filePath');
    } catch (e) {
      debugPrint('Error removing from recent files: $e');
    }
  }

  /// Get file size as human-readable string
  static Future<String> _getFileSizeString(File file) async {
    try {
      final bytes = await file.length();

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get file name from path
  static String getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// Get file directory from path
  static String getFileDirectory(String path) {
    return File(path).parent.path;
  }

  /// Check if app has storage permissions (for Android)
  ///
  /// Note: In Flutter 3.x with modern Android, scoped storage is default
  /// so explicit permission checks may not be needed for file picker
  static Future<bool> checkStoragePermissions() async {
    // On Android 10+, scoped storage is used by default
    // File picker handles permissions internally

    // For legacy Android or custom requirements, would use permission_handler package
    // For now, assume file_picker handles permissions

    return true;
  }

  /// Request storage permissions (placeholder for future implementation)
  static Future<bool> requestStoragePermissions() async {
    // Would use permission_handler package:
    // final status = await Permission.storage.request();
    // return status.isGranted;

    // For now, rely on file_picker's internal permission handling
    return true;
  }
}

/// Custom exception for file picker errors
class FilePickerException implements Exception {
  final String message;

  FilePickerException(this.message);

  @override
  String toString() => 'FilePickerException: $message';
}
