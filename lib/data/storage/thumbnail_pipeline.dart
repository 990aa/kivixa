import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ThumbnailPipeline {
  // Generate a thumbnail for an image file using platform-specific codecs if available
  static Future<Uint8List> generateThumbnail(
    File imageFile, {
    int maxDimension = 256,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    final thumbnail = img.copyResize(image, width: maxDimension);
    return Uint8List.fromList(img.encodePng(thumbnail));
  }

  // Save thumbnail to platform-appropriate directory
  static Future<String> saveThumbnail(
    Uint8List thumbnailBytes,
    String assetId,
  ) async {
    final dir = await _getThumbnailDirectory();
    final filePath = join(dir.path, '$assetId.png');
    final file = File(filePath);
    await file.writeAsBytes(thumbnailBytes);
    return filePath;
  }

  static Future<Directory> _getThumbnailDirectory() async {
    if (Platform.isAndroid) {
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isWindows) {
      return await getApplicationSupportDirectory();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
}
