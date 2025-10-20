import 'package:flutter/material.dart';

/// A point in a stroke with pressure and stylus information
class StrokePoint {
  final Offset position;
  final double pressure; // 0.0-1.0
  final double tilt; // Stylus tilt angle
  final double orientation; // Stylus orientation

  const StrokePoint({
    required this.position,
    this.pressure = 1.0,
    this.tilt = 0.0,
    this.orientation = 0.0,
  });

  /// Create a copy with modified values
  StrokePoint copyWith({
    Offset? position,
    double? pressure,
    double? tilt,
    double? orientation,
  }) {
    return StrokePoint(
      position: position ?? this.position,
      pressure: pressure ?? this.pressure,
      tilt: tilt ?? this.tilt,
      orientation: orientation ?? this.orientation,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'x': position.dx,
      'y': position.dy,
      'pressure': pressure,
      'tilt': tilt,
      'orientation': orientation,
    };
  }

  /// Create from JSON
  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      position: Offset(json['x'] as double, json['y'] as double),
      pressure: json['pressure'] as double? ?? 1.0,
      tilt: json['tilt'] as double? ?? 0.0,
      orientation: json['orientation'] as double? ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StrokePoint &&
        other.position == position &&
        other.pressure == pressure &&
        other.tilt == tilt &&
        other.orientation == orientation;
  }

  @override
  int get hashCode =>
      position.hashCode ^
      pressure.hashCode ^
      tilt.hashCode ^
      orientation.hashCode;
}
