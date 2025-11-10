import 'package:flutter/material.dart';

/// High-precision coordinate storage using 64-bit double precision
///
/// Dart doubles are IEEE 754 64-bit floating point with 53 bits of integer precision
/// (~9 quadrillion values). This is more than sufficient for any canvas coordinate.
///
/// CRITICAL: Never round coordinates during storage/retrieval to prevent
/// sub-pixel position shifts that accumulate and ruin artwork.
///
/// Example:
/// ```dart
/// final coord = PrecisionCoordinate(123.456789012345, 987.654321098765);
/// final json = coord.toJson();
/// final restored = PrecisionCoordinate.fromJson(json);
/// // restored.x == 123.456789012345 (exact!)
/// ```
class PrecisionCoordinate {
  /// X coordinate with full 64-bit precision
  final double x;

  /// Y coordinate with full 64-bit precision
  final double y;

  const PrecisionCoordinate(this.x, this.y);

  /// Create from Flutter Offset
  factory PrecisionCoordinate.fromOffset(Offset offset) {
    return PrecisionCoordinate(offset.dx, offset.dy);
  }

  /// Convert to Flutter Offset
  Offset toOffset() => Offset(x, y);

  /// Serialize with full precision (no rounding)
  ///
  /// Stores as strings to preserve exact precision in JSON.
  /// JSON numbers lose precision beyond ~15 digits.
  Map<String, dynamic> toJson() {
    return {
      'x': x.toString(), // Full precision string
      'y': y.toString(),
    };
  }

  /// Deserialize with exact precision restoration
  factory PrecisionCoordinate.fromJson(Map<String, dynamic> json) {
    return PrecisionCoordinate(
      double.parse(json['x'] as String),
      double.parse(json['y'] as String),
    );
  }

  /// Calculate distance to another coordinate
  double distanceTo(PrecisionCoordinate other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy); // Return squared distance for performance
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrecisionCoordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'PrecisionCoordinate($x, $y)';
}

/// High-precision stroke point with pressure and tilt
class PrecisionStrokePoint {
  final PrecisionCoordinate position;
  final double pressure; // 0.0 - 1.0
  final double tilt; // 0.0 - 1.0
  final DateTime timestamp;

  PrecisionStrokePoint({
    required this.position,
    this.pressure = 1.0,
    this.tilt = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serialize with full precision
  Map<String, dynamic> toJson() {
    return {
      'position': position.toJson(),
      'pressure': pressure.toString(),
      'tilt': tilt.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserialize with exact precision restoration
  factory PrecisionStrokePoint.fromJson(Map<String, dynamic> json) {
    return PrecisionStrokePoint(
      position: PrecisionCoordinate.fromJson(
        json['position'] as Map<String, dynamic>,
      ),
      pressure: double.parse(json['pressure'] as String),
      tilt: double.parse(json['tilt'] as String? ?? '0.0'),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  String toString() =>
      'PrecisionStrokePoint(pos: $position, pressure: $pressure)';
}

/// Validates coordinate precision is maintained
class PrecisionValidator {
  /// Check if coordinate roundtrip maintains precision
  static bool validateRoundtrip(PrecisionCoordinate original) {
    final json = original.toJson();
    final restored = PrecisionCoordinate.fromJson(json);

    // Coordinates should be exactly equal (no precision loss)
    return original.x == restored.x && original.y == restored.y;
  }

  /// Calculate maximum precision error in a stroke
  static double calculateMaxError(
    List<PrecisionStrokePoint> original,
    List<PrecisionStrokePoint> restored,
  ) {
    if (original.length != restored.length) {
      return double.infinity;
    }

    double maxError = 0.0;
    for (int i = 0; i < original.length; i++) {
      final error = original[i].position.distanceTo(restored[i].position);
      if (error > maxError) maxError = error;
    }

    return maxError;
  }

  /// Verify no precision loss across save/load cycle
  static Map<String, dynamic> runPrecisionTest() {
    // Test with extreme values
    final testCoords = [
      const PrecisionCoordinate(0.0, 0.0),
      const PrecisionCoordinate(1.0, 1.0),
      const PrecisionCoordinate(123.456789012345, 987.654321098765),
      const PrecisionCoordinate(9999999.999999, 9999999.999999),
      const PrecisionCoordinate(-1234.5678, -9876.5432),
    ];

    int passed = 0;
    int failed = 0;
    double maxError = 0.0;

    for (final coord in testCoords) {
      if (validateRoundtrip(coord)) {
        passed++;
      } else {
        failed++;
        final json = coord.toJson();
        final restored = PrecisionCoordinate.fromJson(json);
        final errorX = (coord.x - restored.x).abs();
        final errorY = (coord.y - restored.y).abs();
        final error = errorX > errorY ? errorX : errorY;
        if (error > maxError) maxError = error;
      }
    }

    return {
      'passed': passed,
      'failed': failed,
      'maxError': maxError,
      'success': failed == 0,
    };
  }
}

/// Extension to add precision methods to existing classes
extension OffsetPrecision on Offset {
  /// Convert to high-precision coordinate
  PrecisionCoordinate toPrecision() => PrecisionCoordinate.fromOffset(this);

  /// Serialize with full precision
  Map<String, dynamic> toJsonPrecise() => toPrecision().toJson();

  /// Deserialize from precision JSON
  static Offset fromJsonPrecise(Map<String, dynamic> json) {
    return PrecisionCoordinate.fromJson(json).toOffset();
  }
}
