import 'package:flutter/material.dart';

/// Tag model with custom colors for document organization
///
/// Features:
/// - Unique tag names
/// - Custom color coding
/// - Usage tracking (how many documents have this tag)
/// - Many-to-many relationship with documents
class Tag {
  final int? id;
  final String name;
  final Color color;
  final DateTime createdAt;
  final int useCount;

  Tag({
    this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.useCount = 0,
  });

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'created_at': createdAt.millisecondsSinceEpoch,
      'use_count': useCount,
    };
  }

  /// Create from database map
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as int?,
      name: map['name'] as String,
      color: Color(map['color'] as int),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      useCount: map['use_count'] as int? ?? 0,
    );
  }

  /// Create a copy with modified fields
  Tag copyWith({
    int? id,
    String? name,
    Color? color,
    DateTime? createdAt,
    int? useCount,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      useCount: useCount ?? this.useCount,
    );
  }

  /// Get tag color with specific opacity
  Color withOpacity(double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get tag display chip widget
  Widget toChip({VoidCallback? onDeleted, VoidCallback? onTap}) {
    return Chip(
      label: Text(
        name,
        style: TextStyle(
          color: _getContrastingTextColor(),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      deleteIcon: onDeleted != null
          ? Icon(Icons.close, size: 16, color: _getContrastingTextColor())
          : null,
      onDeleted: onDeleted,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Get contrasting text color (black or white) based on background
  Color _getContrastingTextColor() {
    // Calculate relative luminance
    final luminance =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Tag(id: $id, name: $name, useCount: $useCount)';
  }
}

/// Predefined tag colors for quick selection
class TagColors {
  static const List<Color> predefined = [
    Color(0xFFE57373), // Red
    Color(0xFFF06292), // Pink
    Color(0xFFBA68C8), // Purple
    Color(0xFF9575CD), // Deep Purple
    Color(0xFF7986CB), // Indigo
    Color(0xFF64B5F6), // Blue
    Color(0xFF4FC3F7), // Light Blue
    Color(0xFF4DD0E1), // Cyan
    Color(0xFF4DB6AC), // Teal
    Color(0xFF81C784), // Green
    Color(0xFFAED581), // Light Green
    Color(0xFFDCE775), // Lime
    Color(0xFFFFF176), // Yellow
    Color(0xFFFFD54F), // Amber
    Color(0xFFFFB74D), // Orange
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFFA1887F), // Brown
    Color(0xFF90A4AE), // Blue Grey
  ];

  /// Get random color from predefined list
  static Color random() {
    return predefined[DateTime.now().millisecond % predefined.length];
  }
}
