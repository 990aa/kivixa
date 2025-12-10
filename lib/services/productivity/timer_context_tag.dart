import 'package:flutter/material.dart';

/// Context tags for categorizing timer sessions
class TimerContextTag {
  const TimerContextTag({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isDefault;

  /// Default tags available out of the box
  static const coding = TimerContextTag(
    id: 'coding',
    name: 'Coding',
    icon: Icons.code,
    color: Color(0xFF4CAF50),
    isDefault: true,
  );

  static const reading = TimerContextTag(
    id: 'reading',
    name: 'Reading',
    icon: Icons.menu_book,
    color: Color(0xFF2196F3),
    isDefault: true,
  );

  static const writing = TimerContextTag(
    id: 'writing',
    name: 'Writing',
    icon: Icons.edit,
    color: Color(0xFF9C27B0),
    isDefault: true,
  );

  static const design = TimerContextTag(
    id: 'design',
    name: 'Design',
    icon: Icons.palette,
    color: Color(0xFFE91E63),
    isDefault: true,
  );

  static const research = TimerContextTag(
    id: 'research',
    name: 'Research',
    icon: Icons.search,
    color: Color(0xFF00BCD4),
    isDefault: true,
  );

  static const meeting = TimerContextTag(
    id: 'meeting',
    name: 'Meeting',
    icon: Icons.groups,
    color: Color(0xFFFF9800),
    isDefault: true,
  );

  static const learning = TimerContextTag(
    id: 'learning',
    name: 'Learning',
    icon: Icons.school,
    color: Color(0xFF673AB7),
    isDefault: true,
  );

  static const planning = TimerContextTag(
    id: 'planning',
    name: 'Planning',
    icon: Icons.event_note,
    color: Color(0xFF795548),
    isDefault: true,
  );

  static const exercise = TimerContextTag(
    id: 'exercise',
    name: 'Exercise',
    icon: Icons.fitness_center,
    color: Color(0xFFF44336),
    isDefault: true,
  );

  static const meditation = TimerContextTag(
    id: 'meditation',
    name: 'Meditation',
    icon: Icons.self_improvement,
    color: Color(0xFF607D8B),
    isDefault: true,
  );

  static const List<TimerContextTag> defaultTags = [
    coding,
    reading,
    writing,
    design,
    research,
    meeting,
    learning,
    planning,
    exercise,
    meditation,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'isDefault': isDefault,
  };
  factory TimerContextTag.fromJson(Map<String, dynamic> json) {
    return TimerContextTag(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['color'] as int),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerContextTag &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Quick-switch presets with different durations and break rules
class QuickPreset {
  const QuickPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.workMinutes,
    required this.breakMinutes,
    this.longBreakMinutes,
    this.cyclesBeforeLongBreak,
    this.totalCycles = 4,
    this.autoStartBreak = true,
    this.autoStartNextSession = false,
    this.description,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final IconData icon;
  final int workMinutes;
  final int breakMinutes;
  final int? longBreakMinutes;
  final int? cyclesBeforeLongBreak;
  final int totalCycles;
  final bool autoStartBreak;
  final bool autoStartNextSession;
  final String? description;
  final bool isDefault;

  /// Predefined quick presets
  static const code = QuickPreset(
    id: 'code',
    name: 'Code',
    icon: Icons.code,
    workMinutes: 45,
    breakMinutes: 10,
    longBreakMinutes: 20,
    cyclesBeforeLongBreak: 3,
    totalCycles: 6,
    description: 'Longer sessions for deep coding work',
    isDefault: true,
  );

  static const reading = QuickPreset(
    id: 'reading',
    name: 'Reading',
    icon: Icons.menu_book,
    workMinutes: 30,
    breakMinutes: 5,
    longBreakMinutes: 15,
    cyclesBeforeLongBreak: 4,
    totalCycles: 8,
    description: 'Shorter sessions for focused reading',
    isDefault: true,
  );

  static const deepDesign = QuickPreset(
    id: 'deep_design',
    name: 'Deep Design',
    icon: Icons.palette,
    workMinutes: 90,
    breakMinutes: 20,
    totalCycles: 3,
    autoStartBreak: false,
    description: 'Extended sessions for creative design work',
    isDefault: true,
  );

  static const quickTask = QuickPreset(
    id: 'quick_task',
    name: 'Quick Task',
    icon: Icons.flash_on,
    workMinutes: 15,
    breakMinutes: 3,
    totalCycles: 8,
    autoStartBreak: true,
    autoStartNextSession: true,
    description: 'Rapid-fire short tasks',
    isDefault: true,
  );

  static const study = QuickPreset(
    id: 'study',
    name: 'Study',
    icon: Icons.school,
    workMinutes: 50,
    breakMinutes: 10,
    longBreakMinutes: 30,
    cyclesBeforeLongBreak: 2,
    totalCycles: 4,
    description: 'Optimized for learning and retention',
    isDefault: true,
  );

  static const meeting = QuickPreset(
    id: 'meeting',
    name: 'Meeting',
    icon: Icons.groups,
    workMinutes: 30,
    breakMinutes: 5,
    totalCycles: 4,
    autoStartBreak: false,
    description: 'Keep meetings focused and on-time',
    isDefault: true,
  );

  static const List<QuickPreset> defaultPresets = [
    code,
    reading,
    deepDesign,
    quickTask,
    study,
    meeting,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'workMinutes': workMinutes,
    'breakMinutes': breakMinutes,
    'longBreakMinutes': longBreakMinutes,
    'cyclesBeforeLongBreak': cyclesBeforeLongBreak,
    'totalCycles': totalCycles,
    'autoStartBreak': autoStartBreak,
    'autoStartNextSession': autoStartNextSession,
    'description': description,
    'isDefault': isDefault,
  };

  factory QuickPreset.fromJson(Map<String, dynamic> json) {
    return QuickPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      workMinutes: json['workMinutes'] as int,
      breakMinutes: json['breakMinutes'] as int,
      longBreakMinutes: json['longBreakMinutes'] as int?,
      cyclesBeforeLongBreak: json['cyclesBeforeLongBreak'] as int?,
      totalCycles: json['totalCycles'] as int? ?? 4,
      autoStartBreak: json['autoStartBreak'] as bool? ?? true,
      autoStartNextSession: json['autoStartNextSession'] as bool? ?? false,
      description: json['description'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickPreset &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
