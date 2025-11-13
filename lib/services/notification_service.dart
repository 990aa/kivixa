import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kivixa/data/calendar_storage.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/data/notification_settings_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _notifications = FlutterLocalNotificationsPlugin();

  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

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
      case 'complete_task':
        if (parts.length > 1) {
          final eventId = parts[1];
          _completeTask(eventId);
        }
    }
  }

  static Future<void> _completeTask(String eventId) async {
    final events = await CalendarStorage.loadEvents();
    final event = events.firstWhere((e) => e.id == eventId);
    final updated = event.copyWith(isCompleted: true);
    await CalendarStorage.updateEvent(updated);
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

    if (event.isAllDay) {
      // Schedule for 9 AM on the day
      await _scheduleNotification(
        id: event.id.hashCode,
        title: event.type == EventType.event
            ? 'Event: ${event.title}'
            : 'Task: ${event.title}',
        body: event.description ?? '',
        scheduledDate: DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
          9,
          0,
        ),
        payload: event.meetingLink != null
            ? 'open_link|${event.meetingLink}'
            : (event.type == EventType.task
                  ? 'complete_task|${event.id}'
                  : null),
        actions: _buildNotificationActions(event),
      );
    } else {
      // Schedule for exact start time
      final scheduledDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        event.startTime!.hour,
        event.startTime!.minute,
      );

      await _scheduleNotification(
        id: event.id.hashCode,
        title: event.type == EventType.event
            ? 'Event: ${event.title}'
            : 'Task: ${event.title}',
        body: event.description ?? '',
        scheduledDate: scheduledDate,
        payload: event.meetingLink != null
            ? 'open_link|${event.meetingLink}'
            : (event.type == EventType.task
                  ? 'complete_task|${event.id}'
                  : null),
        actions: _buildNotificationActions(event),
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
    );

    // Schedule daily reminder at 9 AM until completed
    await _scheduleDailyOverdueReminder(event, overdueDate);
  }

  Future<void> _scheduleDailyOverdueReminder(
    CalendarEvent event,
    DateTime overdueDate,
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
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    List<AndroidNotificationAction>? actions,
  }) async {
    // Don't schedule notifications in the past
    if (scheduledDate.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'calendar_notifications',
      'Calendar Notifications',
      channelDescription: 'Notifications for calendar events and tasks',
      importance: Importance.high,
      priority: Priority.high,
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelEventNotifications(CalendarEvent event) async {
    await cancelNotification(event.id.hashCode);

    // Cancel overdue notifications
    for (int i = 1; i <= 7; i++) {
      await cancelNotification('${event.id}_overdue_$i'.hashCode);
      await cancelNotification('${event.id}_overdue_day_$i'.hashCode);
    }
  }

  Future<void> rescheduleAllNotifications() async {
    final events = await CalendarStorage.loadEvents();
    final now = DateTime.now();

    for (final event in events) {
      // Only schedule future events/tasks
      final eventDateTime = event.isAllDay
          ? DateTime(event.date.year, event.date.month, event.date.day, 9, 0)
          : DateTime(
              event.date.year,
              event.date.month,
              event.date.day,
              event.startTime?.hour ?? 9,
              event.startTime?.minute ?? 0,
            );

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
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
