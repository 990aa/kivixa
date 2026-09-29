import 'package:flutter/material.dart';
import 'package:kivixa/services/productivity/material_icon_codec.dart';

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
      icon: MaterialIconCodec.fromCodePoint(
        json['icon'] as int,
        fallback: Icons.timer,
      ),
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
    this.workSeconds = 0,
    required this.breakMinutes,
    this.breakSeconds = 0,
    this.longBreakMinutes,
    this.longBreakSeconds,
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
  final int workSeconds;
  final int breakMinutes;
  final int breakSeconds;
  final int? longBreakMinutes;
  final int? longBreakSeconds;
  final int? cyclesBeforeLongBreak;
  final int totalCycles;
  final bool autoStartBreak;
  final bool autoStartNextSession;
  final String? description;
  final bool isDefault;

  Duration get workDuration =>
      Duration(minutes: workMinutes, seconds: workSeconds);
  Duration get breakDuration =>
      Duration(minutes: breakMinutes, seconds: breakSeconds);
  Duration? get longBreakDuration => longBreakMinutes == null
      ? null
      : Duration(minutes: longBreakMinutes!, seconds: longBreakSeconds ?? 0);

  /// Predefined quick presets
  static const code = QuickPreset(
    id: 'code',
    name: 'Code',
    icon: Icons.code,
    workMinutes: 45,
    workSeconds: 0,
    breakMinutes: 10,
    breakSeconds: 0,
    longBreakMinutes: 20,
    longBreakSeconds: 0,
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
    workSeconds: 0,
    breakMinutes: 5,
    breakSeconds: 0,
    longBreakMinutes: 15,
    longBreakSeconds: 0,
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
    workSeconds: 0,
    breakMinutes: 20,
    breakSeconds: 0,
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
    workSeconds: 0,
    breakMinutes: 3,
    breakSeconds: 0,
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
    workSeconds: 0,
    breakMinutes: 10,
    breakSeconds: 0,
    longBreakMinutes: 30,
    longBreakSeconds: 0,
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
    workSeconds: 0,
    breakMinutes: 5,
    breakSeconds: 0,
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
    'workSeconds': workSeconds,
    'breakMinutes': breakMinutes,
    'breakSeconds': breakSeconds,
    'longBreakMinutes': longBreakMinutes,
    'longBreakSeconds': longBreakSeconds,
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
      icon: MaterialIconCodec.fromCodePoint(
        json['icon'] as int,
        fallback: Icons.timer,
      ),
      workMinutes: json['workMinutes'] as int,
      workSeconds: json['workSeconds'] as int? ?? 0,
      breakMinutes: json['breakMinutes'] as int,
      breakSeconds: json['breakSeconds'] as int? ?? 0,
      longBreakMinutes: json['longBreakMinutes'] as int?,
      longBreakSeconds: json['longBreakSeconds'] as int? ?? 0,
      cyclesBeforeLongBreak: json['cyclesBeforeLongBreak'] as int?,
      totalCycles: json['totalCycles'] as int? ?? 4,
      autoStartBreak: json['autoStartBreak'] as bool? ?? true,
      autoStartNextSession: json['autoStartNextSession'] as bool? ?? false,
      description: json['description'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  QuickPreset copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? workMinutes,
    int? workSeconds,
    int? breakMinutes,
    int? breakSeconds,
    int? longBreakMinutes,
    int? longBreakSeconds,
    int? cyclesBeforeLongBreak,
    int? totalCycles,
    bool? autoStartBreak,
    bool? autoStartNextSession,
    String? description,
    bool? isDefault,
  }) {
    return QuickPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      workMinutes: workMinutes ?? this.workMinutes,
      workSeconds: workSeconds ?? this.workSeconds,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      breakSeconds: breakSeconds ?? this.breakSeconds,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      longBreakSeconds: longBreakSeconds ?? this.longBreakSeconds,
      cyclesBeforeLongBreak:
          cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
      totalCycles: totalCycles ?? this.totalCycles,
      autoStartBreak: autoStartBreak ?? this.autoStartBreak,
      autoStartNextSession: autoStartNextSession ?? this.autoStartNextSession,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
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
