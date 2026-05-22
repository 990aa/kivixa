import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:kivixa/services/app_lifecycle_manager.dart';
import 'package:kivixa/services/notification_sound_catalog_service.dart';
import 'package:kivixa/services/productivity/chained_routine_service.dart';
import 'package:kivixa/services/productivity/multi_timer_service.dart';
import 'package:kivixa/services/productivity/timer_context_tag.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

export 'package:kivixa/services/productivity/timer_context_tag.dart';

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

class _ResolvedAndroidSound {
  const _ResolvedAndroidSound({required this.sound, required this.identity});

  final AndroidNotificationSound? sound;
  final String identity;
}

/// Productivity Timer Service
/// Manages timer logic, sessions, notifications, and statistics
class ProductivityTimerService extends ChangeNotifier {
  ProductivityTimerService._();

  static final _instance = ProductivityTimerService._();
  static ProductivityTimerService get instance => _instance;

  static const _statusNotificationId = 9001;
  static const _completionNotificationId = 9002;
  static const _actionPause = 'productivity_pause';
  static const _actionResume = 'productivity_resume';
  static const _actionStop = 'productivity_stop';
  static const _actionDismiss = 'productivity_dismiss';
  static var _timeZonesInitialized = false;

  // Timer state
  Timer? _timer;
  TimerState _state = TimerState.idle;
  SessionType _sessionType = SessionType.focus;
  var _totalDuration = const Duration(minutes: 25);
  var _remainingTime = const Duration(minutes: 25);
  Duration _workDuration = const Duration(minutes: 25);
  var _breakDuration = const Duration(minutes: 5);
  var _currentCycle = 1;
  var _totalCycles = 4;
  TimerTemplate? _activeTemplate;
  QuickPreset? _activePreset;
  DateTime? _phaseStartTime;
  DateTime? _phaseEndTime;
  var _lifecycleBound = false;

  final _defaultQuickPresets = List<QuickPreset>.from(
    QuickPreset.defaultPresets,
  );
  final List<QuickPreset> _customQuickPresets = [];

  // Context tags
  TimerContextTag? _currentContextTag;
  final List<TimerContextTag> _customTags = [];
  final Map<String, int> _tagMinutes = {}; // tagId -> total minutes

  // Statistics
  var _stats = SessionStats();
  var _goal = const ProductivityGoal();

  // Notifications
  FlutterLocalNotificationsPlugin? _notifications;
  var _notificationsInitialized = false;
  Player? _alarmPlayer;
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
  static const _tagsKey = 'productivity_tags';
  static const _tagMinutesKey = 'productivity_tag_minutes';
  static const _defaultQuickPresetsKey = 'productivity_default_quick_presets';
  static const _customQuickPresetsKey = 'productivity_custom_quick_presets';
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
  QuickPreset? get activePreset => _activePreset;
  TimerContextTag? get currentContextTag => _currentContextTag;
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

  /// Get all available context tags (default + custom)
  List<TimerContextTag> get allContextTags => [
    ...TimerContextTag.defaultTags,
    ..._customTags,
  ];

  /// Get all available quick presets (default + custom)
  List<QuickPreset> get allQuickPresets => [
    ..._defaultQuickPresets,
    ..._customQuickPresets,
  ];

  List<QuickPreset> get defaultQuickPresets =>
      List.unmodifiable(_defaultQuickPresets);
  List<QuickPreset> get customQuickPresets =>
      List.unmodifiable(_customQuickPresets);

  /// Get tag minutes statistics
  Map<String, int> get tagMinutes => Map.unmodifiable(_tagMinutes);

  /// Get minutes for a specific tag
  int getMinutesForTag(String tagId) => _tagMinutes[tagId] ?? 0;

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
  bool get _isActivePhase =>
      _state == TimerState.running || _state == TimerState.breakTime;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    await _loadStats();
    await _loadSettings();
    await _loadQuickPresets();
    await _loadTags();
    await _loadTagMinutes();
    await _initializeNotifications();

    try {
      MediaKit.ensureInitialized();
      _alarmPlayer = Player();
    } catch (e) {
      debugPrint('Failed to initialize alarm player: $e');
    }

    if (!_lifecycleBound) {
      AppLifecycleManager.instance.addResumeListener(_handleAppResume);
      _lifecycleBound = true;
    }

    _workDuration = _totalDuration;

    _checkDayReset();
    _initialized = true;
  }

  /// Initialize notifications
  Future<void> _initializeNotifications() async {
    // Skip notifications on unsupported platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      _notificationsInitialized = false;
      return;
    }

    _notifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications?.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationResponse,
      );
      _notificationsInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    instance._handleNotificationResponse(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    instance._handleNotificationResponse(response);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _stopAlarmSound();
    
    if (response.actionId == _actionDismiss) {
      unawaited(_notifications?.cancel(response.id ?? _statusNotificationId));
      return;
    }

    switch (response.actionId) {
      case _actionPause:
        pause();
      case _actionResume:
        resume();
      case _actionStop:
        stop();
      default:
        break;
    }
  }

  Future<void> _playAlarmSound() async {
    if (!_soundEnabled) return;
    final settings = await NotificationSettingsStorage.loadSettings();
    if (!settings.notificationSoundEnabled) return;

    final path = await NotificationSoundCatalogService.instance
        .localPathForReminderSound(settings.reminderSoundId);
    if (path != null && File(path).existsSync()) {
      try {
        await _alarmPlayer?.open(Media(path), play: true);
        await _alarmPlayer?.setPlaylistMode(PlaylistMode.loop);
      } catch (e) {
        debugPrint('Failed to play alarm: $e');
      }
    }
  }

  void _stopAlarmSound() {
    _alarmPlayer?.stop();
  }

  /// Show notification
  Future<void> _showNotification({
    required String title,
    required String body,
    bool playSound = true,
    int? notificationId,
    bool ongoing = false,
    bool longVibrationAlert = true,
    DateTime? chronometerStart,
    bool chronometerCountDown = false,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    if (!_notificationsInitialized) return;

    final globalSettings = await NotificationSettingsStorage.loadSettings();
    final effectivePlaySound =
        playSound && _soundEnabled && _shouldPlaySound(globalSettings);
    final enableVibration = _shouldVibrate(globalSettings);
    final resolvedSound = await _resolveAndroidSound(
      globalSettings,
      effectivePlaySound,
    );
    final soundIdentity = resolvedSound.identity;
    final vibrationPattern = enableVibration
        ? (longVibrationAlert
              ? _longReminderVibrationPattern()
              : _shortNotificationVibrationPattern())
        : null;

    final effectiveActions = <AndroidNotificationAction>[...?actions];
    if (!ongoing &&
        !effectiveActions.any((action) => action.id == _actionDismiss)) {
      effectiveActions.add(
        const AndroidNotificationAction(
          _actionDismiss,
          'Dismiss',
          showsUserInterface: false,
        ),
      );
    }

    final androidDetails = AndroidNotificationDetails(
      _channelIdForSettings(globalSettings, soundIdentity),
      'Productivity Timer',
      channelDescription: 'Notifications for productivity timer',
      importance: Importance.high,
      priority: Priority.high,
      playSound: effectivePlaySound,
      sound: resolvedSound.sound,
      audioAttributesUsage: _resolveAudioAttributesUsage(effectivePlaySound),
      enableVibration: enableVibration,
      vibrationPattern: vibrationPattern,
      timeoutAfter: longVibrationAlert ? 60000 : null,
      ongoing: ongoing,
      autoCancel: !ongoing,
      onlyAlertOnce: true,
      showWhen: chronometerStart != null,
      when: chronometerStart?.millisecondsSinceEpoch,
      usesChronometer: chronometerStart != null,
      chronometerCountDown: chronometerCountDown,
      actions: effectiveActions,
    );

    final soundFileName = effectivePlaySound
        ? NotificationSoundCatalogService.instance
              .optionById(globalSettings.reminderSoundId)
              .fileName
        : null;

    final darwinDetails = DarwinNotificationDetails(
      sound: effectivePlaySound
          ? (soundFileName ?? 'kivixa_notification.mp3')
          : null,
      presentSound: effectivePlaySound,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notifications?.show(
        notificationId ?? DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  String _channelIdForSettings(NotificationSettings settings, String soundId) {
    return 'productivity_timer_${settings.notificationFeedbackMode.storageKey}_$soundId';
  }

  bool _shouldPlaySound(NotificationSettings settings) {
    return settings.notificationSoundEnabled;
  }

  bool _shouldVibrate(NotificationSettings settings) {
    return settings.notificationVibrationEnabled;
  }

  Future<_ResolvedAndroidSound> _resolveAndroidSound(
    NotificationSettings settings,
    bool shouldPlaySound,
  ) async {
    if (!shouldPlaySound) {
      return const _ResolvedAndroidSound(sound: null, identity: 'sound_off');
    }

    final path = await NotificationSoundCatalogService.instance
        .localPathForReminderSound(settings.reminderSoundId);
    if (path == null || path.trim().isEmpty) {
      return const _ResolvedAndroidSound(
        sound: RawResourceAndroidNotificationSound('kivixa_notification'),
        identity: 'kivixa_notification',
      );
    }
    final file = File(path);
    if (!file.existsSync()) {
      return const _ResolvedAndroidSound(
        sound: RawResourceAndroidNotificationSound('kivixa_notification'),
        identity: 'kivixa_notification',
      );
    }
    final modified = file.lastModifiedSync();
    return _ResolvedAndroidSound(
      sound: UriAndroidNotificationSound(Uri.file(path).toString()),
      identity:
          '${settings.reminderSoundId}_${modified.millisecondsSinceEpoch}',
    );
  }

  AudioAttributesUsage _resolveAudioAttributesUsage(bool playSound) {
    return playSound
        ? AudioAttributesUsage.alarm
        : AudioAttributesUsage.notification;
  }

  Int64List _shortNotificationVibrationPattern() {
    return Int64List.fromList([0, 180]);
  }

  Int64List _longReminderVibrationPattern() {
    final pattern = <int>[0];
    var elapsedMs = 0;

    while (elapsedMs < 60000) {
      final vibrate = min(450, 60000 - elapsedMs);
      pattern.add(vibrate);
      elapsedMs += vibrate;

      if (elapsedMs >= 60000) {
        break;
      }

      final pause = min(350, 60000 - elapsedMs);
      pattern.add(pause);
      elapsedMs += pause;
    }

    return Int64List.fromList(pattern);
  }

  List<AndroidNotificationAction> _buildStatusActions() {
    if (_state == TimerState.paused) {
      return const [
        AndroidNotificationAction(_actionResume, 'Resume'),
        AndroidNotificationAction(_actionStop, 'Stop'),
      ];
    }

    if (_state == TimerState.running || _state == TimerState.breakTime) {
      return const [
        AndroidNotificationAction(_actionPause, 'Pause'),
        AndroidNotificationAction(_actionStop, 'Stop'),
      ];
    }

    return const [];
  }

  String _buildProductivityContextSummary() {
    final summary = <String>['Current: ${_sessionType.label} ($formattedTime)'];

    final routineService = ChainedRoutineService.instance;
    final currentBlock = routineService.currentBlock;
    if (currentBlock != null) {
      summary.add('Subroutine: ${currentBlock.name}');
      final nextIndex = routineService.currentBlockIndex + 1;
      final routine = routineService.currentRoutine;
      if (routine != null && nextIndex < routine.blocks.length) {
        summary.add('Next: ${routine.blocks[nextIndex].name}');
      }
    }

    final parallelTimers = MultiTimerService.instance.activeCount;
    if (parallelTimers > 0) {
      summary.add('Parallel timers: $parallelTimers');
    }

    return summary.join(' | ');
  }

  Future<void> _showTimerStatusNotification() async {
    if (_state == TimerState.idle || _state == TimerState.completed) {
      await _notifications?.cancel(_statusNotificationId);
      return;
    }

    final title = switch (_state) {
      TimerState.running => 'Focus Timer Running',
      TimerState.breakTime => 'Break Timer Running',
      TimerState.paused => 'Focus Timer Paused',
      TimerState.idle => 'Focus Timer',
      TimerState.completed => 'Focus Timer Complete',
    };

    await _showNotification(
      notificationId: _statusNotificationId,
      title: title,
      body: _buildProductivityContextSummary(),
      playSound: false,
      ongoing: true,
      chronometerStart: _phaseStartTime,
      payload: 'productivity_timer_status',
      actions: _buildStatusActions(),
    );
  }

  Future<void> _ensureTimeZonesInitialized() async {
    if (_timeZonesInitialized) {
      return;
    }
    tz.initializeTimeZones();
    _timeZonesInitialized = true;
  }

  Future<void> _cancelScheduledCompletionNotification() async {
    if (!_notificationsInitialized) {
      return;
    }
    await _notifications?.cancel(_completionNotificationId);
  }

  ({String title, String body}) _completionNotificationContent() {
    if (_state == TimerState.breakTime) {
      if (_currentCycle < _totalCycles) {
        return (
          title: 'Break Complete!',
          body:
              'Ready for the next session?\n${_buildProductivityContextSummary()}',
        );
      }
      return (
        title: 'All Sessions Complete! 🎉',
        body:
            'Great job! You completed $_totalCycles sessions.\n${_buildProductivityContextSummary()}',
      );
    }

    return (
      title: 'Session Complete!',
      body: 'Time for a break!\n${_buildProductivityContextSummary()}',
    );
  }

  Future<void> _scheduleCurrentPhaseCompletionNotification() async {
    if (!_notificationsInitialized || _phaseEndTime == null) {
      return;
    }

    final scheduledTime = _phaseEndTime!;
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    await _ensureTimeZonesInitialized();

    final globalSettings = await NotificationSettingsStorage.loadSettings();
    final effectivePlaySound =
        _soundEnabled && _shouldPlaySound(globalSettings);
    final enableVibration = _shouldVibrate(globalSettings);
    final resolvedSound = await _resolveAndroidSound(
      globalSettings,
      effectivePlaySound,
    );
    final vibrationPattern = enableVibration
        ? _longReminderVibrationPattern()
        : null;

    final androidDetails = AndroidNotificationDetails(
      _channelIdForSettings(globalSettings, resolvedSound.identity),
      'Productivity Timer',
      channelDescription: 'Notifications for productivity timer',
      importance: Importance.high,
      priority: Priority.high,
      playSound: effectivePlaySound,
      sound: resolvedSound.sound,
      audioAttributesUsage: _resolveAudioAttributesUsage(effectivePlaySound),
      enableVibration: enableVibration,
      vibrationPattern: vibrationPattern,
      timeoutAfter: 60000,
      actions: const [
        AndroidNotificationAction(
          _actionDismiss,
          'Dismiss',
          showsUserInterface: false,
        ),
      ],
    );

    final soundFileName = effectivePlaySound
        ? NotificationSoundCatalogService.instance
              .optionById(globalSettings.reminderSoundId)
              .fileName
        : null;

    final darwinDetails = DarwinNotificationDetails(
      sound: effectivePlaySound
          ? (soundFileName ?? 'kivixa_notification.mp3')
          : null,
      presentSound: effectivePlaySound,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final content = _completionNotificationContent();

    try {
      await _notifications?.zonedSchedule(
        _completionNotificationId,
        content.title,
        content.body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'productivity_timer_completion',
      );
    } catch (e) {
      debugPrint('Failed to schedule completion notification: $e');
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

  void _handleAppResume() {
    if (_isActivePhase) {
      _syncWithClock();
    }
  }



  void _setPhaseTiming(DateTime startTime, Duration duration) {
    _phaseStartTime = startTime;
    _phaseEndTime = startTime.add(duration);
    _remainingTime = duration;
  }

  void _clearPhaseTiming() {
    _phaseStartTime = null;
    _phaseEndTime = null;
  }

  void _syncWithClock() {
    if (!_isActivePhase || _phaseStartTime == null) {
      return;
    }

    _cancelScheduledCompletionNotification();

    final now = DateTime.now();
    var elapsed = now.difference(_phaseStartTime!);
    if (elapsed.isNegative) {
      return;
    }

    while (_isActivePhase && elapsed >= _remainingTime) {
      elapsed -= _remainingTime;
      _onTimerComplete(silent: true);
    }

    if (_isActivePhase) {
      final remaining = _remainingTime - elapsed;
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
      final adjustedStart = now.subtract(_totalDuration - _remainingTime);
      _phaseStartTime = adjustedStart;
      _phaseEndTime = now.add(_remainingTime);
      _startTimer();
      unawaited(_showTimerStatusNotification());
      unawaited(_scheduleCurrentPhaseCompletionNotification());
    }

    notifyListeners();
  }

  // ============================================================
  // Timer Controls
  // ============================================================

  /// Start a new session
  void startSession({
    SessionType? type,
    Duration? duration,
    TimerTemplate? template,
    QuickPreset? preset,
    TimerContextTag? contextTag,
  }) {
    _sessionType = type ?? _sessionType;
    _currentContextTag = contextTag ?? _currentContextTag;

    if (preset != null) {
      _activePreset = preset;
      _activeTemplate = null;
      _totalDuration = Duration(minutes: preset.workMinutes);
      _breakDuration = Duration(minutes: preset.breakMinutes);
      _totalCycles = preset.totalCycles;
      _currentCycle = 1;
      _autoStartBreak = preset.autoStartBreak;
      _autoStartNextSession = preset.autoStartNextSession;
    } else if (template != null) {
      _activeTemplate = template;
      _activePreset = null;
      _totalDuration = Duration(minutes: template.workMinutes);
      _breakDuration = Duration(minutes: template.breakMinutes);
      _totalCycles = template.cycles;
      _currentCycle = 1;
    } else if (duration != null) {
      _totalDuration = duration;
      _activeTemplate = null;
      _activePreset = null;
    }

    _remainingTime = _totalDuration;
    _state = TimerState.running;

    _setPhaseTiming(DateTime.now(), _remainingTime);
    _startTimer();
    notifyListeners();

    final tagInfo = _currentContextTag != null
        ? ' (${_currentContextTag!.name})'
        : '';
    unawaited(
      _showNotification(
        title: '${_sessionType.label} Started$tagInfo',
        body:
            'Focus time: ${_totalDuration.inMinutes} minutes\n${_buildProductivityContextSummary()}',
      ),
    );
    unawaited(_showTimerStatusNotification());
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
      unawaited(
        _showNotification(
          title: '$_preEndWarningMinutes minutes left',
          body:
              '${_state == TimerState.breakTime ? 'Break ending soon' : 'Session ending soon'}\n${_buildProductivityContextSummary()}',
        ),
      );
    }

    onTimerTick?.call();
    notifyListeners();
  }

  /// Handle timer completion
  void _onTimerComplete({bool silent = false}) {
    _timer?.cancel();
    unawaited(_notifications?.cancel(_statusNotificationId));

    if (_state == TimerState.breakTime) {
      if (!silent) {
        unawaited(
          _showNotification(
            title: 'Break Complete!',
            body:
                'Ready for the next session?\n${_buildProductivityContextSummary()}',
            playSound: false,
          ),
        );
        _playAlarmSound();
      }
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
        _clearPhaseTiming();
        if (!silent) {
          unawaited(
            _showNotification(
              title: 'All Sessions Complete! 🎉',
              body:
                  'Great job! You completed $_totalCycles sessions.\n${_buildProductivityContextSummary()}',
              playSound: false,
            ),
          );
          _playAlarmSound();
        }
      }
    } else {
      // Work session completed
      _recordSession();
      if (!silent) {
        unawaited(
          _showNotification(
            title: 'Session Complete!',
            body: 'Time for a break!\n${_buildProductivityContextSummary()}',
            playSound: false,
          ),
        );
        _playAlarmSound();
      }
      onSessionComplete?.call();

      if (_autoStartBreak) {
        _startBreak();
      } else {
        _state = TimerState.idle;
        _clearPhaseTiming();
      }
    }

    if (!silent) {
      unawaited(_showTimerStatusNotification());
      unawaited(_scheduleCurrentPhaseCompletionNotification());
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
    _setPhaseTiming(DateTime.now(), _remainingTime);
    _startTimer();
    unawaited(_showTimerStatusNotification());
    unawaited(_scheduleCurrentPhaseCompletionNotification());
    notifyListeners();
  }

  /// Start next work session
  void _startNextWorkSession() {
    _totalDuration = _activeTemplate != null
        ? Duration(minutes: _activeTemplate!.workMinutes)
        : _totalDuration;
    _remainingTime = _totalDuration;
    _state = TimerState.running;
    _setPhaseTiming(DateTime.now(), _remainingTime);
    _startTimer();
    unawaited(_showTimerStatusNotification());
    unawaited(_scheduleCurrentPhaseCompletionNotification());
    notifyListeners();
  }

  /// Pause the timer
  void pause() {
    if (_state == TimerState.running || _state == TimerState.breakTime) {
      _timer?.cancel();
      _state = TimerState.paused;
      _clearPhaseTiming();
      unawaited(_showTimerStatusNotification());
      unawaited(_cancelScheduledCompletionNotification());
      notifyListeners();
    }
  }

  /// Resume the timer
  void resume() {
    if (_state == TimerState.paused) {
      _state = _remainingTime == _breakDuration
          ? TimerState.breakTime
          : TimerState.running;
      _setPhaseTiming(DateTime.now(), _remainingTime);
      _startTimer();
      unawaited(_showTimerStatusNotification());
      unawaited(_scheduleCurrentPhaseCompletionNotification());
      notifyListeners();
    }
  }

  /// Stop/reset the timer
  void stop() {
    _timer?.cancel();
    _state = TimerState.idle;
    _remainingTime = _totalDuration;
    _currentCycle = 1;
    _clearPhaseTiming();
    unawaited(_notifications?.cancel(_statusNotificationId));
    unawaited(_cancelScheduledCompletionNotification());
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
    unawaited(_showTimerStatusNotification());
    notifyListeners();
  }

  /// Add extra time
  void addTime(Duration extra) {
    _remainingTime += extra;
    _totalDuration += extra;
    if (_isActivePhase) {
      _setPhaseTiming(DateTime.now(), _remainingTime);
      unawaited(_showTimerStatusNotification());
      unawaited(_scheduleCurrentPhaseCompletionNotification());
    }
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

    // Update context tag minutes
    if (_currentContextTag != null) {
      _tagMinutes[_currentContextTag!.id] =
          (_tagMinutes[_currentContextTag!.id] ?? 0) + focusMinutes;
      _saveTagMinutes();
    }

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
  // Context Tags
  // ============================================================

  /// Set the current context tag
  void setContextTag(TimerContextTag? tag) {
    _currentContextTag = tag;
    notifyListeners();
  }

  /// Add a custom context tag
  void addCustomTag(TimerContextTag tag) {
    _customTags.add(tag);
    _saveTags();
    notifyListeners();
  }

  /// Remove a custom context tag
  void removeCustomTag(String tagId) {
    _customTags.removeWhere((t) => t.id == tagId);
    _saveTags();
    notifyListeners();
  }

  /// Get stats filtered by tag
  int getMinutesByTag(String tagId) {
    return _tagMinutes[tagId] ?? 0;
  }

  /// Get top tags by usage
  List<MapEntry<String, int>> getTopTags({int limit = 5}) {
    final entries = _tagMinutes.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  // ============================================================
  // Quick Presets
  // ============================================================

  void saveQuickPreset(QuickPreset preset) {
    final defaultIndex = _defaultQuickPresets.indexWhere(
      (p) => p.id == preset.id,
    );
    if (defaultIndex != -1) {
      _defaultQuickPresets[defaultIndex] = preset.copyWith(isDefault: true);
      _saveDefaultQuickPresets();
      notifyListeners();
      return;
    }

    final customIndex = _customQuickPresets.indexWhere(
      (p) => p.id == preset.id,
    );
    if (customIndex != -1) {
      _customQuickPresets[customIndex] = preset.copyWith(isDefault: false);
    } else {
      _customQuickPresets.add(preset.copyWith(isDefault: false));
    }

    _saveCustomQuickPresets();
    notifyListeners();
  }

  void deleteQuickPreset(String id) {
    final defaultBefore = _defaultQuickPresets.length;
    _defaultQuickPresets.removeWhere((p) => p.id == id);
    if (_defaultQuickPresets.length != defaultBefore) {
      _saveDefaultQuickPresets();
      notifyListeners();
      return;
    }

    final customBefore = _customQuickPresets.length;
    _customQuickPresets.removeWhere((p) => p.id == id);
    if (_customQuickPresets.length != customBefore) {
      _saveCustomQuickPresets();
      notifyListeners();
    }
  }

  void deleteAllCustomQuickPresets() {
    if (_customQuickPresets.isEmpty) {
      return;
    }
    _customQuickPresets.clear();
    _saveCustomQuickPresets();
    notifyListeners();
  }

  void restoreDefaultPresets({bool preserveCustom = true}) {
    _defaultQuickPresets
      ..clear()
      ..addAll(QuickPreset.defaultPresets);
    _saveDefaultQuickPresets();

    if (!preserveCustom) {
      _customQuickPresets.clear();
      _saveCustomQuickPresets();
    }

    notifyListeners();
  }

  /// Start a session with a quick preset
  void startWithPreset(QuickPreset preset, {TimerContextTag? contextTag}) {
    startSession(preset: preset, contextTag: contextTag);
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

  Future<void> _loadQuickPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final defaultJson = prefs.getString(_defaultQuickPresetsKey);
      if (defaultJson != null) {
        final decoded = jsonDecode(defaultJson) as List<dynamic>;
        _defaultQuickPresets
          ..clear()
          ..addAll(
            decoded
                .map(
                  (item) => QuickPreset.fromJson(item as Map<String, dynamic>),
                )
                .map((preset) => preset.copyWith(isDefault: true)),
          );
      }

      final customJson = prefs.getString(_customQuickPresetsKey);
      if (customJson != null) {
        final decoded = jsonDecode(customJson) as List<dynamic>;
        _customQuickPresets
          ..clear()
          ..addAll(
            decoded
                .map(
                  (item) => QuickPreset.fromJson(item as Map<String, dynamic>),
                )
                .map((preset) => preset.copyWith(isDefault: false)),
          );
      }
    } catch (e) {
      debugPrint('Failed to load quick presets: $e');
    }
  }

  Future<void> _saveDefaultQuickPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _defaultQuickPresets
          .map((preset) => preset.toJson())
          .toList();
      await prefs.setString(_defaultQuickPresetsKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('Failed to save default quick presets: $e');
    }
  }

  Future<void> _saveCustomQuickPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _customQuickPresets
          .map((preset) => preset.toJson())
          .toList();
      await prefs.setString(_customQuickPresetsKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('Failed to save custom quick presets: $e');
    }
  }

  Future<void> _loadTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_tagsKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _customTags.clear();
        for (final item in list) {
          _customTags.add(
            TimerContextTag.fromJson(item as Map<String, dynamic>),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load tags: $e');
    }
  }

  Future<void> _saveTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _customTags.map((t) => t.toJson()).toList();
      await prefs.setString(_tagsKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Failed to save tags: $e');
    }
  }

  Future<void> _loadTagMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_tagMinutesKey);
      if (json != null) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _tagMinutes.clear();
        map.forEach((k, v) => _tagMinutes[k] = v as int);
      }
    } catch (e) {
      debugPrint('Failed to load tag minutes: $e');
    }
  }

  Future<void> _saveTagMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tagMinutesKey, jsonEncode(_tagMinutes));
    } catch (e) {
      debugPrint('Failed to save tag minutes: $e');
    }
  }

  /// Reset all statistics
  Future<void> resetStats() async {
    _stats = SessionStats();
    _tagMinutes.clear();
    await _saveStats();
    await _saveTagMinutes();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
