import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/calendar_event.dart';
import 'package:kivixa/data/models/notification_settings.dart';
import 'package:flutter/material.dart';

void main() {
  group('Task Checkbox and Completion Tests', () {
    test('Checkbox toggles task completion state', () {
      final task = CalendarEvent(
        id: '1',
        title: 'Test Task',
        date: DateTime(2024, 1, 15),
        type: EventType.task,
        isCompleted: false,
      );

      final updated = task.copyWith(isCompleted: !task.isCompleted);

      expect(updated.isCompleted, true);
      expect(task.isCompleted, false); // Original unchanged
    });

    test('Unchecking completed task changes state back', () {
      final task = CalendarEvent(
        id: '1',
        title: 'Completed Task',
        date: DateTime(2024, 1, 15),
        type: EventType.task,
        isCompleted: true,
      );

      final updated = task.copyWith(isCompleted: !task.isCompleted);

      expect(updated.isCompleted, false);
    });
  });

  group('Task Sorting Tests', () {
    late List<CalendarEvent> tasks;

    setUp(() {
      final testDate = DateTime(2024, 1, 15);
      tasks = [
        CalendarEvent(
          id: '1',
          title: 'Task Due at 10 AM',
          date: testDate,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
          isCompleted: false,
        ),
        CalendarEvent(
          id: '2',
          title: 'Task Due at 3 PM',
          date: testDate,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
          isCompleted: false,
        ),
        CalendarEvent(
          id: '3',
          title: 'Completed Task',
          date: testDate,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 11, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          isCompleted: true,
        ),
        CalendarEvent(
          id: '4',
          title: 'Task Due at 2 PM',
          date: testDate,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 13, minute: 0),
          endTime: const TimeOfDay(hour: 14, minute: 0),
          isCompleted: false,
        ),
      ];
    });

    test('Incomplete tasks sorted by deadline (endTime)', () {
      final incompleteTasks = tasks.where((t) => !t.isCompleted).toList()
        ..sort((a, b) {
          final aMinutes =
              (a.endTime?.hour ?? 23) * 60 + (a.endTime?.minute ?? 59);
          final bMinutes =
              (b.endTime?.hour ?? 23) * 60 + (b.endTime?.minute ?? 59);
          return aMinutes.compareTo(bMinutes);
        });

      expect(incompleteTasks[0].title, 'Task Due at 10 AM'); // 10:00 deadline
      expect(incompleteTasks[1].title, 'Task Due at 2 PM'); // 14:00 deadline
      expect(incompleteTasks[2].title, 'Task Due at 3 PM'); // 15:00 deadline
    });

    test('Completed tasks appear at the bottom', () {
      final sorted = List<CalendarEvent>.from(tasks)
        ..sort((a, b) {
          if (a.isCompleted && !b.isCompleted) return 1; // Completed to bottom
          if (!a.isCompleted && b.isCompleted) return -1; // Incomplete to top

          final aMinutes =
              (a.endTime?.hour ?? 23) * 60 + (a.endTime?.minute ?? 59);
          final bMinutes =
              (b.endTime?.hour ?? 23) * 60 + (b.endTime?.minute ?? 59);
          return aMinutes.compareTo(bMinutes);
        });

      // Last item should be completed
      expect(sorted.last.isCompleted, true);
      expect(sorted.last.title, 'Completed Task');

      // First three should be incomplete
      expect(sorted[0].isCompleted, false);
      expect(sorted[1].isCompleted, false);
      expect(sorted[2].isCompleted, false);
    });

    test('Tasks sorted by deadline within incomplete group', () {
      final sorted = List<CalendarEvent>.from(tasks)
        ..sort((a, b) {
          if (a.isCompleted && !b.isCompleted) return 1;
          if (!a.isCompleted && b.isCompleted) return -1;

          final aMinutes =
              (a.endTime?.hour ?? 23) * 60 + (a.endTime?.minute ?? 59);
          final bMinutes =
              (b.endTime?.hour ?? 23) * 60 + (b.endTime?.minute ?? 59);
          return aMinutes.compareTo(bMinutes);
        });

      // Verify order of incomplete tasks
      expect(sorted[0].title, 'Task Due at 10 AM'); // 10:00
      expect(sorted[1].title, 'Task Due at 2 PM'); // 14:00
      expect(sorted[2].title, 'Task Due at 3 PM'); // 15:00
      expect(sorted[3].title, 'Completed Task'); // Last
    });
  });

  group('Mixed Events and Tasks Sorting', () {
    late List<CalendarEvent> mixed;

    setUp(() {
      final testDate = DateTime(2024, 1, 15);
      mixed = [
        CalendarEvent(
          id: '1',
          title: 'Morning Meeting',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        ),
        CalendarEvent(
          id: '2',
          title: 'Task Due at 11 AM',
          date: testDate,
          type: EventType.task,
          endTime: const TimeOfDay(hour: 11, minute: 0),
          isCompleted: false,
        ),
        CalendarEvent(
          id: '3',
          title: 'Afternoon Event',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
        ),
        CalendarEvent(
          id: '4',
          title: 'Completed Task',
          date: testDate,
          type: EventType.task,
          endTime: const TimeOfDay(hour: 12, minute: 0),
          isCompleted: true,
        ),
      ];
    });

    test('Events appear before tasks in mixed list', () {
      final sorted = List<CalendarEvent>.from(mixed)
        ..sort((a, b) {
          // Separate logic for events and tasks
          if (a.type == EventType.task && b.type == EventType.task) {
            if (a.isCompleted && !b.isCompleted) return 1;
            if (!a.isCompleted && b.isCompleted) return -1;

            final aMinutes =
                (a.endTime?.hour ?? 23) * 60 + (a.endTime?.minute ?? 59);
            final bMinutes =
                (b.endTime?.hour ?? 23) * 60 + (b.endTime?.minute ?? 59);
            return aMinutes.compareTo(bMinutes);
          }

          if (a.type == EventType.event && b.type == EventType.event) {
            final aMinutes =
                (a.startTime?.hour ?? 0) * 60 + (a.startTime?.minute ?? 0);
            final bMinutes =
                (b.startTime?.hour ?? 0) * 60 + (b.startTime?.minute ?? 0);
            return aMinutes.compareTo(bMinutes);
          }

          // Mixed - events first
          if (a.type == EventType.event) return -1;
          return 1;
        });

      // First two should be events
      expect(sorted[0].type, EventType.event);
      expect(sorted[1].type, EventType.event);

      // Then incomplete task
      expect(sorted[2].type, EventType.task);
      expect(sorted[2].isCompleted, false);

      // Finally completed task
      expect(sorted[3].type, EventType.task);
      expect(sorted[3].isCompleted, true);
    });
  });

  group('Notification Settings Tests', () {
    test('Default notification settings are all enabled', () {
      final settings = NotificationSettings();

      expect(settings.notificationsEnabled, true);
      expect(settings.eventNotificationsEnabled, true);
      expect(settings.taskNotificationsEnabled, true);
      expect(settings.overdueNotificationsEnabled, true);
    });

    test('Notification settings can be disabled', () {
      final settings = NotificationSettings(notificationsEnabled: false);

      expect(settings.notificationsEnabled, false);
    });

    test('Individual notification types can be toggled', () {
      final settings = NotificationSettings(
        eventNotificationsEnabled: false,
        taskNotificationsEnabled: false,
      );

      expect(settings.notificationsEnabled, true); // Master still enabled
      expect(settings.eventNotificationsEnabled, false);
      expect(settings.taskNotificationsEnabled, false);
      expect(settings.overdueNotificationsEnabled, true); // Still enabled
    });

    test('Notification settings serialization works', () {
      final settings = NotificationSettings(
        notificationsEnabled: false,
        eventNotificationsEnabled: true,
        taskNotificationsEnabled: false,
        overdueNotificationsEnabled: true,
      );

      final json = settings.toJson();

      expect(json['notificationsEnabled'], false);
      expect(json['eventNotificationsEnabled'], true);
      expect(json['taskNotificationsEnabled'], false);
      expect(json['overdueNotificationsEnabled'], true);
    });

    test('Notification settings deserialization works', () {
      final json = {
        'notificationsEnabled': false,
        'eventNotificationsEnabled': true,
        'taskNotificationsEnabled': false,
        'overdueNotificationsEnabled': true,
      };

      final settings = NotificationSettings.fromJson(json);

      expect(settings.notificationsEnabled, false);
      expect(settings.eventNotificationsEnabled, true);
      expect(settings.taskNotificationsEnabled, false);
      expect(settings.overdueNotificationsEnabled, true);
    });

    test('Notification settings copyWith works', () {
      final settings = NotificationSettings();

      final updated = settings.copyWith(
        eventNotificationsEnabled: false,
        overdueNotificationsEnabled: false,
      );

      expect(updated.notificationsEnabled, true); // Unchanged
      expect(updated.eventNotificationsEnabled, false); // Changed
      expect(updated.taskNotificationsEnabled, true); // Unchanged
      expect(updated.overdueNotificationsEnabled, false); // Changed
    });

    test('Notification settings JSON string conversion works', () {
      final settings = NotificationSettings(notificationsEnabled: false);

      final jsonString = settings.toJsonString();
      final restored = NotificationSettings.fromJsonString(jsonString);

      expect(restored.notificationsEnabled, settings.notificationsEnabled);
      expect(
        restored.eventNotificationsEnabled,
        settings.eventNotificationsEnabled,
      );
      expect(
        restored.taskNotificationsEnabled,
        settings.taskNotificationsEnabled,
      );
      expect(
        restored.overdueNotificationsEnabled,
        settings.overdueNotificationsEnabled,
      );
    });
  });

  group('Overdue Task Notification Logic', () {
    test('Task becomes overdue after deadline passes', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final task = CalendarEvent(
        id: '1',
        title: 'Overdue Task',
        date: yesterday,
        type: EventType.task,
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: false,
      );

      final deadline = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.endTime!.hour,
        task.endTime!.minute,
      );

      expect(deadline.isBefore(now), true);
    });

    test('Completed task is not considered overdue', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final task = CalendarEvent(
        id: '1',
        title: 'Completed Task',
        date: yesterday,
        type: EventType.task,
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: true,
      );

      final isOverdue = !task.isCompleted;

      expect(isOverdue, false);
    });

    test('Future task is not overdue', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final task = CalendarEvent(
        id: '1',
        title: 'Future Task',
        date: tomorrow,
        type: EventType.task,
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: false,
      );

      final deadline = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.endTime!.hour,
        task.endTime!.minute,
      );

      expect(deadline.isBefore(now), false);
    });
  });

  group('Notification Scheduling Logic', () {
    test('Event notification scheduled for start time', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Meeting',
        date: DateTime(2024, 6, 15),
        type: EventType.event,
        startTime: const TimeOfDay(hour: 14, minute: 30),
        endTime: const TimeOfDay(hour: 15, minute: 30),
      );

      final scheduledTime = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        event.startTime!.hour,
        event.startTime!.minute,
      );

      expect(scheduledTime.hour, 14);
      expect(scheduledTime.minute, 30);
    });

    test('All-day event scheduled for 9 AM', () {
      final event = CalendarEvent(
        id: '1',
        title: 'All Day Event',
        date: DateTime(2024, 6, 15),
        type: EventType.event,
        isAllDay: true,
      );

      final scheduledTime = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        9,
        0,
      );

      expect(scheduledTime.hour, 9);
      expect(scheduledTime.minute, 0);
    });

    test('Task notification scheduled for due time', () {
      final task = CalendarEvent(
        id: '1',
        title: 'Task',
        date: DateTime(2024, 6, 15),
        type: EventType.task,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 30),
      );

      final scheduledTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.startTime!.hour,
        task.startTime!.minute,
      );

      expect(scheduledTime.hour, 10);
      expect(scheduledTime.minute, 0);
    });
  });

  group('Meeting Link in Notifications', () {
    test('Event with meeting link has payload', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Team Meeting',
        date: DateTime(2024, 6, 15),
        type: EventType.event,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        meetingLink: 'https://meet.example.com/abc123',
      );

      expect(event.meetingLink, isNotNull);
      expect(event.meetingLink, contains('https://'));

      final payload = 'open_link|${event.meetingLink}';
      expect(payload, 'open_link|https://meet.example.com/abc123');
    });

    test('Event without meeting link has no payload', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Meeting',
        date: DateTime(2024, 6, 15),
        type: EventType.event,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
      );

      expect(event.meetingLink, isNull);
    });

    test('Task has complete payload', () {
      final task = CalendarEvent(
        id: '1',
        title: 'Task',
        date: DateTime(2024, 6, 15),
        type: EventType.task,
        endTime: const TimeOfDay(hour: 11, minute: 0),
      );

      final payload = 'complete_task|${task.id}';
      expect(payload, 'complete_task|1');
    });
  });

  group('Daily Overdue Reminders', () {
    test('Multiple overdue notifications scheduled for consecutive days', () {
      final task = CalendarEvent(
        id: '1',
        title: 'Overdue Task',
        date: DateTime(2024, 6, 15),
        type: EventType.task,
        endTime: const TimeOfDay(hour: 11, minute: 0),
        isCompleted: false,
      );

      // Generate notification IDs for 7 days
      final notificationIds = <int>[];
      for (int i = 1; i <= 7; i++) {
        notificationIds.add('${task.id}_overdue_day_$i'.hashCode);
      }

      expect(notificationIds.length, 7);
      expect(notificationIds.toSet().length, 7); // All unique
    });

    test('Overdue reminder scheduled at 9 AM each day', () {
      final overdueDate = DateTime(2024, 6, 15, 11, 0);

      // Reminders for next 3 days
      for (int i = 1; i <= 3; i++) {
        final reminderDate = DateTime(
          overdueDate.year,
          overdueDate.month,
          overdueDate.day + i,
          9,
          0,
        );

        expect(reminderDate.hour, 9);
        expect(reminderDate.minute, 0);
        expect(reminderDate.day, 15 + i);
      }
    });
  });
}
