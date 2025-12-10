import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A secondary timer that runs in parallel with the main focus timer
class SecondaryTimer {
  SecondaryTimer({
    required this.id,
    required this.name,
    required this.duration,
    this.icon = Icons.timer,
    this.color = Colors.blue,
    this.message,
    this.repeat = false,
  });

  final String id;
  final String name;
  final Duration duration;
  final IconData icon;
  final Color color;
  final String? message;
  final bool repeat;

  Duration _remainingTime = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false;

  Duration get remainingTime => _remainingTime;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isCompleted => _isCompleted;
  bool get isIdle => !_isRunning && !_isPaused && !_isCompleted;

  double get progress {
    if (duration.inSeconds == 0) return 0;
    return 1.0 - (_remainingTime.inSeconds / duration.inSeconds);
  }

  String get formattedTime {
    final hours = _remainingTime.inHours;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  VoidCallback? onTick;
  VoidCallback? onComplete;

  void start() {
    _remainingTime = duration;
    _isRunning = true;
    _isPaused = false;
    _isCompleted = false;
    _startTimer();
  }

  void pause() {
    _timer?.cancel();
    _isPaused = true;
    _isRunning = false;
  }

  void resume() {
    _isPaused = false;
    _isRunning = true;
    _startTimer();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _isCompleted = false;
    _remainingTime = Duration.zero;
  }

  void reset() {
    _timer?.cancel();
    _remainingTime = duration;
    _isRunning = false;
    _isPaused = false;
    _isCompleted = false;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingTime.inSeconds <= 0) {
        _onComplete();
        return;
      }
      _remainingTime -= const Duration(seconds: 1);
      onTick?.call();
    });
  }

  void _onComplete() {
    _timer?.cancel();
    _isRunning = false;
    _isCompleted = true;
    onComplete?.call();

    if (repeat) {
      _remainingTime = duration;
      _isCompleted = false;
      _isRunning = true;
      _startTimer();
    }
  }

  void dispose() {
    _timer?.cancel();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'durationSeconds': duration.inSeconds,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'message': message,
    'repeat': repeat,
  };
  factory SecondaryTimer.fromJson(Map<String, dynamic> json) {
    return SecondaryTimer(
      id: json['id'] as String,
      name: json['name'] as String,
      duration: Duration(seconds: json['durationSeconds'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['color'] as int),
      message: json['message'] as String?,
      repeat: json['repeat'] as bool? ?? false,
    );
  }
}

/// Common secondary timer presets
class SecondaryTimerPreset {
  const SecondaryTimerPreset({
    required this.name,
    required this.duration,
    required this.icon,
    required this.color,
    this.message,
    this.repeat = false,
  });

  final String name;
  final Duration duration;
  final IconData icon;
  final Color color;
  final String? message;
  final bool repeat;

  /// Tea/Coffee timer - 5 minutes
  static const tea = SecondaryTimerPreset(
    name: 'Tea Timer',
    duration: Duration(minutes: 5),
    icon: Icons.local_cafe,
    color: Color(0xFF795548),
    message: 'Your tea is ready!',
  );

  /// Commit reminder - 30 minutes
  static const commitReminder = SecondaryTimerPreset(
    name: 'Commit Reminder',
    duration: Duration(minutes: 30),
    icon: Icons.save,
    color: Color(0xFF4CAF50),
    message: 'Time to commit your code!',
    repeat: true,
  );

  /// Stretch reminder - 45 minutes
  static const stretchReminder = SecondaryTimerPreset(
    name: 'Stretch Reminder',
    duration: Duration(minutes: 45),
    icon: Icons.accessibility,
    color: Color(0xFF2196F3),
    message: 'Time to stretch!',
    repeat: true,
  );

  /// Water reminder - 30 minutes
  static const waterReminder = SecondaryTimerPreset(
    name: 'Water Reminder',
    duration: Duration(minutes: 30),
    icon: Icons.water_drop,
    color: Color(0xFF03A9F4),
    message: 'Stay hydrated!',
    repeat: true,
  );

  /// Eye rest reminder - 20 minutes (20-20-20 rule)
  static const eyeRest = SecondaryTimerPreset(
    name: 'Eye Rest (20-20-20)',
    duration: Duration(minutes: 20),
    icon: Icons.visibility,
    color: Color(0xFF00BCD4),
    message: 'Look at something 20 feet away for 20 seconds',
    repeat: true,
  );

  /// Standup reminder - 60 minutes
  static const standUp = SecondaryTimerPreset(
    name: 'Stand Up',
    duration: Duration(minutes: 60),
    icon: Icons.directions_walk,
    color: Color(0xFFFF9800),
    message: 'Time to stand up and move!',
    repeat: true,
  );

  /// Laundry timer - 45 minutes
  static const laundry = SecondaryTimerPreset(
    name: 'Laundry',
    duration: Duration(minutes: 45),
    icon: Icons.local_laundry_service,
    color: Color(0xFF9C27B0),
    message: 'Laundry is done!',
  );

  /// Cooking timer - customizable
  static const cooking = SecondaryTimerPreset(
    name: 'Cooking Timer',
    duration: Duration(minutes: 15),
    icon: Icons.restaurant,
    color: Color(0xFFE91E63),
    message: 'Check your food!',
  );

  static const List<SecondaryTimerPreset> presets = [
    tea,
    commitReminder,
    stretchReminder,
    waterReminder,
    eyeRest,
    standUp,
    laundry,
    cooking,
  ];

  SecondaryTimer toTimer({String? customId}) {
    return SecondaryTimer(
      id:
          customId ??
          '${name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      duration: duration,
      icon: icon,
      color: color,
      message: message,
      repeat: repeat,
    );
  }
}

/// Manages multiple secondary timers
class MultiTimerService extends ChangeNotifier {
  MultiTimerService._();

  static final _instance = MultiTimerService._();
  static MultiTimerService get instance => _instance;

  final List<SecondaryTimer> _timers = [];
  FlutterLocalNotificationsPlugin? _notifications;
  var _initialized = false;

  static const _storageKey = 'secondary_timers';

  List<SecondaryTimer> get timers => List.unmodifiable(_timers);
  int get activeCount => _timers.where((t) => t.isRunning || t.isPaused).length;
  bool get hasActiveTimers => activeCount > 0;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    _notifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications?.initialize(initSettings);
    } catch (e) {
      debugPrint(
        'Failed to initialize notifications for MultiTimerService: $e',
      );
    }

    await _loadTimers();
    _initialized = true;
  }

  /// Add a new secondary timer
  void addTimer(SecondaryTimer timer) {
    timer.onTick = () => notifyListeners();
    timer.onComplete = () => _onTimerComplete(timer);
    _timers.add(timer);
    _saveTimers();
    notifyListeners();
  }

  /// Add timer from preset
  void addFromPreset(SecondaryTimerPreset preset) {
    final timer = preset.toTimer();
    addTimer(timer);
  }

  /// Remove a timer
  void removeTimer(String timerId) {
    final timer = _timers.firstWhere(
      (t) => t.id == timerId,
      orElse: () => throw Exception('Timer not found'),
    );
    timer.dispose();
    _timers.remove(timer);
    _saveTimers();
    notifyListeners();
  }

  /// Start a timer
  void startTimer(String timerId) {
    final timer = _timers.firstWhere((t) => t.id == timerId);
    timer.start();
    notifyListeners();
  }

  /// Pause a timer
  void pauseTimer(String timerId) {
    final timer = _timers.firstWhere((t) => t.id == timerId);
    timer.pause();
    notifyListeners();
  }

  /// Resume a timer
  void resumeTimer(String timerId) {
    final timer = _timers.firstWhere((t) => t.id == timerId);
    timer.resume();
    notifyListeners();
  }

  /// Stop a timer
  void stopTimer(String timerId) {
    final timer = _timers.firstWhere((t) => t.id == timerId);
    timer.stop();
    notifyListeners();
  }

  /// Reset a timer
  void resetTimer(String timerId) {
    final timer = _timers.firstWhere((t) => t.id == timerId);
    timer.reset();
    notifyListeners();
  }

  /// Stop all timers
  void stopAllTimers() {
    for (final timer in _timers) {
      timer.stop();
    }
    notifyListeners();
  }

  /// Clear all timers
  void clearAllTimers() {
    for (final timer in _timers) {
      timer.dispose();
    }
    _timers.clear();
    _saveTimers();
    notifyListeners();
  }

  void _onTimerComplete(SecondaryTimer timer) {
    _showNotification(
      title: '${timer.name} Complete!',
      body: timer.message ?? 'Timer finished',
    );
    notifyListeners();
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'secondary_timers',
      'Secondary Timers',
      channelDescription: 'Notifications for secondary timers',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      // Use timer id hash to allow multiple notifications
      await _notifications?.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> _loadTimers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        for (final item in list) {
          final timer = SecondaryTimer.fromJson(item as Map<String, dynamic>);
          timer.onTick = () => notifyListeners();
          timer.onComplete = () => _onTimerComplete(timer);
          _timers.add(timer);
        }
      }
    } catch (e) {
      debugPrint('Failed to load secondary timers: $e');
    }
  }

  Future<void> _saveTimers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _timers.map((t) => t.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Failed to save secondary timers: $e');
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.dispose();
    }
    super.dispose();
  }
}
