import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:kivixa/data/models/project.dart';
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
      await prefs.setString(
        'notification_settings',
        NotificationSettings().toJsonString(),
      );

      await notificationService.scheduleEventNotification(event);

      expect(mockPlugin.scheduledNotifications.length, 4);
      final scheduled = mockPlugin.scheduledNotifications.first;
      expect(scheduled['title'], 'Event: Test Event');
      expect(scheduled['body'], 'Test Description');
      expect(scheduled['id'], event.id.hashCode);
    });

    test(
      'scheduleEventNotification schedules an all-day event at 9 AM',
      () async {
        final eventDate = DateTime.now().add(const Duration(days: 1));
        final event = CalendarEvent(
          id: '2',
          title: 'All Day Event',
          date: eventDate,
          type: EventType.event,
          isAllDay: true,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'notification_settings',
          NotificationSettings().toJsonString(),
        );

        await notificationService.scheduleEventNotification(event);

        expect(mockPlugin.scheduledNotifications.length, 4);
        final scheduled = mockPlugin.scheduledNotifications.first;
        expect(scheduled['title'], 'Event: All Day Event');
        final scheduledDateUtc = (scheduled['scheduledDate'] as DateTime)
            .toUtc();
        final expectedDateUtc = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
          9,
          0,
        ).toUtc();
        expect(scheduledDateUtc.hour, expectedDateUtc.hour);
        expect(scheduledDateUtc.minute, expectedDateUtc.minute);
      },
    );

    test(
      'scheduleEventNotification does not schedule if notifications are disabled',
      () async {
        final eventDate = DateTime.now().add(const Duration(days: 1));
        final event = CalendarEvent(
          id: '3',
          title: 'Disabled Event',
          date: eventDate,
          type: EventType.event,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'notification_settings',
          NotificationSettings(notificationsEnabled: false).toJsonString(),
        );

        await notificationService.scheduleEventNotification(event);

        expect(mockPlugin.scheduledNotifications.isEmpty, isTrue);
      },
    );

    test(
      'scheduleEventNotification schedules overdue notification for task',
      () async {
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
        await prefs.setString(
          'notification_settings',
          NotificationSettings().toJsonString(),
        );

        await notificationService.scheduleEventNotification(task);

        // 1 main + 3 lead reminders + 1 first overdue + 7 daily overdue reminders
        expect(mockPlugin.scheduledNotifications.length, 1 + 3 + 1 + 7);

        final firstScheduled = mockPlugin.scheduledNotifications.first;
        expect(firstScheduled['title'], 'Task: Test Task');

        final overdueScheduled = mockPlugin.scheduledNotifications.firstWhere(
          (n) => n['title'] == 'Overdue Task: Test Task',
        );
        expect(overdueScheduled, isNotNull);
      },
    );

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
      // And lead-time + overdue IDs
      expect(mockPlugin.cancelledIds.length, 23);
    });

    test(
      'rescheduleAllNotifications reads storage and schedules future events',
      () async {
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
        await prefs.setString(
          'notification_settings',
          NotificationSettings().toJsonString(),
        );
        await prefs.setString(
          'calendar_events',
          json.encode([futureEvent.toJson(), pastEvent.toJson()]),
        );

        await notificationService.rescheduleAllNotifications();

        // Should only schedule the future event
        expect(mockPlugin.scheduledNotifications.length, 4);
        expect(
          mockPlugin.scheduledNotifications.first['title'],
          'Event: Future Event',
        );
      },
    );

    test('exact-time setting disabled schedules at 9 AM', () async {
      final eventDate = DateTime.now().add(const Duration(days: 1));
      final event = CalendarEvent(
        id: 'exact-off',
        title: 'Exact Off Event',
        description: 'Will be normalized to 9 AM',
        date: eventDate,
        type: EventType.event,
        startTime: const TimeOfDay(hour: 17, minute: 30),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings',
        NotificationSettings(exactTimeNotificationsEnabled: false)
            .toJsonString(),
      );

      await notificationService.scheduleEventNotification(event);

      final scheduled = mockPlugin.scheduledNotifications.first;
      final scheduledDateUtc = (scheduled['scheduledDate'] as DateTime)
          .toUtc();
      expect(scheduledDateUtc.hour, 9);
      expect(scheduledDateUtc.minute, 0);
    });

    test('scheduleProjectDeadlineNotification schedules main and lead reminders', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings',
        NotificationSettings().toJsonString(),
      );

      final project = Project(
        id: 'project-1',
        title: 'Launch Website',
        description: 'Prepare release checklist',
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(const Duration(days: 2)),
      );

      await notificationService.scheduleProjectDeadlineNotification(project);

      expect(mockPlugin.scheduledNotifications.length, 4);
      expect(
        mockPlugin.scheduledNotifications.first['title'],
        'Project Deadline: Launch Website',
      );
    });

    test('cancelProjectDeadlineNotifications cancels known IDs', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings',
        NotificationSettings().toJsonString(),
      );

      final project = Project(
        id: 'project-2',
        title: 'Roadmap',
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(const Duration(days: 3)),
      );

      await notificationService.cancelProjectDeadlineNotifications(project);

      // main + 8 lead-time slots from cancellation compatibility set
      expect(mockPlugin.cancelledIds.length, 9);
    });
  });
}
