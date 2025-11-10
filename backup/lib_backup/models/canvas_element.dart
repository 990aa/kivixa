import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Base class for all canvas elements
abstract class CanvasElement {
  String id;
  Offset position;
  double rotation;
  double scale;

  CanvasElement({
    String? id,
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
  }) : id = id ?? const Uuid().v4();

  /// Create a copy of this element
  CanvasElement copyWith();
}

/// Text element that can be placed on canvas
class TextElement extends CanvasElement {
  String text;
  TextStyle style;

  TextElement({
    super.id,
    required super.position,
    super.rotation,
    super.scale,
    required this.text,
    TextStyle? style,
  }) : style = style ?? const TextStyle(fontSize: 24, color: Colors.black);

  @override
  TextElement copyWith({
    String? id,
    Offset? position,
    double? rotation,
    double? scale,
    String? text,
    TextStyle? style,
  }) {
    return TextElement(
      id: id ?? this.id,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      text: text ?? this.text,
      style: style ?? this.style,
    );
  }
}

/// Image element that can be placed on canvas
class ImageElement extends CanvasElement {
  Uint8List imageData;
  double width;
  double height;

  ImageElement({
    super.id,
    required super.position,
    super.rotation,
    super.scale,
    required this.imageData,
    required this.width,
    required this.height,
  });

  @override
  ImageElement copyWith({
    String? id,
    Offset? position,
    double? rotation,
    double? scale,
    Uint8List? imageData,
    double? width,
    double? height,
  }) {
    return ImageElement(
      id: id ?? this.id,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      imageData: imageData ?? this.imageData,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
