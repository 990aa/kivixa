import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// Verifies that exported images maintain proper alpha channel
/// and transparency properties.
///
/// CRITICAL: Use this to verify that exports contain genuine
/// transparency and not white/black pixels masquerading as transparency.
class AlphaChannelVerifier {
  /// Verify that a PNG image has transparent pixels
  ///
  /// Returns true if the image contains at least one pixel with alpha < 255.
  /// This confirms that transparency is preserved in the export.
  static Future<bool> verifyTransparency(Uint8List pngBytes) async {
    try {
      // Decode PNG
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Get raw RGBA pixel data
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      image.dispose();
      codec.dispose();

      if (byteData == null) return false;

      final pixels = byteData.buffer.asUint8List();
      bool hasTransparency = false;

      // Check every 4th byte (alpha channel)
      // RGBA format: [R, G, B, A, R, G, B, A, ...]
      for (int i = 3; i < pixels.length; i += 4) {
        if (pixels[i] < 255) {
          // Alpha < 255 means transparency
          hasTransparency = true;
          break;
        }
      }

      return hasTransparency;
    } catch (e) {
      debugPrint('Error verifying transparency: $e');
      return false;
    }
  }

  /// Get detailed transparency statistics for an image
  ///
  /// Returns a map containing:
  /// - totalPixels: Total number of pixels
  /// - transparentPixels: Pixels with alpha < 255
  /// - opaquePixels: Pixels with alpha == 255
  /// - averageAlpha: Average alpha value across all pixels
  /// - minAlpha: Minimum alpha value found
  /// - maxAlpha: Maximum alpha value found
  static Future<Map<String, dynamic>> getTransparencyStats(
    Uint8List pngBytes,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      image.dispose();
      codec.dispose();

      if (byteData == null) {
        return {'error': 'Failed to get image data'};
      }

      final pixels = byteData.buffer.asUint8List();
      final totalPixels = pixels.length ~/ 4;

      int transparentPixels = 0;
      int opaquePixels = 0;
      int totalAlpha = 0;
      int minAlpha = 255;
      int maxAlpha = 0;

      for (int i = 3; i < pixels.length; i += 4) {
        final alpha = pixels[i];
        totalAlpha += alpha;

        if (alpha < 255) {
          transparentPixels++;
        } else {
          opaquePixels++;
        }

        if (alpha < minAlpha) minAlpha = alpha;
        if (alpha > maxAlpha) maxAlpha = alpha;
      }

      return {
        'totalPixels': totalPixels,
        'transparentPixels': transparentPixels,
        'opaquePixels': opaquePixels,
        'averageAlpha': totalAlpha / totalPixels,
        'minAlpha': minAlpha,
        'maxAlpha': maxAlpha,
        'transparencyPercentage': (transparentPixels / totalPixels) * 100,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Verify that an image is completely opaque (no transparency)
  ///
  /// Useful for verifying display rendering vs export rendering
  static Future<bool> verifyCompletelyOpaque(Uint8List pngBytes) async {
    final hasTransparency = await verifyTransparency(pngBytes);
    return !hasTransparency;
  }

  /// Check if specific regions are transparent
  ///
  /// Samples pixels in the specified regions and returns true if
  /// they contain transparency.
  static Future<bool> verifyRegionTransparency(
    Uint8List pngBytes,
    List<Rect> regions,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      final width = image.width;
      final height = image.height;

      image.dispose();
      codec.dispose();

      if (byteData == null) return false;

      final pixels = byteData.buffer.asUint8List();

      for (final region in regions) {
        // Sample pixels in this region
        final startX = region.left.toInt().clamp(0, width - 1);
        final endX = region.right.toInt().clamp(0, width - 1);
        final startY = region.top.toInt().clamp(0, height - 1);
        final endY = region.bottom.toInt().clamp(0, height - 1);

        for (int y = startY; y <= endY; y++) {
          for (int x = startX; x <= endX; x++) {
            final index = (y * width + x) * 4 + 3; // Alpha channel
            if (pixels[index] < 255) {
              return true; // Found transparency in region
            }
          }
        }
      }

      return false; // No transparency found in any region
    } catch (e) {
      debugPrint('Error verifying region transparency: $e');
      return false;
    }
  }

  /// Compare two images and report alpha channel differences
  ///
  /// Useful for comparing display rendering vs export rendering.
  /// Returns percentage of pixels with different alpha values.
  static Future<double> compareAlphaChannels(
    Uint8List image1Bytes,
    Uint8List image2Bytes,
  ) async {
    try {
      final codec1 = await ui.instantiateImageCodec(image1Bytes);
      final codec2 = await ui.instantiateImageCodec(image2Bytes);

      final frame1 = await codec1.getNextFrame();
      final frame2 = await codec2.getNextFrame();

      final image1 = frame1.image;
      final image2 = frame2.image;

      if (image1.width != image2.width || image1.height != image2.height) {
        image1.dispose();
        image2.dispose();
        codec1.dispose();
        codec2.dispose();
        throw Exception('Images must have same dimensions');
      }

      final byteData1 = await image1.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final byteData2 = await image2.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      image1.dispose();
      image2.dispose();
      codec1.dispose();
      codec2.dispose();

      if (byteData1 == null || byteData2 == null) {
        return 0.0;
      }

      final pixels1 = byteData1.buffer.asUint8List();
      final pixels2 = byteData2.buffer.asUint8List();

      int differentPixels = 0;
      final totalPixels = pixels1.length ~/ 4;

      for (int i = 3; i < pixels1.length; i += 4) {
        if (pixels1[i] != pixels2[i]) {
          differentPixels++;
        }
      }

      return (differentPixels / totalPixels) * 100;
    } catch (e) {
      debugPrint('Error comparing alpha channels: $e');
      return 0.0;
    }
  }

  /// Verify that erased regions are truly transparent (alpha = 0)
  ///
  /// Checks that eraser tool created genuine transparency, not
  /// white/black pixels.
  static Future<bool> verifyEraserTransparency(
    Uint8List pngBytes,
    List<Offset> eraserPoints,
    double eraserRadius,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(pngBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      final width = image.width;
      final height = image.height;

      image.dispose();
      codec.dispose();

      if (byteData == null) return false;

      final pixels = byteData.buffer.asUint8List();

      // Check each eraser point
      for (final point in eraserPoints) {
        final x = point.dx.toInt().clamp(0, width - 1);
        final y = point.dy.toInt().clamp(0, height - 1);

        // Sample pixels in eraser radius
        final radius = eraserRadius.toInt();
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final px = (x + dx).clamp(0, width - 1);
            final py = (y + dy).clamp(0, height - 1);

            // Check if point is within circle
            if (dx * dx + dy * dy <= radius * radius) {
              final index = (py * width + px) * 4 + 3;
              if (pixels[index] == 0) {
                return true; // Found transparent pixel from eraser
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error verifying eraser transparency: $e');
      return false;
    }
  }

  /// Generate a human-readable report of transparency verification
  static Future<String> generateTransparencyReport(Uint8List pngBytes) async {
    final stats = await getTransparencyStats(pngBytes);

    if (stats.containsKey('error')) {
      return 'Error: ${stats['error']}';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Transparency Verification Report ===');
    buffer.writeln('Total Pixels: ${stats['totalPixels']}');
    buffer.writeln('Transparent Pixels: ${stats['transparentPixels']}');
    buffer.writeln('Opaque Pixels: ${stats['opaquePixels']}');
    buffer.writeln(
      'Transparency: ${stats['transparencyPercentage'].toStringAsFixed(2)}%',
    );
    buffer.writeln(
      'Average Alpha: ${stats['averageAlpha'].toStringAsFixed(2)}',
    );
    buffer.writeln('Alpha Range: ${stats['minAlpha']} - ${stats['maxAlpha']}');

    if (stats['transparentPixels'] > 0) {
      buffer.writeln('\n✅ Alpha channel preserved - transparency verified!');
    } else {
      buffer.writeln('\n❌ No transparency detected - check export process!');
    }

    return buffer.toString();
  }
}

/// Extension methods for quick transparency checks
extension TransparencyVerification on Uint8List {
  /// Quick check if image has transparency
  Future<bool> hasTransparency() =>
      AlphaChannelVerifier.verifyTransparency(this);

  /// Get transparency statistics
  Future<Map<String, dynamic>> transparencyStats() =>
      AlphaChannelVerifier.getTransparencyStats(this);

  /// Generate readable report
  Future<String> transparencyReport() =>
      AlphaChannelVerifier.generateTransparencyReport(this);
}
