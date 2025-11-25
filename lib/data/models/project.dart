import 'package:flutter/material.dart';

enum ProjectStatus { upcoming, ongoing, completed }

class ProjectChange {
  final String id;
  final String description;
  final DateTime timestamp;
  final bool isCompleted;

  ProjectChange({
    required this.id,
    required this.description,
    required this.timestamp,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory ProjectChange.fromJson(Map<String, dynamic> json) {
    return ProjectChange(
      id: json['id'] as String,
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  ProjectChange copyWith({
    String? id,
    String? description,
    DateTime? timestamp,
    bool? isCompleted,
  }) {
    return ProjectChange(
      id: id ?? this.id,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class Project {
  final String id;
  final String title;
  final String? description;
  final ProjectStatus status;
  final List<ProjectChange> changes;
  final List<String> taskIds; // References to CalendarEvent IDs
  final List<String> noteIds; // References to note file paths
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? lastActivityAt;
  final Color? color;
  final String? readme; // Project README content
  final int starCount; // For pinned/starred projects

  Project({
    required this.id,
    required this.title,
    this.description,
    this.status = ProjectStatus.upcoming,
    this.changes = const [],
    this.taskIds = const [],
    this.noteIds = const [],
    required this.createdAt,
    this.completedAt,
    this.lastActivityAt,
    this.color,
    this.readme,
    this.starCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'changes': changes.map((c) => c.toJson()).toList(),
      'taskIds': taskIds,
      'noteIds': noteIds,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'color': color?.toARGB32(),
      'readme': readme,
      'starCount': starCount,
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProjectStatus.upcoming,
      ),
      changes:
          (json['changes'] as List?)
              ?.map((c) => ProjectChange.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      taskIds: (json['taskIds'] as List?)?.cast<String>() ?? [],
      noteIds: (json['noteIds'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : null,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      readme: json['readme'] as String?,
      starCount: json['starCount'] as int? ?? 0,
    );
  }

  Project copyWith({
    String? id,
    String? title,
    String? description,
    ProjectStatus? status,
    List<ProjectChange>? changes,
    List<String>? taskIds,
    List<String>? noteIds,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? lastActivityAt,
    Color? color,
    String? readme,
    int? starCount,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      changes: changes ?? this.changes,
      taskIds: taskIds ?? this.taskIds,
      noteIds: noteIds ?? this.noteIds,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      color: color ?? this.color,
      readme: readme ?? this.readme,
      starCount: starCount ?? this.starCount,
    );
  }

  /// Get all changes (completed and pending)
  List<ProjectChange> get allChanges => changes;

  /// Get only completed changes
  List<ProjectChange> get completedChanges =>
      changes.where((c) => c.isCompleted).toList();

  /// Get only pending changes
  List<ProjectChange> get pendingChanges =>
      changes.where((c) => !c.isCompleted).toList();

  /// Get change timeline sorted by timestamp
  List<ProjectChange> get timeline {
    final sorted = List<ProjectChange>.from(changes);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }
}
