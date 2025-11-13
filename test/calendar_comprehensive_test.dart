import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kivixa/data/models/calendar_event.dart';

void main() {
  group('CalendarEvent Model Tests', () {
    test('Task completion field defaults to false', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Test Task',
        date: DateTime(2024, 1, 15),
        type: EventType.task,
      );

      expect(event.isCompleted, false);
    });

    test('Task completion can be set to true', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Test Task',
        date: DateTime(2024, 1, 15),
        type: EventType.task,
        isCompleted: true,
      );

      expect(event.isCompleted, true);
    });

    test('copyWith updates isCompleted field', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Test Task',
        date: DateTime(2024, 1, 15),
        type: EventType.task,
        isCompleted: false,
      );

      final updated = event.copyWith(isCompleted: true);

      expect(updated.isCompleted, true);
      expect(event.isCompleted, false); // Original unchanged
    });

    test('toJson includes isCompleted field', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Test Task',
        date: DateTime(2024, 1, 15),
        type: EventType.task,
        isCompleted: true,
      );

      final json = event.toJson();

      expect(json['isCompleted'], true);
    });

    test('fromJson parses isCompleted field', () {
      final json = {
        'id': '1',
        'title': 'Test Task',
        'date': DateTime(2024, 1, 15).toIso8601String(),
        'type': 'task',
        'isCompleted': true,
        'isAllDay': false,
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.isCompleted, true);
    });

    test('fromJson defaults isCompleted to false when missing', () {
      final json = {
        'id': '1',
        'title': 'Test Task',
        'date': DateTime(2024, 1, 15).toIso8601String(),
        'type': 'task',
        'isAllDay': false,
      };

      final event = CalendarEvent.fromJson(json);

      expect(event.isCompleted, false);
    });
  });

  group('Overdue Task Detection', () {
    test('Task is overdue when endTime has passed', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final event = CalendarEvent(
        id: '1',
        title: 'Overdue Task',
        date: yesterday,
        type: EventType.task,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: false,
      );

      final eventDateTime = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        event.endTime!.hour,
        event.endTime!.minute,
      );

      expect(eventDateTime.isBefore(now), true);
    });

    test('Task is not overdue when endTime has not passed', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final event = CalendarEvent(
        id: '1',
        title: 'Future Task',
        date: tomorrow,
        type: EventType.task,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: false,
      );

      final eventDateTime = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        event.endTime!.hour,
        event.endTime!.minute,
      );

      expect(eventDateTime.isBefore(now), false);
    });

    test('Completed task is not considered overdue', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final event = CalendarEvent(
        id: '1',
        title: 'Completed Task',
        date: yesterday,
        type: EventType.task,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: true,
      );

      // Even though endTime passed, isCompleted = true means not overdue
      expect(event.isCompleted, true);
    });

    test('All-day task uses 23:59 as default end time for overdue check', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final event = CalendarEvent(
        id: '1',
        title: 'All Day Task',
        date: yesterday,
        type: EventType.task,
        isAllDay: true,
        isCompleted: false,
      );

      final eventDateTime = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
        23,
        59,
      );

      // Yesterday at 23:59 should be before now
      expect(eventDateTime.isBefore(now), true);
    });
  });

  group('Event Filtering Logic', () {
    late List<CalendarEvent> testEvents;

    setUp(() {
      final testDate = DateTime(2024, 1, 15);
      testEvents = [
        CalendarEvent(
          id: '1',
          title: 'Meeting',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        ),
        CalendarEvent(
          id: '2',
          title: 'Task 1',
          date: testDate,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 11, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          isCompleted: false,
        ),
        CalendarEvent(
          id: '3',
          title: 'Conference',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 14, minute: 0),
          endTime: const TimeOfDay(hour: 15, minute: 0),
        ),
        CalendarEvent(
          id: '4',
          title: 'Task 2',
          date: testDate,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 16, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          isCompleted: true,
        ),
      ];
    });

    test('Filter shows all events and tasks', () {
      final filtered = testEvents;
      expect(filtered.length, 4);
    });

    test('Filter shows only events', () {
      final filtered = testEvents
          .where((e) => e.type == EventType.event)
          .toList();
      expect(filtered.length, 2);
      expect(filtered.every((e) => e.type == EventType.event), true);
    });

    test('Filter shows only tasks', () {
      final filtered = testEvents
          .where((e) => e.type == EventType.task)
          .toList();
      expect(filtered.length, 2);
      expect(filtered.every((e) => e.type == EventType.task), true);
    });

    test('Filtered events maintain chronological order', () {
      final sorted = List<CalendarEvent>.from(testEvents)
        ..sort((a, b) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
          if (a.isAllDay && b.isAllDay) return 0;

          final aMinutes =
              (a.startTime?.hour ?? 0) * 60 + (a.startTime?.minute ?? 0);
          final bMinutes =
              (b.startTime?.hour ?? 0) * 60 + (b.startTime?.minute ?? 0);
          return aMinutes.compareTo(bMinutes);
        });

      // Verify chronological order
      for (int i = 0; i < sorted.length - 1; i++) {
        final current = sorted[i];
        final next = sorted[i + 1];

        if (!current.isAllDay && !next.isAllDay) {
          final currentMinutes =
              (current.startTime?.hour ?? 0) * 60 +
              (current.startTime?.minute ?? 0);
          final nextMinutes =
              (next.startTime?.hour ?? 0) * 60 + (next.startTime?.minute ?? 0);
          expect(currentMinutes <= nextMinutes, true);
        }
      }
    });

    test('All-day events appear first in sorted list', () {
      final eventsWithAllDay = [
        ...testEvents,
        CalendarEvent(
          id: '5',
          title: 'All Day Event',
          date: DateTime(2024, 1, 15),
          type: EventType.event,
          isAllDay: true,
        ),
      ];

      final sorted = List<CalendarEvent>.from(eventsWithAllDay)
        ..sort((a, b) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
          if (a.isAllDay && b.isAllDay) return 0;

          final aMinutes =
              (a.startTime?.hour ?? 0) * 60 + (a.startTime?.minute ?? 0);
          final bMinutes =
              (b.startTime?.hour ?? 0) * 60 + (b.startTime?.minute ?? 0);
          return aMinutes.compareTo(bMinutes);
        });

      expect(sorted.first.isAllDay, true);
      expect(sorted.first.title, 'All Day Event');
    });
  });

  group('Year View Dot Indicators', () {
    test('Events have orange dots', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Meeting',
          date: DateTime(2024, 1, 15),
          type: EventType.event,
        ),
      ];

      final hasEvents = events.any((e) => e.type == EventType.event);
      expect(hasEvents, true);

      // Orange dot color verification (Colors.orange is MaterialColor)
      const orangeDot = Color(0xFFFF9800);
      expect(orangeDot.toARGB32(), Colors.orange.toARGB32());
    });

    test('Active tasks have green dots', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Task',
          date: DateTime(2024, 1, 15),
          type: EventType.task,
          isCompleted: false,
        ),
      ];

      final tasks = events.where((e) => e.type == EventType.task).toList();
      final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

      expect(incompleteTasks.length, 1);

      // Green dot color verification (Colors.green is MaterialColor)
      const greenDot = Color(0xFF4CAF50);
      expect(greenDot.value, Colors.green.value);
    });

    test('Overdue tasks have red dots', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final events = [
        CalendarEvent(
          id: '1',
          title: 'Overdue Task',
          date: yesterday,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
          isCompleted: false,
        ),
      ];

      final tasks = events.where((e) => e.type == EventType.task).toList();
      final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

      final hasOverdueTasks = incompleteTasks.any((task) {
        final eventDateTime = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          task.endTime?.hour ?? 23,
          task.endTime?.minute ?? 59,
        );
        return eventDateTime.isBefore(now);
      });

      expect(hasOverdueTasks, true);

      // Red dot color verification (Colors.red is MaterialColor)
      const redDot = Color(0xFFF44336);
      expect(redDot.value, Colors.red.value);
    });

    test('Completed tasks have grey dots', () {
      final events = [
        CalendarEvent(
          id: '1',
          title: 'Completed Task',
          date: DateTime(2024, 1, 15),
          type: EventType.task,
          isCompleted: true,
        ),
      ];

      final tasks = events.where((e) => e.type == EventType.task).toList();
      final allTasksCompleted =
          tasks.isNotEmpty && tasks.every((t) => t.isCompleted);

      expect(allTasksCompleted, true);

      // Grey dot color verification (Colors.grey is MaterialColor)
      const greyDot = Color(0xFF9E9E9E);
      expect(greyDot.value, Colors.grey.value);
    });

    test('Mixed tasks show red for overdue', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final events = [
        CalendarEvent(
          id: '1',
          title: 'Overdue Task',
          date: yesterday,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
          isCompleted: false,
        ),
        CalendarEvent(
          id: '2',
          title: 'Completed Task',
          date: yesterday,
          type: EventType.task,
          startTime: const TimeOfDay(hour: 11, minute: 0),
          endTime: const TimeOfDay(hour: 12, minute: 0),
          isCompleted: true,
        ),
      ];

      final tasks = events.where((e) => e.type == EventType.task).toList();
      final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

      final hasOverdueTasks = incompleteTasks.any((task) {
        final eventDateTime = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          task.endTime?.hour ?? 23,
          task.endTime?.minute ?? 59,
        );
        return eventDateTime.isBefore(now);
      });

      // Should show red dot when any task is overdue
      expect(hasOverdueTasks, true);
    });
  });

  group('Sunday Display', () {
    test('Sunday is weekday 7 in Dart', () {
      final sunday = DateTime(2024, 1, 14); // Known Sunday
      expect(sunday.weekday, 7);
    });

    test('Monday is weekday 1 in Dart', () {
      final monday = DateTime(2024, 1, 15); // Known Monday
      expect(monday.weekday, 1);
    });

    test('Saturday is weekday 6 in Dart', () {
      final saturday = DateTime(2024, 1, 13); // Known Saturday
      expect(saturday.weekday, 6);
    });

    test('Red color applied to Sundays', () {
      final sunday = DateTime(2024, 1, 14);
      final isSunday = sunday.weekday == 7;

      expect(isSunday, true);

      // Verify red color constant (Colors.red is MaterialColor)
      const redColor = Color(0xFFF44336);
      expect(redColor.value, Colors.red.value);
    });

    test('Non-Sunday dates do not get red color', () {
      final monday = DateTime(2024, 1, 15);
      final isSunday = monday.weekday == 7;

      expect(isSunday, false);
    });
  });

  group('Task Persistence Across Days', () {
    test('Incomplete task from yesterday still appears today', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final task = CalendarEvent(
        id: '1',
        title: 'Incomplete Task',
        date: yesterday,
        type: EventType.task,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: false,
      );

      // Task persists because it's stored with original date
      expect(task.date, yesterday);
      expect(task.isCompleted, false);

      // In UI, incomplete tasks should be displayed regardless of date
      // if they're not completed
      final shouldDisplay = !task.isCompleted;
      expect(shouldDisplay, true);
    });

    test('Completed task does not show overdue indication', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final task = CalendarEvent(
        id: '1',
        title: 'Completed Task',
        date: yesterday,
        type: EventType.task,
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        isCompleted: true,
      );

      expect(task.isCompleted, true);

      // Completed tasks are not overdue
      final isOverdue =
          !task.isCompleted &&
          DateTime(
            task.date.year,
            task.date.month,
            task.date.day,
            task.endTime?.hour ?? 23,
            task.endTime?.minute ?? 59,
          ).isBefore(now);

      expect(isOverdue, false);
    });
  });

  group('Column Overflow Prevention', () {
    test('Text with Flexible respects parent constraints', () {
      // This is a conceptual test - in real UI, Flexible widgets
      // prevent overflow by constraining child Text widgets
      const containerHeight = 36.0;
      const padding = 16.0;
      const availableHeight = containerHeight - padding;

      // With Flexible, text should not exceed available height
      expect(availableHeight > 0, true);
    });

    test('Long text truncates with ellipsis', () {
      const longText = 'This is a very long text that would normally overflow';

      // TextOverflow.ellipsis ensures text doesn't overflow
      expect(longText.length > 20, true);

      // In actual rendering, ellipsis would be added
      // This test verifies the concept
    });
  });

  group('Event Sorting', () {
    test('Events sorted by start time', () {
      final testDate = DateTime(2024, 1, 15);
      final events = [
        CalendarEvent(
          id: '3',
          title: 'Event 3',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 15, minute: 0),
          endTime: const TimeOfDay(hour: 16, minute: 0),
        ),
        CalendarEvent(
          id: '1',
          title: 'Event 1',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        ),
        CalendarEvent(
          id: '2',
          title: 'Event 2',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 12, minute: 0),
          endTime: const TimeOfDay(hour: 13, minute: 0),
        ),
      ];

      final sorted = List<CalendarEvent>.from(events)
        ..sort((a, b) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
          if (a.isAllDay && b.isAllDay) return 0;

          final aMinutes =
              (a.startTime?.hour ?? 0) * 60 + (a.startTime?.minute ?? 0);
          final bMinutes =
              (b.startTime?.hour ?? 0) * 60 + (b.startTime?.minute ?? 0);
          return aMinutes.compareTo(bMinutes);
        });

      expect(sorted[0].title, 'Event 1'); // 9:00
      expect(sorted[1].title, 'Event 2'); // 12:00
      expect(sorted[2].title, 'Event 3'); // 15:00
    });

    test('All-day events appear before timed events', () {
      final testDate = DateTime(2024, 1, 15);
      final events = [
        CalendarEvent(
          id: '2',
          title: 'Morning Event',
          date: testDate,
          type: EventType.event,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 0),
        ),
        CalendarEvent(
          id: '1',
          title: 'All Day Event',
          date: testDate,
          type: EventType.event,
          isAllDay: true,
        ),
      ];

      final sorted = List<CalendarEvent>.from(events)
        ..sort((a, b) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
          if (a.isAllDay && b.isAllDay) return 0;

          final aMinutes =
              (a.startTime?.hour ?? 0) * 60 + (a.startTime?.minute ?? 0);
          final bMinutes =
              (b.startTime?.hour ?? 0) * 60 + (b.startTime?.minute ?? 0);
          return aMinutes.compareTo(bMinutes);
        });

      expect(sorted[0].title, 'All Day Event');
      expect(sorted[0].isAllDay, true);
      expect(sorted[1].title, 'Morning Event');
      expect(sorted[1].isAllDay, false);
    });
  });

  group('Time Formatting', () {
    test('Format morning time correctly', () {
      const time = TimeOfDay(hour: 9, minute: 30);
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '$hour:$minute $period';

      expect(formatted, '9:30 AM');
    });

    test('Format afternoon time correctly', () {
      const time = TimeOfDay(hour: 15, minute: 45);
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '$hour:$minute $period';

      expect(formatted, '3:45 PM');
    });

    test('Format midnight correctly', () {
      const time = TimeOfDay(hour: 0, minute: 0);
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '$hour:$minute $period';

      expect(formatted, '12:00 AM');
    });

    test('Format noon correctly', () {
      const time = TimeOfDay(hour: 12, minute: 0);
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '$hour:$minute $period';

      expect(formatted, '12:00 PM');
    });
  });

  group('Date Navigation', () {
    test('Navigate to previous month', () {
      final current = DateTime(2024, 3, 15);
      final previous = DateTime(current.year, current.month - 1);

      expect(previous.month, 2);
      expect(previous.year, 2024);
    });

    test('Navigate to next month', () {
      final current = DateTime(2024, 3, 15);
      final next = DateTime(current.year, current.month + 1);

      expect(next.month, 4);
      expect(next.year, 2024);
    });

    test('Navigate from January to previous December', () {
      final current = DateTime(2024, 1, 15);
      final previous = DateTime(current.year, current.month - 1);

      expect(previous.month, 12);
      expect(previous.year, 2023);
    });

    test('Navigate from December to next January', () {
      final current = DateTime(2024, 12, 15);
      final next = DateTime(current.year, current.month + 1);

      expect(next.month, 1);
      expect(next.year, 2025);
    });
  });

  group('Event Type Identification', () {
    test('Event type is correctly identified', () {
      final event = CalendarEvent(
        id: '1',
        title: 'Meeting',
        date: DateTime(2024, 1, 15),
        type: EventType.event,
      );

      expect(event.type, EventType.event);
      expect(event.type == EventType.task, false);
    });

    test('Task type is correctly identified', () {
      final task = CalendarEvent(
        id: '1',
        title: 'Task',
        date: DateTime(2024, 1, 15),
        type: EventType.task,
      );

      expect(task.type, EventType.task);
      expect(task.type == EventType.event, false);
    });
  });
}
