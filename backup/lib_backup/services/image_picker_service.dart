import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:kivixa/models/canvas_element.dart';

/// Service for handling image picking and import
class ImagePickerService {
  final _picker = ImagePicker();

  /// Pick an image from the specified source
  Future<ImageElement?> pickImage({
    required ImageSource source,
    required Offset position,
    double defaultWidth = 300,
    double defaultHeight = 300,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();

      final imageElement = ImageElement(
        id: const Uuid().v4(),
        imageData: bytes,
        position: position,
        width: defaultWidth,
        height: defaultHeight,
      );

      return imageElement;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<ImageElement?> pickFromGallery({
    required Offset position,
    double defaultWidth = 300,
    double defaultHeight = 300,
  }) async {
    return pickImage(
      source: ImageSource.gallery,
      position: position,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
    );
  }

  /// Pick image from camera
  Future<ImageElement?> pickFromCamera({
    required Offset position,
    double defaultWidth = 300,
    double defaultHeight = 300,
  }) async {
    return pickImage(
      source: ImageSource.camera,
      position: position,
      defaultWidth: defaultWidth,
      defaultHeight: defaultHeight,
    );
  }

  /// Create a text element at the specified position
  TextElement createTextElement({
    required Offset position,
    String initialText = 'Double tap to edit',
    TextStyle? style,
  }) {
    return TextElement(
      id: const Uuid().v4(),
      position: position,
      text: initialText,
      style: style ?? const TextStyle(fontSize: 24, color: Colors.black),
    );
  }
}
