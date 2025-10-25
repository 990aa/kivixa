import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:kivixa/models/layer_stroke.dart';

/// Drawing layer that stores all necessary information for each layer
class DrawingLayer {
  String id; // Unique identifier
  String name; // User-defined name
  ui.Image? cachedImage; // Cached bitmap of layer content
  List<LayerStroke> strokes; // All strokes on this layer
  double opacity; // Layer opacity (0.0-1.0)
  BlendMode blendMode; // How it composites with layers below
  bool isVisible; // Show/hide layer
  bool isLocked; // Prevent editing
  Rect? bounds; // Bounding box for optimization
  DateTime createdAt; // Creation timestamp
  DateTime modifiedAt; // Last modification timestamp

  DrawingLayer({
    String? id,
    this.name = 'Layer',
    this.cachedImage,
    List<LayerStroke>? strokes,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.isVisible = true,
    this.isLocked = false,
    this.bounds,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) : id = id ?? const Uuid().v4(),
       strokes = strokes ?? [],
       createdAt = createdAt ?? DateTime.now(),
       modifiedAt = modifiedAt ?? DateTime.now();

  /// Update the bounds based on all strokes in this layer
  void updateBounds() {
    if (strokes.isEmpty) {
      bounds = null;
      return;
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final stroke in strokes) {
      for (final point in stroke.points) {
        if (point.position.dx < minX) minX = point.position.dx;
        if (point.position.dx > maxX) maxX = point.position.dx;
        if (point.position.dy < minY) minY = point.position.dy;
        if (point.position.dy > maxY) maxY = point.position.dy;
      }
    }

    // Add padding based on max stroke width
    final maxStrokeWidth = strokes
        .map((s) => s.brushProperties.strokeWidth)
        .reduce((a, b) => a > b ? a : b);
    final padding = maxStrokeWidth * 2;

    bounds = Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  /// Add a stroke to this layer
  void addStroke(LayerStroke stroke) {
    strokes.add(stroke);
    modifiedAt = DateTime.now();
    updateBounds();
  }

  /// Remove a stroke from this layer
  bool removeStroke(String strokeId) {
    final initialLength = strokes.length;
    strokes.removeWhere((s) => s.id == strokeId);
    final removed = initialLength != strokes.length;
    if (removed) {
      modifiedAt = DateTime.now();
      updateBounds();
      return true;
    }
    return false;
  }

  /// Clear all strokes from this layer
  void clearStrokes() {
    strokes.clear();
    bounds = null;
    modifiedAt = DateTime.now();
    cachedImage = null;
  }

  /// Invalidate the cached image (call when layer content changes)
  void invalidateCache() {
    cachedImage = null;
  }

  /// Create a copy of this layer
  DrawingLayer copyWith({
    String? id,
    String? name,
    ui.Image? cachedImage,
    List<LayerStroke>? strokes,
    double? opacity,
    BlendMode? blendMode,
    bool? isVisible,
    bool? isLocked,
    Rect? bounds,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return DrawingLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      cachedImage: cachedImage ?? this.cachedImage,
      strokes: strokes ?? List.from(this.strokes),
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      bounds: bounds ?? this.bounds,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      'opacity': opacity,
      'blendMode': blendMode.index,
      'isVisible': isVisible,
      'isLocked': isLocked,
      'bounds': bounds != null
          ? {
              'left': bounds!.left,
              'top': bounds!.top,
              'right': bounds!.right,
              'bottom': bounds!.bottom,
            }
          : null,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory DrawingLayer.fromJson(Map<String, dynamic> json) {
    return DrawingLayer(
      id: json['id'] as String,
      name: json['name'] as String,
      strokes: (json['strokes'] as List)
          .map((s) => LayerStroke.fromJson(s as Map<String, dynamic>))
          .toList(),
      opacity: json['opacity'] as double,
      blendMode: BlendMode.values[json['blendMode'] as int],
      isVisible: json['isVisible'] as bool,
      isLocked: json['isLocked'] as bool,
      bounds: json['bounds'] != null
          ? Rect.fromLTRB(
              json['bounds']['left'] as double,
              json['bounds']['top'] as double,
              json['bounds']['right'] as double,
              json['bounds']['bottom'] as double,
            )
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
    );
  }
}
