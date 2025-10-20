import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Model for a mind map node
class MindMapNode {
  final String id;
  String text;
  Offset position;
  Color color;
  List<String> childIds;
  double fontSize;
  bool isCollapsed;

  MindMapNode({
    String? id,
    required this.text,
    this.position = Offset.zero,
    this.color = Colors.blue,
    List<String>? childIds,
    this.fontSize = 16.0,
    this.isCollapsed = false,
  })  : id = id ?? const Uuid().v4(),
        childIds = childIds ?? [];

  /// Copy with modifications
  MindMapNode copyWith({
    String? text,
    Offset? position,
    Color? color,
    List<String>? childIds,
    double? fontSize,
    bool? isCollapsed,
  }) {
    return MindMapNode(
      id: id,
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      childIds: childIds ?? List.from(this.childIds),
      fontSize: fontSize ?? this.fontSize,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'position': {'dx': position.dx, 'dy': position.dy},
      'color': color.toARGB32(),
      'childIds': childIds,
      'fontSize': fontSize,
      'isCollapsed': isCollapsed,
    };
  }

  /// Create from JSON
  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'] as String,
      text: json['text'] as String,
      position: Offset(
        json['position']['dx'] as double,
        json['position']['dy'] as double,
      ),
      color: Color(json['color'] as int),
      childIds: List<String>.from(json['childIds'] as List),
      fontSize: json['fontSize'] as double? ?? 16.0,
      isCollapsed: json['isCollapsed'] as bool? ?? false,
    );
  }

  /// Serialize list of nodes to JSON string
  static String serializeNodes(List<MindMapNode> nodes) {
    return jsonEncode(nodes.map((n) => n.toJson()).toList());
  }

  /// Deserialize JSON string to list of nodes
  static List<MindMapNode> deserializeNodes(String json) {
    final List<dynamic> data = jsonDecode(json);
    return data.map((n) => MindMapNode.fromJson(n as Map<String, dynamic>)).toList();
  }
}

/// Model for a mind map edge/connection
class MindMapEdge {
  final String id;
  final String fromNodeId;
  final String toNodeId;
  Color color;
  double strokeWidth;
  String label;

  MindMapEdge({
    String? id,
    required this.fromNodeId,
    required this.toNodeId,
    this.color = Colors.grey,
    this.strokeWidth = 2.0,
    this.label = '',
  }) : id = id ?? const Uuid().v4();

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      'label': label,
    };
  }

  /// Create from JSON
  factory MindMapEdge.fromJson(Map<String, dynamic> json) {
    return MindMapEdge(
      id: json['id'] as String,
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      color: Color(json['color'] as int),
      strokeWidth: json['strokeWidth'] as double? ?? 2.0,
      label: json['label'] as String? ?? '',
    );
  }

  /// Serialize list of edges to JSON string
  static String serializeEdges(List<MindMapEdge> edges) {
    return jsonEncode(edges.map((e) => e.toJson()).toList());
  }

  /// Deserialize JSON string to list of edges
  static List<MindMapEdge> deserializeEdges(String json) {
    final List<dynamic> data = jsonDecode(json);
    return data.map((e) => MindMapEdge.fromJson(e as Map<String, dynamic>)).toList();
  }
}
