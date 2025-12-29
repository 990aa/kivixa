import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kivixa/services/productivity/material_icon_codec.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single block in a routine chain
class RoutineBlock {
  const RoutineBlock({
    required this.name,
    required this.durationMinutes,
    this.icon = Icons.timer,
    this.color = Colors.blue,
    this.description,
  });

  final String name;
  final int durationMinutes;
  final IconData icon;
  final Color color;
  final String? description;

  Duration get duration => Duration(minutes: durationMinutes);

  Map<String, dynamic> toJson() => {
    'name': name,
    'durationMinutes': durationMinutes,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'description': description,
  };
  factory RoutineBlock.fromJson(Map<String, dynamic> json) {
    return RoutineBlock(
      name: json['name'] as String,
      durationMinutes: json['durationMinutes'] as int,
      icon: MaterialIconCodec.fromCodePoint(
        json['icon'] as int,
        fallback: Icons.timer,
      ),
      color: Color(json['color'] as int),
      description: json['description'] as String?,
    );
  }

  RoutineBlock copyWith({
    String? name,
    int? durationMinutes,
    IconData? icon,
    Color? color,
    String? description,
  }) {
    return RoutineBlock(
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
    );
  }
}

/// A chained routine consisting of multiple timed blocks
class ChainedRoutine {
  const ChainedRoutine({
    required this.id,
    required this.name,
    required this.blocks,
    this.icon = Icons.playlist_play,
    this.color = Colors.blue,
    this.description,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final List<RoutineBlock> blocks;
  final IconData icon;
  final Color color;
  final String? description;
  final bool isDefault;

  Duration get totalDuration {
    return blocks.fold(Duration.zero, (total, block) => total + block.duration);
  }

  int get totalMinutes => totalDuration.inMinutes;

  /// Morning routine preset
  static const morningRoutine = ChainedRoutine(
    id: 'morning_routine',
    name: 'Morning Routine',
    icon: Icons.wb_sunny,
    color: Color(0xFFFF9800),
    description: 'Start your day right',
    isDefault: true,
    blocks: [
      RoutineBlock(
        name: 'Meditate',
        durationMinutes: 10,
        icon: Icons.self_improvement,
        color: Color(0xFF9C27B0),
        description: 'Calm your mind',
      ),
      RoutineBlock(
        name: 'Exercise',
        durationMinutes: 20,
        icon: Icons.fitness_center,
        color: Color(0xFFF44336),
        description: 'Get your body moving',
      ),
      RoutineBlock(
        name: 'Journal',
        durationMinutes: 10,
        icon: Icons.edit_note,
        color: Color(0xFF4CAF50),
        description: 'Write down your thoughts',
      ),
      RoutineBlock(
        name: 'Plan Day',
        durationMinutes: 10,
        icon: Icons.event_note,
        color: Color(0xFF2196F3),
        description: 'Set your priorities',
      ),
    ],
  );

  /// Evening wind-down routine
  static const eveningRoutine = ChainedRoutine(
    id: 'evening_routine',
    name: 'Evening Wind-Down',
    icon: Icons.nights_stay,
    color: Color(0xFF673AB7),
    description: 'Prepare for restful sleep',
    isDefault: true,
    blocks: [
      RoutineBlock(
        name: 'Review Day',
        durationMinutes: 10,
        icon: Icons.checklist,
        color: Color(0xFF4CAF50),
        description: 'Reflect on accomplishments',
      ),
      RoutineBlock(
        name: 'Light Reading',
        durationMinutes: 20,
        icon: Icons.menu_book,
        color: Color(0xFF2196F3),
        description: 'Read something relaxing',
      ),
      RoutineBlock(
        name: 'Gratitude',
        durationMinutes: 5,
        icon: Icons.favorite,
        color: Color(0xFFE91E63),
        description: 'Write 3 things you\'re grateful for',
      ),
      RoutineBlock(
        name: 'Breathe',
        durationMinutes: 5,
        icon: Icons.air,
        color: Color(0xFF9C27B0),
        description: 'Deep breathing exercises',
      ),
    ],
  );

  /// Study session routine
  static const studySession = ChainedRoutine(
    id: 'study_session',
    name: 'Study Session',
    icon: Icons.school,
    color: Color(0xFF2196F3),
    description: 'Structured learning blocks',
    isDefault: true,
    blocks: [
      RoutineBlock(
        name: 'Review Notes',
        durationMinutes: 15,
        icon: Icons.note_alt,
        color: Color(0xFF9C27B0),
        description: 'Review previous material',
      ),
      RoutineBlock(
        name: 'Active Learning',
        durationMinutes: 30,
        icon: Icons.psychology,
        color: Color(0xFF4CAF50),
        description: 'Focus on new material',
      ),
      RoutineBlock(
        name: 'Practice',
        durationMinutes: 20,
        icon: Icons.edit,
        color: Color(0xFFFF9800),
        description: 'Apply what you learned',
      ),
      RoutineBlock(
        name: 'Quiz Yourself',
        durationMinutes: 10,
        icon: Icons.quiz,
        color: Color(0xFFF44336),
        description: 'Test your knowledge',
      ),
    ],
  );

  /// Creative work session
  static const creativeSession = ChainedRoutine(
    id: 'creative_session',
    name: 'Creative Session',
    icon: Icons.palette,
    color: Color(0xFFE91E63),
    description: 'Structured creative work',
    isDefault: true,
    blocks: [
      RoutineBlock(
        name: 'Warm Up',
        durationMinutes: 10,
        icon: Icons.brush,
        color: Color(0xFFFF9800),
        description: 'Quick sketches or exercises',
      ),
      RoutineBlock(
        name: 'Deep Work',
        durationMinutes: 45,
        icon: Icons.palette,
        color: Color(0xFFE91E63),
        description: 'Main creative work',
      ),
      RoutineBlock(
        name: 'Review',
        durationMinutes: 10,
        icon: Icons.visibility,
        color: Color(0xFF2196F3),
        description: 'Step back and evaluate',
      ),
      RoutineBlock(
        name: 'Document',
        durationMinutes: 5,
        icon: Icons.camera_alt,
        color: Color(0xFF4CAF50),
        description: 'Save progress and notes',
      ),
    ],
  );

  /// Work sprint routine
  static const workSprint = ChainedRoutine(
    id: 'work_sprint',
    name: 'Work Sprint',
    icon: Icons.flash_on,
    color: Color(0xFFF44336),
    description: 'High-intensity work blocks',
    isDefault: true,
    blocks: [
      RoutineBlock(
        name: 'Plan Sprint',
        durationMinutes: 5,
        icon: Icons.assignment,
        color: Color(0xFF2196F3),
        description: 'Define sprint goals',
      ),
      RoutineBlock(
        name: 'Sprint 1',
        durationMinutes: 25,
        icon: Icons.code,
        color: Color(0xFF4CAF50),
        description: 'First focus block',
      ),
      RoutineBlock(
        name: 'Quick Break',
        durationMinutes: 5,
        icon: Icons.coffee,
        color: Color(0xFF795548),
      ),
      RoutineBlock(
        name: 'Sprint 2',
        durationMinutes: 25,
        icon: Icons.code,
        color: Color(0xFF4CAF50),
        description: 'Second focus block',
      ),
      RoutineBlock(
        name: 'Review',
        durationMinutes: 5,
        icon: Icons.checklist,
        color: Color(0xFFFF9800),
        description: 'Check off completed tasks',
      ),
    ],
  );

  static final List<ChainedRoutine> defaultRoutines = [
    morningRoutine,
    eveningRoutine,
    studySession,
    creativeSession,
    workSprint,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'description': description,
    'isDefault': isDefault,
  };
  factory ChainedRoutine.fromJson(Map<String, dynamic> json) {
    return ChainedRoutine(
      id: json['id'] as String,
      name: json['name'] as String,
      blocks: (json['blocks'] as List)
          .map((b) => RoutineBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      icon: MaterialIconCodec.fromCodePoint(
        json['icon'] as int,
        fallback: Icons.playlist_play,
      ),
      color: Color(json['color'] as int),
      description: json['description'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  ChainedRoutine copyWith({
    String? id,
    String? name,
    List<RoutineBlock>? blocks,
    IconData? icon,
    Color? color,
    String? description,
    bool? isDefault,
  }) {
    return ChainedRoutine(
      id: id ?? this.id,
      name: name ?? this.name,
      blocks: blocks ?? this.blocks,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// State of the chained routine runner
enum RoutineState { idle, running, paused, betweenBlocks, completed }

/// Manages running chained routines
/// PERFORMANCE: Uses cached SharedPreferences and debounced saves
class ChainedRoutineService extends ChangeNotifier {
  ChainedRoutineService._();

  static final _instance = ChainedRoutineService._();
  static ChainedRoutineService get instance => _instance;

  // Routine state
  ChainedRoutine? _currentRoutine;
  var _currentBlockIndex = 0;
  RoutineState _state = RoutineState.idle;
  Duration _remainingTime = Duration.zero;
  Timer? _timer;

  // User-created routines
  final List<ChainedRoutine> _customRoutines = [];

  // Notifications
  FlutterLocalNotificationsPlugin? _notifications;
  var _initialized = false;
  var _soundEnabled = true;

  // PERFORMANCE: Cache SharedPreferences instance
  SharedPreferences? _prefs;
  Timer? _saveRoutinesDebounce;
  Timer? _saveSettingsDebounce;
  static const _debounceDelay = Duration(milliseconds: 500);

  static const _routinesKey = 'custom_routines';
  static const _settingsKey = 'routine_settings';

  // Getters
  ChainedRoutine? get currentRoutine => _currentRoutine;
  int get currentBlockIndex => _currentBlockIndex;
  RoutineState get state => _state;
  Duration get remainingTime => _remainingTime;
  bool get isRunning => _state == RoutineState.running;
  bool get isPaused => _state == RoutineState.paused;
  bool get isIdle => _state == RoutineState.idle;
  bool get isCompleted => _state == RoutineState.completed;
  bool get soundEnabled => _soundEnabled;

  RoutineBlock? get currentBlock {
    if (_currentRoutine == null ||
        _currentBlockIndex >= _currentRoutine!.blocks.length) {
      return null;
    }
    return _currentRoutine!.blocks[_currentBlockIndex];
  }

  int get totalBlocks => _currentRoutine?.blocks.length ?? 0;
  int get completedBlocks => _currentBlockIndex;
  int get remainingBlocks => totalBlocks - completedBlocks;

  double get blockProgress {
    final block = currentBlock;
    if (block == null) return 0;
    return 1.0 - (_remainingTime.inSeconds / block.duration.inSeconds);
  }

  double get overallProgress {
    if (_currentRoutine == null) return 0;
    final completed = _currentBlockIndex / totalBlocks;
    final current = (1 / totalBlocks) * blockProgress;
    return (completed + current).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  List<ChainedRoutine> get allRoutines => [
    ...ChainedRoutine.defaultRoutines,
    ..._customRoutines,
  ];

  List<ChainedRoutine> get customRoutines => List.unmodifiable(_customRoutines);

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    // PERFORMANCE: Pre-cache SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Only initialize notifications on supported platforms
    if (Platform.isAndroid || Platform.isIOS) {
      _notifications = FlutterLocalNotificationsPlugin();
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      try {
        await _notifications?.initialize(initSettings);
      } catch (e) {
        debugPrint(
          'Failed to initialize notifications for ChainedRoutineService: $e',
        );
      }
    }

    await _loadRoutines();
    await _loadSettings();
    _initialized = true;
  }

  /// Start a routine
  void startRoutine(ChainedRoutine routine) {
    _currentRoutine = routine;
    _currentBlockIndex = 0;
    _state = RoutineState.running;
    _remainingTime = routine.blocks.first.duration;
    _startTimer();
    notifyListeners();

    _showNotification(
      title: '${routine.name} Started',
      body:
          'First: ${routine.blocks.first.name} (${routine.blocks.first.durationMinutes} min)',
    );
  }

  /// Pause the routine
  void pause() {
    if (_state == RoutineState.running) {
      _timer?.cancel();
      _state = RoutineState.paused;
      notifyListeners();
    }
  }

  /// Resume the routine
  void resume() {
    if (_state == RoutineState.paused) {
      _state = RoutineState.running;
      _startTimer();
      notifyListeners();
    }
  }

  /// Stop the routine
  void stop() {
    _timer?.cancel();
    _currentRoutine = null;
    _currentBlockIndex = 0;
    _state = RoutineState.idle;
    _remainingTime = Duration.zero;
    notifyListeners();
  }

  /// Skip to next block
  void skipBlock() {
    _timer?.cancel();
    _advanceToNextBlock();
  }

  /// Add extra time to current block
  void addTime(Duration extra) {
    _remainingTime += extra;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingTime.inSeconds <= 0) {
        _onBlockComplete();
        return;
      }
      _remainingTime -= const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _onBlockComplete() {
    _timer?.cancel();
    final block = currentBlock;
    if (block != null) {
      _showNotification(
        title: '${block.name} Complete!',
        body: _currentBlockIndex < totalBlocks - 1
            ? 'Next: ${_currentRoutine!.blocks[_currentBlockIndex + 1].name}'
            : 'Routine complete!',
      );
    }
    _advanceToNextBlock();
  }

  void _advanceToNextBlock() {
    _currentBlockIndex++;
    if (_currentBlockIndex >= totalBlocks) {
      _state = RoutineState.completed;
      _showNotification(
        title: '${_currentRoutine!.name} Complete! 🎉',
        body: 'Great job! You completed all $totalBlocks blocks.',
      );
      notifyListeners();
      return;
    }

    _remainingTime = _currentRoutine!.blocks[_currentBlockIndex].duration;
    _state = RoutineState.running;
    _startTimer();
    notifyListeners();
  }

  // Custom routine management
  void addCustomRoutine(ChainedRoutine routine) {
    _customRoutines.add(routine);
    _saveRoutines();
    notifyListeners();
  }

  void updateCustomRoutine(String id, ChainedRoutine updated) {
    final index = _customRoutines.indexWhere((r) => r.id == id);
    if (index != -1) {
      _customRoutines[index] = updated;
      _saveRoutines();
      notifyListeners();
    }
  }

  void deleteCustomRoutine(String id) {
    _customRoutines.removeWhere((r) => r.id == id);
    _saveRoutines();
    notifyListeners();
  }

  // Settings
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  // Notifications
  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    if (!_soundEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      'chained_routines',
      'Chained Routines',
      channelDescription: 'Notifications for chained routine blocks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notifications?.show(2, title, body, details);
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  // Persistence
  Future<void> _loadRoutines() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final json = prefs.getString(_routinesKey);
      if (json != null) {
        // PERFORMANCE: Offload JSON parsing to isolate
        final list = await compute(_parseJsonList, json);
        _customRoutines.clear();
        for (final item in list) {
          _customRoutines.add(
            ChainedRoutine.fromJson(item as Map<String, dynamic>),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load custom routines: $e');
    }
  }

  static List<dynamic> _parseJsonList(String json) => jsonDecode(json) as List;

  void _saveRoutines() {
    // PERFORMANCE: Debounce saves
    _saveRoutinesDebounce?.cancel();
    _saveRoutinesDebounce = Timer(_debounceDelay, () async {
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        final list = _customRoutines.map((r) => r.toJson()).toList();
        await prefs.setString(_routinesKey, jsonEncode(list));
      } catch (e) {
        debugPrint('Failed to save custom routines: $e');
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      final json = prefs.getString(_settingsKey);
      if (json != null) {
        final settings = jsonDecode(json) as Map<String, dynamic>;
        _soundEnabled = settings['soundEnabled'] as bool? ?? true;
      }
    } catch (e) {
      debugPrint('Failed to load routine settings: $e');
    }
  }

  void _saveSettings() {
    // PERFORMANCE: Debounce saves
    _saveSettingsDebounce?.cancel();
    _saveSettingsDebounce = Timer(_debounceDelay, () async {
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        _prefs = prefs;
        await prefs.setString(
          _settingsKey,
          jsonEncode({'soundEnabled': _soundEnabled}),
        );
      } catch (e) {
        debugPrint('Failed to save routine settings: $e');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveRoutinesDebounce?.cancel();
    _saveSettingsDebounce?.cancel();
    super.dispose();
  }
}
