import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Types of timer sessions
enum SessionType {
  focus('Focus', Icons.psychology, Color(0xFF4CAF50)),
  deepWork('Deep Work', Icons.work, Color(0xFF2196F3)),
  sprint('Sprint', Icons.flash_on, Color(0xFFFF9800)),
  meeting('Meeting', Icons.groups, Color(0xFF9C27B0)),
  study('Study', Icons.school, Color(0xFF00BCD4)),
  workout('Workout', Icons.fitness_center, Color(0xFFE91E63)),
  custom('Custom', Icons.tune, Color(0xFF607D8B));

  const SessionType(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

/// Timer state
enum TimerState { idle, running, paused, breakTime, completed }

/// Preset timer templates
class TimerTemplate {
  const TimerTemplate({
    required this.name,
    required this.workMinutes,
    required this.breakMinutes,
    required this.cycles,
    this.longBreakMinutes,
    this.longBreakAfterCycles,
  });

  final String name;
  final int workMinutes;
  final int breakMinutes;
  final int cycles;
  final int? longBreakMinutes;
  final int? longBreakAfterCycles;

  static const pomodoro = TimerTemplate(
    name: 'Pomodoro',
    workMinutes: 25,
    breakMinutes: 5,
    cycles: 4,
    longBreakMinutes: 15,
    longBreakAfterCycles: 4,
  );

  static const ultraFocus = TimerTemplate(
    name: '52/17 Method',
    workMinutes: 52,
    breakMinutes: 17,
    cycles: 3,
  );

  static const ultradian = TimerTemplate(
    name: 'Ultradian (90 min)',
    workMinutes: 90,
    breakMinutes: 20,
    cycles: 2,
  );

  static const examPrep = TimerTemplate(
    name: 'Exam Prep',
    workMinutes: 50,
    breakMinutes: 10,
    cycles: 4,
    longBreakMinutes: 20,
    longBreakAfterCycles: 2,
  );

  static const quickSprint = TimerTemplate(
    name: 'Quick Sprint',
    workMinutes: 15,
    breakMinutes: 3,
    cycles: 6,
  );

  static const allTemplates = [
    pomodoro,
    ultraFocus,
    ultradian,
    examPrep,
    quickSprint,
  ];
}

/// Session statistics
class SessionStats {
  SessionStats({
    this.totalFocusMinutes = 0,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.todayFocusMinutes = 0,
    this.todaySessions = 0,
    DateTime? lastSessionDate,
    Map<String, int>? dailyMinutes,
    Map<String, int>? sessionsByType,
  }) : lastSessionDate = lastSessionDate ?? DateTime.now(),
       dailyMinutes = dailyMinutes ?? {},
       sessionsByType = sessionsByType ?? {};

  int totalFocusMinutes;
  int totalSessions;
  int completedSessions;
  int currentStreak;
  int longestStreak;
  int todayFocusMinutes;
  int todaySessions;
  DateTime lastSessionDate;
  Map<String, int> dailyMinutes; // YYYY-MM-DD -> minutes
  Map<String, int> sessionsByType; // SessionType.name -> count

  double get averageSessionMinutes =>
      totalSessions > 0 ? totalFocusMinutes / totalSessions : 0;

  double get completionRate =>
      totalSessions > 0 ? completedSessions / totalSessions : 0;

  Map<String, dynamic> toJson() => {
    'totalFocusMinutes': totalFocusMinutes,
    'totalSessions': totalSessions,
    'completedSessions': completedSessions,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'todayFocusMinutes': todayFocusMinutes,
    'todaySessions': todaySessions,
    'lastSessionDate': lastSessionDate.toIso8601String(),
    'dailyMinutes': dailyMinutes,
    'sessionsByType': sessionsByType,
  };

  factory SessionStats.fromJson(Map<String, dynamic> json) {
    return SessionStats(
      totalFocusMinutes: json['totalFocusMinutes'] as int? ?? 0,
      totalSessions: json['totalSessions'] as int? ?? 0,
      completedSessions: json['completedSessions'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      todayFocusMinutes: json['todayFocusMinutes'] as int? ?? 0,
      todaySessions: json['todaySessions'] as int? ?? 0,
      lastSessionDate: json['lastSessionDate'] != null
          ? DateTime.parse(json['lastSessionDate'] as String)
          : DateTime.now(),
      dailyMinutes:
          (json['dailyMinutes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      sessionsByType:
          (json['sessionsByType'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
    );
  }
}

/// Goal configuration
class ProductivityGoal {
  const ProductivityGoal({
    this.dailyFocusMinutes = 120,
    this.dailySessions = 4,
    this.weeklyFocusMinutes = 600,
  });

  final int dailyFocusMinutes;
  final int dailySessions;
  final int weeklyFocusMinutes;

  Map<String, dynamic> toJson() => {
    'dailyFocusMinutes': dailyFocusMinutes,
    'dailySessions': dailySessions,
    'weeklyFocusMinutes': weeklyFocusMinutes,
  };

  factory ProductivityGoal.fromJson(Map<String, dynamic> json) {
    return ProductivityGoal(
      dailyFocusMinutes: json['dailyFocusMinutes'] as int? ?? 120,
      dailySessions: json['dailySessions'] as int? ?? 4,
      weeklyFocusMinutes: json['weeklyFocusMinutes'] as int? ?? 600,
    );
  }

  ProductivityGoal copyWith({
    int? dailyFocusMinutes,
    int? dailySessions,
    int? weeklyFocusMinutes,
  }) {
    return ProductivityGoal(
      dailyFocusMinutes: dailyFocusMinutes ?? this.dailyFocusMinutes,
      dailySessions: dailySessions ?? this.dailySessions,
      weeklyFocusMinutes: weeklyFocusMinutes ?? this.weeklyFocusMinutes,
    );
  }
}

/// Productivity Timer Service
/// Manages timer logic, sessions, notifications, and statistics
class ProductivityTimerService extends ChangeNotifier {
  ProductivityTimerService._();

  static final _instance = ProductivityTimerService._();
  static ProductivityTimerService get instance => _instance;

  // Timer state
  Timer? _timer;
  TimerState _state = TimerState.idle;
  SessionType _sessionType = SessionType.focus;
  var _totalDuration = const Duration(minutes: 25);
  var _remainingTime = const Duration(minutes: 25);
  var _breakDuration = const Duration(minutes: 5);
  var _currentCycle = 1;
  var _totalCycles = 4;
  TimerTemplate? _activeTemplate;

  // Statistics
  var _stats = SessionStats();
  var _goal = const ProductivityGoal();

  // Notifications
  FlutterLocalNotificationsPlugin? _notifications;
  var _notificationsInitialized = false;
  var _soundEnabled = true;
  var _showPreEndWarning = true;
  var _preEndWarningMinutes = 5;

  // Settings
  var _autoStartBreak = true;
  var _autoStartNextSession = false;
  var _microBreakIntervalMinutes = 30;
  var _microBreaksEnabled = false;

  // Persistence
  static const _statsKey = 'productivity_stats';
  static const _goalKey = 'productivity_goal';
  static const _settingsKey = 'productivity_settings';
  var _initialized = false;

  // Callbacks for UI updates
  VoidCallback? onSessionComplete;
  VoidCallback? onBreakComplete;
  VoidCallback? onTimerTick;

  // Getters
  TimerState get state => _state;
  SessionType get sessionType => _sessionType;
  Duration get totalDuration => _totalDuration;
  Duration get remainingTime => _remainingTime;
  Duration get breakDuration => _breakDuration;
  int get currentCycle => _currentCycle;
  int get totalCycles => _totalCycles;
  TimerTemplate? get activeTemplate => _activeTemplate;
  SessionStats get stats => _stats;
  ProductivityGoal get goal => _goal;
  bool get soundEnabled => _soundEnabled;
  bool get showPreEndWarning => _showPreEndWarning;
  int get preEndWarningMinutes => _preEndWarningMinutes;
  bool get autoStartBreak => _autoStartBreak;
  bool get autoStartNextSession => _autoStartNextSession;
  bool get microBreaksEnabled => _microBreaksEnabled;
  int get microBreakIntervalMinutes => _microBreakIntervalMinutes;
  bool get initialized => _initialized;

  double get progress {
    if (_totalDuration.inSeconds == 0) return 0;
    return 1.0 - (_remainingTime.inSeconds / _totalDuration.inSeconds);
  }

  String get formattedTime {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isBreak => _state == TimerState.breakTime;
  bool get isIdle => _state == TimerState.idle;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadStats();
    await _loadSettings();
    await _initializeNotifications();

    _checkDayReset();
    _initialized = true;
  }

  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications?.initialize(initSettings);
      _notificationsInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  /// Show notification
  Future<void> _showNotification({
    required String title,
    required String body,
    bool playSound = true,
  }) async {
    if (!_notificationsInitialized || !_soundEnabled && playSound) return;

    final androidDetails = AndroidNotificationDetails(
      'productivity_timer',
      'Productivity Timer',
      channelDescription: 'Notifications for productivity timer',
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound && _soundEnabled,
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notifications?.show(0, title, body, details);
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Check if we need to reset daily stats
  void _checkDayReset() {
    final today = DateTime.now();
    final lastDate = _stats.lastSessionDate;

    if (today.year != lastDate.year ||
        today.month != lastDate.month ||
        today.day != lastDate.day) {
      // New day - check streak
      final difference = today.difference(lastDate).inDays;
      if (difference > 1) {
        _stats.currentStreak = 0;
      }
      _stats.todayFocusMinutes = 0;
      _stats.todaySessions = 0;
      _stats.lastSessionDate = today;
      _saveStats();
    }
  }

  // ============================================================
  // Timer Controls
  // ============================================================

  /// Start a new session
  void startSession({
    SessionType? type,
    Duration? duration,
    TimerTemplate? template,
  }) {
    _sessionType = type ?? _sessionType;

    if (template != null) {
      _activeTemplate = template;
      _totalDuration = Duration(minutes: template.workMinutes);
      _breakDuration = Duration(minutes: template.breakMinutes);
      _totalCycles = template.cycles;
      _currentCycle = 1;
    } else if (duration != null) {
      _totalDuration = duration;
      _activeTemplate = null;
    }

    _remainingTime = _totalDuration;
    _state = TimerState.running;

    _startTimer();
    notifyListeners();

    _showNotification(
      title: '${_sessionType.label} Started',
      body: 'Focus time: ${_totalDuration.inMinutes} minutes',
    );
  }

  /// Start the internal timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  /// Timer tick handler
  void _onTick(Timer timer) {
    if (_remainingTime.inSeconds <= 0) {
      _onTimerComplete();
      return;
    }

    _remainingTime -= const Duration(seconds: 1);

    // Check for pre-end warning
    if (_showPreEndWarning &&
        _remainingTime.inMinutes == _preEndWarningMinutes &&
        _remainingTime.inSeconds % 60 == 0) {
      _showNotification(
        title: '$_preEndWarningMinutes minutes left',
        body: _state == TimerState.breakTime
            ? 'Break ending soon'
            : 'Session ending soon',
      );
    }

    onTimerTick?.call();
    notifyListeners();
  }

  /// Handle timer completion
  void _onTimerComplete() {
    _timer?.cancel();

    if (_state == TimerState.breakTime) {
      // Break completed
      _showNotification(
        title: 'Break Complete!',
        body: 'Ready for the next session?',
      );
      onBreakComplete?.call();

      if (_currentCycle < _totalCycles) {
        _currentCycle++;
        if (_autoStartNextSession) {
          _startNextWorkSession();
        } else {
          _state = TimerState.idle;
        }
      } else {
        // All cycles completed
        _state = TimerState.completed;
        _showNotification(
          title: 'All Sessions Complete! 🎉',
          body: 'Great job! You completed $_totalCycles sessions.',
        );
      }
    } else {
      // Work session completed
      _recordSession();
      _showNotification(title: 'Session Complete!', body: 'Time for a break!');
      onSessionComplete?.call();

      if (_autoStartBreak) {
        _startBreak();
      } else {
        _state = TimerState.idle;
      }
    }

    notifyListeners();
  }

  /// Start break time
  void _startBreak() {
    // Check for long break
    if (_activeTemplate?.longBreakAfterCycles != null &&
        _currentCycle % _activeTemplate!.longBreakAfterCycles! == 0 &&
        _activeTemplate!.longBreakMinutes != null) {
      _totalDuration = Duration(minutes: _activeTemplate!.longBreakMinutes!);
    } else {
      _totalDuration = _breakDuration;
    }

    _remainingTime = _totalDuration;
    _state = TimerState.breakTime;
    _startTimer();
    notifyListeners();
  }

  /// Start next work session
  void _startNextWorkSession() {
    _totalDuration = _activeTemplate != null
        ? Duration(minutes: _activeTemplate!.workMinutes)
        : _totalDuration;
    _remainingTime = _totalDuration;
    _state = TimerState.running;
    _startTimer();
    notifyListeners();
  }

  /// Pause the timer
  void pause() {
    if (_state == TimerState.running || _state == TimerState.breakTime) {
      _timer?.cancel();
      _state = TimerState.paused;
      notifyListeners();
    }
  }

  /// Resume the timer
  void resume() {
    if (_state == TimerState.paused) {
      _state = _remainingTime == _breakDuration
          ? TimerState.breakTime
          : TimerState.running;
      _startTimer();
      notifyListeners();
    }
  }

  /// Stop/reset the timer
  void stop() {
    _timer?.cancel();
    _state = TimerState.idle;
    _remainingTime = _totalDuration;
    _currentCycle = 1;
    notifyListeners();
  }

  /// Skip current phase (work or break)
  void skip() {
    _timer?.cancel();
    if (_state == TimerState.breakTime) {
      if (_currentCycle < _totalCycles) {
        _currentCycle++;
        _startNextWorkSession();
      } else {
        _state = TimerState.completed;
      }
    } else {
      _startBreak();
    }
    notifyListeners();
  }

  /// Add extra time
  void addTime(Duration extra) {
    _remainingTime += extra;
    _totalDuration += extra;
    notifyListeners();
  }

  // ============================================================
  // Statistics
  // ============================================================

  /// Record completed session
  void _recordSession() {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final focusMinutes = _totalDuration.inMinutes;

    _stats.totalFocusMinutes += focusMinutes;
    _stats.totalSessions++;
    _stats.completedSessions++;
    _stats.todayFocusMinutes += focusMinutes;
    _stats.todaySessions++;
    _stats.lastSessionDate = now;

    // Update daily minutes
    _stats.dailyMinutes[dateKey] =
        (_stats.dailyMinutes[dateKey] ?? 0) + focusMinutes;

    // Update session type count
    final typeKey = _sessionType.name;
    _stats.sessionsByType[typeKey] = (_stats.sessionsByType[typeKey] ?? 0) + 1;

    // Update streak
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (_stats.dailyMinutes.containsKey(yesterdayKey) ||
        _stats.currentStreak == 0) {
      _stats.currentStreak++;
      if (_stats.currentStreak > _stats.longestStreak) {
        _stats.longestStreak = _stats.currentStreak;
      }
    }

    _saveStats();
  }

  /// Get weekly focus minutes
  int getWeeklyFocusMinutes() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    var total = 0;

    for (var i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      total += _stats.dailyMinutes[key] ?? 0;
    }

    return total;
  }

  /// Get daily progress (0.0 - 1.0)
  double getDailyProgress() {
    if (_goal.dailyFocusMinutes == 0) return 0;
    return (_stats.todayFocusMinutes / _goal.dailyFocusMinutes).clamp(0.0, 1.0);
  }

  /// Get weekly progress (0.0 - 1.0)
  double getWeeklyProgress() {
    if (_goal.weeklyFocusMinutes == 0) return 0;
    return (getWeeklyFocusMinutes() / _goal.weeklyFocusMinutes).clamp(0.0, 1.0);
  }

  // ============================================================
  // Settings
  // ============================================================

  void setSessionType(SessionType type) {
    _sessionType = type;
    notifyListeners();
  }

  void setDuration(Duration duration) {
    if (_state == TimerState.idle) {
      _totalDuration = duration;
      _remainingTime = duration;
      notifyListeners();
    }
  }

  void setBreakDuration(Duration duration) {
    _breakDuration = duration;
    notifyListeners();
    _saveSettings();
  }

  void setCycles(int cycles) {
    _totalCycles = cycles;
    notifyListeners();
    _saveSettings();
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
    _saveSettings();
  }

  void setPreEndWarning(bool enabled, {int? minutes}) {
    _showPreEndWarning = enabled;
    if (minutes != null) _preEndWarningMinutes = minutes;
    notifyListeners();
    _saveSettings();
  }

  void setAutoStartBreak(bool enabled) {
    _autoStartBreak = enabled;
    notifyListeners();
    _saveSettings();
  }

  void setAutoStartNextSession(bool enabled) {
    _autoStartNextSession = enabled;
    notifyListeners();
    _saveSettings();
  }

  void setMicroBreaks(bool enabled, {int? intervalMinutes}) {
    _microBreaksEnabled = enabled;
    if (intervalMinutes != null) _microBreakIntervalMinutes = intervalMinutes;
    notifyListeners();
    _saveSettings();
  }

  void setGoal(ProductivityGoal goal) {
    _goal = goal;
    notifyListeners();
    _saveGoal();
  }

  // ============================================================
  // Persistence
  // ============================================================

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_statsKey);
      if (json != null) {
        _stats = SessionStats.fromJson(
          jsonDecode(json) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Failed to load stats: $e');
    }
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
    } catch (e) {
      debugPrint('Failed to save stats: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load goal
      final goalJson = prefs.getString(_goalKey);
      if (goalJson != null) {
        _goal = ProductivityGoal.fromJson(
          jsonDecode(goalJson) as Map<String, dynamic>,
        );
      }

      // Load settings
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
        _soundEnabled = settings['soundEnabled'] as bool? ?? true;
        _showPreEndWarning = settings['showPreEndWarning'] as bool? ?? true;
        _preEndWarningMinutes = settings['preEndWarningMinutes'] as int? ?? 5;
        _autoStartBreak = settings['autoStartBreak'] as bool? ?? true;
        _autoStartNextSession =
            settings['autoStartNextSession'] as bool? ?? false;
        _microBreaksEnabled = settings['microBreaksEnabled'] as bool? ?? false;
        _microBreakIntervalMinutes =
            settings['microBreakIntervalMinutes'] as int? ?? 30;
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _settingsKey,
        jsonEncode({
          'soundEnabled': _soundEnabled,
          'showPreEndWarning': _showPreEndWarning,
          'preEndWarningMinutes': _preEndWarningMinutes,
          'autoStartBreak': _autoStartBreak,
          'autoStartNextSession': _autoStartNextSession,
          'microBreaksEnabled': _microBreaksEnabled,
          'microBreakIntervalMinutes': _microBreakIntervalMinutes,
        }),
      );
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  Future<void> _saveGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_goalKey, jsonEncode(_goal.toJson()));
    } catch (e) {
      debugPrint('Failed to save goal: $e');
    }
  }

  /// Reset all statistics
  Future<void> resetStats() async {
    _stats = SessionStats();
    await _saveStats();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
