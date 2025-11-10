import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Represents an image annotation on a PDF page
class ImageAnnotation {
  final String id;
  final Uint8List imageBytes;
  final Offset position; // Position on the page
  final Size size; // Size of the image
  final int pageNumber;
  final DateTime createdAt;

  ImageAnnotation({
    required this.id,
    required this.imageBytes,
    required this.position,
    required this.size,
    required this.pageNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ImageAnnotation copyWith({
    String? id,
    Uint8List? imageBytes,
    Offset? position,
    Size? size,
    int? pageNumber,
    DateTime? createdAt,
  }) {
    return ImageAnnotation(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      position: position ?? this.position,
      size: size ?? this.size,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageBytes': imageBytes.toList(),
      'positionX': position.dx,
      'positionY': position.dy,
      'width': size.width,
      'height': size.height,
      'pageNumber': pageNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ImageAnnotation.fromJson(Map<String, dynamic> json) {
    return ImageAnnotation(
      id: json['id'] as String,
      imageBytes: Uint8List.fromList(
        (json['imageBytes'] as List<dynamic>).cast<int>(),
      ),
      position: Offset(
        (json['positionX'] as num).toDouble(),
        (json['positionY'] as num).toDouble(),
      ),
      size: Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      pageNumber: json['pageNumber'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
