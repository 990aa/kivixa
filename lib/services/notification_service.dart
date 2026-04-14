import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/models/project.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:kivixa/data/project_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _defaultNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const _legacyLeadTimesInMinutes = <int>[
    5,
    10,
    15,
    30,
    60,
    120,
    1440,
    2880,
  ];

  @visibleForTesting
  FlutterLocalNotificationsPlugin? notificationsPluginOverride;

  FlutterLocalNotificationsPlugin get _notifications =>
      notificationsPluginOverride ?? _defaultNotificationsPlugin;

  var _initialized = false;

  @visibleForTesting
  void resetForTesting() {
    _initialized = false;
    notificationsPluginOverride = null;
  }

  @visibleForTesting
  static bool? forceIsSupported;

  /// Returns true if notifications are supported on the current platform
  static bool get isSupported =>
      forceIsSupported ?? (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized) return;

    // Notifications are only supported on mobile platforms
    if (!isSupported) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _handleBackgroundNotificationResponse,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    _processNotificationAction(response);
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(
    NotificationResponse response,
  ) {
    _processNotificationAction(response);
  }

  static void _processNotificationAction(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    final parts = payload.split('|');
    if (parts.isEmpty) return;

    final action = parts[0];

    switch (action) {
      case 'open_link':
        if (parts.length > 1) {
          final url = parts[1];
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        break;
      case 'complete_task':
        if (parts.length > 1) {
          final eventId = parts[1];
          _completeTask(eventId);
        }
        break;
    }
  }

  static Future<void> _completeTask(String eventId) async {
    final events = await CalendarStorage.loadEvents();
    final index = events.indexWhere((e) => e.id == eventId);
    if (index == -1) {
      return;
    }
    final event = events[index];
    final updated = event.copyWith(isCompleted: true);
    await CalendarStorage.updateEvent(updated);
  }

  DateTime _resolveEventNotificationDate(
    CalendarEvent event,
    NotificationSettings settings,
  ) {
    if (!settings.exactTimeNotificationsEnabled || event.isAllDay) {
      return DateTime(event.date.year, event.date.month, event.date.day, 9, 0);
    }

    final eventTime = event.type == EventType.task
        ? (event.endTime ?? event.startTime)
        : event.startTime;

    return DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      eventTime?.hour ?? 9,
      eventTime?.minute ?? 0,
    );
  }

  String _formatLeadTime(int leadMinutes) {
    if (leadMinutes % 1440 == 0) {
      final days = leadMinutes ~/ 1440;
      return days == 1 ? 'in 1 day' : 'in $days days';
    }
    if (leadMinutes % 60 == 0) {
      final hours = leadMinutes ~/ 60;
      return hours == 1 ? 'in 1 hour' : 'in $hours hours';
    }
    return 'in $leadMinutes minutes';
  }

  String _channelIdForSettings(
    String channelPrefix,
    NotificationSettings settings,
  ) {
    final vibrationMode = settings.vibrateOnlyOnAndroid
        ? 'vibrate_only'
        : 'normal';
    return '${channelPrefix}_${settings.soundProfile.storageKey}_$vibrationMode';
  }

  bool _shouldPlaySound(NotificationSettings settings) {
    if (settings.vibrateOnlyOnAndroid) {
      return false;
    }
    return settings.soundProfile != NotificationSoundProfile.silent;
  }

  AndroidNotificationSound? _resolveAndroidSound(
    NotificationSettings settings,
  ) {
    if (!_shouldPlaySound(settings)) {
      return null;
    }

    switch (settings.soundProfile) {
      case NotificationSoundProfile.defaultTone:
        return null;
      case NotificationSoundProfile.alarm:
        return const UriAndroidNotificationSound(
          'content://settings/system/alarm_alert',
        );
      case NotificationSoundProfile.ringtone:
        return const UriAndroidNotificationSound(
          'content://settings/system/ringtone',
        );
      case NotificationSoundProfile.silent:
        return null;
    }
  }

  Int64List? _resolveVibrationPattern(NotificationSettings settings) {
    if (!settings.vibrateOnlyOnAndroid) {
      return null;
    }
    return Int64List.fromList([0, 280, 180, 280]);
  }

  String _eventNotificationTitle(CalendarEvent event) {
    return event.type == EventType.event
        ? 'Event: ${event.title}'
        : 'Task: ${event.title}';
  }

  String? _eventPayload(CalendarEvent event) {
    if (event.meetingLink != null) {
      return 'open_link|${event.meetingLink}';
    }
    if (event.type == EventType.task) {
      return 'complete_task|${event.id}';
    }
    return null;
  }

  int _projectDeadlineNotificationId(String projectId) {
    return 'project_${projectId}_deadline'.hashCode;
  }

  int _projectLeadNotificationId(String projectId, int leadMinutes) {
    return 'project_${projectId}_lead_$leadMinutes'.hashCode;
  }

  Future<void> scheduleEventNotification(CalendarEvent event) async {
    final settings = await NotificationSettingsStorage.loadSettings();

    if (!settings.notificationsEnabled) return;
    if (event.type == EventType.event && !settings.eventNotificationsEnabled) {
      return;
    }
    if (event.type == EventType.task && !settings.taskNotificationsEnabled) {
      return;
    }

    final scheduledDate = _resolveEventNotificationDate(event, settings);

    await _scheduleNotification(
      id: event.id.hashCode,
      title: _eventNotificationTitle(event),
      body: event.description ?? '',
      scheduledDate: scheduledDate,
      payload: _eventPayload(event),
      actions: _buildNotificationActions(event),
      settings: settings,
      channelIdPrefix: 'calendar_notifications',
      channelName: 'Calendar Notifications',
      channelDescription: 'Notifications for calendar events and tasks',
    );

    for (final leadMinutes in settings.leadTimesInMinutes) {
      final leadDate = scheduledDate.subtract(Duration(minutes: leadMinutes));
      await _scheduleNotification(
        id: '${event.id}_lead_$leadMinutes'.hashCode,
        title: event.type == EventType.task
            ? 'Task Due Soon: ${event.title}'
            : 'Upcoming Event: ${event.title}',
        body:
            'Reminder ${_formatLeadTime(leadMinutes)}${event.description == null || event.description!.isEmpty ? '' : '\n${event.description}'}',
        scheduledDate: leadDate,
        payload: _eventPayload(event),
        actions: _buildNotificationActions(event),
        settings: settings,
        channelIdPrefix: 'calendar_notifications',
        channelName: 'Calendar Notifications',
        channelDescription: 'Notifications for calendar events and tasks',
      );
    }

    // Schedule overdue notification for tasks
    if (event.type == EventType.task && !event.isCompleted) {
      await scheduleOverdueNotification(event);
    }
  }

  List<AndroidNotificationAction> _buildNotificationActions(
    CalendarEvent event,
  ) {
    final actions = <AndroidNotificationAction>[];

    if (event.meetingLink != null) {
      actions.add(
        const AndroidNotificationAction(
          'open_link',
          'Join Meeting',
          showsUserInterface: true,
        ),
      );
    }

    if (event.type == EventType.task && !event.isCompleted) {
      actions.add(
        const AndroidNotificationAction(
          'complete_task',
          'Mark Complete',
          showsUserInterface: false,
        ),
      );
    }

    return actions;
  }

  Future<void> scheduleProjectDeadlineNotification(Project project) async {
    final deadline = project.deadline;
    if (deadline == null) return;
    if (project.status == ProjectStatus.completed) return;

    final settings = await NotificationSettingsStorage.loadSettings();
    if (!settings.notificationsEnabled ||
        !settings.projectDeadlineNotificationsEnabled) {
      return;
    }

    final scheduledDate = settings.exactTimeNotificationsEnabled
        ? deadline
        : DateTime(deadline.year, deadline.month, deadline.day, 9, 0);

    await _scheduleNotification(
      id: _projectDeadlineNotificationId(project.id),
      title: 'Project Deadline: ${project.title}',
      body: project.description?.trim().isNotEmpty == true
          ? project.description!
          : 'Deadline reached for this project.',
      scheduledDate: scheduledDate,
      settings: settings,
      channelIdPrefix: 'project_notifications',
      channelName: 'Project Deadlines',
      channelDescription: 'Notifications for project deadlines and reminders',
    );

    for (final leadMinutes in settings.leadTimesInMinutes) {
      final leadDate = scheduledDate.subtract(Duration(minutes: leadMinutes));
      await _scheduleNotification(
        id: _projectLeadNotificationId(project.id, leadMinutes),
        title: 'Upcoming Deadline: ${project.title}',
        body: 'Project deadline ${_formatLeadTime(leadMinutes)}.',
        scheduledDate: leadDate,
        settings: settings,
        channelIdPrefix: 'project_notifications',
        channelName: 'Project Deadlines',
        channelDescription:
            'Notifications for project deadlines and reminders',
      );
    }
  }

  Future<void> cancelProjectDeadlineNotifications(Project project) async {
    if (!isSupported) return;

    await cancelNotification(_projectDeadlineNotificationId(project.id));

    final settings = await NotificationSettingsStorage.loadSettings();
    final leadTimes = <int>{
      ..._legacyLeadTimesInMinutes,
      ...settings.leadTimesInMinutes,
    };

    for (final leadMinutes in leadTimes) {
      await cancelNotification(
        _projectLeadNotificationId(project.id, leadMinutes),
      );
    }
  }

  Future<void> scheduleOverdueNotification(CalendarEvent event) async {
    if (event.type != EventType.task) return;
    if (event.isCompleted) return;

    final settings = await NotificationSettingsStorage.loadSettings();
    if (!settings.notificationsEnabled ||
        !settings.overdueNotificationsEnabled) {
      return;
    }

    final overdueDate = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
      event.endTime?.hour ?? 23,
      event.endTime?.minute ?? 59,
    );

    // Schedule notification 1 hour after due time
    final firstOverdueNotification = overdueDate.add(const Duration(hours: 1));

    await _scheduleNotification(
      id: '${event.id}_overdue_1'.hashCode,
      title: 'Overdue Task: ${event.title}',
      body: 'This task is now overdue. ${event.description ?? ''}',
      scheduledDate: firstOverdueNotification,
      payload: 'complete_task|${event.id}',
      actions: [
        const AndroidNotificationAction(
          'complete_task',
          'Mark Complete',
          showsUserInterface: false,
        ),
      ],
      settings: settings,
      channelIdPrefix: 'calendar_overdue',
      channelName: 'Overdue Task Notifications',
      channelDescription: 'Daily reminders for overdue tasks',
    );

    // Schedule daily reminder at 9 AM until completed
    await _scheduleDailyOverdueReminder(event, overdueDate, settings);
  }

  Future<void> _scheduleDailyOverdueReminder(
    CalendarEvent event,
    DateTime overdueDate,
    NotificationSettings settings,
  ) async {
    // Schedule for next 7 days
    for (int i = 1; i <= 7; i++) {
      final reminderDate = DateTime(
        overdueDate.year,
        overdueDate.month,
        overdueDate.day + i,
        9,
        0,
      );

      await _scheduleNotification(
        id: '${event.id}_overdue_day_$i'.hashCode,
        title: 'Overdue Task: ${event.title}',
        body: 'This task is still pending. ${event.description ?? ''}',
        scheduledDate: reminderDate,
        payload: 'complete_task|${event.id}',
        actions: [
          const AndroidNotificationAction(
            'complete_task',
            'Mark Complete',
            showsUserInterface: false,
          ),
        ],
        settings: settings,
        channelIdPrefix: 'calendar_overdue',
        channelName: 'Overdue Task Notifications',
        channelDescription: 'Daily reminders for overdue tasks',
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationSettings settings,
    required String channelIdPrefix,
    required String channelName,
    required String channelDescription,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    // Don't schedule notifications on unsupported platforms
    if (!isSupported) return;

    // Don't schedule notifications in the past
    if (scheduledDate.isBefore(DateTime.now())) return;

    final playSound = _shouldPlaySound(settings);
    final sound = _resolveAndroidSound(settings);
    final vibrationPattern = _resolveVibrationPattern(settings);

    final androidDetails = AndroidNotificationDetails(
      _channelIdForSettings(channelIdPrefix, settings),
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: playSound,
      sound: sound,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      actions: actions,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!isSupported) return;
    await _notifications.cancel(id);
  }

  Future<void> cancelEventNotifications(CalendarEvent event) async {
    if (!isSupported) return;
    await cancelNotification(event.id.hashCode);

    final settings = await NotificationSettingsStorage.loadSettings();
    final leadTimes = <int>{
      ..._legacyLeadTimesInMinutes,
      ...settings.leadTimesInMinutes,
    };

    for (final leadMinutes in leadTimes) {
      await cancelNotification('${event.id}_lead_$leadMinutes'.hashCode);
    }

    // Cancel overdue notifications
    for (int i = 1; i <= 7; i++) {
      await cancelNotification('${event.id}_overdue_$i'.hashCode);
      await cancelNotification('${event.id}_overdue_day_$i'.hashCode);
    }
  }

  Future<void> rescheduleAllNotifications() async {
    final events = await CalendarStorage.loadEvents();
    final projects = await ProjectStorage.loadProjects();
    final now = DateTime.now();
    final settings = await NotificationSettingsStorage.loadSettings();

    for (final event in events) {
      // Only schedule future events/tasks
      final eventDateTime = _resolveEventNotificationDate(event, settings);

      if (eventDateTime.isAfter(now)) {
        await scheduleEventNotification(event);
      }

      // Check for overdue tasks
      if (event.type == EventType.task && !event.isCompleted) {
        final dueDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
          event.endTime?.hour ?? 23,
          event.endTime?.minute ?? 59,
        );

        if (dueDate.isBefore(now)) {
          await scheduleOverdueNotification(event);
        }
      }
    }

    for (final project in projects) {
      await scheduleProjectDeadlineNotification(project);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!isSupported) return;
    await _notifications.cancelAll();
  }
}
