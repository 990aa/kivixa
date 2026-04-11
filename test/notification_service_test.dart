import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'mock/mock_flutter_local_notifications_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  late NotificationService notificationService;
  late MockFlutterLocalNotificationsPlugin mockPlugin;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    mockPlugin = MockFlutterLocalNotificationsPlugin();

    notificationService = NotificationService.instance;
    notificationService.resetForTesting();
    notificationService.notificationsPluginOverride = mockPlugin;
    NotificationService.forceIsSupported = true; // Force support for testing
  });

  tearDown(() {
    NotificationService.forceIsSupported = null;
  });

  group('NotificationService tests', () {
    test('initializes correctly', () async {
      await notificationService.initialize();
      expect(mockPlugin.initialized, isTrue);
    });

    test('scheduleEventNotification schedules an event notification', () async {
      final eventDate = DateTime.now().add(const Duration(days: 1));
      final event = CalendarEvent(
        id: '1',
        title: 'Test Event',
        description: 'Test Description',
        date: eventDate,
        type: EventType.event,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
      );

      // Save valid notification settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', NotificationSettings().toJsonString());

      await notificationService.scheduleEventNotification(event);

      expect(mockPlugin.scheduledNotifications.length, 1);
      final scheduled = mockPlugin.scheduledNotifications.first;
      expect(scheduled['title'], 'Event: Test Event');
      expect(scheduled['body'], 'Test Description');
      expect(scheduled['id'], event.id.hashCode);
    });

    test('scheduleEventNotification schedules an all-day event at 9 AM', () async {
      final eventDate = DateTime.now().add(const Duration(days: 1));
      final event = CalendarEvent(
        id: '2',
        title: 'All Day Event',
        date: eventDate,
        type: EventType.event,
        isAllDay: true,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', NotificationSettings().toJsonString());

      await notificationService.scheduleEventNotification(event);

      expect(mockPlugin.scheduledNotifications.length, 1);
      final scheduled = mockPlugin.scheduledNotifications.first;
      expect(scheduled['title'], 'Event: All Day Event');
      expect(scheduled['scheduledDate'].hour, 9);
      expect(scheduled['scheduledDate'].minute, 0);
    });

    test('scheduleEventNotification does not schedule if notifications are disabled', () async {
      final eventDate = DateTime.now().add(const Duration(days: 1));
      final event = CalendarEvent(
        id: '3',
        title: 'Disabled Event',
        date: eventDate,
        type: EventType.event,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', NotificationSettings(notificationsEnabled: false).toJsonString());

      await notificationService.scheduleEventNotification(event);

      expect(mockPlugin.scheduledNotifications.isEmpty, isTrue);
    });

    test('scheduleEventNotification schedules overdue notification for task', () async {
      final taskDate = DateTime.now().add(const Duration(days: 1));
      final task = CalendarEvent(
        id: '4',
        title: 'Test Task',
        date: taskDate,
        type: EventType.task,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        isCompleted: false,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', NotificationSettings().toJsonString());

      await notificationService.scheduleEventNotification(task);

      // Should schedule 1 for the start time, 1 for 1hr overdue, and 7 daily reminders
      expect(mockPlugin.scheduledNotifications.length, 1 + 1 + 7);

      final firstScheduled = mockPlugin.scheduledNotifications.first;
      expect(firstScheduled['title'], 'Task: Test Task');

      final overdueScheduled = mockPlugin.scheduledNotifications.firstWhere(
        (n) => n['title'] == 'Overdue Task: Test Task'
      );
      expect(overdueScheduled, isNotNull);
    });

    test('cancelNotification cancels correctly', () async {
      await notificationService.cancelNotification(123);
      expect(mockPlugin.cancelledIds, contains(123));
    });

    test('cancelAllNotifications cancels everything', () async {
      await notificationService.cancelAllNotifications();
      expect(mockPlugin.cancelAllCount, 1);
    });

    test('cancelEventNotifications cancels all associated IDs', () async {
      final event = CalendarEvent(
        id: '5',
        title: 'Cancel Me',
        date: DateTime.now().add(const Duration(days: 1)),
        type: EventType.task,
      );

      await notificationService.cancelEventNotifications(event);

      // Should cancel the main event ID
      expect(mockPlugin.cancelledIds, contains(event.id.hashCode));
      // And the 7 overdue days + 7 first overdue hours
      expect(mockPlugin.cancelledIds.length, 1 + 7 * 2);
    });

    test('rescheduleAllNotifications reads storage and schedules future events', () async {
      final now = DateTime.now();
      final futureEvent = CalendarEvent(
        id: 'future',
        title: 'Future Event',
        date: now.add(const Duration(days: 1)),
        type: EventType.event,
        startTime: const TimeOfDay(hour: 10, minute: 0),
      );

      final pastEvent = CalendarEvent(
        id: 'past',
        title: 'Past Event',
        date: now.subtract(const Duration(days: 1)),
        type: EventType.event,
        startTime: const TimeOfDay(hour: 10, minute: 0),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notification_settings', NotificationSettings().toJsonString());
      await prefs.setString('calendar_events', json.encode([futureEvent.toJson(), pastEvent.toJson()]));

      await notificationService.rescheduleAllNotifications();

      // Should only schedule the future event
      expect(mockPlugin.scheduledNotifications.length, 1);
      expect(mockPlugin.scheduledNotifications.first['title'], 'Event: Future Event');
    });
  });
}
