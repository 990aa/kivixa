import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

/// Service for handling image operations including clipboard and file picking
class ImageService {
  /// Get image from clipboard (Ctrl+V)
  /// Returns null if no image is available in clipboard
  static Future<Uint8List?> getImageFromClipboard() async {
    try {
      if (kIsWeb) {
        // Web doesn't support direct clipboard image access via pasteboard
        // Would need to use web-specific APIs
        debugPrint('Clipboard image access not supported on web');
        return null;
      }

      // Get image bytes from clipboard
      final imageBytes = await Pasteboard.image;

      if (imageBytes != null && imageBytes.isNotEmpty) {
        return imageBytes;
      }

      debugPrint('No image found in clipboard');
      return null;
    } catch (e) {
      debugPrint('Error accessing clipboard: $e');
      return null;
    }
  }

  /// Pick image from file system using file picker
  /// Returns null if user cancels or no file is selected
  static Future<Uint8List?> pickImageFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true, // Important: Load file data
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('No file selected');
        return null;
      }

      final file = result.files.first;

      if (file.bytes != null) {
        return file.bytes;
      }

      // Fallback: try reading from path (desktop platforms)
      if (!kIsWeb && file.path != null) {
        debugPrint('Reading image from path: ${file.path}');
        // Note: This would require additional file reading logic
        // For now, we rely on bytes being loaded
      }

      debugPrint('Could not load image data');
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Validate if bytes represent a valid image
  /// Returns true if the bytes appear to be a valid image format
  static bool isValidImageData(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return false;

    // Check for common image file signatures
    if (bytes.length < 4) return false;

    // PNG signature
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true;
    }

    // JPEG signature
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }

    // GIF signature
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return true;
    }

    // BMP signature
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return true;
    }

    // WebP signature
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }

    return false;
  }
}
